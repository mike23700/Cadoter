<?php

namespace App\Models;

use Carbon\CarbonImmutable;
use Database\Factories\ImportantDateFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable(['user_id', 'person_name', 'title', 'event_date'])]
class ImportantDate extends Model
{
    /** @use HasFactory<ImportantDateFactory> */
    use HasFactory;

    protected $appends = ['next_occurrence'];

    protected function casts(): array
    {
        return [
            'event_date' => 'date',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function getNextOccurrenceAttribute(): string
    {
        $today = CarbonImmutable::today(config('app.timezone'));
        $occurrence = $this->occurrenceInYear($today->year);

        if ($occurrence->lessThan($today)) {
            $occurrence = $this->occurrenceInYear($today->year + 1);
        }

        return $occurrence->toDateString();
    }

    private function occurrenceInYear(int $year): CarbonImmutable
    {
        $month = (int) $this->event_date->format('m');
        $day = (int) $this->event_date->format('d');
        $yearStart = CarbonImmutable::create($year, 1, 1, 0, 0, 0, config('app.timezone'));

        if ($month === 2 && $day === 29 && ! $yearStart->isLeapYear()) {
            $day = 28;
        }

        return CarbonImmutable::create($year, $month, $day, 0, 0, 0, config('app.timezone'));
    }
}
