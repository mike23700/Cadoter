<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\ImportantDate;
use Illuminate\Database\Query\Builder;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Http\Response;
use Illuminate\Support\Facades\DB;

class ImportantDateController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $dates = $request->user()->importantDates()->get()->sortBy('next_occurrence')->values();

        return response()->json($dates);
    }

    public function store(Request $request): JsonResponse
    {
        $data = $this->validated($request);
        $importantDate = $request->user()->importantDates()->create($data);

        return response()->json($importantDate, 201);
    }

    public function update(Request $request, ImportantDate $importantDate): JsonResponse
    {
        abort_unless($importantDate->user_id === $request->user()->id, 404);
        $data = $this->validated($request);
        $importantDate->fill($data);

        if ($importantDate->isDirty('event_date')) {
            DB::table('important_date_reminders')->where('important_date_id', $importantDate->id)->delete();
        }

        $importantDate->save();

        return response()->json($importantDate);
    }

    public function destroy(Request $request, ImportantDate $importantDate): Response
    {
        abort_unless($importantDate->user_id === $request->user()->id, 404);
        $importantDate->delete();

        return response()->noContent();
    }

    /** @return array{person_name: string, title: string, event_date: string} */
    private function validated(Request $request): array
    {
        return $request->validate([
            'person_name' => ['required', 'string', 'max:120'],
            'title' => ['required', 'string', 'max:160'],
            'event_date' => ['required', 'date_format:Y-m-d'],
        ]);
    }
}
