<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        // Articles « Inspirations » gérés depuis l'administration (traduction anglaise facultative)
        Schema::create('inspirations', function (Blueprint $table) {
            $table->id();
            $table->string('slug')->unique();
            $table->string('tag', 80);
            $table->string('title');
            $table->string('excerpt', 500)->nullable();
            $table->text('body');
            $table->string('tag_en', 80)->nullable();
            $table->string('title_en')->nullable();
            $table->string('excerpt_en', 500)->nullable();
            $table->text('body_en')->nullable();
            $table->string('image_path')->nullable();
            $table->unsignedSmallInteger('minutes')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('inspirations');
    }
};
