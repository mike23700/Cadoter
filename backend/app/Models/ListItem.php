<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Facades\Storage;

class ListItem extends Model
{
    public const STATUSES = ['Disponible', 'Réservé', 'Indisponible'];

    protected $fillable = [
        'gift_id', 'external_url', 'external_name', 'external_description', 'external_image', 'external_image_path', 'external_price', 'external_seller_name',
        'status', 'reserved_by_name', 'reserved_by_user_id', 'reserved_at',
    ];

    protected $hidden = ['reserved_by_user_id'];

    protected function casts(): array
    {
        return ['reserved_at' => 'datetime'];
    }

    protected static function booted(): void
    {
        static::deleted(function (self $item): void {
            if ($item->external_image_path) {
                Storage::disk('public')->delete($item->external_image_path);
            }
        });
    }

    public function list(): BelongsTo
    {
        return $this->belongsTo(GiftList::class, 'gift_list_id');
    }

    public function gift(): BelongsTo
    {
        return $this->belongsTo(Gift::class);
    }

    /** Vue unifiée (catalogue ou lien externe) consommée par le web et le mobile. */
    public function toPublicArray(bool $owner = false): array
    {
        $g = $this->gift;

        return [
            'id' => $this->id,
            'status' => $this->status,
            'gift_id' => $this->gift_id,
            'gift_slug' => $g?->slug,
            'name' => $g?->name ?? $this->external_name ?? __('Produit externe'),
            'description' => $g?->description ?? $this->external_description,
            'seller_name' => $g?->seller_name ?? $this->external_seller_name,
            'price' => $g?->price ?? $this->external_price,
            'currency' => $g?->currency ?? 'FCFA',
            'city' => $g?->city,
            'area' => $g?->area,
            'image_url' => $g?->image_url
                ?? ($this->external_image_path ? Storage::disk('public')->url($this->external_image_path) : $this->external_image),
            'external_url' => $this->external_url,
            'reserved_by_name' => $owner ? $this->reserved_by_name : null,
            'reserved_at' => $this->reserved_at,
        ];
    }
}
