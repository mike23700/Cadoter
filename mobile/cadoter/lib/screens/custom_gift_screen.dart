import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'wrapping_screen.dart';

/// « Mobile · Cadeau personnalisé » : formulaire, l'équipe recontacte (pas de commande directe).
class CustomGiftScreen extends StatefulWidget {
  const CustomGiftScreen({super.key, this.initialDescription, this.initialBudget});
  /// Pré-remplissage depuis l'assistante (« Le commander via CADOTER »).
  final String? initialDescription;
  final int? initialBudget;

  @override
  State<CustomGiftScreen> createState() => _CustomGiftScreenState();
}

class _CustomGiftScreenState extends State<CustomGiftScreen> {
  final _form = GlobalKey<FormState>();
  late final _user = SessionScope.read(context).user;
  late final _name = TextEditingController(text: _user?.name);
  late final _phone = TextEditingController(text: _user?.phone);
  late final _budget = TextEditingController(text: widget.initialBudget?.toString());
  late final _desc = TextEditingController(text: widget.initialDescription);
  bool _busy = false;
  ApiException? _error;

  String? _req(String? v) => (v ?? '').trim().isEmpty ? tr('Champ obligatoire.') : null;

  Future<void> _continue() async {
    if (!_form.currentState!.validate()) return;
    // Étape 2 : choix de l'emballage, puis envoi
    final wrap = await Navigator.push<Wrapping?>(context, MaterialPageRoute(builder: (_) => const WrappingScreen()));
    if (!mounted) return;
    setState(() { _busy = true; _error = null; });
    try {
      final res = await Api.instance.post('/custom-requests', {
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'budget': int.tryParse(_budget.text.replaceAll(RegExp(r'\D'), '')) ?? 0,
        'description': _desc.text.trim(),
        'wrapping_id': wrap?.id,
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Demande envoyée.'), style: T.serif(22)),
          content: Text('${res['message']}', style: T.sans(13)),
          actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('OK')))],
        ),
      );
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (mounted) toast(context, e.errors.values.firstOrNull?.first ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('Une attention sur mesure'),
        bottomNavigationBar: const AppBottomNav(current: 1),
        body: Form(
          key: _form,
          child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 24), children: [
            const NetImage('assets/images/bouquet.jpg', aspect: 354 / 170),
            const SizedBox(height: 28),
            Text(tr('Vous l’imaginez. On vous accompagne.'), style: T.serif(32)),
            const SizedBox(height: 16),
            Text(tr('Décrivez le cadeau souhaité. Nous vous recontacterons pour préciser votre demande.'), style: T.sans(14, color: AppColors.gray)),
            const SizedBox(height: 24),
            LabeledField(label: 'Nom *', controller: _name, hint: 'Aïcha Koné', validator: _req, errorText: _error?.field('name')),
            LabeledField(label: 'Téléphone *', controller: _phone, hint: '+225 07 00 00 00 00', keyboard: TextInputType.phone, validator: _req, errorText: _error?.field('phone')),
            LabeledField(
              label: 'Budget *', controller: _budget, hint: '30 000 FCFA', keyboard: TextInputType.number, errorText: _error?.field('budget'),
              validator: (v) => (int.tryParse((v ?? '').replaceAll(RegExp(r'\D'), '')) ?? 0) < 1000 ? tr('Budget minimum : 1 000 FCFA.') : null,
            ),
            LabeledField(label: 'Description du cadeau *', controller: _desc, maxLines: 4, hint: 'Un coffret de thé pour ma mère…', validator: _req, errorText: _error?.field('description')),
            Text(tr('* Champs obligatoires · Vos coordonnées servent à suivre cette demande.'), style: T.sans(11, color: AppColors.gray)),
            const SizedBox(height: 24),
            PrimaryButton('Continuer vers l’emballage', loading: _busy, onPressed: _continue),
          ]),
        ),
      );
}
