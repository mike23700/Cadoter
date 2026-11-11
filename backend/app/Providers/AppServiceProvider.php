<?php

namespace App\Providers;

use Illuminate\Cache\RateLimiting\Limit;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Support\ServiceProvider;

class AppServiceProvider extends ServiceProvider
{
    /**
     * Register any application services.
     */
    public function register(): void
    {
        //
    }

    /**
     * Bootstrap any application services.
     */
    public function boot(): void
    {
        // Limiteurs nommés : chacun a son propre compteur (les « throttle:X,Y » anonymes
        // partagent un même compteur par IP, toutes routes confondues).
        $ip = fn (Request $r) => $r->ip();
        $userOrIp = fn (Request $r) => $r->user('sanctum')?->id ?? $r->ip();

        // Connexion / inscription : par IP, et par identifiant visé (devinette de mot de passe répartie sur plusieurs IP)
        RateLimiter::for('auth', fn (Request $r) => [
            Limit::perMinute(10)->by('ip:'.$r->ip()),
            Limit::perMinute(5)->by('login:'.mb_strtolower(trim((string) $r->input('login', $r->input('email'))))),
        ]);
        RateLimiter::for('password-reset', fn (Request $r) => [
            Limit::perMinute(5)->by('ip:'.$r->ip()),
            Limit::perHour(5)->by('email:'.mb_strtolower(trim((string) $r->input('email')))),
        ]);
        RateLimiter::for('password-change', fn (Request $r) => Limit::perMinute(5)->by($userOrIp($r)));
        // Code d'accès d'une liste protégée : empêche de le deviner par essais successifs
        RateLimiter::for('shared-list', fn (Request $r) => [
            Limit::perMinute(60)->by('ip:'.$r->ip()),
            Limit::perMinute(10)->by('code:'.$r->ip().'|'.$r->route('code'))
                ->after(fn ($response) => $response->getStatusCode() === 423),
        ]);
        RateLimiter::for('public-write', fn (Request $r) => [
            Limit::perMinute(20)->by($userOrIp($r)),
            Limit::perDay(200)->by($userOrIp($r)),
        ]);
        // Appels à l'IA (payants) : plafond par minute et par jour
        RateLimiter::for('assistant', fn (Request $r) => [
            Limit::perMinute(20)->by($userOrIp($r)),
            Limit::perDay(300)->by($userOrIp($r)),
        ]);
        RateLimiter::for('assistant-external', fn (Request $r) => [
            Limit::perMinute(6)->by($userOrIp($r)),
            Limit::perDay(60)->by($userOrIp($r)),
        ]);
        RateLimiter::for('client-log', fn (Request $r) => [
            Limit::perMinute(30)->by($ip($r)),
            Limit::perDay(1000)->by($ip($r)),
        ]);
        // Aperçu d'un lien marchand (requête sortante vers un site tiers)
        RateLimiter::for('link-preview', fn (Request $r) => Limit::perMinute(20)->by($userOrIp($r)));
    }
}
