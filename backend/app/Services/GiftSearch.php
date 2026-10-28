<?php

namespace App\Services;

use App\Models\Gift;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

/**
 * Recherche hybride des cadeaux pour l'assistante :
 *  1. filtres stricts en SQL (en ligne, en stock, budget, ville) ;
 *  2. trois classements : plein texte français, similarité de sens (vecteurs) et
 *     correspondance occasion / destinataire ;
 *  3. fusion des classements (Reciprocal Rank Fusion) → les meilleurs candidats.
 * Si les vecteurs sont indisponibles, les deux autres classements suffisent.
 */
class GiftSearch
{
    private const PER_RANKING = 50;

    private const RRF_K = 60;

    public function __construct(private OpenRouter $ai) {}

    /**
     * @param  array{budget: int, city?: ?string, occasion?: ?string, for_who?: ?string}  $filters
     * @return Collection<int, Gift>
     */
    public function candidates(string $query, array $filters, int $limit = 30): Collection
    {
        $rankings = [
            $this->fullText($query, $filters),
            $this->semantic($query, $filters),
            $this->structured($filters),
        ];

        $scores = [];
        foreach ($rankings as $ids) {
            foreach (array_values($ids) as $rank => $id) {
                $scores[$id] = ($scores[$id] ?? 0) + 1 / (self::RRF_K + $rank + 1);
            }
        }
        arsort($scores);
        $ids = array_slice(array_keys($scores), 0, $limit);

        $gifts = Gift::with('partner:id,shop_name')->whereKey($ids)->get()->keyBy('id');

        return collect($ids)->map(fn ($id) => $gifts[$id] ?? null)->filter()->values();
    }

    private function base(array $filters): Builder
    {
        return Gift::query()
            ->where('is_active', true)
            ->where(fn ($q) => $q->whereNull('stock')->orWhere('stock', '>', 0))
            ->where('price', '<=', $filters['budget'])
            ->when($filters['city'] ?? null, fn ($q, $c) => $q->where('city', $c));
    }

    /** Mots de la demande (sans accents, ≥ 3 lettres), combinés par OU. */
    private function fullText(string $query, array $filters): array
    {
        $words = collect(preg_split('/[^\pL\pN]+/u', Str::lower(Str::ascii($query))))
            ->filter(fn ($w) => mb_strlen($w) >= 3)->unique()->take(30);
        if ($words->isEmpty()) {
            return [];
        }
        // MySQL / MariaDB : index FULLTEXT (pas de tsvector).
        if (in_array(DB::connection()->getDriverName(), ['mysql', 'mariadb'], true)) {
            $terms = $words->map(fn ($w) => '+'.$w.'*')->implode(' ');

            try {
                return $this->base($filters)
                    ->whereRaw('MATCH(name, description, category, ai_tags) AGAINST (? IN BOOLEAN MODE)', [$terms])
                    ->orderByRaw('MATCH(name, description, category, ai_tags) AGAINST (? IN BOOLEAN MODE) DESC', [$terms])
                    ->limit(self::PER_RANKING)->pluck('id')->all();
            } catch (Throwable $e) {
                Log::warning("Recherche plein texte MySQL indisponible : {$e->getMessage()}");

                // Repli sans index FULLTEXT (migration non appliquée, moteur sans FULLTEXT…)
                return $this->base($filters)
                    ->where(function ($q) use ($words) {
                        $first = true;
                        foreach ($words as $w) {
                            if ($first) {
                                $q->whereRaw('LOWER(name) LIKE ?', ['%'.$w.'%']);
                                $first = false;
                            } else {
                                $q->orWhereRaw('LOWER(name) LIKE ?', ['%'.$w.'%']);
                            }
                            $q->orWhereRaw('LOWER(description) LIKE ?', ['%'.$w.'%']);
                        }
                    })
                    ->limit(self::PER_RANKING)->pluck('id')->all();
            }
        }

        $tsquery = $words->implode(' | ');

        return $this->base($filters)
            ->whereRaw("search_vector @@ to_tsquery('french', ?)", [$tsquery])
            ->orderByRaw("ts_rank_cd(search_vector, to_tsquery('french', ?)) DESC", [$tsquery])
            ->limit(self::PER_RANKING)->pluck('id')->all();
    }

    /** Cadeaux au sens le plus proche de la demande (distance cosinus des vecteurs). */
    private function semantic(string $query, array $filters): array
    {
        if (! $this->ai->enabled() || trim($query) === '') {
            return [];
        }

        // pgvector uniquement : sur MySQL/MariaDB on garde le plein texte + les critères.
        if (DB::connection()->getDriverName() !== 'pgsql') {
            return [];
        }

        try {
            // Le vecteur d'une même demande est gardé en cache : un seul appel par formulation
            $vector = Cache::remember('embed:'.config('services.openrouter.embedding_model').':'.sha1($query), now()->addDay(),
                fn () => GiftSearchIndex::vectorLiteral($this->ai->embed([$query])[0]));

            return DB::transaction(function () use ($vector, $filters) {
                // Parcours itératif de l'index HNSW : assez de résultats même avec des filtres sélectifs
                DB::statement("SET LOCAL hnsw.iterative_scan = 'relaxed_order'");
                DB::statement('SET LOCAL hnsw.ef_search = 100');

                return $this->base($filters)
                    ->join('gift_embeddings', 'gift_embeddings.gift_id', '=', 'gifts.id')
                    ->orderByRaw('gift_embeddings.embedding <=> ?::halfvec', [$vector])
                    ->limit(self::PER_RANKING)->pluck('gifts.id')->all();
            });
        } catch (Throwable $e) {
            Log::warning("Recherche vectorielle indisponible : {$e->getMessage()}");

            return [];
        }
    }

    /** Correspondance avec l'occasion et le destinataire, puis mise en avant / nouveauté. */
    private function structured(array $filters): array
    {
        $occasion = $filters['occasion'] ?? null;
        $forWho = $filters['for_who'] ?? null;

        // MySQL / MariaDB : JSON_CONTAINS au lieu de l'opérateur jsonb de PostgreSQL.
        if (in_array(DB::connection()->getDriverName(), ['mysql', 'mariadb'], true)) {
            return $this->base($filters)
                ->orderByRaw('(CASE WHEN JSON_CONTAINS(occasions, JSON_QUOTE(?)) THEN 1 ELSE 0 END)
                    + (CASE WHEN JSON_CONTAINS(for_who, JSON_QUOTE(?)) THEN 1 ELSE 0 END) DESC',
                    [$occasion, $forWho])
                ->orderByDesc('is_featured')->latest()
                ->limit(self::PER_RANKING)->pluck('id')->all();
        }

        return $this->base($filters)
            ->orderByRaw('(CASE WHEN ?::text IS NOT NULL AND occasions::jsonb @> to_jsonb(?::text) THEN 1 ELSE 0 END)
                + (CASE WHEN ?::text IS NOT NULL AND for_who::jsonb @> to_jsonb(?::text) THEN 1 ELSE 0 END) DESC',
                [$occasion, $occasion, $forWho, $forWho])
            ->orderByDesc('is_featured')->latest()
            ->limit(self::PER_RANKING)->pluck('id')->all();
    }
}
