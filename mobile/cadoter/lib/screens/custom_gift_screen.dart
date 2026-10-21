import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CustomGiftScreen extends StatelessWidget {
  const CustomGiftScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Cadeau personnalisé', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 354, height: 170, color: AppColors.cream),
            const SizedBox(height: 22),
            Text('Cadeau personnalisé', style: const TextStyle(fontSize: 32, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 22),
            Text('Décrivez le cadeau que vous imaginez. Notre équipe vous recontacte pour le concrétiser. Ce n\'est pas une commande directe.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 30),
            _field('Nom du cadeau', 'Ex. Bijou sur mesure'),
            const SizedBox(height: 22),
            _field('Téléphone', '+221 XX XXX XX XX'),
            const SizedBox(height: 22),
            _field('Budget', 'Ex. 50 000 FCFA'),
            const SizedBox(height: 22),
            _field('Description', 'Précisez vos envies...', maxLines: 4),
            const SizedBox(height: 22),
            _field('Emballage (optionnel)', 'Rosé signature / Naturel / Ciel'),
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
                child: const Text('Envoyer la demande', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
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
