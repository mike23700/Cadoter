<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Log;

/**
 * Diagnostic TEMPORAIRE de la « page blanche » : le navigateur envoie ce qu'il voit
 * (storage/logs/client.log). À retirer une fois le problème résolu.
 */
class ClientLogController extends Controller
{
    public function store(Request $request)
    {
        $data = $request->validate([
            'type' => ['required', 'string', 'max:30'],
            'session' => ['required', 'string', 'max:20'],
            'data' => ['nullable', 'array'],
        ]);

        Log::build(['driver' => 'single', 'path' => storage_path('logs/client.log')])->info(
            "[{$data['session']}] {$data['type']}",
            ['ip' => $request->ip(), 'ua' => mb_substr((string) $request->userAgent(), 0, 200)]
                + ['data' => json_decode(mb_substr(json_encode($data['data'] ?? []), 0, 8000), true) ?? ['tronqué' => true]],
        );

        return response()->noContent();
    }
}
