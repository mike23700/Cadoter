<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

/** Liste de tous les comptes (clients, boutiques, administrateurs). */
class UserController extends Controller
{
    public function index(Request $request)
    {
        $q = User::query()->select(['id', 'name', 'email', 'phone', 'role', 'shop_name', 'language', 'created_at'])->withCount(['lists', 'orders', 'gifts'])->latest();
        if (in_array($role = $request->query('role'), ['user', 'partner', 'admin'], true)) {
            $q->where('role', $role);
        }
        if ($s = trim((string) $request->query('q'))) {
            $q->where(fn ($w) => $w->where('name', 'like', "%$s%")->orWhere('email', 'like', "%$s%")
                ->orWhere('phone', 'like', "%$s%")->orWhere('shop_name', 'like', "%$s%"));
        }

        return response()->json($q->limit(500)->get());
    }

    /** Mot de passe facultatif : renseigné, il remplace l'ancien et déconnecte le compte. */
    public function update(Request $request, User $user)
    {
        if ($request->has('email')) {
            $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);
        }

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:120'],
            'email' => ['sometimes', 'email', 'max:190', Rule::unique('users', 'email')->ignore($user->id)],
            'phone' => ['nullable', 'string', 'max:30', Rule::unique('users', 'phone')->ignore($user->id)],
            'role' => ['sometimes', Rule::in(['user', 'partner', 'admin'])],
            'shop_name' => [Rule::requiredIf(fn () => $request->input('role', $user->role) === 'partner'), 'nullable', 'string', 'max:120'],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ], ['shop_name.required' => __('Indiquez le nom de la boutique.')]);

        // Un administrateur ne peut pas se retirer lui-même ses droits
        if ($user->is($request->user()) && ($data['role'] ?? 'admin') !== 'admin') {
            return response()->json(['message' => __('Vous ne pouvez pas retirer vos propres droits d\'administrateur.')], 422);
        }
        if (empty($data['password'])) {
            unset($data['password']);
        }

        $user->forceFill($data)->save();
        if (isset($data['password'])) {
            $user->tokens()->delete();
        }

        return response()->json($user->only(['id', 'name', 'email', 'phone', 'role', 'shop_name', 'language', 'created_at']));
    }
}
