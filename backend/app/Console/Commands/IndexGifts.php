<?php

namespace App\Console\Commands;

use App\Models\Gift;
use App\Services\GiftSearchIndex;
use Illuminate\Console\Command;
use Throwable;

/** Indexe le catalogue pour l'assistante IA (à lancer après l'installation ou un changement de modèle). */
class IndexGifts extends Command
{
    protected $signature = 'gifts:index {--force : Tout recalculer, même les cadeaux déjà à jour} {--batch=32 : Cadeaux par appel d\'embeddings}';

    protected $description = 'Étiquettes IA + vecteurs des cadeaux pour la recherche de l\'assistante';

    public function handle(GiftSearchIndex $index): int
    {
        $done = 0;
        $failed = 0;
        $bar = $this->output->createProgressBar(Gift::count());

        Gift::query()->orderBy('id')->chunkById(max(1, (int) $this->option('batch')), function ($gifts) use ($index, &$done, &$failed, $bar) {
            try {
                $done += $index->indexMany($gifts, (bool) $this->option('force'));
            } catch (Throwable $e) {
                $failed += $gifts->count();
                $this->newLine();
                $this->warn("Lot ignoré ({$gifts->first()->id}–{$gifts->last()->id}) : {$e->getMessage()}");
            }
            $bar->advance($gifts->count());
        });

        $bar->finish();
        $this->newLine();
        $this->info("$done cadeau(x) indexé(s)".($failed ? ", $failed en échec (relancez la commande)" : '').'.');

        return $failed ? self::FAILURE : self::SUCCESS;
    }
}
