import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class LanguageScreen extends StatelessWidget {
  const LanguageScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choix de langue', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(width: 40, height: 40, decoration: BoxDecoration(
              color: AppColors.magenta.withOpacity(0.1),
              border: Border.all(color: AppColors.magenta, width: 1.7),
              shape: BoxShape.circle,
            )),
            const SizedBox(height: 18),
            Text('Bienvenue', style: const TextStyle(fontSize: 36, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 18),
            Text('Choisissez la langue de l\'application.', style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.pinkBg,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Langue', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                  Container(width: 22, height: 22, decoration: BoxDecoration(
                    color: AppColors.magenta.withOpacity(0.1),
                    border: Border.all(color: AppColors.magenta, width: 1.7),
                    shape: BoxShape.circle,
                  )),
                ],
              ),
            ),
            const SizedBox(height: 22),
            Container(
              padding: const EdgeInsets.all(20),
              color: AppColors.cream,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Français', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                  Container(width: 22, height: 22, decoration: BoxDecoration(
                    border: Border.all(color: const Color(0xFF786C74), width: 1.7),
                    borderRadius: BorderRadius.circular(50),
                  )),
                ],
              ),
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pushReplacementNamed(context, '/onboarding'),
                child: const Text('Continuer', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}
