<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use App\Models\Gift;
use App\Models\Inspiration;
use App\Models\Setting;
use App\Models\User;
use App\Models\Wrapping;
use Illuminate\Http\Request;

class CatalogController extends Controller
{
    public const OCCASIONS = ['Anniversaire', 'Mariage', 'Naissance', 'Dot', 'Décès · Soutenir un proche', 'Autre'];

    public const FOR_WHO = ['Enfants', 'Parents', 'Couple', 'Ami(e)s', 'Collègue', 'Famille'];

    public function gifts(Request $request)
    {
        $q = Gift::query()->with('partner:id,shop_name')->where('is_active', true);

        if ($s = trim((string) $request->query('q'))) {
            $q->where(fn ($w) => $w->where('name', 'like', "%$s%")->orWhere('description', 'like', "%$s%"));
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

        // Avec ?page=N : réponse paginée { data, current_page, last_page, total… } (catalogue web).
        // Sans : simple tableau limité, comme avant (accueil, listes, application mobile).
        if ($request->has('page')) {
            return response()->json($q->paginate(min((int) $request->query('per_page', 24) ?: 24, 100))->withQueryString());
        }

        return response()->json($q->limit($limit)->get());
    }

    public function gift(string $slug)
    {
        $gift = Gift::with('partner:id,shop_name')->where('is_active', true)
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
            'wrappings' => Wrapping::where('is_active', true)->orderBy('position')->orderBy('id')->get(),
            'payment_methods' => [
                ['code' => 'orange_money', 'name' => 'Orange Money'],
                ['code' => 'mtn_momo', 'name' => 'MTN Mobile Money'],
            ],
            'contact' => ['whatsapp' => Setting::getValue('whatsapp_number')],
        ]);
    }

    /** Page publique d'une boutique partenaire et de ses produits en ligne. */
    public function shop(User $partner)
    {
        abort_unless($partner->role === 'partner', 404);

        return response()->json([
            'id' => $partner->id,
            'shop_name' => $partner->shop_name,
            'created_at' => $partner->created_at,
            'gifts' => $partner->gifts()->with('partner:id,shop_name')->where('is_active', true)
                ->orderByDesc('is_featured')->latest()->get(),
        ]);
    }

    public function inspirations()
    {
        return response()->json(Inspiration::where('is_active', true)->latest()->orderByDesc('id')->get()
            ->map(fn (Inspiration $a) => $a->localized(false)));
    }

    public function inspiration(string $slug)
    {
        return response()->json(Inspiration::where('is_active', true)->where('slug', $slug)->firstOrFail()->localized());
    }

    public function faqs()
    {
        return response()->json(Faq::where('is_active', true)->orderBy('position')->orderBy('id')->get()
            ->map(fn (Faq $f) => $f->localized()));
    }
}
