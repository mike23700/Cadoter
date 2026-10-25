<?php

namespace App\Jobs;

use App\Models\Gift;
use App\Services\GiftSearchIndex;
use Illuminate\Contracts\Queue\ShouldBeUnique;
use Illuminate\Contracts\Queue\ShouldQueue;
use Illuminate\Foundation\Queue\Queueable;

/** Étiquettes IA + vecteur d'un cadeau, après sa création ou sa modification. */
class IndexGiftForSearch implements ShouldBeUnique, ShouldQueue
{
    use Queueable;

    public int $tries = 3;

    public array $backoff = [30, 120];

    public int $uniqueFor = 600;

    public function __construct(public int $giftId) {}

    public function uniqueId(): string
    {
        return (string) $this->giftId;
    }

    public function handle(GiftSearchIndex $index): void
    {
        if ($gift = Gift::find($this->giftId)) {
            $index->index($gift);
        }
    }
}
