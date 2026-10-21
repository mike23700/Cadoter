import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'gift_screen.dart';

/// « Mobile · Assistante IA formulaire »
class AssistantScreen extends StatefulWidget {
  const AssistantScreen({super.key});

  @override
  State<AssistantScreen> createState() => _AssistantScreenState();
}

class _AssistantScreenState extends State<AssistantScreen> {
  static const _events = ['Anniversaire', 'Mariage', 'Naissance', 'Dot', 'Fête des mères', 'Fête des pères', 'Noël', 'Remerciement', 'Décès · Soutenir un proche'];
  static const _genders = ['Femme', 'Homme', 'Non précisé'];
  static const _relations = ['Amie', 'Ami', 'Mère', 'Père', 'Conjointe', 'Conjoint', 'Sœur', 'Frère', 'Enfant', 'Collègue', 'Famille'];
  static const _budgets = [10000, 20000, 30000, 40000, 50000, 75000, 100000, 200000];
  static final _ages = [for (var a = 1; a <= 90; a++) '$a'];

  String _event = 'Anniversaire', _gender = 'Femme', _relation = 'Amie', _age = '30';
  int _budget = 40000;
  final _info = TextEditingController();
  bool _busy = false;

  Future<void> _submit() async {
    setState(() => _busy = true);
    try {
      final res = await Api.instance.post('/assistant/suggest', {
        'event': _event,
        'gender': _gender,
        'age': int.parse(_age),
        'relation': _relation,
        'budget': _budget,
        'info': _info.text.trim(),
      });
      final list = (res['suggestions'] as List).map((s) => Suggestion(Gift.fromJson(s['gift']), s['reason'] as String)).toList();
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SuggestionsScreen(
          suggestions: list,
          disclaimer: res['disclaimer'] as String? ?? '',
          chips: [_event, '$_relation · $_age ans', '≤ ${formatPrice(_budget)}'],
        ),
      ));
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('L’assistante CADOTER', showBack: false),
        body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
          const Icon(Icons.auto_awesome_outlined, color: AppColors.magenta, size: 32),
          const SizedBox(height: 18),
          Text('Parlez-nous de cette personne.', style: T.serif(32)),
          const SizedBox(height: 16),
          Text('Quelques détails suffisent pour faire naître les bonnes idées.', style: T.sans(14, color: AppColors.gray)),
          const SizedBox(height: 24),
          DropdownField(label: 'Type d’événement *', value: _event, items: _events, onChanged: (v) => setState(() => _event = v!)),
          DropdownField(label: 'Sexe de la personne *', value: _gender, items: _genders, onChanged: (v) => setState(() => _gender = v!)),
          DropdownField(label: 'Âge *', value: _age, items: _ages, display: (a) => '$a ans', onChanged: (v) => setState(() => _age = v!)),
          DropdownField(label: 'Lien avec la personne *', value: _relation, items: _relations, onChanged: (v) => setState(() => _relation = v!)),
          DropdownField(
            label: 'Budget alloué *',
            value: '$_budget',
            items: _budgets.map((b) => '$b').toList(),
            display: (b) => '${formatPrice(int.parse(b))} maximum',
            onChanged: (v) => setState(() => _budget = int.parse(v!)),
          ),
          LabeledField(label: 'Autres informations', controller: _info, maxLines: 3, hint: 'Elle aime le thé, la décoration et les moments calmes.'),
          Text('* Champs requis · Suggestions indicatives à vérifier auprès du marchand. Évitez de partager des informations sensibles.',
              style: T.sans(11, color: AppColors.gray)),
          const SizedBox(height: 24),
          PrimaryButton('Trouver mes idées', icon: Icons.auto_awesome_outlined, loading: _busy, onPressed: _submit),
        ]),
      );
}

/// « Mobile · Suggestions IA »
class SuggestionsScreen extends StatelessWidget {
  const SuggestionsScreen({super.key, required this.suggestions, required this.disclaimer, required this.chips});
  final List<Suggestion> suggestions;
  final String disclaimer;
  final List<String> chips;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('Vos idées de cadeaux'),
        bottomNavigationBar: const AppBottomNav(current: 3),
        body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
          Text('Une attention qui lui ressemble.', style: T.serif(32)),
          const SizedBox(height: 20),
          Wrap(spacing: 8, runSpacing: 8, children: [for (final c in chips) Pill(c)]),
          const SizedBox(height: 22),
          const IllustrativeNote(),
          const SizedBox(height: 14),
          Text(disclaimer, style: T.sans(12, color: AppColors.gray)),
          const SizedBox(height: 22),
          if (suggestions.isEmpty)
            Panel(child: Text('Aucune idée dans ce budget pour l’instant. Essayez un budget plus large ou une demande personnalisée.', style: T.sans(13))),
          for (final s in suggestions) ...[
            NetImage(s.gift.imageUrl, aspect: 354 / 220),
            const SizedBox(height: 16),
            Align(alignment: Alignment.centerLeft, child: StatusBadge(s.gift.available ? 'Disponible' : 'Indisponible', ok: s.gift.available)),
            const SizedBox(height: 12),
            Text(s.gift.name, style: T.sans(17, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(s.gift.place, style: T.sans(13, color: AppColors.gray)),
            const SizedBox(height: 8),
            Text(formatPrice(s.gift.price, s.gift.currency), style: T.sans(15, weight: FontWeight.w600, color: AppColors.magenta)),
            const SizedBox(height: 14),
            Panel(
              pink: true,
              padding: const EdgeInsets.all(14),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Pourquoi ce cadeau ?', style: T.sans(12, weight: FontWeight.w600, color: AppColors.magenta)),
                const SizedBox(height: 6),
                Text(s.reason, style: T.sans(13)),
              ]),
            ),
            const SizedBox(height: 14),
            SecondaryButton('Voir ce cadeau',
                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GiftScreen(slug: s.gift.slug)))),
            const SizedBox(height: 28),
          ],
          PrimaryButton('Affiner mes critères', onPressed: () => Navigator.pop(context)),
        ]),
      );
}
