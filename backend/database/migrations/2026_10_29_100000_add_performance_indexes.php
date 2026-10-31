<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

/**
 * Index des clés étrangères et des filtres fréquents : PostgreSQL n'indexe pas
 * automatiquement les colonnes « foreignId()->constrained() ».
 */
return new class extends Migration
{
    private const INDEXES = [
        'gift_lists' => [['owner_id']],
        'list_items' => [['gift_list_id'], ['gift_id'], ['reserved_by_user_id']],
        'orders' => [['user_id'], ['gift_id'], ['list_item_id'], ['status', 'created_at']],
        'custom_requests' => [['user_id'], ['status']],
        'favorites' => [['gift_id']],
        'gifts' => [['partner_id'], ['is_active', 'is_featured', 'created_at']],
        'important_dates' => [['user_id']],
        'users' => [['role']],
    ];

    public function up(): void
    {
        foreach (self::INDEXES as $table => $indexes) {
            foreach ($indexes as $columns) {
                if (! Schema::hasIndex($table, $columns)) {
                    Schema::table($table, fn (Blueprint $t) => $t->index($columns));
                }
            }
        }
    }

    public function down(): void
    {
        foreach (self::INDEXES as $table => $indexes) {
            foreach ($indexes as $columns) {
                if (Schema::hasIndex($table, $columns)) {
                    Schema::table($table, fn (Blueprint $t) => $t->dropIndex($columns));
                }
            }
        }
    }
};
