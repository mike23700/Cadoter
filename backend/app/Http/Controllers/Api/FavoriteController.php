<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Gift;
use Illuminate\Http\Request;

class FavoriteController extends Controller
{
    public function index(Request $request)
    {
        return response()->json($request->user()->favorites()->where('is_active', true)->get());
    }

    public function toggle(Request $request, Gift $gift)
    {
        $result = $request->user()->favorites()->toggle($gift->id);

        return response()->json(['favorite' => count($result['attached']) > 0]);
    }
}
