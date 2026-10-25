<?php

namespace App\Http\Controllers\Api\Admin;

use App\Http\Controllers\Controller;
use App\Models\Faq;
use App\Models\Setting;
use Illuminate\Http\Request;

/** FAQ publique et réglages de contact (WhatsApp). */
class FaqController extends Controller
{
    public function index()
    {
        return response()->json(Faq::orderBy('position')->orderBy('id')->get());
    }

    public function store(Request $request)
    {
        $faq = new Faq($this->validated($request, true));
        $faq->position ??= (int) Faq::max('position') + 1;
        $faq->save();

        return response()->json($faq, 201);
    }

    public function update(Request $request, Faq $faq)
    {
        $faq->update($this->validated($request, false));

        return response()->json($faq);
    }

    public function destroy(Faq $faq)
    {
        $faq->delete();

        return response()->noContent();
    }

    public function settings()
    {
        return response()->json(Setting::allValues());
    }

    public function updateSettings(Request $request)
    {
        $data = $request->validate([
            'whatsapp_number' => ['nullable', 'string', 'max:30', 'regex:/^\+?[\d\s.\-()]{8,}$/'],
        ], ['whatsapp_number.regex' => __('Numéro WhatsApp invalide (ex. +225 07 00 00 00 00).')]);

        foreach ($data as $key => $value) {
            Setting::updateOrCreate(['key' => $key], ['value' => $value]);
        }

        return response()->json(Setting::allValues());
    }

    private function validated(Request $request, bool $creating): array
    {
        $req = $creating ? 'required' : 'sometimes';
        $data = $request->validate([
            'question' => [$req, 'string', 'max:255'],
            'answer' => [$req, 'string', 'max:5000'],
            'question_en' => ['nullable', 'string', 'max:255'],
            'answer_en' => ['nullable', 'string', 'max:5000'],
            'position' => ['nullable', 'integer', 'min:0'],
            'is_active' => ['nullable', 'boolean'],
        ]);
        // Position / statut laissés vides : valeur par défaut à la création, inchangés à la modification
        foreach (['position' => null, 'is_active' => true] as $key => $default) {
            if (array_key_exists($key, $data) && $data[$key] === null) {
                if ($creating && $default !== null) {
                    $data[$key] = $default;
                } else {
                    unset($data[$key]);
                }
            }
        }

        return $data;
    }
}
