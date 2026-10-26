<?php

namespace App\Services;

use App\Models\Gift;
use App\Models\ImportantDate;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Support\Collection;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;
use Throwable;

class ImportantDateGiftSuggestions
{
    private const SELECTION_SCHEMA = [
        'type' => 'object',
        'additionalProperties' => false,
        'required' => ['suggestions'],
        'properties' => [
            'suggestions' => [
                'type' => 'array',
                'items' => [
                    'type' => 'object',
                    'additionalProperties' => false,
                    'required' => ['id', 'reason'],
                    'properties' => [
                        'id' => ['type' => 'integer'],
                        'reason' => ['type' => 'string'],
                    ],
                ],
            ],
        ],
    ];

    public function __construct(private OpenRouter $ai) {}

    /**
     * @return Collection<int, array{gift: Gift, reason: string}>
     */
    public function forEvent(ImportantDate $importantDate, int $eventYear): Collection
    {
        $gifts = Gift::query()
            ->where('is_active', true)
            ->where(fn (Builder $query) => $query->whereNull('stock')->orWhere('stock', '>', 0))
            ->orderByDesc('is_featured')
            ->latest()
            ->limit(30)
            ->get();

        if ($gifts->isEmpty()) {
            return collect();
        }

        if (! $this->ai->enabled()) {
            return $this->fallback($gifts, $importantDate->user?->language ?? 'fr');
        }

        $language = $importantDate->user?->language === 'en' ? 'en' : 'fr';
        $cacheKey = 'important-date-gifts:'.sha1(json_encode([
            $importantDate->id,
            $eventYear,
            $importantDate->title,
            $importantDate->person_name,
            $language,
            $gifts->modelKeys(),
        ], JSON_UNESCAPED_UNICODE));

        try {
            $picks = Cache::remember($cacheKey, now()->addYear(), fn () => $this->selectWithAi($importantDate, $eventYear, $gifts, $language));
            $giftById = $gifts->keyBy('id');
            $suggestions = collect($picks)
                ->filter(fn (array $pick) => isset($giftById[$pick['id']]))
                ->map(fn (array $pick) => ['gift' => $giftById[$pick['id']], 'reason' => $pick['reason']])
                ->values();

            if ($suggestions->isNotEmpty()) {
                return $suggestions;
            }
        } catch (Throwable $exception) {
            Log::warning('Les suggestions IA pour un rappel de date sont indisponibles.', [
                'important_date_id' => $importantDate->id,
                'exception' => $exception->getMessage(),
            ]);
        }

        return $this->fallback($gifts, $language);
    }

    /** @return array<int, array{id: int, reason: string}> */
    private function selectWithAi(ImportantDate $importantDate, int $eventYear, Collection $gifts, string $language): array
    {
        $catalog = $gifts->map(fn (Gift $gift) => collect([
            '#'.$gift->id.' '.$gift->name,
            number_format((float) $gift->price, 0, ',', ' ').' '.$gift->currency,
            $gift->category,
            $gift->occasions ? 'occasions : '.implode(', ', $gift->occasions) : null,
            $gift->for_who ? 'pour : '.implode(', ', $gift->for_who) : null,
            $gift->description ? Str::limit($gift->description, 180) : null,
        ])->filter()->implode(' | '))->implode("\n");

        $languageName = $language === 'en' ? 'English' : 'français';
        $result = $this->ai->json(
            'Tu es l’assistant cadeaux de CADOTER. Choisis au maximum 3 cadeaux du catalogue pour la date célébrée. '
                .'Utilise seulement les identifiants présents dans le catalogue, ne crée jamais de produit ni de prix. '
                .'Donne une raison courte et chaleureuse dans '.$languageName.'.',
            "Événement : {$importantDate->title}\nPersonne : {$importantDate->person_name}\nAnnée : {$eventYear}\n\nCatalogue disponible :\n{$catalog}",
            'important_date_gifts',
            self::SELECTION_SCHEMA,
            700,
        );

        $allowedIds = $gifts->modelKeys();

        return collect($result['data']['suggestions'] ?? [])
            ->filter(fn (array $pick) => isset($pick['id'], $pick['reason'])
                && in_array((int) $pick['id'], $allowedIds, true)
                && filled($pick['reason']))
            ->unique(fn (array $pick) => (int) $pick['id'])
            ->take(3)
            ->map(fn (array $pick) => [
                'id' => (int) $pick['id'],
                'reason' => Str::limit(trim($pick['reason']), 300),
            ])
            ->values()
            ->all();
    }

    /**
     * @return Collection<int, array{gift: Gift, reason: string}>
     */
    private function fallback(Collection $gifts, string $language): Collection
    {
        $reason = $language === 'en'
            ? 'A gift idea selected from the CADOTER catalogue for this special occasion.'
            : 'Une idée choisie dans le catalogue CADOTER pour cette belle occasion.';

        return $gifts->take(3)
            ->map(fn (Gift $gift) => ['gift' => $gift, 'reason' => $reason])
            ->values();
    }
}
