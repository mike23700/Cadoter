<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\CustomRequest;
use App\Models\Gift;
use App\Models\GiftList;
use App\Models\Order;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class OrderController extends Controller
{
    public function stats()
    {
        return response()->json([
            'gifts' => Gift::count(),
            'active_gifts' => Gift::where('is_active', true)->count(),
            'orders' => Order::count(),
            'pending_orders' => Order::where('status', 'en_attente')->count(),
            'revenue' => (int) Order::whereIn('status', ['payee', 'livree'])->sum('total'),
            'custom_requests' => CustomRequest::where('status', 'nouvelle')->count(),
            'users' => User::count(),
            'lists' => GiftList::count(),
        ]);
    }

    public function partnerStats(Request $request)
    {
        $partner = $request->user();
        abort_unless($partner->role === 'partner', 403);

        $revenue = Order::query()
            ->whereIn('status', ['payee', 'livree'])
            ->whereHas('gift', fn ($query) => $query->where('partner_id', $partner->id))
            ->sum('total');

        return response()->json([
            'active_gifts' => $partner->gifts()->where('is_active', true)->count(),
            'revenue' => (int) $revenue,
        ]);
    }

    public function index(Request $request)
    {
        return response()->json(
            Order::with('wrapping:id,name')
                ->when($request->query('status'), fn ($q, $s) => $q->where('status', $s))
                ->latest()->limit(200)->get()
        );
    }

    public function update(Request $request, Order $order)
    {
        $data = $request->validate(['status' => ['required', Rule::in(Order::STATUSES)]]);
        $order->update($data);

        // Paiement validé : le cadeau de la liste devient réservé pour les autres proches
        if (in_array($data['status'], ['payee', 'livree'], true) && $order->listItem && $order->listItem->status === 'Disponible') {
            $order->listItem->update([
                'status' => 'Réservé',
                'reserved_by_name' => $order->customer_name,
                'reserved_by_user_id' => $order->user_id,
                'reserved_at' => now(),
            ]);
        }

        return response()->json($order);
    }

    public function customRequests()
    {
        return response()->json(CustomRequest::with('wrapping:id,name')->latest()->limit(200)->get());
    }

    public function updateCustomRequest(Request $request, CustomRequest $customRequest)
    {
        $customRequest->update($request->validate(['status' => ['required', Rule::in(CustomRequest::STATUSES)]]));

        return response()->json($customRequest);
    }
}
