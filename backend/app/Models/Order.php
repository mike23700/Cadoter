<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Support\Str;

class Order extends Model
{
    public const STATUSES = ['en_attente', 'payee', 'livree', 'annulee'];

    protected $fillable = [
        'reference', 'user_id', 'gift_id', 'list_item_id', 'wrapping_id', 'gift_name', 'quantity',
        'unit_price', 'total', 'currency', 'customer_name', 'customer_phone', 'customer_email',
        'delivery_city', 'delivery_address', 'message', 'payment_method', 'status',
    ];

    protected static function booted(): void
    {
        static::creating(fn (Order $o) => $o->reference ??= 'CMD-'.now()->format('ymd').'-'.Str::upper(Str::random(5)));
    }

    public function gift(): BelongsTo
    {
        return $this->belongsTo(Gift::class);
    }

    public function wrapping(): BelongsTo
    {
        return $this->belongsTo(Wrapping::class);
    }

    public function listItem(): BelongsTo
    {
        return $this->belongsTo(ListItem::class);
    }
}
