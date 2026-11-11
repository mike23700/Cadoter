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
        $list = GiftList::with('owner', 'items.gift.partner:id,shop_name')->where('code', $code)->first();

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
        $front = rtrim((string) config('services.frontend_url'), '/');
        $proto = trim(explode(',', (string) $request->header('X-Forwarded-Proto'))[0]) ?: $request->getScheme();
        $host = strtolower(trim(explode(',', (string) $request->header('X-Forwarded-Host'))[0]) ?: $request->getHttpHost());

        // Les en-têtes Host / X-Forwarded-Host sont falsifiables : seuls le site configuré,
        // localhost et les tunnels ngrok sont acceptés, sinon l'aperçu pointe vers FRONTEND_URL
        $name = (string) parse_url("http://$host", PHP_URL_HOST);
        $allowed = $name === parse_url($front, PHP_URL_HOST)
            || in_array($name, ['localhost', '127.0.0.1'], true)
            || preg_match('/^[a-z0-9-]+(\.[a-z0-9-]+)*\.ngrok(-free)?\.(app|dev|io)$/', $name);
        if (! $allowed || ! preg_match('/^[a-z0-9.\-]+(:\d{1,5})?$/', $host)) {
            return $front;
        }

        return (in_array($proto, ['http', 'https'], true) ? $proto : 'https').'://'.$host;
    }
}
