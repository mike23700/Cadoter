<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class ListItem extends Model
{
    public const STATUSES = ['Disponible', 'Réservé', 'Indisponible'];

    protected $fillable = [
        'gift_id', 'external_url', 'external_name', 'external_image', 'external_price',
        'status', 'reserved_by_name', 'reserved_by_user_id', 'reserved_at',
    ];

    protected $hidden = ['reserved_by_user_id'];

    protected function casts(): array
    {
        return ['reserved_at' => 'datetime'];
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
            'name' => $g?->name ?? $this->external_name ?? 'Produit externe',
            'price' => $g?->price ?? $this->external_price,
            'currency' => $g?->currency ?? 'FCFA',
            'city' => $g?->city,
            'area' => $g?->area,
            'image_url' => $g?->image_url ?? $this->external_image,
            'external_url' => $this->external_url,
            'reserved_by_name' => $owner ? $this->reserved_by_name : null,
            'reserved_at' => $this->reserved_at,
        ];
    }
}
