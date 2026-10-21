<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;

class AuthController extends Controller
{
    public function register(Request $request)
    {
        $data = $request->validate([
            'name' => ['required', 'string', 'max:120'],
            'phone' => ['required', 'string', 'max:30', 'unique:users,phone'],
            'email' => ['required', 'email', 'max:190', 'unique:users,email'],
            'password' => ['required', 'confirmed', Password::min(8)],
            'terms' => ['accepted'],
            'language' => ['nullable', 'in:fr,en'],
        ], [
            'terms.accepted' => "Veuillez accepter les conditions d'utilisation.",
            'email.unique' => 'Cet email est déjà utilisé.',
            'phone.unique' => 'Ce numéro est déjà utilisé.',
        ]);

        $user = User::create([
            'name' => $data['name'],
            'phone' => $data['phone'],
            'email' => strtolower($data['email']),
            'password' => $data['password'],
            'language' => $data['language'] ?? 'fr',
        ]);

        return response()->json($this->session($user, $request), 201);
    }

    /** Connexion par email ou téléphone. */
    public function login(Request $request)
    {
        $data = $request->validate([
            'login' => ['required', 'string'],
            'password' => ['required', 'string'],
        ]);

        $login = trim($data['login']);
        $user = str_contains($login, '@')
            ? User::where('email', strtolower($login))->first()
            : User::where('phone', $login)->first();

        // Tolère un espace copié-collé autour du mot de passe
        $ok = $user && (Hash::check($data['password'], $user->password)
            || (trim($data['password']) !== $data['password'] && Hash::check(trim($data['password']), $user->password)));

        if (! $ok) {
            throw ValidationException::withMessages(['login' => 'Identifiants incorrects.']);
        }

        return response()->json($this->session($user, $request));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => 'Déconnecté.']);
    }

    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    public function update(Request $request)
    {
        $user = $request->user();
        $data = $request->validate([
            'name' => ['sometimes', 'string', 'max:120'],
            'phone' => ['sometimes', 'string', 'max:30', 'unique:users,phone,'.$user->id],
            'language' => ['sometimes', 'in:fr,en'],
        ]);
        $user->update($data);

        return response()->json($user);
    }

    private function session(User $user, Request $request): array
    {
        $device = substr((string) $request->userAgent(), 0, 60) ?: 'app';

        return ['token' => $user->createToken($device)->plainTextToken, 'user' => $user];
    }
}
