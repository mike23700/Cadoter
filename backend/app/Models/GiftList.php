<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class GiftList extends Model
{
    protected $fillable = ['title', 'description', 'occasion', 'image_path', 'code', 'access_code', 'event_date'];

    protected $hidden = ['access_code'];

    protected $appends = ['image_url', 'is_locked'];

    protected function casts(): array
    {
        return ['event_date' => 'date:Y-m-d'];
    }

    public static function uniqueCode(string $owner, string $title): string
    {
        $base = Str::slug(Str::before($owner, ' ').'-'.$title) ?: 'liste';
        $code = $base;
        while (static::where('code', $code)->exists()) {
            $code = $base.'-'.Str::lower(Str::random(4));
        }

        return $code;
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_id');
    }

    public function items(): HasMany
    {
        return $this->hasMany(ListItem::class)->orderBy('id');
    }

    public function getImageUrlAttribute(): ?string
    {
        return $this->image_path ? Storage::disk('public')->url($this->image_path) : null;
    }

    public function getIsLockedAttribute(): bool
    {
        return filled($this->access_code);
    }
}
