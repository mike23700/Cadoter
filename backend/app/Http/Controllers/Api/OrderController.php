<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\CustomRequest;
use App\Models\Gift;
use App\Models\ListItem;
use App\Models\Order;
use App\Models\Wrapping;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\DB;

class OrderController extends Controller
{
    /** Commande d'un cadeau du catalogue (paiement Mobile Money confirmé ensuite). */
    public function store(Request $request)
    {
        $data = $request->validate([
            'gift_id' => ['required', 'exists:gifts,id'],
            'list_item_id' => ['nullable', 'exists:list_items,id'],
            'wrapping_id' => ['nullable', 'exists:wrappings,id'],
            'quantity' => ['nullable', 'integer', 'min:1', 'max:20'],
            'customer_name' => ['required', 'string', 'max:120'],
            'customer_phone' => ['required', 'string', 'max:30'],
            'customer_email' => ['nullable', 'email'],
            'delivery_city' => ['nullable', 'string', 'max:80'],
            'delivery_address' => ['nullable', 'string', 'max:255'],
            'message' => ['nullable', 'string', 'max:1000'],
            'payment_method' => ['required', 'in:orange_money,mtn_momo'],
        ]);

        $order = DB::transaction(function () use ($data, $request) {
            $gift = Gift::whereKey($data['gift_id'])->lockForUpdate()->firstOrFail();
            abort_unless($gift->available, 409, "Ce cadeau n'est plus disponible.");
            $qty = $data['quantity'] ?? 1;
            abort_if($gift->stock !== null && $gift->stock < $qty, 409, 'Stock insuffisant.');

            if (! empty($data['list_item_id'])) {
                $item = ListItem::whereKey($data['list_item_id'])->lockForUpdate()->first();
                abort_if(! $item || $item->gift_id !== $gift->id, 422, 'Élément de liste invalide.');
                abort_if($item->status === 'Indisponible', 409, "Ce cadeau n'est plus disponible.");
            }

            $wrapPrice = ! empty($data['wrapping_id']) ? Wrapping::find($data['wrapping_id'])->price : 0;
            if ($gift->stock !== null) {
                $gift->decrement('stock', $qty);
            }

            return Order::create([
                ...$data,
                'user_id' => $request->user('sanctum')?->id,
                'gift_name' => $gift->name,
                'quantity' => $qty,
                'unit_price' => $gift->price,
                'total' => $gift->price * $qty + $wrapPrice,
                'currency' => $gift->currency,
            ]);
        });

        return response()->json([
            'order' => $order,
            'message' => 'Commande enregistrée. Vous recevrez une demande de paiement Mobile Money sur le '.$order->customer_phone.'.',
        ], 201);
    }

    public function mine(Request $request)
    {
        return response()->json(Order::where('user_id', $request->user()->id)->with('gift')->latest()->get());
    }

    /** Formulaire « cadeau personnalisé » : pas de commande directe, l'équipe recontacte. */
    public function customRequest(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'phone' => ['required', 'string', 'max:30'],
            'budget' => ['required', 'integer', 'min:1000'],
            'description' => ['required', 'string', 'max:3000'],
            'wrapping_id' => ['nullable', 'exists:wrappings,id'],
        ]);

        $req = CustomRequest::create([...$data, 'user_id' => $request->user('sanctum')?->id]);

        return response()->json(['request' => $req, 'message' => 'Merci ! Nous vous recontactons pour préciser les possibilités.'], 201);
    }
}
