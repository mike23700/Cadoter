<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\GiftList;
use App\Models\ListItem;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

/** Liste vue par un proche via le lien partagé. */
class SharedListController extends Controller
{
    public function show(Request $request, string $code)
    {
        $list = $this->open($request, $code);

        return response()->json(ListController::present($list->load('items.gift', 'owner'), false));
    }

    /** Une personne par cadeau : verrou de ligne pour éviter les doubles réservations. */
    public function reserve(Request $request, string $code, int $item)
    {
        $list = $this->open($request, $code);
        $data = $request->validate(['name' => ['nullable', 'string', 'max:120']]);
        $user = $request->user('sanctum');

        $item = DB::transaction(function () use ($list, $item, $data, $user) {
            $item = ListItem::whereKey($item)->where('gift_list_id', $list->id)->lockForUpdate()->firstOrFail();
            abort_if($item->status !== 'Disponible', 409, __('Un proche a déjà choisi ce cadeau.'));
            $item->update([
                'status' => 'Réservé',
                'reserved_by_name' => $data['name'] ?? $user?->name ?? __('Un proche'),
                'reserved_by_user_id' => $user?->id,
                'reserved_at' => now(),
            ]);

            return $item;
        });

        return response()->json($item->load('gift')->toPublicArray());
    }

    private function open(Request $request, string $code): GiftList
    {
        $list = GiftList::where('code', $code)->firstOrFail();
        if ($list->is_locked && $request->input('access_code', $request->header('X-Access-Code')) !== $list->access_code) {
            abort(response()->json(['message' => __("Cette liste est protégée par un code d'accès."), 'locked' => true, 'title' => $list->title], 423));
        }

        return $list;
    }
}
