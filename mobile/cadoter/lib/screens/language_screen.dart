import 'package:flutter/material.dart';

import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'onboarding_screen.dart';

/// « Mobile · Choix de langue »
class LanguageScreen extends StatefulWidget {
  const LanguageScreen({super.key, this.fromSettings = false});
  final bool fromSettings;

  @override
  State<LanguageScreen> createState() => _LanguageScreenState();
}

class _LanguageScreenState extends State<LanguageScreen> {
  late String lang = SessionScope.read(context).language;

  Widget _option(String code, String label) {
    final on = lang == code;
    return GestureDetector(
      onTap: () => setState(() => lang = code),
      child: Container(
        margin: const EdgeInsets.only(bottom: 22),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        decoration: BoxDecoration(color: on ? AppColors.pinkBg : AppColors.cream, borderRadius: BorderRadius.circular(16)),
        child: Row(children: [
          Expanded(child: Text(label, style: T.sans(14, weight: FontWeight.w600))),
          Icon(on ? Icons.check_circle_outline : Icons.radio_button_unchecked, color: on ? AppColors.magenta : AppColors.gray),
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: widget.fromSettings ? const TopBar('Langue') : null,
        body: SafeArea(
          child: ListView(padding: EdgeInsets.zero, children: [
            if (!widget.fromSettings) const BrandHeader(),
            Padding(
              padding: const EdgeInsets.fromLTRB(kGutter, 50, kGutter, 24),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                const Icon(Icons.language, color: AppColors.magenta, size: 36),
                const SizedBox(height: 22),
                Text('On parle la même langue.', style: T.serif(34)),
                const SizedBox(height: 18),
                Text('Choisissez la langue qui vous ressemble. Vous pourrez la modifier dans les paramètres.',
                    style: T.sans(14, color: AppColors.gray)),
                const SizedBox(height: 46),
                _option('fr', 'Français'),
                _option('en', 'English'),
                PrimaryButton(lang == 'fr' ? 'Continuer en français' : 'Continue in English', onPressed: () async {
                  await SessionScope.read(context).setLanguage(lang);
                  if (!context.mounted) return;
                  if (widget.fromSettings) {
                    Navigator.pop(context);
                  } else {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const OnboardingScreen()));
                  }
                }),
                const SizedBox(height: 22),
                Center(child: Text('Votre langue, votre expérience.', style: T.sans(12, color: AppColors.gray))),
              ]),
            ),
          ]),
        ),
      );
}
