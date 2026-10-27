<!doctype html>
<html lang="{{ $language }}">
<head>
    <meta charset="utf-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>{{ $language === 'en' ? 'Reset your password' : 'Réinitialisez votre mot de passe' }}</title>
</head>
<body style="margin:0;background:#fff8fc;color:#30232c;font-family:Arial,sans-serif;">
    <div style="max-width:620px;margin:0 auto;padding:36px 20px;">
        <p style="margin:0 0 14px;color:#c90091;font-size:12px;font-weight:bold;letter-spacing:2px;">CADOTER</p>
        <h1 style="margin:0 0 16px;font-family:Georgia,serif;font-size:30px;font-weight:normal;">
            {{ $language === 'en' ? 'Choose a new password' : 'Choisissez un nouveau mot de passe' }}
        </h1>
        <p style="font-size:15px;line-height:1.6;">
            {{ $language === 'en' ? 'Hello' : 'Bonjour' }} {{ $userName }},
            {{ $language === 'en'
                ? 'we received a request to reset the password of your CADOTER account.'
                : 'nous avons reçu une demande de réinitialisation du mot de passe de votre compte CADOTER.' }}
        </p>
        <p style="margin:28px 0;">
            <a href="{{ $resetUrl }}" style="display:inline-block;padding:14px 22px;border-radius:8px;background:#c90091;color:#fff;font-size:14px;font-weight:bold;text-decoration:none;">
                {{ $language === 'en' ? 'Reset my password' : 'Réinitialiser mon mot de passe' }}
            </a>
        </p>
        <p style="color:#706f6c;font-size:13px;line-height:1.5;">
            {{ $language === 'en'
                ? "This link expires in {$expiresInMinutes} minutes."
                : "Ce lien expire dans {$expiresInMinutes} minutes." }}
        </p>
        <p style="color:#706f6c;font-size:13px;line-height:1.5;word-break:break-all;">
            {{ $language === 'en' ? 'If the button does not work, copy this link:' : 'Si le bouton ne fonctionne pas, copiez ce lien :' }}<br>
            <a href="{{ $resetUrl }}" style="color:#c90091;">{{ $resetUrl }}</a>
        </p>
        <p style="margin:30px 0 0;color:#706f6c;font-size:12px;line-height:1.5;">
            {{ $language === 'en'
                ? 'If you did not request this, you can ignore this email: your password will not change.'
                : 'Si vous n’êtes pas à l’origine de cette demande, ignorez cet e-mail : votre mot de passe ne changera pas.' }}
        </p>
    </div>
</body>
</html>
