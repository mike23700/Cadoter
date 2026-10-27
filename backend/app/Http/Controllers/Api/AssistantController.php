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
 *  1. recherche hybride dans le catalogue (plein texte + vecteurs) → ~30 candidats qui respectent budget et ville ;
 *  2. l'IA (OpenRouter) choisit les 4 meilleurs et explique chaque choix ;
 *  3. rien de convenable (ou IA indisponible) → liste vide : le site cherche alors sur des sites marchands.
 * Aucune raison n'est rédigée à l'avance : chaque explication vient de l'IA.
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

    public function suggest(Request $request, ExternalGiftSearch $external)
    {
        $data = $this->criteria($request);

        return response()->json([
            'criteria' => $data,
            'suggestions' => $this->suggestions($data),
            // Le site propose des idées hors catalogue quand il y en a moins de 3
            'external_available' => $external->enabled(),
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
            'budget' => ['required', 'integer', 'min:1000', 'max:2000000000'],
            'city' => ['nullable', 'string', 'max:80'],
            'info' => ['nullable', 'string', 'max:500'],
        ]);
    }

    /**
     * Sélection de l'IA parmi les candidats de la recherche hybride.
     *
     * @return Collection<int, array{gift: Gift, reason: string}>
     */
    private function suggestions(array $data): Collection
    {
        if (! $this->ai->enabled()) {
            return collect();
        }

        $query = collect([
            "Cadeau pour : {$data['event']}.",
            "Destinataire : {$data['relation']} ({$data['gender']}, {$data['age']} ans).",
            // Texte libre : goûts de la personne ou objet précis que l'acheteur veut offrir
            filled($data['info'] ?? null) ? "Précisions de l'acheteur : {$data['info']}" : null,
        ])->filter()->implode("\n");

        // Mêmes critères, même langue → même sélection pendant une heure (ids + raisons seulement)
        $key = 'assistant:v3:'.sha1(json_encode([$data, app()->getLocale(), config('services.openrouter.model')]));
        $picked = Cache::get($key);

        if ($picked === null) {
            $forWho = $data['age'] < 13 ? 'Enfants' : (self::RELATION_TO_FOR_WHO[$data['relation']] ?? null);
            $candidates = $this->search->candidates($query, [
                'budget' => $data['budget'], 'city' => $data['city'] ?? null, 'occasion' => $data['event'], 'for_who' => $forWho,
            ]);
            if ($candidates->isEmpty()) {
                return collect();
            }

            try {
                $picked = $this->pick($query, $data, $candidates);
            } catch (Throwable $e) {
                Log::warning("Assistante IA indisponible : {$e->getMessage()}");

                return collect();
            }
            // Liste vide = l'IA juge que rien ne convient (ex. « une voiture ») : on le respecte,
            // le site cherchera alors des idées ailleurs au lieu de proposer des cadeaux hors sujet
            Cache::put($key, $picked, now()->addHour());
        }

        // Rechargés à chaque fois : un cadeau retiré ou épuisé entre-temps n'est plus proposé
        $gifts = Gift::with('partner:id,shop_name')->whereKey(array_column($picked, 'id'))
            ->where('is_active', true)->where('price', '<=', $data['budget'])->get()->keyBy('id');

        return collect($picked)->filter(fn ($p) => isset($gifts[$p['id']]) && $gifts[$p['id']]->available)
            ->map(fn ($p) => ['gift' => $gifts[$p['id']], 'reason' => $p['reason']])->values();
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
            $g->description ? Str::limit($g->description, 400) : null,
        ])->filter()->implode(' | '))->implode("\n");

        $res = $this->ai->json(
            "Tu es l'assistante cadeaux de CADOTER, un site de cadeaux en Côte d'Ivoire. "
            .'Lis toute la demande : occasion, lien avec la personne, sexe, âge, budget et précisions de l\'acheteur. '
            .'Avant de choisir, remplis requested_item : l\'objet précis que l\'acheteur veut offrir (« voiture », « iPhone », « voyage »), '
            .'ou une chaîne vide s\'il décrit seulement des goûts (« elle aime le luxe », « il aime la musique »). '
            .'Puis requested_item_in_list : true seulement si ce même objet figure dans la liste '
            .'(une miniature, un jouet, un accessoire ou un produit dérivé ne compte pas). '
            .'Si un objet précis est demandé et absent, ne propose aucun substitut : suggestions vide. '
            .'Sinon, choisis au maximum 4 cadeaux de la liste, vraiment adaptés à cette personne et à l\'occasion, en variant les idées. '
            .'Utilise uniquement les numéros (#id) de la liste : n\'invente jamais de produit. '
            .'Respecte le sexe de la personne : jamais un produit marqué pour l\'autre sexe (ex. « parfum homme » pour une femme). '
            ."Pour chaque cadeau, écris en $lang une raison de 2 à 3 phrases adressée à l'acheteur, qui s'appuie sur toute sa demande : "
            .'ce que le produit contient ou a de concret (d\'après sa description), pourquoi il convient à cette personne précise '
            .'(son âge, votre lien, ses goûts) et à l\'occasion, et le moment ou l\'usage qu\'il lui offrira. '
            .'Pas de formule creuse ou passe-partout, pas de prix. Si rien ne convient vraiment, renvoie une liste vide.',
            "Demande :\n$query\nBudget maximum : {$data['budget']} FCFA\n\nCadeaux disponibles :\n$list",
            'gift_selection',
            self::SELECTION_SCHEMA,
            1500,
        );

        // Objet précis demandé mais absent du catalogue : aucun substitut, même si l'IA en propose
        if (filled(trim((string) ($res['data']['requested_item'] ?? ''))) && ($res['data']['requested_item_in_list'] ?? false) !== true) {
            return [];
        }

        $allowed = $candidates->pluck('id')->flip();

        return collect($res['data']['suggestions'] ?? [])
            ->filter(fn ($s) => isset($s['id'], $allowed[(int) $s['id']]) && filled($s['reason'] ?? null))
            ->unique(fn ($s) => (int) $s['id'])->take(4)
            ->map(fn ($s) => ['id' => (int) $s['id'], 'reason' => Str::limit(trim($s['reason']), 600)])
            ->values()->all();
    }
}
