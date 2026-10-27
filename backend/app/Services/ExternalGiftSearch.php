<?php

namespace App\Services;

use Illuminate\Http\Client\Pool;
use Illuminate\Http\Client\Response;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

/**
 * Idées trouvées hors de CADOTER, quand le catalogue ne suffit pas :
 *  0. l'IA traduit la demande en 3 requêtes d'achat variées (« SUV neuf », « berline neuve »… plutôt
 *     que « idée cadeau ») : le moteur trouve des fiches produit au lieu de pages cadeaux génériques ;
 *  1. recherches web de l'IA en parallèle (OpenRouter + Exa), chaque requête sur les boutiques locales
 *     (ex. Jumia) et sur les grands sites internationaux (Amazon, AliExpress…), pour que les
 *     seconds n'écrasent pas les premières ;
 *  2. seules les adresses réellement renvoyées par le moteur sont gardées (l'IA ne peut pas en inventer),
 *     nettoyées de leurs paramètres de suivi (ex. code d'affiliation d'un autre site), et le prix
 *     n'est gardé que s'il figure dans le texte de la page ;
 *  3. chaque adresse doit être une fiche produit : reconnue à sa forme pour les grands sites
 *     (qui bloquent souvent les robots), sinon vérifiée en ouvrant la page ;
 *  4. images : celles de la page, sinon celles indexées par Exa (si EXA_API_KEY est définie),
 *     car les grands sites (ex. Alibaba) renvoient un captcha à notre lecteur de pages.
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
                    'properties' => [
                        'url' => ['type' => 'string'], 'title' => ['type' => 'string'], 'reason' => ['type' => 'string'],
                        // Le vrai objet demandé et adapté à la personne (un jouet ou un accessoire → false, produit écarté)
                        'fits' => ['type' => 'boolean'],
                        // Texte de carte de vœux, à copier par l'acheteur
                        'card' => ['type' => 'string'],
                        // Prix lu dans le texte du résultat : utilisé si la page elle-même ne peut pas être lue
                        'price' => ['type' => ['number', 'null']], 'currency' => ['type' => ['string', 'null']],
                    ],
                    'required' => ['url', 'title', 'reason', 'fits', 'card', 'price', 'currency'],
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

    private const QUERY_SCHEMA = [
        'type' => 'object',
        'properties' => ['queries' => ['type' => 'array', 'items' => ['type' => 'string']]],
        'required' => ['queries'],
        'additionalProperties' => false,
    ];

    public function __construct(private LinkPreview $preview, private OpenRouter $ai) {}

    public function enabled(): bool
    {
        return filled(config('services.openrouter.key')) && $this->domainGroups() !== [];
    }

    /**
     * @return array<int, array{title: string, url: string, image: ?string, price: ?int, currency: ?string, site: string, reason: string, card: string}>
     */
    public function search(array $criteria, int $limit = 10): array
    {
        if (! $this->enabled()) {
            return [];
        }
        $key = 'assistant-ext:v4:'.sha1(json_encode([$criteria, app()->getLocale(), $this->domainGroups(), $limit]));

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
        // Chaque requête sur chaque groupe : locaux d'abord
        $searches = collect($groups)->flatMap(fn ($domains, $g) => array_map(
            fn ($query) => ['group' => $g, 'domains' => $domains, 'query' => $query], $this->searchQueries($c),
        ))->values();
        $responses = Http::pool(fn (Pool $pool) => $searches->map(
            fn ($s, $i) => $this->searchRequest($pool->as("s$i"), $c, $s['domains'], $s['query']),
        )->all());

        $lists = [];
        foreach ($searches as $i => $s) {
            $res = $responses["s$i"] ?? null;
            if (! $res instanceof Response || ! $res->successful() || isset($res['error'])) {
                Log::warning("Recherche externe ({$s['query']}, groupe {$s['group']}) indisponible : "
                    .($res instanceof Response ? $res->body() : ($res?->getMessage() ?? '?')));

                continue;
            }
            $lists[] = $this->picked($res->json(), $s['domains']);
        }
        // Alternance entre les recherches : variété des idées et des sites
        $picked = collect();
        for ($r = 0; $r < 6; $r++) {
            foreach ($lists as $list) {
                if (isset($list[$r])) {
                    $picked->push($list[$r]);
                }
            }
        }
        // Plus de candidats que nécessaire : certains seront écartés à la vérification
        $picked = $picked->unique(fn ($p) => self::key($p['url']))->take($limit + 4)->values();
        if ($picked->isEmpty()) {
            return [];
        }

        $previews = $this->preview->fetchMany($picked->pluck('url')->all());
        $images = $this->indexedImages($picked->pluck('url')->reject(fn ($u) => isset($previews[$u]['image']))->all());

        return $picked->map(fn ($p) => $this->verified($p, $previews[$p['url']] ?? null, $images[self::key($p['url'])] ?? null, $c['budget']))
            ->filter()->take($limit)->values()->all();
    }

    /** Demande complète de l'acheteur, telle que l'IA doit la respecter. */
    private static function describe(array $c): string
    {
        return "Occasion : {$c['event']}. Destinataire : {$c['relation']} ({$c['gender']}, {$c['age']} ans)."
            .(filled($c['info'] ?? null) ? " Précisions de l'acheteur : {$c['info']}." : '')
            ." Budget maximum : {$c['budget']} FCFA (environ ".(int) round($c['budget'] / self::EUR_TO_XOF).' €).';
    }

    /**
     * Jusqu'à 3 requêtes d'achat concrètes et variées pour le moteur de recherche (à défaut : les précisions de l'acheteur).
     *
     * @return string[]
     */
    private function searchQueries(array $c): array
    {
        try {
            $queries = $this->ai->json(
                'Tu prépares une recherche sur des sites marchands. Écris 3 requêtes différentes (3 à 8 mots chacune, en français) '
                .'qu\'on taperait pour trouver des fiches produit à acheter, en variant les idées (modèles, gammes, styles). '
                .'Si l\'acheteur demande un objet précis, chaque requête décrit ce vrai objet adapté à la personne et au budget '
                .'(ex. « SUV neuf 5 places automatique », « berline neuve confortable », « voiture électrique citadine neuve »), '
                .'sans les mots cadeau, jouet ou miniature. '
                .'Sinon, choisis des types de produits concrets adaptés aux goûts, au sexe, à l\'âge, à l\'occasion et au budget.',
                self::describe($c),
                'search_queries',
                self::QUERY_SCHEMA,
                200,
            )['data']['queries'] ?? [];
        } catch (Throwable $e) {
            Log::warning("Requêtes de recherche externe par défaut : {$e->getMessage()}");
            $queries = [];
        }
        $queries = collect(is_array($queries) ? $queries : [])->filter(fn ($q) => is_string($q) && trim($q) !== '')
            ->map(fn ($q) => Str::limit(trim($q), 120, ''))->unique()->take(3)->values()->all();

        return $queries ?: [filled($c['info'] ?? null) ? $c['info'] : "cadeau {$c['event']} {$c['relation']}"];
    }

    /**
     * Images des pages indexées par Exa, pour les sites qui bloquent notre lecteur de pages.
     *
     * @param  string[]  $urls
     * @return array<string, string> images indexées par self::key(url)
     */
    private function indexedImages(array $urls): array
    {
        if (! $urls || blank(config('services.exa.key'))) {
            return [];
        }
        try {
            $res = Http::withHeaders(['x-api-key' => config('services.exa.key')])->acceptJson()
                ->timeout(10)->connectTimeout(5)
                ->post('https://api.exa.ai/contents', ['urls' => array_values($urls)])->throw()->json();
        } catch (Throwable $e) {
            Log::warning("Images Exa indisponibles : {$e->getMessage()}");

            return [];
        }

        return collect($res['results'] ?? [])
            ->filter(fn ($r) => is_string($r['url'] ?? null) && is_string($r['image'] ?? null) && str_starts_with($r['image'], 'https://'))
            ->mapWithKeys(fn ($r) => [self::key($r['url']) => $r['image']])->all();
    }

    private function searchRequest($client, array $c, array $domains, string $query)
    {
        $lang = app()->getLocale() === 'en' ? 'anglais' : 'français';

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
                        .'adaptées à la personne (sexe, âge, lien), à l\'occasion et dans le budget. '
                        .'Si l\'acheteur demande un objet précis (ex. une voiture), ne propose que ce vrai objet : '
                        .'jamais une miniature, un jouet, un accessoire ou un produit dérivé. '
                        .'Recopie l\'adresse exacte de chaque page. '
                        ."Pour chacune, donne en $lang le nom court et clair du produit (sans le nom du site) "
                        .'et une raison de 2 à 3 phrases adressée à l\'acheteur, qui s\'appuie sur toute sa demande : '
                        .'ce que ce produit a de concret d\'après le texte de sa page (caractéristiques, équipement, matière…), '
                        .'pourquoi il convient à cette personne précise (son âge, votre lien, ses goûts) et à l\'occasion, '
                        .'et, pour un site étranger, le point pratique à prévoir (livraison ou importation en Côte d\'Ivoire). '
                        .'Pas de formule creuse ou passe-partout, pas de prix (il est affiché à part). '
                        ."Écris aussi en $lang le champ "
                        .'card : le texte d\'une carte de vœux à glisser avec ce cadeau, que l\'acheteur recopiera tel quel : '
                        .'2 à 4 phrases chaleureuses, écrites par l\'acheteur à la personne (« Maman, … » pour une mère ; tutoiement ou vouvoiement selon le lien), '
                        .'adaptées à l\'occasion (pour un décès : un message de soutien sobre, jamais de vœux), qui évoquent le cadeau avec délicatesse '
            .'et ce que la personne aime ; sans prix, sans signature, sans guillemets. '
                        .'Dans price et currency (code ISO, ex. XOF, EUR, USD), recopie le prix écrit dans le résultat de recherche '
                        .'(le plus bas s\'il y a une fourchette), ou null s\'il n\'y figure pas : ne l\'estime jamais. '
                        .'fits : true seulement si la page est bien ce que l\'acheteur cherche, pour cette personne ; '
                        .'sinon false (mieux : ne mets pas ce produit dans la liste). '
                        .'Si rien ne convient, renvoie une liste vide.'
                        ."\n\nDemande de l'acheteur : ".self::describe($c)],
                    // La recherche web s'appuie sur ce message : une requête d'achat concrète
                    ['role' => 'user', 'content' => $query],
                ],
                'response_format' => ['type' => 'json_schema', 'json_schema' => ['name' => 'external_products', 'strict' => true, 'schema' => self::SCHEMA]],
                'provider' => ['require_parameters' => true],
                'reasoning' => ['enabled' => false],
                'max_tokens' => 3000,
            ]);
    }

    /** Produits choisis par l'IA, limités aux adresses réellement trouvées par le moteur. */
    private function picked(array $res, array $domains): array
    {
        $message = $res['choices'][0]['message'] ?? [];
        $content = (string) ($message['content'] ?? '');
        $data = json_decode($content, true) ?? (preg_match('/\{.*\}/s', $content, $m) ? json_decode($m[0], true) : null);
        // Adresse trouvée par le moteur → chiffres du texte de sa page (pour vérifier le prix recopié par l'IA)
        $found = collect($message['annotations'] ?? [])->filter(fn ($a) => is_string($a['url_citation']['url'] ?? null))
            ->mapWithKeys(fn ($a) => [self::key($a['url_citation']['url']) => preg_replace('/\D+/', '', (string) ($a['url_citation']['content'] ?? ''))]);

        return collect($data['products'] ?? [])
            ->filter(fn ($p) => ($p['fits'] ?? false) === true && is_string($p['url'] ?? null)
                && isset($found[self::key($p['url'])]) && self::inDomains($p['url'], $domains))
            ->map(function ($p) use ($found) {
                $price = is_numeric($p['price'] ?? null) && $p['price'] > 0 ? (float) $p['price'] : null;
                if ($price !== null && ! str_contains($found[self::key($p['url'])], preg_replace('/\D+/', '', (string) $price))) {
                    $price = null; // absent du texte de la page : inventé ou mal lu
                }

                return [
                    'url' => self::clean($p['url']), 'title' => trim((string) ($p['title'] ?? '')), 'reason' => self::plain((string) ($p['reason'] ?? '')), 'card' => self::plain((string) ($p['card'] ?? '')),
                    'price' => $price, 'currency' => $price !== null && is_string($p['currency'] ?? null) ? $p['currency'] : null,
                ];
            })
            ->values()->all();
    }

    private function verified(array $p, ?array $info, ?string $indexedImage, int $budget): ?array
    {
        $knownProductUrl = self::looksLikeProduct($p['url']);
        if (! $knownProductUrl && ! ($info['is_product'] ?? false)) {
            return null; // page non reconnue comme fiche produit
        }
        if (($info['in_stock'] ?? null) === false) {
            return null;
        }

        // Prix de la page, sinon celui du résultat de recherche ; en FCFA quand c'est possible (l'euro a une parité fixe)
        [$price, $currency] = isset($info['price']) ? [$info['price'], $info['currency'] ?? null] : [$p['price'], $p['currency']];
        $currency = strtoupper((string) $currency);
        if ($price !== null && $currency === 'EUR') {
            [$price, $currency] = [$price * self::EUR_TO_XOF, 'XOF'];
        }
        $price = $price === null ? null : (int) round($price);
        $xof = in_array($currency, ['XOF', 'FCFA', 'CFA'], true);
        if ($xof && $price > $budget) {
            return null;
        }

        return [
            // Données de la page si elle a pu être lue, sinon nom donné par l'IA d'après le résultat de recherche
            'title' => ($info['is_product'] ?? false) ? $info['name'] : (Str::limit($p['title'], 160) ?: ($info['name'] ?? '')),
            'url' => $p['url'],
            'image' => $info['image'] ?? $indexedImage,
            'price' => $price,
            'currency' => $price === null ? null : ($xof ? 'FCFA' : ($currency ?: null)),
            'site' => Str::after((string) parse_url($p['url'], PHP_URL_HOST), 'www.'),
            'reason' => Str::limit($p['reason'], 600),
            'card' => Str::limit($p['card'], 700),
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

    /** Texte sans liens markdown ni adresses (certains modèles citent leurs sources dans la raison). */
    private static function plain(string $text): string
    {
        $text = preg_replace('/\[([^\]]*)\]\([^)]*\)/u', '$1', $text);

        return trim(preg_replace(['#\s*\(?https?://\S+\)?#u', '/\s+/u'], ['', ' '], $text));
    }

    private static function key(string $url): string
    {
        return rtrim(strtolower(self::clean($url)), '/');
    }
}
