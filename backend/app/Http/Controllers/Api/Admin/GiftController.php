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
        $q = Gift::query()->with('partner:id,shop_name')->latest();
        if (! $request->user()->isAdmin()) {
            $q->where('partner_id', $request->user()->id);
        }
        if (is_string($s = $request->query('q')) && ($s = trim($s)) !== '') {
            $q->where('name', 'like', "%$s%");
        }

        return response()->json($q->get());
    }

    public function store(Request $request)
    {
        $data = $this->validated($request, true);
        $gift = new Gift($data);
        $gift->partner_id = $request->user()->isAdmin() ? null : $request->user()->id;
        if (! $request->user()->isAdmin()) {
            $gift->is_featured = false;
        }
        $oldImagePaths = $this->replaceImages($request, $gift);
        $gift->save();
        Storage::disk('public')->delete($oldImagePaths);

        return response()->json($gift->load('partner:id,shop_name'), 201);
    }

    /** POST multipart (envoi d'image) ou PUT. */
    public function update(Request $request, Gift $gift)
    {
        $this->authorizeGift($request, $gift);
        $gift->fill($this->validated($request, false));
        $oldImagePaths = $this->replaceImages($request, $gift);
        $gift->save();
        Storage::disk('public')->delete($oldImagePaths);

        return response()->json($gift->load('partner:id,shop_name'));
    }

    public function destroy(Request $request, Gift $gift)
    {
        $this->authorizeGift($request, $gift);
        Storage::disk('public')->delete($this->storedImagePaths($gift));
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

        $rules = [
            'name' => [$req, 'string', 'max:190'],
            'description' => ['nullable', 'string', 'max:3000'],
            'price' => [$req, 'integer', 'min:0'],
            'currency' => ['nullable', 'string', 'max:8'],
            'country' => [$req, 'string', 'max:80'],
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
            'images' => [$creating ? 'required_without:image' : 'sometimes', 'array', 'min:1', 'max:4'],
            'images.*' => ['image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
            'image' => [$creating ? 'required_without:images' : 'sometimes', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ];
        if ($request->user()->isAdmin()) {
            $rules['is_featured'] = ['nullable', 'boolean'];
        }

        $data = $request->validate($rules, [
            'image.required_without' => __('Ajoutez au moins une photo du cadeau.'),
            'images.required_without' => __('Ajoutez au moins une photo du cadeau.'),
            'images.min' => __('Ajoutez au moins une photo du cadeau.'),
            'images.max' => __('Un cadeau peut avoir au maximum 4 photos.'),
        ]);
        unset($data['image'], $data['images']);

        return $data;
    }

    /** Replace the gallery when new photos are provided and return the old file paths. */
    private function replaceImages(Request $request, Gift $gift): array
    {
        if (! $request->hasFile('images') && ! $request->hasFile('image')) {
            return [];
        }

        $oldPaths = $this->storedImagePaths($gift);
        $files = $request->file('images');
        if (! is_array($files)) {
            $files = [$request->file('image')];
        }

        $paths = collect($files)
            ->filter()
            ->map(fn ($file) => $file->store('gifts', 'public'))
            ->values()
            ->all();

        $gift->image_paths = $paths;
        $gift->image_path = $paths[0] ?? null;

        return $oldPaths;
    }

    private function storedImagePaths(Gift $gift): array
    {
        return array_values(array_unique(array_filter([
            ...($gift->image_paths ?? []),
            $gift->image_path,
        ])));
    }

    private function authorizeGift(Request $request, Gift $gift): void
    {
        abort_unless(
            $request->user()->isAdmin() || (int) $gift->partner_id === (int) $request->user()->id,
            404,
        );
    }
}
