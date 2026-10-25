<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;

class Faq extends Model
{
    protected $fillable = ['question', 'answer', 'question_en', 'answer_en', 'position', 'is_active'];

    protected function casts(): array
    {
        return ['is_active' => 'boolean', 'position' => 'integer'];
    }

    /** Question / réponse dans la langue de la requête (français si la traduction manque). */
    public function localized(): array
    {
        $en = app()->getLocale() === 'en';

        return [
            'id' => $this->id,
            'question' => ($en ? $this->question_en : null) ?: $this->question,
            'answer' => ($en ? $this->answer_en : null) ?: $this->answer,
        ];
    }
}
