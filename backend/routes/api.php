<?php

use App\Http\Controllers\Api\Admin\FaqController as AdminFaq;
use App\Http\Controllers\Api\Admin\GiftController as AdminGift;
use App\Http\Controllers\Api\Admin\InspirationController as AdminInspiration;
use App\Http\Controllers\Api\Admin\OrderController as AdminOrder;
use App\Http\Controllers\Api\Admin\PartnerController;
use App\Http\Controllers\Api\Admin\UserController as AdminUser;
use App\Http\Controllers\Api\Admin\WrappingController as AdminWrapping;
use App\Http\Controllers\Api\AssistantController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\ClientLogController;
use App\Http\Controllers\Api\FavoriteController;
use App\Http\Controllers\Api\ImportantDateController;
use App\Http\Controllers\Api\ListController;
use App\Http\Controllers\Api\OrderController;
use App\Http\Controllers\Api\SharedListController;
use App\Http\Middleware\EnsureAdmin;
use App\Http\Middleware\EnsureAdminOrPartner;
use Illuminate\Support\Facades\Route;

// ---- Public ----
Route::middleware('throttle:10,1')->group(function () {
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
});

Route::middleware('throttle:5,1')->group(function () {
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);
});

Route::get('/meta', [CatalogController::class, 'meta']);
Route::get('/gifts', [CatalogController::class, 'gifts']);
Route::get('/gifts/{slug}', [CatalogController::class, 'gift']);
Route::get('/faqs', [CatalogController::class, 'faqs']);
Route::get('/inspirations', [CatalogController::class, 'inspirations']);
Route::get('/inspirations/{slug}', [CatalogController::class, 'inspiration']);
Route::get('/shops/{partner}', [CatalogController::class, 'shop'])->whereNumber('partner');

Route::get('/l/{code}', [SharedListController::class, 'show']);
Route::post('/l/{code}/items/{item}/reserve', [SharedListController::class, 'reserve'])->middleware('throttle:20,1');

Route::middleware('throttle:20,1')->group(function () {
    Route::post('/orders', [OrderController::class, 'store']);
    Route::post('/custom-requests', [OrderController::class, 'customRequest']);
    Route::post('/assistant/suggest', [AssistantController::class, 'suggest']);
});
// Diagnostic temporaire de la « page blanche » (voir ClientLogController)
Route::post('/client-log', [ClientLogController::class, 'store'])->middleware('throttle:60,1');

// Recherche web (payante) : plus limitée
Route::post('/assistant/external', [AssistantController::class, 'external'])->middleware('throttle:6,1');

// ---- Connecté ----
Route::middleware('auth:sanctum')->group(function () {
    Route::get('/me', [AuthController::class, 'me']);
    Route::put('/me', [AuthController::class, 'update']);
    Route::put('/me/password', [AuthController::class, 'updatePassword'])->middleware('throttle:5,1');
    Route::post('/logout', [AuthController::class, 'logout']);

    Route::get('/lists', [ListController::class, 'index']);
    Route::post('/lists', [ListController::class, 'store']);
    Route::get('/lists/{list}', [ListController::class, 'show']);
    Route::match(['put', 'post'], '/lists/{list}/update', [ListController::class, 'update']);
    Route::put('/lists/{list}', [ListController::class, 'update']);
    Route::delete('/lists/{list}', [ListController::class, 'destroy']);
    Route::post('/lists/{list}/items', [ListController::class, 'addItem']);
    Route::post('/lists/{list}/items/manual', [ListController::class, 'addManualItem']);
    Route::put('/lists/{list}/items/{item}', [ListController::class, 'updateItem']);
    Route::delete('/lists/{list}/items/{item}', [ListController::class, 'removeItem']);

    Route::get('/favorites', [FavoriteController::class, 'index']);
    Route::post('/favorites/{gift}', [FavoriteController::class, 'toggle']);

    Route::get('/orders/mine', [OrderController::class, 'mine']);

    Route::get('/important-dates', [ImportantDateController::class, 'index']);
    Route::post('/important-dates', [ImportantDateController::class, 'store']);
    Route::put('/important-dates/{importantDate}', [ImportantDateController::class, 'update']);
    Route::delete('/important-dates/{importantDate}', [ImportantDateController::class, 'destroy']);

    // ---- Administration (/admin) ----
    Route::prefix('admin')->middleware(EnsureAdmin::class)->group(function () {
        Route::get('/stats', [AdminOrder::class, 'stats']);
        Route::get('/users', [AdminUser::class, 'index']);
        Route::put('/users/{user}', [AdminUser::class, 'update']);
        Route::get('/partners', [PartnerController::class, 'index']);
        Route::post('/partners', [PartnerController::class, 'store']);
        Route::put('/partners/{partner}', [PartnerController::class, 'update']);
        Route::get('/faqs', [AdminFaq::class, 'index']);
        Route::post('/faqs', [AdminFaq::class, 'store']);
        Route::put('/faqs/{faq}', [AdminFaq::class, 'update']);
        Route::delete('/faqs/{faq}', [AdminFaq::class, 'destroy']);
        Route::get('/settings', [AdminFaq::class, 'settings']);
        Route::put('/settings', [AdminFaq::class, 'updateSettings']);
        Route::get('/inspirations', [AdminInspiration::class, 'index']);
        Route::post('/inspirations', [AdminInspiration::class, 'store']);
        Route::post('/inspirations/{inspiration}', [AdminInspiration::class, 'update']);
        Route::put('/inspirations/{inspiration}', [AdminInspiration::class, 'update']);
        Route::delete('/inspirations/{inspiration}', [AdminInspiration::class, 'destroy']);
        Route::get('/wrappings', [AdminWrapping::class, 'index']);
        Route::post('/wrappings', [AdminWrapping::class, 'store']);
        Route::post('/wrappings/{wrapping}', [AdminWrapping::class, 'update']);
        Route::put('/wrappings/{wrapping}', [AdminWrapping::class, 'update']);
        Route::delete('/wrappings/{wrapping}', [AdminWrapping::class, 'destroy']);
        Route::get('/orders', [AdminOrder::class, 'index']);
        Route::put('/orders/{order}', [AdminOrder::class, 'update']);
        Route::get('/custom-requests', [AdminOrder::class, 'customRequests']);
        Route::put('/custom-requests/{customRequest}', [AdminOrder::class, 'updateCustomRequest']);
    });

    Route::prefix('admin')->middleware(EnsureAdminOrPartner::class)->group(function () {
        Route::get('/partner-stats', [AdminOrder::class, 'partnerStats']);
        Route::get('/gifts', [AdminGift::class, 'index']);
        Route::post('/gifts', [AdminGift::class, 'store']);
        Route::post('/gifts/{gift}', [AdminGift::class, 'update']);
        Route::put('/gifts/{gift}', [AdminGift::class, 'update']);
        Route::delete('/gifts/{gift}', [AdminGift::class, 'destroy']);
    });
});
