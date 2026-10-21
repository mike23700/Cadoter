import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AssistantScreen extends StatelessWidget {
  const AssistantScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Assistante IA', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 32, height: 32, decoration: BoxDecoration(
              color: AppColors.magenta.withOpacity(0.1),
              border: Border.all(color: AppColors.magenta, width: 1.7),
              shape: BoxShape.circle,
            )),
            const SizedBox(height: 18),
            Text('Votre recherche', style: const TextStyle(fontSize: 33, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 18),
            Text('Décrivez la personne, l\'événement et le budget. L\'assistante vous propose des cadeaux avec un « Pourquoi ce cadeau ? ».',
                style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 22),
            _field('Type d\'événement', 'Anniversaire'),
            const SizedBox(height: 22),
            _field('Sexe', 'Femme / Homme / Autre'),
            const SizedBox(height: 22),
            _field('Âge', '25 ans'),
            const SizedBox(height: 22),
            _field('Lien avec la personne', 'Parent / Ami(e) / Conjoint(e)'),
            const SizedBox(height: 22),
            _field('Budget max', '50 000 FCFA'),
            const SizedBox(height: 22),
            _field('Infos libres', 'Aime la lecture, la décoration et le thé', maxLines: 4),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magenta, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.auto_stories, size: 18, color: Colors.white),
                  SizedBox(width: 6), Text('Obtenir des suggestions', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
        const SizedBox(height: 7),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF786C74)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9E1E5))),
            filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(13),
          ),
        ),
      ],
    );
  }
}
