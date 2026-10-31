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

    /** Taille maximale d'une page lue (au-delà : aperçu abandonné). */
    private const MAX_BYTES = 3 * 1024 * 1024;

    /**
     * Protection SSRF : adresse http(s), port standard, IP publique
     * vers laquelle la requête sera épinglée, ou null si l'adresse est refusée.
     * Toutes les IP du nom (IPv4 et IPv6) doivent être publiques ; la connexion utilise ensuite
     * cette IP (CURLOPT_RESOLVE) : un DNS qui change de réponse entre-temps ne peut pas viser le réseau interne.
     *
     * @return array{host: string, port: int, ip: string}|null
     */
    private static function resolve(string $url): ?array
    {
        $parts = parse_url($url);
        $scheme = strtolower($parts['scheme'] ?? '');
        $host = strtolower(trim($parts['host'] ?? '', '[]'));
        if (! in_array($scheme, ['http', 'https'], true) || $host === '' || isset($parts['user']) || isset($parts['pass'])) {
            return null;
        }
        $port = $parts['port'] ?? ($scheme === 'https' ? 443 : 80);
        if (! in_array($port, [80, 443], true)) {
            return null;
        }

        if (filter_var($host, FILTER_VALIDATE_IP)) {
            $ips = [$host];
        } else {
            $records = @dns_get_record($host, DNS_A | DNS_AAAA) ?: [];
            $ips = array_values(array_filter(array_map(fn ($r) => $r['ip'] ?? $r['ipv6'] ?? null, $records)));
            if (! $ips && ($v4 = @gethostbynamel($host))) {
                $ips = $v4;
            }
        }
        if (! $ips) {
            return null;
        }
        foreach ($ips as $ip) {
            if (! self::isPublicIp($ip)) {
                return null;
            }
        }

        return ['host' => $host, 'port' => $port, 'ip' => $ips[0]];
    }

    private static function isPublicIp(string $ip): bool
    {
        if (! filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
            return false;
        }
        // Plages absentes des filtres de PHP : partage d'adresses opérateur (CGNAT), IPv4 mappée en IPv6, NAT64
        foreach (['100.64.0.0/10', '192.0.0.0/24', '198.18.0.0/15'] as $cidr) {
            if (filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_IPV4) && self::inCidr($ip, $cidr)) {
                return false;
            }
        }

        return ! preg_match('/^(::ffff:|64:ff9b:|fc|fd|fe80)/i', $ip);
    }

    private static function inCidr(string $ip, string $cidr): bool
    {
        [$net, $bits] = explode('/', $cidr);
        $mask = -1 << (32 - (int) $bits);

        return (ip2long($ip) & $mask) === (ip2long($net) & $mask);
    }

    /**
     * @return array{name: string, image: ?string, price: ?int, currency: ?string, is_product: bool, in_stock: ?bool}
     */
    public function fetch(string $url): array
    {
        $out = self::empty($url);
        if (! $target = self::resolve($url)) {
            return $out;
        }
        try {
            return self::parse($url, $this->request(null, $target)->get($url));
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
        $targets = [];
        foreach (array_unique($urls) as $u) {
            if ($t = self::resolve($u)) {
                $targets[$u] = $t;
            }
        }
        $urls = array_keys($targets);
        if (! $urls) {
            return [];
        }
        $responses = Http::pool(fn ($pool) => array_map(fn ($u) => $this->request($pool->as($u), $targets[$u])->get($u), $urls));

        $out = [];
        foreach ($urls as $u) {
            $res = $responses[$u] ?? null;
            $out[$u] = $res instanceof Response ? self::parse($u, $res) : self::empty($u);
        }

        return $out;
    }

    private function request($client, array $target)
    {
        // Pas de redirection suivie : sécurité, et sur les boutiques une redirection signale souvent un produit épuisé
        return ($client ?? Http::getFacadeRoot())->timeout(6)->connectTimeout(4)->withOptions([
            'allow_redirects' => false,
            'curl' => [
                CURLOPT_RESOLVE => ["{$target['host']}:{$target['port']}:".(str_contains($target['ip'], ':') ? "[{$target['ip']}]" : $target['ip'])],
            ],
            'on_headers' => function ($response) {
                if ((int) $response->getHeaderLine('Content-Length') > self::MAX_BYTES) {
                    throw new \RuntimeException('Page trop volumineuse.');
                }
            },
            // Taille réellement reçue (Content-Length absent ou faux)
            'progress' => function ($total, $downloaded) {
                if ($downloaded > self::MAX_BYTES) {
                    throw new \RuntimeException('Page trop volumineuse.');
                }
            },
        ])->withHeaders(['User-Agent' => self::USER_AGENT, 'Accept-Language' => 'fr']);
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
        if ($out['image'] !== null && ! preg_match('#^https?://#i', $out['image'])) {
            $out['image'] = null; // image relative ou schéma inattendu (data:, javascript:…)
        }
        $out['image'] = $out['image'] !== null ? mb_substr($out['image'], 0, 2048) : null;
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
