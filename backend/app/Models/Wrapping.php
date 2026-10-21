<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Wrapping extends Model
{
    protected $fillable = ['code', 'name', 'detail', 'price', 'image_path', 'position', 'is_active'];

    protected $appends = ['image_url'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean', 'price' => 'integer', 'position' => 'integer'];
    }

    protected static function booted(): void
    {
        // Code technique unique dérivé du nom (ex. « Rosé signature » → rose-signature)
        static::creating(function (Wrapping $w) {
            if (! $w->code) {
                $base = Str::slug($w->name) ?: 'emballage';
                $code = $base;
                $i = 2;
                while (static::where('code', $code)->exists()) {
                    $code = $base.'-'.$i++;
                }
                $w->code = $code;
            }
        });
    }

    public function getImageUrlAttribute(): ?string
    {
        return $this->image_path ? Storage::disk('public')->url($this->image_path) : null;
    }
}
