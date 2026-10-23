<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gift;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Suggestions de cadeaux. Version par règles sur le catalogue en attendant
 * le branchement d'un modèle d'IA : mêmes entrées / sorties.
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

    public function suggest(Request $request)
    {
        $data = $request->validate([
            'event' => ['required', 'string', 'max:60'],
            'gender' => ['required', 'string', 'max:20'],
            'age' => ['required', 'integer', 'min:0', 'max:120'],
            'relation' => ['required', 'string', 'max:40'],
            'budget' => ['required', 'integer', 'min:1000'],
            'city' => ['nullable', 'string', 'max:80'],
            'info' => ['nullable', 'string', 'max:500'],
        ]);

        $forWho = $data['age'] < 13 ? 'Enfants' : (self::RELATION_TO_FOR_WHO[$data['relation']] ?? null);
        $stop = ['elle', 'aime', 'adore', 'avec', 'pour', 'dans', 'les', 'des', 'une', 'son', 'ses', 'sur', 'qui', 'que', 'est', 'tres', 'beaucoup', 'moments'];
        // clé = mot sans accents (comparaison), valeur = mot saisi (affichage)
        $words = collect(preg_split('/[\s,;.!?\'’]+/u', Str::lower($data['info'] ?? '')))
            ->mapWithKeys(fn ($w) => [Str::ascii($w) => $w])
            ->filter(fn ($w, $k) => strlen($k) >= 3 && ! in_array($k, $stop, true));

        $gifts = Gift::where('is_active', true)->where('price', '<=', $data['budget'])
            ->when($data['city'] ?? null, fn ($q, $c) => $q->where('city', $c))
            ->get()
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

        return response()->json([
            'criteria' => $data,
            'suggestions' => $gifts,
            'disclaimer' => __('Exemples de suggestions, sans garantie de disponibilité. Prix et disponibilité à confirmer auprès du marchand.'),
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
