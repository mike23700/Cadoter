import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  int _page = 0;
  final List<Map<String, String>> _pages = const [
    {
      'title': 'Offrir',
      'body': "Créez une liste de cadeaux pour un événement : anniversaire, mariage, naissance, dot ou soutien. Partagez le lien avec vos proches.",
      'image': 'gift',
    },
    {
      'title': 'Listes',
      'body': 'Ajoutez des cadeaux depuis le catalogue ou n\'importe quel site marchand. Chaque cadeau est réservé par une seule personne.',
      'image': 'list',
    },
    {
      'title': 'Assistante',
      'body': 'Besoin d\'idées ? Décrivez la personne et le budget, l\'assistante IA vous suggère des cadeaux adaptés.',
      'image': 'sparkles',
    },
  ];

  @override
  Widget build(BuildContext context) {
    final p = _pages[_page];
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const BackButton(),
                  Container(width: 22, height: 22, decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF30232C), width: 1.7),
                    shape: BoxShape.circle,
                  )),
                ],
              ),
              const SizedBox(height: 22),
              Expanded(
                child: Column(
                  children: [
                    Container(width: 354, height: 330, color: AppColors.cream),
                    const SizedBox(height: 28),
                    Row(
                      children: List.generate(3, (i) => Container(
                        width: i == _page ? 28 : 7, height: 7,
                        margin: const EdgeInsets.only(right: 7),
                        decoration: BoxDecoration(
                          color: i == _page ? AppColors.magenta : const Color(0xFFE9E1E5),
                          borderRadius: BorderRadius.circular(7),
                        ),
                      )),
                    ),
                    const SizedBox(height: 34),
                    Text(p['title'] ?? '', style: const TextStyle(fontSize: 34, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
                    const SizedBox(height: 20),
                    Text(p['body'] ?? '', style: const TextStyle(fontSize: 15, color: Color(0xFF786C74), height: 1.35), textAlign: TextAlign.center),
                  ],
                ),
              ),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _page == 2
                      ? () => Navigator.pushReplacementNamed(context, '/language')
                      : () => setState(() => _page++),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Continuer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 6),
                      const Icon(Icons.arrow_right, size: 18, color: Colors.white),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/language'),
                child: const Text('Passer', style: TextStyle(fontSize: 12, color: Color(0xFF786C74))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
