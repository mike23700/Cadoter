<?php

namespace App\Mail;

use App\Models\Gift;
use App\Models\ImportantDate;
use App\Models\User;
use Carbon\CarbonImmutable;
use Illuminate\Bus\Queueable;
use Illuminate\Mail\Mailable;
use Illuminate\Mail\Mailables\Content;
use Illuminate\Mail\Mailables\Envelope;
use Illuminate\Queue\SerializesModels;

class ImportantDateReminder extends Mailable
{
    use Queueable, SerializesModels;

    /**
     * @param  array<int, array{gift: Gift, reason: string}>  $suggestions
     */
    public function __construct(
        public User $user,
        public ImportantDate $importantDate,
        public int $daysBefore,
        public CarbonImmutable $eventDate,
        public array $suggestions,
        public string $frontendUrl,
    ) {}

    public function envelope(): Envelope
    {
        $event = $this->importantDate->title.' — '.$this->importantDate->person_name;
        $timing = $this->timingLabel();

        return new Envelope(
            subject: $this->user->language === 'en'
                ? "Reminder: {$event} {$timing}"
                : "Rappel : {$event} {$timing}",
        );
    }

    public function content(): Content
    {
        $language = $this->user->language === 'en' ? 'en' : 'fr';

        return new Content(
            view: 'emails.important-date-reminder',
            with: [
                'language' => $language,
                'userName' => $this->user->name,
                'eventDateLabel' => $this->eventDate->locale($language)->translatedFormat('j F Y'),
                'timingLabel' => $this->timingLabel(),
                'catalogUrl' => $this->frontendUrl.'/cadeaux',
            ],
        );
    }

    private function timingLabel(): string
    {
        if ($this->user->language === 'en') {
            return match ($this->daysBefore) {
                7 => 'is in one week',
                3 => 'is in three days',
                default => 'is today',
            };
        }

        return match ($this->daysBefore) {
            7 => 'est dans une semaine',
            3 => 'est dans trois jours',
            default => 'est aujourd’hui',
        };
    }
}
