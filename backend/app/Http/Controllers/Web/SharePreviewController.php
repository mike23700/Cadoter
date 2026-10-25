<?php

namespace App\Http\Controllers\Web;

use App\Http\Controllers\Controller;
use App\Models\GiftList;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

/**
 * Page HTML minimale avec les balises Open Graph d'une liste partagée : les robots
 * d'aperçu (WhatsApp, Facebook, Telegram…) n'exécutent pas l'application React.
 */
class SharePreviewController extends Controller
{
    public function list(Request $request, string $code)
    {
        $front = $this->publicOrigin($request);
        $list = GiftList::with('owner', 'items.gift')->where('code', $code)->first();

        if (! $list) {
            return response()->view('share-preview', [
                'title' => 'CADOTER',
                'description' => __('De petites attentions, de grands liens.'),
                'image' => "$front/img/emballage-rose.jpg",
                'url' => "$front/l/".rawurlencode($code),
            ], 404);
        }

        $owner = $list->owner?->name;
        $count = $list->items->count();
        if ($list->is_locked) {
            // Liste protégée : rien de son contenu dans l'aperçu
            $description = __('Liste protégée par un code d\'accès.');
        } else {
            $description = $list->description ?: ($owner
                ? __(':name vous invite à découvrir sa liste de cadeaux.', ['name' => $owner])
                : __('Découvrez cette liste de cadeaux.'));
            $description .= ' '.trans_choice(':count cadeau|:count cadeaux', $count, ['count' => $count]).'.';
        }

        $image = $list->image_url
            ?? ($list->is_locked ? null : $list->items->map(fn ($i) => $i->toPublicArray(false)['image_url'] ?? null)->filter()->first());
        // Les images sont servies par le même domaine que le site (/storage relayé vers l'API)
        $image = $image && ($i = strpos($image, '/storage/')) !== false
            ? $front.substr($image, $i)
            : ($image ?? "$front/img/emballage-rose.jpg");

        return response()->view('share-preview', [
            'title' => $owner ? "{$list->title} · {$owner}" : $list->title,
            'description' => Str::limit($description, 200),
            'image' => $image,
            'url' => "$front/l/".rawurlencode($list->code),
        ]);
    }

    /**
     * Domaine public par lequel le robot est arrivé (ex. ngrok → proxy Vite → API),
     * pour que les liens et l'image de l'aperçu pointent vers le site et non vers l'API.
     */
    private function publicOrigin(Request $request): string
    {
        $proto = trim(explode(',', (string) $request->header('X-Forwarded-Proto'))[0]) ?: $request->getScheme();
        $host = trim(explode(',', (string) $request->header('X-Forwarded-Host'))[0]) ?: $request->getHttpHost();

        return (in_array($proto, ['http', 'https'], true) ? $proto : 'https').'://'.$host;
    }
}
