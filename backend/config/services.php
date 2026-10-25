<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Third Party Services
    |--------------------------------------------------------------------------
    |
    | This file is for storing the credentials for third party services such
    | as Resend, Postmark, AWS, and more. This file provides the de facto
    | location for this type of information, allowing packages to have
    | a conventional file to locate the various service credentials.
    |
    */

    'postmark' => [
        'key' => env('POSTMARK_API_KEY'),
    ],

    'resend' => [
        'key' => env('RESEND_API_KEY'),
    ],

    'ses' => [
        'key' => env('AWS_ACCESS_KEY_ID'),
        'secret' => env('AWS_SECRET_ACCESS_KEY'),
        'region' => env('AWS_DEFAULT_REGION', 'us-east-1'),
    ],

    'slack' => [
        'notifications' => [
            'bot_user_oauth_token' => env('SLACK_BOT_USER_OAUTH_TOKEN'),
            'channel' => env('SLACK_BOT_USER_DEFAULT_CHANNEL'),
        ],
    ],

    // IA de l'assistante (OpenRouter). Les modèles sont essayés dans l'ordre :
    // le modèle principal, puis les secours si OpenRouter ne peut pas le joindre.
    'openrouter' => [
        'key' => env('OPENROUTER_API_KEY'),
        'url' => env('OPENROUTER_URL', 'https://openrouter.ai/api/v1'),
        'model' => env('OPENROUTER_MODEL', 'anthropic/claude-haiku-5.5'),
        'fallback_models' => array_values(array_filter(array_map('trim', explode(',', (string) env('OPENROUTER_FALLBACK_MODELS', 'deepseek/deepseek-v4.1-flash'))))),
        'embedding_model' => env('OPENROUTER_EMBEDDING_MODEL', 'baai/bge-m3'),
        'embedding_dimensions' => (int) env('OPENROUTER_EMBEDDING_DIMENSIONS', 1024),
        'timeout' => (int) env('OPENROUTER_TIMEOUT', 12),
        // Recherche d'idées hors catalogue (assistante) : boutiques autorisées, séparées par des virgules. Vide = désactivée
        'external_domains' => array_values(array_filter(array_map(fn ($d) => strtolower(trim($d)), explode(',', (string) env('ASSISTANT_EXTERNAL_DOMAINS', 'jumia.ci'))))),
        // Grands sites internationaux, cherchés à part pour ne pas écraser les boutiques locales
        'external_intl_domains' => array_values(array_filter(array_map(fn ($d) => strtolower(trim($d)), explode(',', (string) env('ASSISTANT_EXTERNAL_INTL_DOMAINS',
            'amazon.fr,amazon.com,aliexpress.com,alibaba.com,ebay.com,etsy.com,temu.com,cdiscount.com,fnac.com'))))),
    ],

];
