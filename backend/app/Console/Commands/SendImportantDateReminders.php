<?php

namespace App\Console\Commands;

use App\Mail\ImportantDateReminder as ImportantDateReminderMail;
use App\Models\ImportantDate;
use App\Services\ImportantDateGiftSuggestions;
use Carbon\CarbonImmutable;
use Illuminate\Console\Attributes\Description;
use Illuminate\Console\Attributes\Signature;
use Illuminate\Console\Command;
use Illuminate\Database\Eloquent\Collection;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Mail;
use Throwable;

#[Signature('cadoter:send-important-date-reminders')]
#[Description('Envoie les rappels e-mail des dates importantes')]
class SendImportantDateReminders extends Command
{
    public function handle(ImportantDateGiftSuggestions $giftSuggestions): int
    {
        $today = CarbonImmutable::today(config('app.timezone'));
        $sent = 0;
        $failed = 0;

        foreach ([7, 3, 0] as $daysBefore) {
            $eventDate = $today->addDays($daysBefore);

            foreach ($this->eventsOn($eventDate) as $importantDate) {
                if (! $importantDate->user?->email) {
                    continue;
                }

                try {
                    if ($this->sendReminder($importantDate, $eventDate, $daysBefore, $giftSuggestions)) {
                        $sent++;
                    }
                } catch (Throwable $exception) {
                    $failed++;
                    Log::error('Échec d’envoi d’un rappel de date importante.', [
                        'important_date_id' => $importantDate->id,
                        'exception' => $exception->getMessage(),
                    ]);
                }
            }
        }

        $this->info("{$sent} rappel(s) envoyé(s).".($failed ? " {$failed} échec(s)." : ''));

        return $failed ? self::FAILURE : self::SUCCESS;
    }

    private function sendReminder(
        ImportantDate $importantDate,
        CarbonImmutable $eventDate,
        int $daysBefore,
        ImportantDateGiftSuggestions $giftSuggestions,
    ): bool {
        $user = $importantDate->user;

        if (! $user || ! $user->email) {
            return false;
        }

        $key = [
            'important_date_id' => $importantDate->id,
            'event_year' => $eventDate->year,
            'days_before' => $daysBefore,
        ];

        DB::table('important_date_reminders')->insertOrIgnore([
            ...$key,
            'sent_at' => null,
            'created_at' => now(),
            'updated_at' => now(),
        ]);

        if (DB::table('important_date_reminders')->where($key)->value('sent_at')) {
            return false;
        }

        $suggestions = $giftSuggestions->forEvent($importantDate, $eventDate->year);
        $frontendUrl = rtrim((string) config('services.frontend_url'), '/');

        Mail::to($user->email)
            ->locale($user->language === 'en' ? 'en' : 'fr')
            ->send(new ImportantDateReminderMail(
                user: $user,
                importantDate: $importantDate,
                daysBefore: $daysBefore,
                eventDate: $eventDate,
                suggestions: $suggestions->all(),
                frontendUrl: $frontendUrl,
            ));

        DB::table('important_date_reminders')->where($key)->update([
            'sent_at' => now(),
            'updated_at' => now(),
        ]);

        return true;
    }

    /** @return Collection<int, ImportantDate> */
    private function eventsOn(CarbonImmutable $date): Collection
    {
        $events = ImportantDate::with('user')
            ->whereMonth('event_date', $date->month)
            ->whereDay('event_date', $date->day)
            ->get();

        if ($date->month === 2 && $date->day === 28 && ! $date->isLeapYear()) {
            $events = $events->merge(ImportantDate::with('user')
                ->whereMonth('event_date', 2)
                ->whereDay('event_date', 29)
                ->get());
        }

        return $events;
    }
}
