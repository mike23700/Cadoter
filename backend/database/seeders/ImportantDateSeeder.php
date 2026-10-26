<?php

namespace Database\Seeders;

use App\Models\ImportantDate;
use Illuminate\Database\Seeder;

class ImportantDateSeeder extends Seeder
{
    /**
     * Run the database seeds.
     */
    public function run(): void
    {
        ImportantDate::factory()->count(3)->create();
    }
}
