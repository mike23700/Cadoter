<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GiftList;
use App\Models\ListItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Http;
use Illuminate\Validation\Rule;

class ListController extends Controller
{
    public function index(Request $request)
    {
        $lists = $request->user()->lists()->with('items.gift.partner:id,shop_name')->latest()->get();

        return response()->json($lists->map(fn ($l) => $this->present($l)));
    }

    public function store(Request $request)
    {
        $data = $this->validated($request, true);
        $user = $request->user();
        $list = new GiftList($data);
        $list->owner()->associate($user);
        $list->code = GiftList::uniqueCode($user->name, $data['title']);
        if ($request->hasFile('image')) {
            $list->image_path = $request->file('image')->store('lists', 'public');
        }
        $list->save();

        return response()->json($this->present($list->load('items.gift.partner:id,shop_name')), 201);
    }

    public function show(Request $request, GiftList $list)
    {
        $this->authorizeOwner($request, $list);

        return response()->json($this->present($list->load('items.gift.partner:id,shop_name')));
    }

    /** POST (multipart) ou PUT. */
    public function update(Request $request, GiftList $list)
    {
        $this->authorizeOwner($request, $list);
        $data = $this->validated($request, false);
        if ($request->hasFile('image')) {
            $data['image_path'] = $request->file('image')->store('lists', 'public');
        }
        $list->update($data);

        return response()->json($this->present($list->load('items.gift.partner:id,shop_name')));
    }

    public function destroy(Request $request, GiftList $list)
    {
        $this->authorizeOwner($request, $list);
        $list->delete();

        return response()->noContent();
    }

    /** Ajouter un cadeau du catalogue (gift_id) ou un lien marchand (url). */
    public function addItem(Request $request, GiftList $list)
    {
        $this->authorizeOwner($request, $list);
        $data = $request->validate([
            'gift_id' => ['required_without:url', 'nullable', 'exists:gifts,id'],
            'url' => ['required_without:gift_id', 'nullable', 'url', 'max:2048'],
            'name' => ['nullable', 'string', 'max:190'],
            'price' => ['nullable', 'integer', 'min:0'],
        ]);

        if (! empty($data['gift_id'])) {
            abort_if($list->items()->where('gift_id', $data['gift_id'])->exists(), 422, __('Ce cadeau est déjà dans la liste.'));
            $item = $list->items()->create(['gift_id' => $data['gift_id']]);
        } else {
            $preview = $this->preview($data['url']);
            $item = $list->items()->create([
                'external_url' => $data['url'],
                'external_name' => $data['name'] ?? $preview['name'],
                'external_image' => $preview['image'],
                'external_price' => $data['price'] ?? $preview['price'],
            ]);
        }

        return response()->json($item->load('gift')->toPublicArray(true), 201);
    }

    public function updateItem(Request $request, GiftList $list, ListItem $item)
    {
        $this->authorizeOwner($request, $list);
        abort_unless($item->gift_list_id === $list->id, 404);
        $data = $request->validate(['status' => ['required', Rule::in(ListItem::STATUSES)]]);

        $item->status = $data['status'];
        if ($data['status'] === 'Disponible') {
            $item->reserved_by_name = null;
            $item->reserved_by_user_id = null;
            $item->reserved_at = null;
        }
        $item->save();

        return response()->json($item->load('gift')->toPublicArray(true));
    }

    public function removeItem(Request $request, GiftList $list, ListItem $item)
    {
        $this->authorizeOwner($request, $list);
        abort_unless($item->gift_list_id === $list->id, 404);
        $item->delete();

        return response()->noContent();
    }

    private function validated(Request $request, bool $creating): array
    {
        $req = $creating ? 'required' : 'sometimes';

        return $request->validate([
            'title' => [$req, 'string', 'max:120'],
            'description' => ['nullable', 'string', 'max:2000'],
            'occasion' => [$req, 'string', 'max:60'],
            'event_date' => ['nullable', 'date'],
            'access_code' => ['nullable', 'string', 'max:20'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png', 'max:5120'],
        ], ['image.max' => __("L'image ne doit pas dépasser 5 Mo.")]);
    }

    private function authorizeOwner(Request $request, GiftList $list): void
    {
        abort_unless($list->owner_id === $request->user()->id, 403, __('Cette liste ne vous appartient pas.'));
    }

    public static function present(GiftList $list, bool $owner = true): array
    {
        $items = $list->items->map(fn ($i) => $i->toPublicArray($owner));

        return [
            'id' => $list->id,
            'code' => $list->code,
            'title' => $list->title,
            'description' => $list->description,
            'occasion' => $list->occasion,
            'image_url' => $list->image_url,
            'event_date' => $list->event_date?->format('Y-m-d'),
            'created_at' => $list->created_at,
            'is_locked' => $list->is_locked,
            'access_code' => $owner ? $list->access_code : null,
            'owner_name' => $list->owner?->name,
            'items' => $items,
            'counts' => [
                'total' => $items->count(),
                'reserved' => $items->where('status', 'Réservé')->count(),
                'available' => $items->where('status', 'Disponible')->count(),
            ],
        ];
    }

    /** Aperçu automatique (Open Graph) d'une page produit. Silencieux en cas d'échec. */
    private function preview(string $url): array
    {
        $out = ['name' => parse_url($url, PHP_URL_HOST) ?: __('Produit externe'), 'image' => null, 'price' => null];
        // Protection SSRF : uniquement http(s) vers une adresse publique
        $host = parse_url($url, PHP_URL_HOST);
        $scheme = parse_url($url, PHP_URL_SCHEME);
        $ip = $host ? gethostbyname($host) : null;
        if (! in_array($scheme, ['http', 'https'], true) || ! $ip
            || ! filter_var($ip, FILTER_VALIDATE_IP, FILTER_FLAG_NO_PRIV_RANGE | FILTER_FLAG_NO_RES_RANGE)) {
            return $out;
        }
        try {
            $html = Http::timeout(5)->withOptions(['allow_redirects' => false])->withHeaders(['User-Agent' => 'Mozilla/5.0 CadoterBot'])->get($url)->body();
            $meta = function (string $prop) use ($html) {
                return preg_match('/<meta[^>]+(?:property|name)=["\']'.preg_quote($prop, '/').'["\'][^>]+content=["\']([^"\']+)/i', $html, $m)
                    ? html_entity_decode($m[1]) : null;
            };
            $out['name'] = $meta('og:title') ?? (preg_match('/<title>([^<]+)/i', $html, $m) ? trim(html_entity_decode($m[1])) : $out['name']);
            $out['image'] = $meta('og:image');
            $price = $meta('product:price:amount') ?? $meta('og:price:amount');
            $out['price'] = $price ? (int) round((float) str_replace([' ', ','], ['', '.'], $price)) : null;
        } catch (\Throwable) {
            // l'aperçu est facultatif
        }
        $out['name'] = mb_substr($out['name'], 0, 190);

        return $out;
    }
}
