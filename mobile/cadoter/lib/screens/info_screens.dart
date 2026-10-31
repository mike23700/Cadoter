import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'gift_screen.dart';

/// Questions fréquentes, gérées depuis l'administration.
class FaqScreen extends StatelessWidget {
  const FaqScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('FAQ'),
        body: ApiBuilder<List<dynamic>>(
          load: () async => (await Api.instance.get('/faqs')) as List,
          builder: (context, faqs, _) => ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28), children: [
            Text(tr('Questions fréquentes'), style: T.serif(32)),
            const SizedBox(height: 12),
            Text(tr('Les réponses aux questions que l\'on nous pose le plus souvent.'), style: T.sans(14, color: AppColors.gray)),
            const SizedBox(height: 22),
            if (faqs.isEmpty) Text(tr('Aucune question pour le moment.'), style: T.sans(13, color: AppColors.gray)),
            for (final f in faqs)
              Theme(
                data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
                child: Container(
                  decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                  child: ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    childrenPadding: const EdgeInsets.only(bottom: 16),
                    expandedAlignment: Alignment.centerLeft,
                    iconColor: AppColors.magenta,
                    collapsedIconColor: AppColors.dark,
                    title: Text('${f['question']}', style: T.sans(14, weight: FontWeight.w600)),
                    children: [Text('${f['answer']}', style: T.sans(13, color: AppColors.gray))],
                  ),
                ),
              ),
            const SizedBox(height: 28),
            Panel(
              pink: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(tr('Vous ne trouvez pas votre réponse ?'), style: T.serif(22)),
                const SizedBox(height: 8),
                Text(tr('Écrivez-nous, nous vous répondons sur WhatsApp.'), style: T.sans(13, color: AppColors.gray)),
                const SizedBox(height: 16),
                PrimaryButton('Nous contacter',
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ContactScreen()))),
              ]),
            ),
          ]),
        ),
      );
}

/// Formulaire de contact : ouvre WhatsApp avec le message pré-rempli (numéro réglé dans l'administration).
class ContactScreen extends StatefulWidget {
  const ContactScreen({super.key});

  @override
  State<ContactScreen> createState() => _ContactScreenState();
}

class _ContactScreenState extends State<ContactScreen> {
  static const _subjects = ['Question sur une commande', 'Liste de cadeaux', 'Devenir boutique partenaire', 'Autre'];
  final _form = GlobalKey<FormState>();
  late final _name = TextEditingController(text: SessionScope.read(context).user?.name);
  final _message = TextEditingController();
  String _subject = _subjects.first;
  bool _loadingMeta = false;

  @override
  void initState() {
    super.initState();
    // Numéro absent : métadonnées chargées hors ligne au démarrage (ou réglage modifié depuis) → on recharge
    if ((SessionScope.read(context).meta.whatsapp ?? '').isEmpty) {
      _loadingMeta = true;
      SessionScope.read(context).reloadMeta().whenComplete(() { if (mounted) setState(() => _loadingMeta = false); });
    }
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? tr('Champ obligatoire.') : null;

  void _send(String number) {
    if (!_form.currentState!.validate()) return;
    final text = '${tr('Bonjour CADOTER, je suis {name}.', {'name': _name.text.trim()})}\n'
        '${tr('Sujet : {subject}', {'subject': tr(_subject)})}\n\n${_message.text.trim()}';
    openUrl(context, 'https://wa.me/$number?text=${Uri.encodeComponent(text)}');
  }

  @override
  Widget build(BuildContext context) {
    final number = (SessionScope.of(context).meta.whatsapp ?? '').replaceAll(RegExp(r'\D'), '');
    return Scaffold(
      appBar: const TopBar('Nous contacter'),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28), children: [
          Text(tr('Parlons-en.'), style: T.serif(32)),
          const SizedBox(height: 12),
          Text(tr('Une question, une idée, un souci ? Écrivez-nous : votre message s\'ouvre dans WhatsApp, prêt à être envoyé.'),
              style: T.sans(14, color: AppColors.gray)),
          const SizedBox(height: 24),
          LabeledField(label: 'Nom *', controller: _name, hint: 'Aïcha Koné', validator: _req),
          DropdownField(label: 'Sujet', value: _subject, items: _subjects, onChanged: (v) => setState(() => _subject = v ?? _subjects.first)),
          LabeledField(label: 'Message *', controller: _message, maxLines: 6, hint: 'Bonjour, je voudrais savoir…', validator: _req),
          if (number.isEmpty && !_loadingMeta) ...[
            Text(tr('Le contact WhatsApp n\'est pas encore configuré.'), style: T.sans(12, color: AppColors.error)),
            const SizedBox(height: 12),
          ],
          PrimaryButton('Envoyer sur WhatsApp', icon: Icons.send_outlined, onPressed: number.isEmpty ? null : () => _send(number)),
          const SizedBox(height: 12),
          Text(tr('WhatsApp s\'ouvre avec votre message : il ne reste plus qu\'à appuyer sur « Envoyer ».'),
              style: T.sans(11, color: AppColors.gray)),
          const SizedBox(height: 28),
          Panel(
            pink: true,
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Avant d\'écrire'), style: T.serif(22)),
              const SizedBox(height: 8),
              Text(tr('La réponse se trouve peut-être déjà dans notre FAQ.'), style: T.sans(13, color: AppColors.gray)),
              const SizedBox(height: 16),
              SecondaryButton('Voir la FAQ',
                  onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const FaqScreen()))),
            ]),
          ),
        ]),
      ),
    );
  }
}

/// Page publique d'une boutique partenaire : ses produits en ligne.
class ShopScreen extends StatelessWidget {
  const ShopScreen({super.key, required this.id});
  final int id;

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('Boutique'),
        body: ApiBuilder<Map<String, dynamic>>(
          load: () async => (await Api.instance.get('/shops/$id')) as Map<String, dynamic>,
          builder: (context, shop, reload) {
            final gifts = (shop['gifts'] as List? ?? []).map((e) => Gift.fromJson(e)).toList();
            final since = DateTime.tryParse('${shop['created_at']}');
            return ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 28), children: [
              const Eyebrow('Boutique partenaire'),
              const SizedBox(height: 12),
              Text('${shop['shop_name'] ?? ''}', style: T.serif(32)),
              const SizedBox(height: 10),
              Text(
                [
                  trn(gifts.length, '{n} cadeau en ligne', '{n} cadeaux en ligne'),
                  if (since != null) tr('Sur CADOTER depuis {date}', {'date': formatMonthYear(since)}),
                ].join(' · '),
                style: T.sans(13, color: AppColors.gray),
              ),
              const SizedBox(height: 24),
              if (gifts.isEmpty)
                Text(tr('Cette boutique n\'a pas encore de produit en ligne.'), style: T.sans(13, color: AppColors.gray))
              else
                GiftGrid(
                  gifts: gifts,
                  onTap: (g) async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => GiftScreen(slug: g.slug)));
                    reload();
                  },
                ),
            ]);
          },
        ),
      );
}
