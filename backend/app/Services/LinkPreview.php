<?php

namespace App\Services;

use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Http;
use Throwable;

/**
 * Lecture d'une page produit externe : titre, image, prix (balises Open Graph et
 * données schema.org « Product »). Utilisé pour les produits externes des listes
 * et pour vérifier les résultats de la recherche web de l'assistante.
 */
class LinkPreview
{
    private const USER_AGENT = 'Mozilla/5.0 CadoterBot';

    /** Adresse http(s) vers une IP publique uniquement (protection SSRF). */
    public static function isSafeUrl(string $url): bool
    {
        $host = parse_url($url, PHP_URL_HOST);
        $ip = $host ? gethostbyname($host) : null;

        return in_array(parse_url($url, PHP_URL_SCHEME), ['http', 'https'], true) && $ip
            && filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE);
    }

    /**
     * @return array{name: string, image: ?string, price: ?int, currency: ?string, is_product: bool, in_stock: ?bool}
     */
    public function fetch(string $url): array
    {
        $out = self::empty($url);
        if (! self::isSafeUrl($url)) {
            return $out;
        }
        try {
            return self::parse($url, $this->request()->get($url));
        } catch (Throwable) {
            return $out; // l'aperçu est facultatif
        }
    }

    /**
     * Plusieurs pages en parallèle (mêmes garanties que fetch()).
     *
     * @param  string[]  $urls
     * @return array<string, array> aperçus indexés par URL
     */
    public function fetchMany(array $urls): array
    {
        $urls = array_values(array_filter(array_unique($urls), self::isSafeUrl(...)));
        if (! $urls) {
            return [];
        }
        $responses = Http::pool(fn ($pool) => array_map(fn ($u) => $this->request($pool->as($u))->get($u), $urls));

        $out = [];
        foreach ($urls as $u) {
            $res = $responses[$u] ?? null;
            $out[$u] = $res instanceof Response ? self::parse($u, $res) : self::empty($u);
        }

        return $out;
    }

    private function request($client = null)
    {
        // Pas de redirection suivie : sécurité, et sur les boutiques une redirection signale souvent un produit épuisé
        return ($client ?? Http::getFacadeRoot())->timeout(6)->withOptions(['allow_redirects' => false])
            ->withHeaders(['User-Agent' => self::USER_AGENT, 'Accept-Language' => 'fr']);
    }

    private static function empty(string $url): array
    {
        return ['name' => parse_url($url, PHP_URL_HOST) ?: __('Produit externe'), 'image' => null, 'price' => null, 'currency' => null, 'is_product' => false, 'in_stock' => null];
    }

    private static function parse(string $url, Response $res): array
    {
        $out = self::empty($url);
        if ($res->status() !== 200) {
            return $out;
        }
        $html = $res->body();
        // content="…" peut contenir des apostrophes (et inversement) ; attributs dans les deux ordres
        $meta = function (string $prop) use ($html) {
            $p = preg_quote($prop, '/');
            if (preg_match('/<meta[^>]+(?:property|name)=["\']'.$p.'["\'][^>]*?content=(["\'])(.*?)\1/is', $html, $m)
                || preg_match('/<meta[^>]+content=(["\'])(.*?)\1[^>]*?(?:property|name)=["\']'.$p.'["\']/is', $html, $m)) {
                return trim(html_entity_decode($m[2])) ?: null;
            }

            return null;
        };

        $product = self::jsonLdProduct($html);
        $offer = $product['offers'] ?? null;
        $offer = is_array($offer) && array_is_list($offer) ? ($offer[0] ?? null) : $offer;
        $image = $product['image'] ?? null;
        $image = is_array($image) ? ($image['url'] ?? ($image[0] ?? null)) : $image;

        // Le nom des données produit est souvent complet, og:title parfois tronqué par la boutique
        $out['name'] = (is_string($product['name'] ?? null) ? trim(html_entity_decode($product['name'])) : null) ?: $meta('og:title')
            ?? (preg_match('/<title>([^<]+)/i', $html, $m) ? trim(html_entity_decode($m[1])) : $out['name']);
        $out['image'] = $meta('og:image') ?? (is_string($image) ? $image : null);
        $price = $offer['price'] ?? $offer['lowPrice'] ?? $meta('product:price:amount') ?? $meta('og:price:amount');
        $out['price'] = is_numeric(str_replace([' ', ','], ['', '.'], (string) $price)) ? (int) round((float) str_replace([' ', ','], ['', '.'], (string) $price)) : null;
        $out['currency'] = $offer['priceCurrency'] ?? $meta('product:price:currency') ?? $meta('og:price:currency');
        $out['is_product'] = $product !== null || strtolower((string) $meta('og:type')) === 'product';
        if (isset($offer['availability'])) {
            $out['in_stock'] = str_contains(strtolower((string) $offer['availability']), 'instock');
        }
        $out['name'] = mb_substr($out['name'], 0, 190);

        return $out;
    }

    /** Premier objet schema.org « Product » des blocs JSON-LD de la page. */
    private static function jsonLdProduct(string $html): ?array
    {
        preg_match_all('#<script[^>]+type=["\']application/ld\+json["\'][^>]*>(.*?)</script>#is', $html, $blocks);
        foreach ($blocks[1] as $json) {
            $data = json_decode(html_entity_decode(trim($json)), true);
            $stack = is_array($data) ? [$data] : [];
            while ($node = array_pop($stack)) {
                $type = $node['@type'] ?? null;
                if ($type === 'Product' || (is_array($type) && in_array('Product', $type, true))) {
                    return $node;
                }
                foreach (array_is_list($node) ? $node : ($node['@graph'] ?? []) as $child) {
                    if (is_array($child)) {
                        $stack[] = $child;
                    }
                }
            }
        }

        return null;
    }
}
