<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class PartnerController extends Controller
{
    public function index()
    {
        return response()->json(User::query()
            ->where('role', 'partner')
            ->latest()
            ->get(['id', 'name', 'email', 'phone', 'shop_name', 'created_at']));
    }

    public function store(Request $request)
    {
        if ($request->has('email')) {
            $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);
        }

        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'shop_name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'phone' => ['nullable', 'string', 'max:30', 'unique:users,phone'],
            'password' => ['required', 'string', 'min:8', 'confirmed'],
        ]);

        $partner = (new User)->forceFill([
            ...$data,
            'role' => 'partner',
            'language' => 'fr',
        ]);
        $partner->save();

        return response()->json($partner, 201);
    }

    /** Mot de passe facultatif : renseigné, il remplace l'ancien et déconnecte la boutique. */
    public function update(Request $request, User $partner)
    {
        abort_unless($partner->role === 'partner', 404);
        if ($request->has('email')) {
            $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);
        }

        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:120'],
            'shop_name' => ['sometimes', 'string', 'max:120'],
            'email' => ['sometimes', 'email', 'max:190', Rule::unique('users', 'email')->ignore($partner->id)],
            'phone' => ['nullable', 'string', 'max:30', Rule::unique('users', 'phone')->ignore($partner->id)],
            'password' => ['nullable', 'string', 'min:8', 'confirmed'],
        ]);
        if (empty($data['password'])) {
            unset($data['password']);
        }

        $partner->update($data);
        if (isset($data['password'])) {
            $partner->tokens()->delete();
        }

        return response()->json($partner->only(['id', 'name', 'email', 'phone', 'shop_name', 'created_at']));
    }
}
