<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GiftList;
use App\Models\ListItem;
use App\Services\LinkPreview;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\Storage;
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

    public function destroy(Request $request, GiftList $list): Response
    {
        $this->authorizeOwner($request, $list);
        $images = $list->items()->whereNotNull('external_image_path')->pluck('external_image_path')->all();
        $list->delete();
        Storage::disk('public')->delete($images);

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

    /** Ajouter manuellement un cadeau avec une photo. */
    public function addManualItem(Request $request, GiftList $list): JsonResponse
    {
        $this->authorizeOwner($request, $list);
        $data = $request->validate([
            'name' => ['required', 'string', 'max:190'],
            'description' => ['required', 'string', 'max:2000'],
            'price' => ['required', 'integer', 'min:0'],
            'seller_name' => ['required', 'string', 'max:190'],
            'image' => ['required', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);

        $item = $list->items()->create([
            'external_name' => $data['name'],
            'external_description' => $data['description'],
            'external_price' => $data['price'],
            'external_seller_name' => $data['seller_name'],
            'external_image_path' => $request->file('image')->store('list-items', 'public'),
        ]);

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

    /** Aperçu automatique (Open Graph / schema.org) d'une page produit. Silencieux en cas d'échec. */
    private function preview(string $url): array
    {
        return app(LinkPreview::class)->fetch($url);
    }
}
