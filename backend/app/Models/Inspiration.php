<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class Inspiration extends Model
{
    protected $fillable = ['slug', 'tag', 'title', 'excerpt', 'body', 'tag_en', 'title_en', 'excerpt_en', 'body_en', 'minutes', 'is_active'];

    protected $appends = ['image_url'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean', 'minutes' => 'integer'];
    }

    protected static function booted(): void
    {
        // Slug unique dérivé du titre (ex. « Pour papa… » → pour-papa)
        static::creating(function (Inspiration $a) {
            if (! $a->slug) {
                $base = Str::limit(Str::slug($a->title), 80, '') ?: 'article';
                $slug = $base;
                $i = 2;
                while (static::where('slug', $slug)->exists()) {
                    $slug = $base.'-'.$i++;
                }
                $a->slug = $slug;
            }
        });
    }

    public function getImageUrlAttribute(): ?string
    {
        return $this->image_path ? Storage::disk('public')->url($this->image_path) : null;
    }

    /** Article dans la langue de la requête (français si la traduction manque), corps découpé en paragraphes. */
    public function localized(bool $withBody = true): array
    {
        $en = app()->getLocale() === 'en';
        $pick = fn (string $field) => ($en ? $this->{$field.'_en'} : null) ?: $this->{$field};
        $body = $pick('body');

        return [
            'id' => $this->id,
            'slug' => $this->slug,
            'tag' => $pick('tag'),
            'title' => $pick('title'),
            'excerpt' => $pick('excerpt'),
            'image_url' => $this->image_url,
            // Temps de lecture saisi, sinon estimé (~200 mots / minute)
            'minutes' => $this->minutes ?: max(1, (int) ceil(str_word_count($this->body) / 200)),
            'created_at' => $this->created_at,
        ] + ($withBody ? ['body' => array_values(array_filter(array_map('trim', preg_split('/\R\s*\R/', $body))))] : []);
    }
}
