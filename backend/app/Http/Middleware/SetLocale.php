<?php

namespace App\Http\Middleware;

use Closure;
use Illuminate\Http\Request;
use Symfony\Component\HttpFoundation\Response;

/**
 * Langue des messages de l'API : en-tête Accept-Language envoyé par le web et
 * le mobile (fr ou en), sinon français.
 */
class SetLocale
{
    public const LOCALES = ['fr', 'en'];

    public function handle(Request $request, Closure $next): Response
    {
        app()->setLocale($request->getPreferredLanguage(self::LOCALES) ?? 'fr');

        return $next($request);
    }
}
