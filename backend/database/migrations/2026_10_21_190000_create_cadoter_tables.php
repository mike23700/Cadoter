<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Catalogue géré depuis /admin
        Schema::create('gifts', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->text('description')->nullable();
            $table->unsignedInteger('price');
            $table->string('currency', 8)->default('FCFA');
            $table->string('country')->default("Côte d'Ivoire");
            $table->string('city');
            $table->string('area')->nullable();
            $table->string('shop')->nullable();
            $table->string('category')->nullable();
            $table->json('for_who')->nullable();
            $table->json('occasions')->nullable();
            $table->string('image_path')->nullable();
            $table->unsignedInteger('stock')->nullable(); // null = illimité
            $table->boolean('is_active')->default(true);
            $table->boolean('is_featured')->default(false);
            $table->timestamps();
            $table->index(['is_active', 'city']);
        });

        Schema::create('wrappings', function (Blueprint $table) {
            $table->id();
            $table->string('code')->unique();
            $table->string('name');
            $table->string('detail')->nullable();
            $table->unsignedInteger('price')->default(0);
            $table->string('image_path')->nullable();
            $table->unsignedSmallInteger('position')->default(0);
            $table->timestamps();
        });

        Schema::create('gift_lists', function (Blueprint $table) {
            $table->id();
            $table->foreignId('owner_id')->constrained('users')->cascadeOnDelete();
            $table->string('title');
            $table->text('description')->nullable();
            $table->string('occasion');
            $table->string('image_path')->nullable();
            $table->string('code')->unique(); // lien public : /l/{code}
            $table->string('access_code', 20)->nullable();
            $table->date('event_date')->nullable();
            $table->timestamps();
        });

        // Un élément de liste : cadeau du catalogue OU lien externe
        Schema::create('list_items', function (Blueprint $table) {
            $table->id();
            $table->foreignId('gift_list_id')->constrained()->cascadeOnDelete();
            $table->foreignId('gift_id')->nullable()->constrained()->nullOnDelete();
            $table->string('external_url', 2048)->nullable();
            $table->string('external_name')->nullable();
            $table->string('external_image', 2048)->nullable();
            $table->unsignedInteger('external_price')->nullable();
            $table->string('status', 20)->default('Disponible'); // Disponible | Réservé | Indisponible
            $table->string('reserved_by_name')->nullable();
            $table->foreignId('reserved_by_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->timestamp('reserved_at')->nullable();
            $table->timestamps();
        });

        Schema::create('orders', function (Blueprint $table) {
            $table->id();
            $table->string('reference')->unique();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('gift_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('list_item_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('wrapping_id')->nullable()->constrained()->nullOnDelete();
            $table->string('gift_name');
            $table->unsignedSmallInteger('quantity')->default(1);
            $table->unsignedInteger('unit_price');
            $table->unsignedInteger('total');
            $table->string('currency', 8)->default('FCFA');
            $table->string('customer_name');
            $table->string('customer_phone', 30);
            $table->string('customer_email')->nullable();
            $table->string('delivery_city')->nullable();
            $table->string('delivery_address')->nullable();
            $table->text('message')->nullable();
            $table->string('payment_method', 30)->default('orange_money'); // orange_money | mtn_momo
            $table->string('status', 20)->default('en_attente'); // en_attente | payee | livree | annulee
            $table->timestamps();
        });

        Schema::create('custom_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('name');
            $table->string('phone', 30);
            $table->unsignedInteger('budget');
            $table->text('description');
            $table->foreignId('wrapping_id')->nullable()->constrained()->nullOnDelete();
            $table->string('status', 20)->default('nouvelle'); // nouvelle | en_cours | traitee
            $table->timestamps();
        });

        Schema::create('favorites', function (Blueprint $table) {
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('gift_id')->constrained()->cascadeOnDelete();
            $table->timestamps();
            $table->primary(['user_id', 'gift_id']);
        });
    }

    public function down(): void
    {
        foreach (['favorites', 'custom_requests', 'orders', 'list_items', 'gift_lists', 'wrappings', 'gifts'] as $t) {
            Schema::dropIfExists($t);
        }
    }
};
