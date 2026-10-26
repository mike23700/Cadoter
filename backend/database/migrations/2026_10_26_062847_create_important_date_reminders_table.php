<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('important_date_reminders', function (Blueprint $table) {
            $table->id();
            $table->foreignId('important_date_id')->constrained()->cascadeOnDelete();
            $table->unsignedSmallInteger('event_year');
            $table->unsignedTinyInteger('days_before');
            $table->timestamp('sent_at')->nullable();
            $table->unique(['important_date_id', 'event_year', 'days_before']);
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('important_date_reminders');
    }
};
