import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Connexion', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 354, height: 175, color: AppColors.cream),
            const SizedBox(height: 22),
            Text('Connexion', style: const TextStyle(fontSize: 34, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 22),
            Text('Connectez-vous avec votre email ou téléphone.', style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 30),
            _field('Email ou téléphone', 'exemple@email.com'),
            const SizedBox(height: 22),
            _field('Mot de passe', '••••••••', obscure: true),
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
                child: const Text('Se connecter', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.pushNamed(context, '/signup'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE9E1E5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                child: const Text('Créer un compte', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
              ),
            ),
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
