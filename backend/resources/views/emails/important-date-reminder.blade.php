<!doctype html>
<html lang="{{ $language }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $language === 'en' ? 'An important date is approaching' : 'Une date importante approche' }}</title>
</head>
<body style="margin:0;background:#fff8fc;color:#30232c;font-family:Arial,sans-serif;">
    <div style="max-width:620px;margin:0 auto;padding:36px 20px;">
        <p style="margin:0 0 14px;color:#c90091;font-size:12px;font-weight:bold;letter-spacing:2px;">CADOTER</p>
        <h1 style="margin:0 0 16px;font-family:Georgia,serif;font-size:30px;font-weight:normal;">
            {{ $language === 'en' ? 'A special day is coming up' : 'Une belle occasion approche' }}
        </h1>
        <p style="font-size:15px;line-height:1.6;">
            {{ $language === 'en' ? 'Hello' : 'Bonjour' }} {{ $userName }},
            {{ $language === 'en' ? 'the event' : 'l’événement' }}
            <strong>{{ $importantDate->title }}</strong>
            {{ $language === 'en' ? 'for' : 'de' }}
            <strong>{{ $importantDate->person_name }}</strong>
            {{ $timingLabel }} ({{ $eventDateLabel }}).
        </p>

        @if (count($suggestions))
            <h2 style="margin:30px 0 14px;font-family:Georgia,serif;font-size:22px;font-weight:normal;">
                {{ $language === 'en' ? 'Gift ideas picked for you' : 'Des idées cadeaux choisies pour vous' }}
            </h2>
            @foreach ($suggestions as $suggestion)
                <div style="margin:0 0 14px;padding:18px;border:1px solid #f0dce9;border-radius:12px;background:#fff;">
                    <h3 style="margin:0 0 7px;font-size:17px;">
                        <a href="{{ $frontendUrl.'/cadeaux/'.rawurlencode($suggestion['gift']->slug) }}" style="color:#c90091;text-decoration:none;">
                            {{ $suggestion['gift']->name }}
                        </a>
                    </h3>
                    <p style="margin:0 0 8px;font-size:14px;font-weight:bold;">
                        {{ number_format((float) $suggestion['gift']->price, 0, ',', ' ') }} {{ $suggestion['gift']->currency }}
                    </p>
                    <p style="margin:0;color:#706f6c;font-size:13px;line-height:1.5;">{{ $suggestion['reason'] }}</p>
                </div>
            @endforeach
        @else
            <p style="color:#706f6c;font-size:14px;line-height:1.5;">
                {{ $language === 'en' ? 'Browse CADOTER for an idea that will make the day special.' : 'Parcourez CADOTER pour trouver une attention qui rendra cette journée spéciale.' }}
            </p>
        @endif

        <p style="margin:28px 0;">
            <a href="{{ $catalogUrl }}" style="display:inline-block;padding:14px 22px;border-radius:8px;background:#c90091;color:#fff;font-size:14px;font-weight:bold;text-decoration:none;">
                {{ $language === 'en' ? 'See other gifts' : 'Voir d’autres cadeaux' }}
            </a>
        </p>
        <p style="margin:30px 0 0;color:#706f6c;font-size:12px;line-height:1.5;">
            {{ $language === 'en' ? 'You receive this reminder because you saved this date in your CADOTER profile.' : 'Vous recevez ce rappel parce que vous avez enregistré cette date dans votre profil CADOTER.' }}
        </p>
    </div>
</body>
</html>
