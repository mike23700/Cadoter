import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// « Mobile · Choix d'emballage ». Renvoie l'emballage choisi, ou null pour « sans emballage ».
class WrappingScreen extends StatefulWidget {
  const WrappingScreen({super.key, this.selected});
  final Wrapping? selected;

  @override
  State<WrappingScreen> createState() => _WrappingScreenState();
}

class _WrappingScreenState extends State<WrappingScreen> {
  late int? _id = widget.selected?.id;

  @override
  Widget build(BuildContext context) {
    final wraps = SessionScope.of(context).meta.wrappings;
    final chosen = wraps.where((w) => w.id == _id).firstOrNull;
    return Scaffold(
      appBar: const TopBar('La touche finale'),
      bottomNavigationBar: const AppBottomNav(current: 1),
      body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
        Text(tr('Le plaisir commence avant d’ouvrir.'), style: T.serif(32)),
        const SizedBox(height: 18),
        Text(tr('Choisissez un modèle pour votre cadeau. Visuels d’emballages présentés à titre d’exemple.'),
            style: T.sans(14, color: AppColors.gray)),
        const SizedBox(height: 22),
        for (final w in wraps)
          GestureDetector(
            onTap: () => setState(() => _id = w.id),
            child: Container(
              margin: const EdgeInsets.only(bottom: 20),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: _id == w.id ? AppColors.magenta : AppColors.border, width: _id == w.id ? 2 : 1),
              ),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NetImage(w.imageUrl, width: 108, height: 124, radius: 12),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const SizedBox(height: 6),
                    Text(w.name, style: T.sans(14, weight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    Text(w.detail, style: T.sans(12, color: AppColors.gray)),
                    if (w.price > 0) ...[
                      const SizedBox(height: 6),
                      Text('+ ${formatPrice(w.price)}', style: T.sans(12, weight: FontWeight.w600, color: AppColors.magenta)),
                    ],
                    const SizedBox(height: 12),
                    Icon(_id == w.id ? Icons.check_circle_outline : Icons.radio_button_unchecked,
                        color: _id == w.id ? AppColors.magenta : AppColors.gray),
                  ]),
                ),
              ]),
            ),
          ),
        if (wraps.isEmpty) Text(tr('Aucun emballage disponible pour le moment.'), style: T.sans(13, color: AppColors.gray)),
        const SizedBox(height: 4),
        PrimaryButton(chosen != null ? tr('Choisir {name}', {'name': chosen.name}) : 'Continuer',
            onPressed: () => Navigator.pop(context, chosen)),
        const SizedBox(height: 20),
        Center(
          child: GestureDetector(
            onTap: () => Navigator.pop(context, null),
            child: Text(tr('Continuer sans emballage'), style: T.sans(13, color: AppColors.gray)),
          ),
        ),
      ]),
    );
  }
}
