<?php

namespace App\Models;

// use Illuminate\Contracts\Auth\MustVerifyEmail;
use App\Mail\PasswordResetLink;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Mail;
use Laravel\Sanctum\HasApiTokens;

#[Fillable(['name', 'email', 'phone', 'password', 'language', 'role', 'shop_name'])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * Get the attributes that should be cast.
     *
     * @return array<string, string>
     */
    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
        ];
    }

    /** Lien de réinitialisation vers le front (et non une route Laravel). */
    public function sendPasswordResetNotification($token): void
    {
        $url = rtrim((string) config('services.frontend_url'), '/').'/reinitialiser-mot-de-passe?'
            .http_build_query(['token' => $token, 'email' => $this->email]);

        Mail::to($this->email)
            ->locale($this->language === 'en' ? 'en' : 'fr')
            ->send(new PasswordResetLink(
                user: $this,
                resetUrl: $url,
                expiresInMinutes: (int) config('auth.passwords.users.expire'),
            ));
    }

    public function isAdmin(): bool
    {
        return $this->role === 'admin';
    }

    public function lists(): HasMany
    {
        return $this->hasMany(GiftList::class, 'owner_id');
    }

    public function favorites(): BelongsToMany
    {
        return $this->belongsToMany(Gift::class, 'favorites')->withTimestamps();
    }

    public function orders(): HasMany
    {
        return $this->hasMany(Order::class);
    }

    public function importantDates(): HasMany
    {
        return $this->hasMany(ImportantDate::class);
    }

    public function gifts(): HasMany
    {
        return $this->hasMany(Gift::class, 'partner_id');
    }
}
