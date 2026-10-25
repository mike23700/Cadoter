<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

/** Réglage clé / valeur du site. */
class Setting extends Model
{
    public const KEYS = ['whatsapp_number'];

    protected $primaryKey = 'key';

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = ['key', 'value'];

    public static function getValue(string $key): ?string
    {
        return static::find($key)?->value;
    }

    /** Tous les réglages connus, null quand ils ne sont pas renseignés. */
    public static function allValues(): array
    {
        $stored = static::whereIn('key', self::KEYS)->pluck('value', 'key');

        return collect(self::KEYS)->mapWithKeys(fn ($k) => [$k => $stored[$k] ?? null])->all();
    }
}
