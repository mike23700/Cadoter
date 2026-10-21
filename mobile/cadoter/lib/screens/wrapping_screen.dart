import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class WrappingScreen extends StatelessWidget {
  const WrappingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choix d\'emballage', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Choix d\'emballage', style: const TextStyle(fontSize: 33, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 22),
            Text('Sélectionnez l\'emballage de votre cadeau, ou choisissez « sans emballage ».',
                style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 30),
            _model('Rosé signature', true),
            const SizedBox(height: 20),
            _model('Naturel délicat', false),
            const SizedBox(height: 20),
            _model('Ciel de douceur', false),
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
                child: const Text('Confirmer l\'emballage', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            Text('Sans emballage également possible.', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74)), textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _model(String name, bool selected) {
    return Container(
      height: 149,
      decoration: BoxDecoration(
        border: Border.all(color: selected ? AppColors.magenta : const Color(0xFFE9E1E5), width: 2),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(width: 108, height: 125, color: AppColors.cream),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                  const SizedBox(height: 8),
                  Text(selected ? 'Papier mat rose poudré, ruban satin magenta.'
                      : 'Papier kraft naturel, ruban coton crème.',
                      style: const TextStyle(fontSize: 12, color: Color(0xFF786C74), height: 1.35)),
                  const Spacer(),
                  Row(
                    children: [
                      Container(width: 22, height: 22, decoration: BoxDecoration(
                        color: selected ? AppColors.magenta : Colors.white,
                        border: Border.all(color: selected ? AppColors.magenta : const Color(0xFF786C74), width: 1.7),
                        shape: BoxShape.circle,
                      )),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
