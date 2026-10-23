import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:google_fonts/google_fonts.dart';

import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import 'auth_screens.dart';
import 'language_screen.dart';
import 'shell.dart';

/// « Mobile · Lancement ».
///
/// Prend le relais du splash natif sans coupure : le logo démarre exactement là où le système
/// l'affiche (centré, 172dp de large), puis glisse vers la mise en page de la maquette pendant
/// que le slogan apparaît. Le splash natif reste affiché tant que le logo n'est pas décodé.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  /// Largeur du logo dans le splash natif (voir flutter_native_splash dans pubspec.yaml).
  static const nativeLogoWidth = 172.0;
  static const logo = AssetImage('assets/images/splash_logo.png');
  static const logoRatio = 2048 / 807;

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final _anim = AnimationController(vsync: this, duration: const Duration(milliseconds: 1100));
  bool _started = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    _boot();
  }

  Future<void> _boot() async {
    final session = SessionScope.read(context);
    final init = session.init();
    await Future.wait([
      precacheImage(SplashScreen.logo, context),
      GoogleFonts.pendingFonts([T.serif(30), T.eyebrow()]),
    ]);
    FlutterNativeSplash.remove(); // le logo Flutter est prêt, à la même place que le natif
    await Future.delayed(const Duration(milliseconds: 150));
    await Future.wait([init, _anim.forward(), Future.delayed(const Duration(milliseconds: 1700))]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 450),
      // Connecté → accueil ; onboarding déjà vu → connexion obligatoire ; sinon → choix de langue
      pageBuilder: (_, _, _) => session.isLoggedIn
          ? const Shell()
          : session.onboarded
              ? const LoginScreen(gate: true)
              : const LanguageScreen(),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  void dispose() {
    _anim.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final size = mq.size;
    // Position finale calquée sur la maquette (402 × 874) : logo centré à 39 % de la hauteur
    final endW = (size.width - 112).clamp(0.0, 340.0);
    final endCenterY = size.height * 0.39;
    final endH = endW / SplashScreen.logoRatio;

    return Scaffold(
      backgroundColor: AppColors.white,
      body: AnimatedBuilder(
        animation: _anim,
        builder: (context, _) {
          final move = Curves.easeInOutCubic.transform((_anim.value / .7).clamp(0.0, 1.0));
          final fade = Curves.easeOut.transform(((_anim.value - .45) / .55).clamp(0.0, 1.0));
          final w = lerpDouble(SplashScreen.nativeLogoWidth, endW, move)!;
          final h = w / SplashScreen.logoRatio;
          final cy = lerpDouble(size.height / 2, endCenterY, move)!;

          return Stack(children: [
            Positioned(
              left: (size.width - w) / 2,
              top: cy - h / 2,
              width: w,
              height: h,
              child: const Image(image: SplashScreen.logo, fit: BoxFit.contain),
            ),
            Positioned(
              left: 24,
              right: 24,
              top: endCenterY + endH / 2 + 28,
              child: Opacity(
                opacity: fade,
                child: Transform.translate(
                  offset: Offset(0, 12 * (1 - fade)),
                  child: Column(children: [
                    Text(tr('Le bonheur d’offrir.\nTout simplement.'), textAlign: TextAlign.center, style: T.serif(30, height: 1.3)),
                    const SizedBox(height: 26),
                    Container(
                      width: 36,
                      height: 3,
                      decoration: BoxDecoration(color: AppColors.magenta, borderRadius: BorderRadius.circular(2)),
                    ),
                  ]),
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: mq.padding.bottom + 40,
              child: Opacity(
                opacity: fade,
                child: Text(tr('DES ATTENTIONS QUI NOUS RAPPROCHENT'), textAlign: TextAlign.center, style: T.eyebrow()),
              ),
            ),
          ]);
        },
      ),
    );
  }
}
