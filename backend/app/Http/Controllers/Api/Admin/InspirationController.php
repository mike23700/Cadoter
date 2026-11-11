<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Inspiration;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Storage;

/** Articles de la page « Inspirations ». */
class InspirationController extends Controller
{
    public function index()
    {
        return response()->json(Inspiration::latest()->orderByDesc('id')->get());
    }

    public function store(Request $request)
    {
        $article = new Inspiration($this->validated($request, true));
        if ($request->hasFile('image')) {
            $article->image_path = $request->file('image')->store('inspirations', 'public');
        }
        $article->save();

        return response()->json($article, 201);
    }

    /** POST multipart (envoi d'image) ou PUT. */
    public function update(Request $request, Inspiration $inspiration)
    {
        $inspiration->fill($this->validated($request, false));
        if ($request->hasFile('image')) {
            $old = $inspiration->image_path;
            $inspiration->image_path = $request->file('image')->store('inspirations', 'public');
            if ($old) {
                Storage::disk('public')->delete($old);
            }
        }
        $inspiration->save();

        return response()->json($inspiration);
    }

    public function destroy(Inspiration $inspiration)
    {
        if ($inspiration->image_path) {
            Storage::disk('public')->delete($inspiration->image_path);
        }
        $inspiration->delete();

        return response()->noContent();
    }

    private function validated(Request $request, bool $creating): array
    {
        $req = $creating ? 'required' : 'sometimes';
        $data = $request->validate([
            'tag' => [$req, 'string', 'max:80'],
            'title' => [$req, 'string', 'max:255'],
            'excerpt' => ['nullable', 'string', 'max:500'],
            'body' => [$req, 'string', 'max:20000'],
            'tag_en' => ['nullable', 'string', 'max:80'],
            'title_en' => ['nullable', 'string', 'max:255'],
            'excerpt_en' => ['nullable', 'string', 'max:500'],
            'body_en' => ['nullable', 'string', 'max:20000'],
            'minutes' => ['nullable', 'integer', 'min:1', 'max:120'],
            'is_active' => ['nullable', 'boolean'],
            'image' => ['nullable', 'image', 'mimes:jpg,jpeg,png,webp', 'max:5120'],
        ]);
        unset($data['image']);
        if (array_key_exists('is_active', $data) && $data['is_active'] === null) {
            if ($creating) {
                $data['is_active'] = true;
            } else {
                unset($data['is_active']);
            }
        }

        return $data;
    }
}
