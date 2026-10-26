<?php

namespace Database\Factories;

use App\Models\ImportantDate;
use App\Models\User;
use Illuminate\Database\Eloquent\Factories\Factory;

/**
 * @extends Factory<ImportantDate>
 */
class ImportantDateFactory extends Factory
{
    /**
     * Define the model's default state.
     *
     * @return array<string, mixed>
     */
    public function definition(): array
    {
        return [
            'user_id' => User::factory(),
            'person_name' => fake()->name(),
            'title' => fake()->randomElement(['Anniversaire', 'Anniversaire de mariage']),
            'event_date' => fake()->date(),
        ];
    }
}
