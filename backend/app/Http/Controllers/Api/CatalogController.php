<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gift;
use App\Models\Wrapping;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public const OCCASIONS = ['Anniversaire', 'Mariage', 'Naissance', 'Dot', 'Décès · Soutenir un proche', 'Autre'];

    public const FOR_WHO = ['Enfants', 'Parents', 'Couple', 'Ami(e)s', 'Collègue', 'Famille'];

    public function gifts(Request $request)
    {
        $q = Gift::query()->where('is_active', true);

        if ($s = trim((string) $request->query('q'))) {
            $q->where(fn ($w) => $w->where('name', 'ilike', "%$s%")->orWhere('description', 'ilike', "%$s%"));
        }
        if ($budget = (int) $request->query('budget')) {
            $q->where('price', '<=', $budget);
        }
        if ($city = $request->query('city')) {
            $q->where('city', $city);
        }
        if ($for = $request->query('for_who')) {
            $q->whereJsonContains('for_who', $for);
        }
        if ($occ = $request->query('occasion')) {
            $q->whereJsonContains('occasions', $occ);
        }
        if ($request->boolean('featured')) {
            $q->where('is_featured', true);
        }

        match ($request->query('sort')) {
            'price_asc' => $q->orderBy('price'),
            'price_desc' => $q->orderByDesc('price'),
            'recent' => $q->latest(),
            default => $q->orderByDesc('is_featured')->latest(),
        };

        $limit = min((int) $request->query('limit', 60) ?: 60, 100);

        return response()->json($q->limit($limit)->get());
    }

    public function gift(string $slug)
    {
        $gift = Gift::where('is_active', true)
            ->where(fn ($w) => ctype_digit($slug) ? $w->whereKey($slug) : $w->where('slug', $slug))
            ->firstOrFail();

        return response()->json($gift);
    }

    public function meta()
    {
        return response()->json([
            'occasions' => self::OCCASIONS,
            'for_who' => self::FOR_WHO,
            'cities' => Gift::where('is_active', true)->distinct()->orderBy('city')->pluck('city'),
            'wrappings' => Wrapping::orderBy('position')->get(),
            'payment_methods' => [
                ['code' => 'orange_money', 'name' => 'Orange Money'],
                ['code' => 'mtn_momo', 'name' => 'MTN Mobile Money'],
            ],
        ]);
    }
}
