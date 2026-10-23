<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Gift;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

class GiftController extends Controller
{
    public function index(Request $request)
    {
        $q = Gift::query()->latest();
        if ($s = $request->query('q')) {
            $q->where('name', 'ilike', "%$s%");
        }

        return response()->json($q->get());
    }

    public function store(Request $request)
    {
        $gift = new Gift($this->validated($request, true));
        $gift->image_path = $request->file('image')?->store('gifts', 'public');
        $gift->save();

        return response()->json($gift, 201);
    }

    /** POST multipart (envoi d'image) ou PUT. */
    public function update(Request $request, Gift $gift)
    {
        $gift->fill($this->validated($request, false));
        if ($request->hasFile('image')) {
            $old = $gift->image_path;
            $gift->image_path = $request->file('image')->store('gifts', 'public');
            if ($old) {
                Storage::disk('public')->delete($old);
            }
        }
        $gift->save();

        return response()->json($gift);
    }

    public function destroy(Gift $gift)
    {
        if ($gift->image_path) {
            Storage::disk('public')->delete($gift->image_path);
        }
        $gift->delete();

        return response()->noContent();
    }

    private function validated(Request $request, bool $creating): array
    {
        // Les formulaires multipart envoient les tableaux en JSON et les booléens en texte
        foreach (['for_who', 'occasions'] as $k) {
            if (is_string($request->input($k))) {
                $request->merge([$k => json_decode($request->input($k), true) ?? []]);
            }
        }
        $req = $creating ? 'required' : 'sometimes';

        $data = $request->validate([
            'name' => [$req, 'string', 'max:190'],
            'description' => ['nullable', 'string', 'max:3000'],
            'price' => [$req, 'integer', 'min:0'],
            'currency' => ['nullable', 'string', 'max:8'],
            'country' => ['nullable', 'string', 'max:80'],
            'city' => [$req, 'string', 'max:80'],
            'area' => ['nullable', 'string', 'max:80'],
            'shop' => ['nullable', 'string', 'max:120'],
            'category' => ['nullable', 'string', 'max:80'],
            'for_who' => ['nullable', 'array'],
            'for_who.*' => ['string', 'max:40'],
            'occasions' => ['nullable', 'array'],
            'occasions.*' => ['string', 'max:60'],
            'stock' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
            'is_featured' => ['nullable', 'boolean'],
            'image' => [$creating ? 'required' : 'nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ], ['image.required' => __('Ajoutez une photo du cadeau.')]);
        unset($data['image']);

        return $data;
    }
}
