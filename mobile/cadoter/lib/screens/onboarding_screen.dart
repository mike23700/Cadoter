import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';

/// « Mobile · Présentation — Offrir / Listes / Assistante »
class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final _pages = PageController();
  int _i = 0;

  static const _slides = [
    ('assets/images/onboarding-offrir.jpg', 'À chacun sa belle attention.',
        'Trouvez un cadeau qui raconte votre lien, pour les petits bonheurs et les grands moments.', 'Continuer'),
    ('assets/images/the.jpg', 'Vos envies, à partager.',
        'Créez votre liste, ajoutez des produits de tous vos sites favoris, sans limite, puis partagez le lien à vos proches.', 'Continuer'),
    ('assets/images/emballage-rose.jpg', 'Un peu d’aide.\nBeaucoup d’idées.',
        'Parlez-nous de la personne. Notre assistante IA vous inspire, jusqu’au choix de l’emballage.', 'C’est parti !'),
  ];

  /// Fin de la présentation : connexion ou inscription obligatoire avant l'accueil.
  Future<void> _finish() async {
    await SessionScope.read(context).setOnboarded();
    if (mounted) LoginScreen.openGate(context);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        body: SafeArea(
          child: Column(children: [
            const BrandHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(kGutter, 18, kGutter, 18),
              child: Row(children: [
                const Eyebrow('Découvrir CADOTER'),
                const Spacer(),
                GestureDetector(onTap: _finish, child: Text('Passer', style: T.sans(14, color: AppColors.magenta))),
              ]),
            ),
            Expanded(
              child: PageView.builder(
                controller: _pages,
                itemCount: _slides.length,
                onPageChanged: (i) => setState(() => _i = i),
                itemBuilder: (_, i) {
                  final s = _slides[i];
                  return ListView(padding: const EdgeInsets.symmetric(horizontal: kGutter), children: [
                    NetImage(s.$1, aspect: 354 / 330),
                    const SizedBox(height: 20),
                    Row(children: [
                      for (var d = 0; d < _slides.length; d++)
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          margin: const EdgeInsets.only(right: 6),
                          width: d == _i ? 28 : 6,
                          height: 6,
                          decoration: BoxDecoration(
                              color: d == _i ? AppColors.magenta : AppColors.border, borderRadius: BorderRadius.circular(3)),
                        ),
                    ]),
                    const SizedBox(height: 22),
                    Text(s.$2, style: T.serif(34, height: 1.35)),
                    const SizedBox(height: 18),
                    Text(s.$3, style: T.sans(15, color: AppColors.gray)),
                  ]);
                },
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 18),
              child: Column(children: [
                PrimaryButton(_slides[_i].$4, icon: Icons.arrow_forward, onPressed: () {
                  if (_i < _slides.length - 1) {
                    _pages.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOut);
                  } else {
                    _finish();
                  }
                }),
                const SizedBox(height: 20),
                GestureDetector(
                  onTap: _finish,
                  child: Text('Déjà un compte ? Se connecter', style: T.sans(12, color: AppColors.gray)),
                ),
              ]),
            ),
          ]),
        ),
      );
}
