<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class CustomRequest extends Model
{
    public const STATUSES = ['nouvelle', 'en_cours', 'traitee'];

    protected $fillable = ['user_id', 'name', 'phone', 'budget', 'description', 'wrapping_id', 'status'];

    public function wrapping(): BelongsTo
    {
        return $this->belongsTo(Wrapping::class);
    }
}
