import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/session.dart';
import 'core/theme.dart';
import 'screens/splash_screen.dart';

void main() {
  // Le splash natif reste affiché jusqu'à ce que SplashScreen soit prêt à prendre le relais
  FlutterNativeSplash.preserve(widgetsBinding: WidgetsFlutterBinding.ensureInitialized());
  // Polices embarquées dans assets/google_fonts : aucun téléchargement, rendu immédiat même hors ligne
  GoogleFonts.config.allowRuntimeFetching = false;
  runApp(CadoterApp(session: Session()));
}

class CadoterApp extends StatelessWidget {
  const CadoterApp({super.key, required this.session});
  final Session session;

  @override
  Widget build(BuildContext context) => SessionScope(
        session: session,
        child: MaterialApp(
          title: 'CADOTER',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.light(),
          locale: const Locale('fr'),
          supportedLocales: const [Locale('fr'), Locale('en')],
          localizationsDelegates: GlobalMaterialLocalizations.delegates,
          home: const SplashScreen(),
        ),
      );
}
