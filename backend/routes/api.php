<?php

use App\Http\Controllers\Api\Admin\GiftController as AdminGift;
use App\Http\Controllers\Api\Admin\OrderController as AdminOrder;
use App\Http\Controllers\Api\Admin\PartnerController;
use App\Http\Controllers\Api\Admin\WrappingController as AdminWrapping;
use App\Http\Controllers\Api\AssistantController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\CatalogController;
use App\Http\Controllers\Api\FavoriteController;
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

Route::get('/meta', [CatalogController::class, 'meta']);
Route::get('/gifts', [CatalogController::class, 'gifts']);
Route::get('/gifts/{slug}', [CatalogController::class, 'gift']);

Route::get('/l/{code}', [SharedListController::class, 'show']);
Route::post('/l/{code}/items/{item}/reserve', [SharedListController::class, 'reserve'])->middleware('throttle:20,1');

Route::middleware('throttle:20,1')->group(function () {
    Route::post('/orders', [OrderController::class, 'store']);
    Route::post('/custom-requests', [OrderController::class, 'customRequest']);
    Route::post('/assistant/suggest', [AssistantController::class, 'suggest']);
});

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

    // ---- Administration (/admin) ----
    Route::prefix('admin')->middleware(EnsureAdmin::class)->group(function () {
        Route::get('/stats', [AdminOrder::class, 'stats']);
        Route::get('/partners', [PartnerController::class, 'index']);
        Route::post('/partners', [PartnerController::class, 'store']);
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
