<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Gift extends Model
{
    protected $fillable = [
        'name', 'slug', 'description', 'price', 'currency', 'country', 'city', 'area', 'shop',
        'category', 'for_who', 'occasions', 'image_path', 'stock', 'is_active', 'is_featured',
    ];

    protected $appends = ['image_url', 'image_urls', 'available', 'seller_name'];

    protected function casts(): array
    {
        return [
            'for_who' => 'array',
            'occasions' => 'array',
            'image_paths' => 'array',
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

    public function getImageUrlsAttribute(): array
    {
        $paths = $this->image_paths ?: ($this->image_path ? [$this->image_path] : []);

        return collect($paths)
            ->filter()
            ->unique()
            ->map(fn (string $path) => Storage::disk('public')->url($path))
            ->values()
            ->all();
    }

    public function getAvailableAttribute(): bool
    {
        return $this->is_active && ($this->stock === null || $this->stock > 0);
    }

    public function partner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'partner_id');
    }

    public function getSellerNameAttribute(): string
    {
        return $this->partner?->shop_name ?: 'cadoter.com';
    }
}
