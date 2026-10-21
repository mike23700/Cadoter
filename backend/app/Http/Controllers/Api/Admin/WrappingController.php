<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Wrapping;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/** Emballages proposés à la commande et pour les cadeaux personnalisés. */
class WrappingController extends Controller
{
    public function index()
    {
        return response()->json(Wrapping::orderBy('position')->orderBy('id')->get());
    }

    public function store(Request $request)
    {
        $wrapping = new Wrapping($this->validated($request, true));
        $wrapping->position ??= (int) Wrapping::max('position') + 1;
        $wrapping->image_path = $request->file('image')->store('wrappings', 'public');
        $wrapping->save();

        return response()->json($wrapping, 201);
    }

    /** POST multipart (envoi d'image) ou PUT. */
    public function update(Request $request, Wrapping $wrapping)
    {
        $wrapping->fill($this->validated($request, false));
        if ($request->hasFile('image')) {
            $old = $wrapping->image_path;
            $wrapping->image_path = $request->file('image')->store('wrappings', 'public');
            if ($old) {
                Storage::disk('public')->delete($old);
            }
        }
        $wrapping->save();

        return response()->json($wrapping);
    }

    /** Les commandes et demandes passées gardent leur historique (clé étrangère mise à null). */
    public function destroy(Wrapping $wrapping)
    {
        if ($wrapping->image_path) {
            Storage::disk('public')->delete($wrapping->image_path);
        }
        $wrapping->delete();

        return response()->noContent();
    }

    private function validated(Request $request, bool $creating): array
    {
        $req = $creating ? 'required' : 'sometimes';
        $data = $request->validate([
            'name' => [$req, 'string', 'max:120'],
            'detail' => ['nullable', 'string', 'max:190'],
            'price' => ['nullable', 'integer', 'min:0'],
            'position' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
            'image' => [$creating ? 'required' : 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ], ['image.required' => "Ajoutez une photo de l'emballage."]);
        unset($data['image']);
        // Prix / position / statut laissés vides : valeur par défaut à la création, inchangés à la modification
        foreach (['price' => 0, 'position' => null, 'is_active' => true] as $key => $default) {
            if (array_key_exists($key, $data) && $data[$key] === null) {
                if ($creating && $default !== null) {
                    $data[$key] = $default;
                } else {
                    unset($data[$key]);
                }
            }
        }

        return $data;
    }
}
