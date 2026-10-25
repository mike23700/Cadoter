<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gift;
use App\Services\ExternalGiftSearch;
use App\Services\GiftSearch;
use App\Services\OpenRouter;
use Illuminate\Http\Request;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

/**
 * Suggestions de cadeaux de l'assistante.
 *  1. recherche hybride dans le catalogue → ~30 candidats qui respectent budget et ville ;
 *  2. l'IA (OpenRouter) choisit les 4 meilleurs et explique chaque choix ;
 *  3. si l'IA est indisponible, sélection par règles (ci-dessous) : le client a toujours une réponse.
 */
class AssistantController extends Controller
{
    private const RELATION_TO_FOR_WHO = [
        'Mère' => 'Parents', 'Père' => 'Parents', 'Parent' => 'Parents',
        'Ami' => 'Ami(e)s', 'Amie' => 'Ami(e)s',
        'Conjoint' => 'Couple', 'Conjointe' => 'Couple',
        'Collègue' => 'Collègue', 'Enfant' => 'Enfants',
        'Frère' => 'Famille', 'Sœur' => 'Famille', 'Famille' => 'Famille',
    ];

    private const SELECTION_SCHEMA = [
        'type' => 'object',
        'properties' => [
            // Objet précis demandé (« une voiture »), vide pour un simple goût (« elle aime le luxe »)
            'requested_item' => ['type' => 'string'],
            'requested_item_in_list' => ['type' => 'boolean'],
            'suggestions' => [
                'type' => 'array',
                'items' => [
                    'type' => 'object',
                    'properties' => ['id' => ['type' => 'integer'], 'reason' => ['type' => 'string']],
                    'required' => ['id', 'reason'],
                    'additionalProperties' => false,
                ],
            ],
        ],
        'required' => ['requested_item', 'requested_item_in_list', 'suggestions'],
        'additionalProperties' => false,
    ];

    public function __construct(private OpenRouter $ai, private GiftSearch $search) {}

    /** Idées hors catalogue (sites marchands autorisés), quand CADOTER a peu de suggestions. */
    public function external(Request $request, ExternalGiftSearch $external)
    {
        $data = $this->criteria($request);
        try {
            $results = $external->search($data);
        } catch (Throwable $e) {
            Log::warning("Recherche externe indisponible : {$e->getMessage()}");
            $results = [];
        }

        return response()->json([
            'results' => $results,
            'disclaimer' => __('Produits vendus par des sites partenaires externes : prix, disponibilité et livraison à vérifier sur leur site.'),
        ]);
    }

    public function suggest(Request $request)
    {
        $data = $this->criteria($request);
        $forWho = $data['age'] < 13 ? 'Enfants' : (self::RELATION_TO_FOR_WHO[$data['relation']] ?? null);

        $suggestions = $this->aiSuggestions($data, $forWho) ?? $this->ruleSuggestions($data, $forWho);

        return response()->json([
            'criteria' => $data,
            'suggestions' => $suggestions,
            // Le site propose des idées hors catalogue quand il y en a moins de 3
            'external_available' => app(ExternalGiftSearch::class)->enabled(),
            'disclaimer' => __('Exemples de suggestions, sans garantie de disponibilité. Prix et disponibilité à confirmer auprès du marchand.'),
        ]);
    }

    private function criteria(Request $request): array
    {
        return $request->validate([
            'event' => ['required', 'string', 'max:60'],
            'gender' => ['required', 'string', 'max:20'],
            'age' => ['required', 'integer', 'min:0', 'max:120'],
            'relation' => ['required', 'string', 'max:40'],
            'budget' => ['required', 'integer', 'min:1000'],
            'city' => ['nullable', 'string', 'max:80'],
            'info' => ['nullable', 'string', 'max:500'],
        ]);
    }

    /** Sélection par l'IA parmi les candidats de la recherche hybride, ou null si elle échoue. */
    private function aiSuggestions(array $data, ?string $forWho): ?Collection
    {
        if (! $this->ai->enabled()) {
            return null;
        }

        $who = trim("{$data['relation']} ({$data['gender']}, {$data['age']} ans)");
        $query = collect([
            "Cadeau pour : {$data['event']}.",
            "Destinataire : $who.",
            filled($data['info'] ?? null) ? "Ce qu'il ou elle aime : {$data['info']}" : null,
        ])->filter()->implode("\n");

        // Mêmes critères, même langue → même sélection pendant une heure (ids + raisons seulement)
        $key = 'assistant:'.sha1(json_encode([$data, app()->getLocale(), config('services.openrouter.model')]));
        $picked = Cache::get($key);

        if ($picked === null) {
            $candidates = $this->search->candidates($query, [
                'budget' => $data['budget'], 'city' => $data['city'] ?? null, 'occasion' => $data['event'], 'for_who' => $forWho,
            ]);
            if ($candidates->isEmpty()) {
                return collect();
            }

            try {
                $picked = $this->pick($query, $data, $candidates);
            } catch (Throwable $e) {
                Log::warning("Assistante IA indisponible, sélection par règles : {$e->getMessage()}");

                return null;
            }
            // Liste vide = l'IA juge que rien ne convient (ex. « une voiture ») : on le respecte,
            // le site cherchera alors des idées ailleurs au lieu de proposer des cadeaux hors sujet
            Cache::put($key, $picked, now()->addHour());
        }
        if ($picked === []) {
            return collect();
        }

        // Rechargés à chaque fois : un cadeau retiré ou épuisé entre-temps n'est plus proposé
        $gifts = Gift::with('partner:id,shop_name')->whereKey(array_column($picked, 'id'))
            ->where('is_active', true)->where('price', '<=', $data['budget'])->get()->keyBy('id');

        $out = collect($picked)->filter(fn ($p) => isset($gifts[$p['id']]) && $gifts[$p['id']]->available)
            ->map(fn ($p) => ['gift' => $gifts[$p['id']], 'reason' => $p['reason']])->values();

        return $out->isEmpty() ? null : $out;
    }

    /** @return array<int, array{id: int, reason: string}> */
    private function pick(string $query, array $data, Collection $candidates): array
    {
        $lang = app()->getLocale() === 'en' ? 'anglais' : 'français';
        $list = $candidates->map(fn (Gift $g) => collect([
            "#{$g->id} {$g->name}",
            number_format($g->price, 0, ',', ' ').' '.$g->currency,
            collect([$g->area, $g->city])->filter()->implode(', '),
            $g->category,
            $g->for_who ? 'pour : '.implode(', ', $g->for_who) : null,
            $g->occasions ? 'occasions : '.implode(', ', $g->occasions) : null,
            $g->ai_tags ? "mots-clés : {$g->ai_tags}" : null,
            $g->description ? Str::limit($g->description, 220) : null,
        ])->filter()->implode(' | '))->implode("\n");

        $res = $this->ai->json(
            "Tu es l'assistante cadeaux de CADOTER, un site de cadeaux en Côte d'Ivoire. "
            .'Choisis au maximum 4 cadeaux parmi la liste fournie, les plus adaptés à la personne et à l\'occasion, '
            .'en variant les idées. Utilise uniquement les numéros (#id) de la liste : n\'invente jamais de produit. '
            ."Pour chaque cadeau, écris en $lang une raison courte (1 à 2 phrases, sans répéter le prix) adressée à l'acheteur, "
            .'qui fait le lien avec ce que la personne aime. Si rien ne convient vraiment, renvoie une liste vide. '
            .'Respecte le sexe de la personne : jamais un produit marqué pour l\'autre sexe (ex. « parfum homme » pour une femme). '
            .'Avant de choisir, remplis requested_item : l\'objet précis que l\'acheteur veut offrir (« voiture », « iPhone », « voyage »), '
            .'ou une chaîne vide s\'il décrit seulement des goûts (« elle aime le luxe », « il aime la musique »). '
            .'Puis requested_item_in_list : true seulement si cet objet (ou le même type d\'objet) figure dans la liste. '
            .'Si un objet précis est demandé et absent, ne propose aucun substitut : suggestions vide.',
            "Demande :\n$query\nBudget maximum : {$data['budget']} FCFA\n\nCadeaux disponibles :\n$list",
            'gift_selection',
            self::SELECTION_SCHEMA,
            1000,
        );

        // Objet précis demandé mais absent du catalogue : aucun substitut, même si l'IA en propose
        if (filled(trim((string) ($res['data']['requested_item'] ?? ''))) && ($res['data']['requested_item_in_list'] ?? false) !== true) {
            return [];
        }

        $allowed = $candidates->pluck('id')->flip();

        return collect($res['data']['suggestions'] ?? [])
            ->filter(fn ($s) => isset($s['id'], $allowed[(int) $s['id']]) && filled($s['reason'] ?? null))
            ->unique(fn ($s) => (int) $s['id'])->take(4)
            ->map(fn ($s) => ['id' => (int) $s['id'], 'reason' => Str::limit(trim($s['reason']), 400)])
            ->values()->all();
    }

    /** Sélection par règles (sans IA) : occasion, destinataire, mots de la description, budget. */
    private function ruleSuggestions(array $data, ?string $forWho): Collection
    {
        $stop = ['elle', 'aime', 'adore', 'avec', 'pour', 'dans', 'les', 'des', 'une', 'son', 'ses', 'sur', 'qui', 'que', 'est', 'tres', 'beaucoup', 'moments'];
        // clé = mot sans accents (comparaison), valeur = mot saisi (affichage)
        $words = collect(preg_split('/[\s,;.!?\'’]+/u', Str::lower($data['info'] ?? '')))
            ->mapWithKeys(fn ($w) => [Str::ascii($w) => $w])
            ->filter(fn ($w, $k) => strlen($k) >= 3 && ! in_array($k, $stop, true));

        // Produits explicitement destinés à l'autre sexe (ex. « coffret parfum homme » pour une mère)
        $other = ['Femme' => 'homme', 'Fille' => 'homme', 'Homme' => 'femme', 'Garçon' => 'femme'][$data['gender']] ?? null;

        return Gift::with('partner:id,shop_name')->where('is_active', true)->where('price', '<=', $data['budget'])
            ->when($data['city'] ?? null, fn ($q, $c) => $q->where('city', $c))
            ->get()
            ->reject(fn (Gift $g) => $other && preg_match('/\b'.$other.'s?\b/u', Str::lower(Str::ascii($g->name.' '.$g->description))))
            ->map(function (Gift $g) use ($data, $forWho, $words) {
                $text = Str::lower(Str::ascii($g->name.' '.$g->description));
                $score = 0;
                $score += in_array($data['event'], $g->occasions ?? [], true) ? 3 : 0;
                $score += $forWho && in_array($forWho, $g->for_who ?? [], true) ? 3 : 0;
                $matches = $words->filter(fn ($w, $k) => str_contains($text, Str::substr($k, 0, 5)))->values();
                $score += $matches->count() * 2;
                $score += $g->price / max($data['budget'], 1); // privilégie ce qui exploite le budget

                return ['gift' => $g, 'score' => $score, 'matches' => $matches];
            })
            ->sortByDesc('score')->take(4)->values()
            ->map(fn ($r) => [
                'gift' => $r['gift'],
                'reason' => $this->reason($r['gift'], $data, $r['matches']->all()),
            ]);
    }

    private function reason(Gift $g, array $d, array $matches): string
    {
        $female = in_array($d['gender'], ['Femme', 'Fille'], true);
        if ($matches) {
            return __($female ? "En lien avec ce qu'elle aime (:likes) : une attention personnelle, dans votre budget." : "En lien avec ce qu'il aime (:likes) : une attention personnelle, dans votre budget.",
                ['likes' => implode(', ', array_slice($matches, 0, 3))]);
        }

        return __("Une attention pensée pour cette personne, idéale pour l'occasion (:event), sans dépasser le budget.", ['event' => Str::lower(__($d['event']))]);
    }
}
