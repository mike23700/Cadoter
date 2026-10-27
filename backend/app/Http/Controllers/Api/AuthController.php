<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\User;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Password as PasswordBroker;
use Illuminate\Support\Str;
use Illuminate\Validation\Rules\Password;
use Illuminate\Validation\ValidationException;
use Throwable;

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
            'terms.accepted' => __("Veuillez accepter les conditions d'utilisation."),
            'email.unique' => __('Cet email est déjà utilisé.'),
            'phone.unique' => __('Ce numéro est déjà utilisé.'),
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
            throw ValidationException::withMessages(['login' => __('Identifiants incorrects.')]);
        }

        return response()->json($this->session($user, $request));
    }

    public function logout(Request $request)
    {
        $request->user()->currentAccessToken()?->delete();

        return response()->json(['message' => __('Déconnecté.')]);
    }

    public function me(Request $request)
    {
        return response()->json($request->user());
    }

    public function update(Request $request)
    {
        $user = $request->user();
        if ($request->has('email')) {
            $request->merge(['email' => strtolower(trim((string) $request->input('email')))]);
        }
        $data = $request->validate([
            'name' => ['sometimes', 'required', 'string', 'max:120'],
            'email' => ['sometimes', 'required', 'email', 'max:190', 'unique:users,email,'.$user->id],
            'phone' => ['sometimes', 'nullable', 'string', 'max:30', 'unique:users,phone,'.$user->id],
            'language' => ['sometimes', 'in:fr,en'],
        ]);
        $user->update($data);

        return response()->json($user);
    }

    public function updatePassword(Request $request)
    {
        $data = $request->validate([
            'current_password' => ['required', 'string'],
            'password' => ['required', 'confirmed', 'different:current_password', Password::min(8)],
        ], [
            'password.different' => 'Le nouveau mot de passe doit être différent de l’actuel.',
        ]);

        if (! Hash::check($data['current_password'], $request->user()->password)) {
            throw ValidationException::withMessages([
                'current_password' => 'Le mot de passe actuel est incorrect.',
            ]);
        }

        $request->user()->update(['password' => $data['password']]);

        return response()->json(['message' => 'Mot de passe modifié.']);
    }

    /** Envoie un lien de réinitialisation. Réponse identique que le compte existe ou non. */
    public function forgotPassword(Request $request)
    {
        $data = $request->validate(['email' => ['required', 'email']]);

        try {
            PasswordBroker::sendResetLink(['email' => strtolower(trim($data['email']))]);
        } catch (Throwable $exception) {
            Log::error('Échec d’envoi du lien de réinitialisation.', ['exception' => $exception->getMessage()]);
            abort(503, __('Impossible d’envoyer l’e-mail pour le moment. Réessayez plus tard.'));
        }

        return response()->json([
            'message' => __('Si un compte existe avec cette adresse, un lien de réinitialisation vient d’être envoyé.'),
        ]);
    }

    public function resetPassword(Request $request)
    {
        $data = $request->validate([
            'token' => ['required', 'string'],
            'email' => ['required', 'email'],
            'password' => ['required', 'confirmed', Password::min(8)],
        ]);

        $status = PasswordBroker::reset(
            [...$data, 'email' => strtolower(trim($data['email']))],
            function (User $user, string $password) {
                $user->forceFill(['password' => $password, 'remember_token' => Str::random(60)])->save();
                // Déconnecte toutes les sessions existantes
                $user->tokens()->delete();
            },
        );

        if ($status !== PasswordBroker::PASSWORD_RESET) {
            throw ValidationException::withMessages([
                'email' => __('Ce lien de réinitialisation est invalide ou a expiré.'),
            ]);
        }

        return response()->json(['message' => __('Mot de passe réinitialisé. Vous pouvez vous connecter.')]);
    }

    private function session(User $user, Request $request): array
    {
        $device = substr((string) $request->userAgent(), 0, 60) ?: 'app';

        return ['token' => $user->createToken($device)->plainTextToken, 'user' => $user];
    }
}
