<?php

namespace App\Services;

use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use RuntimeException;
use Throwable;

/** Client minimal de l'API OpenRouter : réponses JSON structurées et embeddings. */
class OpenRouter
{
    public function enabled(): bool
    {
        return filled(config('services.openrouter.key'));
    }

    /**
     * Réponse JSON conforme au schéma. OpenRouter essaie le modèle principal puis,
     * s'il est indisponible (panne, surcharge, limite), les modèles de secours.
     *
     * Si l'appel échoue malgré tout (ex. modèle principal retiré d'OpenRouter), un second
     * essai est fait avec les seuls modèles de secours.
     *
     * @return array{data: array, model: string}
     */
    public function json(string $system, string $user, string $name, array $schema, int $maxTokens = 1200): array
    {
        $fallbacks = config('services.openrouter.fallback_models');
        try {
            return $this->jsonWith([config('services.openrouter.model'), ...$fallbacks], $system, $user, $name, $schema, $maxTokens);
        } catch (Throwable $e) {
            if (! $fallbacks) {
                throw $e;
            }
            Log::warning("OpenRouter : échec avec le modèle principal, essai des modèles de secours ({$e->getMessage()})");

            return $this->jsonWith($fallbacks, $system, $user, $name, $schema, $maxTokens);
        }
    }

    private function jsonWith(array $models, string $system, string $user, string $name, array $schema, int $maxTokens): array
    {
        $res = $this->http()->post('/chat/completions', [
            'models' => $models,
            'messages' => [
                ['role' => 'system', 'content' => $system],
                ['role' => 'user', 'content' => $user],
            ],
            'response_format' => [
                'type' => 'json_schema',
                'json_schema' => ['name' => $name, 'strict' => true, 'schema' => $schema],
            ],
            // Uniquement des fournisseurs qui respectent le schéma JSON
            'provider' => ['require_parameters' => true],
            // Pas de « temperature » : Claude Haiku 5.5 ne l'accepte pas, et require_parameters l'écarterait
            'max_tokens' => $maxTokens,
            // Tâches courtes et cadrées : pas de phase de réflexion (plus rapide, moins cher)
            'reasoning' => ['enabled' => false],
        ])->throw()->json();

        if (isset($res['error'])) {
            throw new RuntimeException('OpenRouter : '.($res['error']['message'] ?? 'erreur inconnue'));
        }
        $content = (string) ($res['choices'][0]['message']['content'] ?? '');
        $data = json_decode($content, true);
        // Certains modèles entourent le JSON de texte ou de ```json … ``` : on garde l'objet
        if (! is_array($data) && preg_match('/\{.*\}/s', $content, $m)) {
            $data = json_decode($m[0], true);
        }
        if (! is_array($data)) {
            throw new RuntimeException(sprintf('OpenRouter : réponse JSON invalide (%s, %s) : %s',
                $res['model'] ?? '?', $res['choices'][0]['finish_reason'] ?? '?', mb_substr($content, 0, 300)));
        }

        return ['data' => $data, 'model' => $res['model'] ?? config('services.openrouter.model')];
    }

    /**
     * Vecteurs des textes, dans le même ordre.
     *
     * @param  string[]  $texts
     * @return array<int, float[]>
     */
    public function embed(array $texts): array
    {
        $res = $this->http()->post('/embeddings', [
            'model' => config('services.openrouter.embedding_model'),
            'input' => array_values($texts),
        ])->throw()->json();

        $vectors = collect($res['data'] ?? [])->sortBy('index')->pluck('embedding')->values()->all();
        if (count($vectors) !== count($texts)) {
            throw new RuntimeException('OpenRouter : embeddings manquants.');
        }

        return $vectors;
    }

    private function http()
    {
        if (! $this->enabled()) {
            throw new RuntimeException('OPENROUTER_API_KEY manquante.');
        }

        return Http::baseUrl(config('services.openrouter.url'))
            ->withToken(config('services.openrouter.key'))
            ->withHeaders(['X-Title' => 'CADOTER'])
            ->acceptJson()
            ->timeout(config('services.openrouter.timeout'))
            ->connectTimeout(5);
    }
}
