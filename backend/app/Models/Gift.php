<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Gift extends Model
{
    protected $fillable = [
        'name', 'slug', 'description', 'price', 'currency', 'country', 'city', 'area', 'shop',
        'category', 'for_who', 'occasions', 'image_path', 'stock', 'is_active', 'is_featured',
    ];

    protected $appends = ['image_url', 'available'];

    protected function casts(): array
    {
        return [
            'for_who' => 'array',
            'occasions' => 'array',
            'is_active' => 'boolean',
            'is_featured' => 'boolean',
            'price' => 'integer',
            'stock' => 'integer',
        ];
    }

    protected static function booted(): void
    {
        static::saving(function (Gift $gift) {
            if (! $gift->slug || $gift->isDirty('name')) {
                $base = Str::slug($gift->name) ?: 'cadeau';
                $slug = $base;
                $i = 2;
                while (static::where('slug', $slug)->whereKeyNot($gift->id)->exists()) {
                    $slug = $base.'-'.$i++;
                }
                $gift->slug = $slug;
            }
        });
    }

    public function getImageUrlAttribute(): ?string
    {
        return $this->image_path ? Storage::disk('public')->url($this->image_path) : null;
    }

    public function getAvailableAttribute(): bool
    {
        return $this->is_active && ($this->stock === null || $this->stock > 0);
    }
}
