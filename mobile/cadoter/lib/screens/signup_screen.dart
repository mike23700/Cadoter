import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inscription', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Inscription', style: const TextStyle(fontSize: 32, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 13),
            _field('Nom', 'Votre nom'),
            const SizedBox(height: 13),
            _field('Téléphone', '+221 XX XXX XX XX'),
            const SizedBox(height: 13),
            _field('Email', 'exemple@email.com'),
            const SizedBox(height: 13),
            _field('Mot de passe', '••••••••', obscure: true),
            const SizedBox(height: 15),
            Row(
              children: [
                Container(width: 22, height: 22, decoration: BoxDecoration(
                  color: AppColors.magenta.withOpacity(0.1),
                  border: Border.all(color: AppColors.magenta, width: 1.7),
                  shape: BoxShape.circle,
                )),
                const SizedBox(width: 10),
                Expanded(child: Text('J\'accepte les CGU et la politique de confidentialité.',
                    style: const TextStyle(fontSize: 12, color: Color(0xFF30232C)))),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magenta, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                child: const Text('Créer mon compte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 10),
            Center(child: Text('Déjà un compte ? Connectez-vous',
                style: const TextStyle(fontSize: 12, color: Color(0xFF30232C), height: 1.35))),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, {bool obscure = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
        const SizedBox(height: 7),
        TextField(
          obscureText: obscure,
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
