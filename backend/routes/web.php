<?php

use App\Http\Controllers\Web\SharePreviewController;
use Illuminate\Support\Facades\Route;

Route::get('/', function () {
    return view('welcome');
});

// Aperçu (Open Graph) d'un lien de liste partagé, servi aux robots de WhatsApp, Facebook…
Route::get('/apercu/l/{code}', [SharePreviewController::class, 'list']);
