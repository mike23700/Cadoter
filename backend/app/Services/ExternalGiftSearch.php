<?php

namespace App\Services;

use Illuminate\Http\Client\Pool;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Idées trouvées hors de CADOTER, quand le catalogue ne suffit pas :
 *  1. deux recherches web de l'IA en parallèle (OpenRouter + Exa) : boutiques locales
 *     (ex. Jumia) et grands sites internationaux (Amazon, AliExpress…), pour que les
 *     seconds n'écrasent pas les premières ;
 *  2. seules les adresses réellement renvoyées par le moteur sont gardées (l'IA ne peut pas en inventer),
 *     nettoyées de leurs paramètres de suivi (ex. code d'affiliation d'un autre site) ;
 *  3. chaque adresse doit être une fiche produit : reconnue à sa forme pour les grands sites
 *     (qui bloquent souvent les robots), sinon vérifiée en ouvrant la page.
 */
class ExternalGiftSearch
{
    private const SCHEMA = [
        'type' => 'object',
        'properties' => [
            'products' => [
                'type' => 'array',
                'items' => [
                    'type' => 'object',
                    'properties' => ['url' => ['type' => 'string'], 'title' => ['type' => 'string'], 'reason' => ['type' => 'string']],
                    'required' => ['url', 'title', 'reason'],
                    'additionalProperties' => false,
                ],
            ],
        ],
        'required' => ['products'],
        'additionalProperties' => false,
    ];

    /** Forme des adresses de fiches produit des grandes boutiques (le reste : catégories, recherches…). */
    private const PRODUCT_URLS = [
        'amazon.' => '#/(dp|gp/product)/[A-Z0-9]{10}#i',
        'aliexpress.' => '#/item/\d+\.html#',
        'alibaba.com' => '#/product-detail/#',
        'ebay.' => '#/itm/\d+#',
        'etsy.com' => '#/listing/\d+#',
        'temu.com' => '#-g-\d+\.html#',
        'cdiscount.com' => '#/f-\d+-[^/]+\.html#',
        'fnac.com' => '#/a\d+/#',
        'jumia.' => '#-\d+\.html$#',
    ];

    /** Parité fixe du franc CFA avec l'euro. */
    private const EUR_TO_XOF = 655.957;

    public function __construct(private LinkPreview $preview) {}

    public function enabled(): bool
    {
        return filled(config('services.openrouter.key')) && $this->domainGroups() !== [];
    }

    /**
     * @return array<int, array{title: string, url: string, image: ?string, price: ?int, currency: ?string, site: string, reason: string}>
     */
    public function search(array $criteria, int $limit = 6): array
    {
        if (! $this->enabled()) {
            return [];
        }
        $key = 'assistant-ext:'.sha1(json_encode([$criteria, app()->getLocale(), $this->domainGroups()]));

        return Cache::remember($key, now()->addHours(6), fn () => $this->run($criteria, $limit));
    }

    /** Groupes de domaines cherchés séparément : locaux d'abord, puis internationaux. */
    private function domainGroups(): array
    {
        return array_values(array_filter([
            config('services.openrouter.external_domains'),
            config('services.openrouter.external_intl_domains'),
        ]));
    }

    private function run(array $c, int $limit): array
    {
        $groups = $this->domainGroups();
        $responses = Http::pool(fn (Pool $pool) => array_map(
            fn ($i) => $this->searchRequest($pool->as("g$i"), $c, $groups[$i]),
            array_keys($groups),
        ));

        // Sélection de l'IA dans chaque groupe, puis alternance locale / internationale
        $byGroup = [];
        foreach (array_keys($groups) as $i) {
            $res = $responses["g$i"] ?? null;
            if (! $res instanceof Response || ! $res->successful() || isset($res['error'])) {
                Log::warning("Recherche externe (groupe $i) indisponible : ".($res instanceof Response ? $res->body() : ($res?->getMessage() ?? '?')));

                continue;
            }
            $byGroup[] = $this->picked($res->json(), $groups[$i]);
        }
        $picked = collect();
        for ($r = 0; $r < 6; $r++) {
            foreach ($byGroup as $list) {
                if (isset($list[$r])) {
                    $picked->push($list[$r]);
                }
            }
        }
        $picked = $picked->unique('url')->take(10)->values();
        if ($picked->isEmpty()) {
            return [];
        }

        $previews = $this->preview->fetchMany($picked->pluck('url')->all());

        return $picked->map(fn ($p) => $this->verified($p, $previews[$p['url']] ?? null, $c['budget']))
            ->filter()->take($limit)->values()->all();
    }

    private function searchRequest($client, array $c, array $domains)
    {
        $lang = app()->getLocale() === 'en' ? 'anglais' : 'français';
        $who = "{$c['relation']} ({$c['gender']}, {$c['age']} ans)";
        // La recherche web s'appuie sur ce message : une demande d'achat concrète
        $request = "Idée cadeau pour : {$c['event']}. Destinataire : $who."
            .(filled($c['info'] ?? null) ? " Ce qu'il ou elle aime : {$c['info']}." : '')
            ." Budget maximum : {$c['budget']} FCFA (environ ".(int) round($c['budget'] / self::EUR_TO_XOF).' €).';

        return $client->baseUrl(config('services.openrouter.url'))
            ->withToken(config('services.openrouter.key'))
            ->withHeaders(['X-Title' => 'CADOTER'])
            ->timeout(30)->connectTimeout(5)
            ->post('/chat/completions', [
                'models' => [config('services.openrouter.model'), ...config('services.openrouter.fallback_models')],
                'plugins' => [['id' => 'web', 'engine' => 'exa', 'max_results' => 10, 'include_domains' => $domains]],
                'messages' => [
                    ['role' => 'system', 'content' => "Tu aides l'assistante cadeaux de CADOTER (Côte d'Ivoire). Parmi les résultats de recherche web, "
                        .'choisis au maximum 6 pages qui sont des fiches produit (jamais des catégories, résultats de recherche, classements ou articles), '
                        .'adaptées à la personne et dans le budget. Recopie l\'adresse exacte de chaque page. '
                        ."Pour chacune, donne en $lang le nom court et clair du produit (sans le nom du site) et une raison courte (1 phrase) "
                        .'adressée à l\'acheteur, sans citer de prix (il est affiché à part). Si rien ne convient, renvoie une liste vide.'],
                    ['role' => 'user', 'content' => $request],
                ],
                'response_format' => ['type' => 'json_schema', 'json_schema' => ['name' => 'external_products', 'strict' => true, 'schema' => self::SCHEMA]],
                'provider' => ['require_parameters' => true],
                'reasoning' => ['enabled' => false],
                'max_tokens' => 1500,
            ]);
    }

    /** Produits choisis par l'IA, limités aux adresses réellement trouvées par le moteur. */
    private function picked(array $res, array $domains): array
    {
        $message = $res['choices'][0]['message'] ?? [];
        $content = (string) ($message['content'] ?? '');
        $data = json_decode($content, true) ?? (preg_match('/\{.*\}/s', $content, $m) ? json_decode($m[0], true) : null);
        $found = collect($message['annotations'] ?? [])->pluck('url_citation.url')->filter()
            ->map(fn ($u) => self::key($u))->flip();

        return collect($data['products'] ?? [])
            ->filter(fn ($p) => is_string($p['url'] ?? null) && isset($found[self::key($p['url'])]) && self::inDomains($p['url'], $domains))
            ->map(fn ($p) => ['url' => self::clean($p['url']), 'title' => trim((string) ($p['title'] ?? '')), 'reason' => trim((string) ($p['reason'] ?? ''))])
            ->values()->all();
    }

    private function verified(array $p, ?array $info, int $budget): ?array
    {
        $knownProductUrl = self::looksLikeProduct($p['url']);
        if (! $knownProductUrl && ! ($info['is_product'] ?? false)) {
            return null; // page non reconnue comme fiche produit
        }
        if (($info['in_stock'] ?? null) === false) {
            return null;
        }

        // Prix en FCFA quand il est connu (l'euro a une parité fixe)
        $currency = strtoupper((string) ($info['currency'] ?? ''));
        $price = $info['price'] ?? null;
        if ($price !== null && $currency === 'EUR') {
            [$price, $currency] = [(int) round($price * self::EUR_TO_XOF), 'XOF'];
        }
        $xof = in_array($currency, ['XOF', 'FCFA', 'CFA'], true);
        if ($xof && $price > $budget) {
            return null;
        }

        return [
            // Données de la page si elle a pu être lue, sinon nom donné par l'IA d'après le résultat de recherche
            'title' => ($info['is_product'] ?? false) ? $info['name'] : (Str::limit($p['title'], 160) ?: ($info['name'] ?? '')),
            'url' => $p['url'],
            'image' => $info['image'] ?? null,
            'price' => $price,
            'currency' => $price === null ? null : ($xof ? 'FCFA' : ($currency ?: null)),
            'site' => Str::after((string) parse_url($p['url'], PHP_URL_HOST), 'www.'),
            'reason' => Str::limit($p['reason'], 300),
        ];
    }

    private static function looksLikeProduct(string $url): bool
    {
        $host = strtolower((string) parse_url($url, PHP_URL_HOST));
        foreach (self::PRODUCT_URLS as $site => $pattern) {
            if (str_contains($host, $site)) {
                return (bool) preg_match($pattern, (string) parse_url($url, PHP_URL_PATH));
            }
        }

        return false;
    }

    private static function inDomains(string $url, array $domains): bool
    {
        $host = strtolower((string) parse_url($url, PHP_URL_HOST));

        return collect($domains)->contains(fn ($d) => $host === $d || Str::endsWith($host, '.'.$d));
    }

    /** Adresse sans paramètres ni ancre : retire les codes de suivi et d'affiliation d'autres sites. */
    private static function clean(string $url): string
    {
        return preg_replace('/[?#].*$/', '', $url);
    }

    private static function key(string $url): string
    {
        return rtrim(strtolower(self::clean($url)), '/');
    }
}
