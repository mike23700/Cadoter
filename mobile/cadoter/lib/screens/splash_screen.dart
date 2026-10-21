import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import 'language_screen.dart';
import 'shell.dart';

/// « Mobile · Lancement »
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    final session = SessionScope.read(context);
    await Future.wait([session.init(), Future.delayed(const Duration(milliseconds: 1400))]);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(PageRouteBuilder(
      transitionDuration: const Duration(milliseconds: 400),
      pageBuilder: (_, _, _) => session.onboarded || session.isLoggedIn ? const Shell() : const LanguageScreen(),
      transitionsBuilder: (_, a, _, child) => FadeTransition(opacity: a, child: child),
    ));
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            const Spacer(flex: 3),
            Padding(padding: const EdgeInsets.symmetric(horizontal: 50), child: Image.asset('assets/images/logo.png')),
            const SizedBox(height: 32),
            Text('Le bonheur d’offrir.\nTout simplement.', textAlign: TextAlign.center, style: T.serif(28, height: 1.4)),
            const SizedBox(height: 24),
            Container(width: 36, height: 3, decoration: BoxDecoration(color: AppColors.magenta, borderRadius: BorderRadius.circular(2))),
            const Spacer(flex: 4),
            Text('DES ATTENTIONS QUI NOUS RAPPROCHENT', style: T.eyebrow()),
            const SizedBox(height: 30),
          ]),
        ),
      );
}
