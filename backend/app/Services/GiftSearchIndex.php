<?php

namespace App\Services;

use App\Models\Gift;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Throwable;

/**
 * Prépare un cadeau pour la recherche de l'assistante :
 *  1. l'IA ajoute des étiquettes (centres d'intérêt, profils, occasions…) aux fiches souvent pauvres ;
 *  2. le texte enrichi est transformé en vecteur (embedding) stocké dans gift_embeddings.
 * Rien n'est recalculé si le contenu du cadeau n'a pas changé (empreinte search_hash).
 */
class GiftSearchIndex
{
    private const TAGS_SCHEMA = [
        'type' => 'object',
        'properties' => ['tags' => ['type' => 'array', 'items' => ['type' => 'string']]],
        'required' => ['tags'],
        'additionalProperties' => false,
    ];

    public function __construct(private OpenRouter $ai) {}

    /** Champs dont la modification impose de réindexer. */
    public const SOURCE_FIELDS = ['name', 'description', 'category', 'for_who', 'occasions', 'city', 'area', 'shop', 'partner_id'];

    public function needsIndexing(Gift $gift): bool
    {
        return $gift->search_hash !== $this->hash($gift)
            || ! DB::table('gift_embeddings')->where('gift_id', $gift->id)->exists();
    }

    public function index(Gift $gift, bool $force = false): void
    {
        $this->indexMany(collect([$gift]), $force);
    }

    /** @param  Collection<int, Gift>  $gifts */
    public function indexMany(Collection $gifts, bool $force = false): int
    {
        $todo = $force ? $gifts : $gifts->filter(fn (Gift $g) => $this->needsIndexing($g));
        if ($todo->isEmpty()) {
            return 0;
        }

        $enriched = [];
        foreach ($todo as $gift) {
            $tags = $this->tags($gift);
            $enriched[$gift->id] = $tags !== null;
            $gift->ai_tags = $tags ?? $gift->ai_tags;
        }

        $vectors = $this->ai->embed($todo->map(fn (Gift $g) => $this->embeddingText($g))->all());
        $model = config('services.openrouter.embedding_model');

        DB::transaction(function () use ($todo, $vectors, $model, $enriched) {
            foreach ($todo->values() as $i => $gift) {
                DB::statement(
                    'INSERT INTO gift_embeddings (gift_id, embedding, model, updated_at) VALUES (?, ?::halfvec, ?, now())
                     ON CONFLICT (gift_id) DO UPDATE SET embedding = EXCLUDED.embedding, model = EXCLUDED.model, updated_at = now()',
                    [$gift->id, self::vectorLiteral($vectors[$i]), $model],
                );
                // Étiquettes non obtenues : pas d'empreinte, le cadeau sera repris au prochain passage
                $gift->search_hash = $enriched[$gift->id] ? $this->hash($gift) : null;
                $gift->saveQuietly(); // pas de nouvel événement « saved » → pas de boucle
            }
        });

        return $todo->count();
    }

    /** Texte décrivant le cadeau, utilisé pour le vecteur. */
    public function embeddingText(Gift $gift): string
    {
        return collect([
            $gift->name,
            $gift->category ? "Catégorie : {$gift->category}" : null,
            $gift->description,
            $gift->for_who ? 'Pour : '.implode(', ', $gift->for_who) : null,
            $gift->occasions ? 'Occasions : '.implode(', ', $gift->occasions) : null,
            $gift->ai_tags ? "Mots-clés : {$gift->ai_tags}" : null,
            'Lieu : '.collect([$gift->area, $gift->city])->filter()->implode(', '),
        ])->filter()->implode("\n");
    }

    public static function vectorLiteral(array $vector): string
    {
        return '['.implode(',', array_map(fn ($v) => round((float) $v, 6), $vector)).']';
    }

    /** Étiquettes de recherche proposées par l'IA, ou null si elle est indisponible. */
    private function tags(Gift $gift): ?string
    {
        $fiche = collect([
            "Nom : {$gift->name}",
            $gift->category ? "Catégorie : {$gift->category}" : null,
            $gift->description ? "Description : {$gift->description}" : null,
            $gift->for_who ? 'Pour : '.implode(', ', $gift->for_who) : null,
            $gift->occasions ? 'Occasions : '.implode(', ', $gift->occasions) : null,
            'Prix : '.$gift->price.' '.$gift->currency,
        ])->filter()->implode("\n");

        try {
            $res = $this->ai->json(
                "Tu enrichis les fiches d'un site de cadeaux en Côte d'Ivoire pour améliorer la recherche. "
                .'À partir de la fiche, donne 10 à 20 mots-clés de recherche en français, en minuscules : '
                ."centres d'intérêt et passions liés, profils de destinataires (âge, genre, relation), occasions adaptées, "
                ."style, usages et synonymes du produit. N'invente aucune caractéristique absente de la fiche (marque, taille, matière).",
                $fiche,
                'gift_tags',
                self::TAGS_SCHEMA,
                800,
            );
        } catch (Throwable $e) {
            Log::warning("Étiquettes IA indisponibles pour le cadeau {$gift->id} : {$e->getMessage()}");

            return null;
        }

        return collect($res['data']['tags'] ?? [])
            ->map(fn ($t) => mb_strtolower(trim((string) $t)))
            ->filter(fn ($t) => $t !== '' && mb_strlen($t) <= 60)
            ->unique()->take(20)->implode(', ') ?: null;
    }

    private function hash(Gift $gift): string
    {
        $source = collect(self::SOURCE_FIELDS)->map(fn ($f) => json_encode($gift->getAttribute($f)))->implode('|');

        return hash('sha256', $source.'|'.config('services.openrouter.embedding_model'));
    }
}
