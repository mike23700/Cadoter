import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';
import 'custom_gift_screen.dart';
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

  final _form = GlobalKey<FormState>();
  String _event = 'Anniversaire', _gender = 'Femme', _relation = 'Amie', _city = '';
  final _age = TextEditingController();
  final _budget = TextEditingController();
  final _info = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  static int? _digits(String? v) => int.tryParse((v ?? '').replaceAll(RegExp(r'\D'), ''));

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    final age = _digits(_age.text)!, budget = _digits(_budget.text)!;
    final body = {
      'event': _event,
      'gender': _gender,
      'age': age,
      'relation': _relation,
      'budget': budget,
      'city': _city.isEmpty ? null : _city,
      'info': _info.text.trim(),
    };
    try {
      final res = await Api.instance.post('/assistant/suggest', body);
      final list = (res['suggestions'] as List).map((s) => Suggestion(Gift.fromJson(s['gift']), s['reason'] as String, s['card'] as String? ?? '')).toList();
      if (!mounted) return;
      Navigator.push(context, MaterialPageRoute(
        builder: (_) => SuggestionsScreen(
          suggestions: list,
          disclaimer: res['disclaimer'] as String? ?? '',
          chips: [tr(_event), '${tr(_relation)} · ${tr('{age} ans', {'age': age})}', '≤ ${formatPrice(budget)}', if (_city.isNotEmpty) _city],
          request: body,
          searchExternal: res['external_available'] == true && list.length < SuggestionsScreen.externalBelow,
        ),
      ));
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (e.errors.isEmpty && mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cities = SessionScope.of(context).meta.cities;
    return Scaffold(
      appBar: const TopBar('L’assistante CADOTER', showBack: false),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
          const Icon(Icons.auto_awesome_outlined, color: AppColors.magenta, size: 32),
          const SizedBox(height: 18),
          Text(tr('Une personne unique. Des idées à son image.'), style: T.serif(32)),
          const SizedBox(height: 16),
          Text(tr('Dites-nous ce qui la rend spéciale. On vous aide à trouver le bon point de départ.'), style: T.sans(14, color: AppColors.gray)),
          const SizedBox(height: 24),
          DropdownField(label: 'Type d’événement *', value: _event, items: _events, onChanged: (v) => setState(() => _event = v!)),
          DropdownField(label: 'Sexe de la personne *', value: _gender, items: _genders, onChanged: (v) => setState(() => _gender = v!)),
          LabeledField(
            label: 'Âge *', controller: _age, keyboard: TextInputType.number, hint: 'Ex. 30', errorText: _error?.field('age'),
            validator: (v) {
              final a = _digits(v);
              return a == null || a > 120 ? tr('Indiquez un âge entre 0 et 120 ans.') : null;
            },
          ),
          DropdownField(label: 'Lien avec la personne *', value: _relation, items: _relations, onChanged: (v) => setState(() => _relation = v!)),
          LabeledField(
            label: 'Budget alloué (FCFA) *', controller: _budget, keyboard: TextInputType.number, hint: 'Ex. 40 000', errorText: _error?.field('budget'),
            validator: (v) => (_digits(v) ?? 0) < 1000 ? tr('Budget minimum : 1 000 FCFA.') : null,
          ),
          DropdownField(
            label: 'Ville',
            value: _city,
            items: ['', ...cities],
            display: (c) => c.isEmpty ? tr('Toutes les villes') : c,
            onChanged: (v) => setState(() => _city = v ?? ''),
          ),
          LabeledField(label: 'Autres informations', controller: _info, maxLines: 3, hint: 'Elle aime le thé, la décoration et les moments calmes.'),
          Text(tr('* Champs requis · Suggestions indicatives à vérifier auprès du marchand. Évitez de partager des informations sensibles.'),
              style: T.sans(11, color: AppColors.gray)),
          const SizedBox(height: 24),
          PrimaryButton('Trouver mes idées', icon: Icons.auto_awesome_outlined, loading: _busy, onPressed: _submit),
        ]),
      ),
    );
  }
}

/// « Mobile · Suggestions IA »
class SuggestionsScreen extends StatefulWidget {
  const SuggestionsScreen({
    super.key,
    required this.suggestions,
    required this.disclaimer,
    required this.chips,
    required this.request,
    this.searchExternal = false,
  });
  final List<Suggestion> suggestions;
  final String disclaimer;
  final List<String> chips;
  /// Critères envoyés à l'assistante, réutilisés pour la recherche sur les sites marchands.
  final Map<String, dynamic> request;
  final bool searchExternal;

  /// En dessous de ce nombre de suggestions CADOTER, on cherche aussi des idées sur des sites marchands.
  static const externalBelow = 3;

  @override
  State<SuggestionsScreen> createState() => _SuggestionsScreenState();
}

class _SuggestionsScreenState extends State<SuggestionsScreen> {
  bool _externalLoading = false;
  List<ExternalIdea> _external = [];
  String _externalDisclaimer = '';
  int _shown = 3; // « Voir plus » en affiche 3 de plus

  @override
  void initState() {
    super.initState();
    if (widget.searchExternal) _loadExternal();
  }

  Future<void> _loadExternal() async {
    setState(() => _externalLoading = true);
    try {
      final res = await Api.instance.post('/assistant/external', widget.request);
      _external = (res['results'] as List? ?? []).map((e) => ExternalIdea.fromJson(e)).toList();
      _externalDisclaimer = res['disclaimer'] as String? ?? '';
    } catch (_) {/* idées complémentaires : on ignore les erreurs */}
    if (mounted) setState(() => _externalLoading = false);
  }

  void _custom({String? description, int? budget}) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => CustomGiftScreen(
            initialDescription: description ?? ((widget.request['info'] as String?)?.isNotEmpty == true ? widget.request['info'] : tr(widget.request['event'])),
            initialBudget: budget ?? widget.request['budget'] as int?,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final suggestions = widget.suggestions;
    return Scaffold(
      appBar: const TopBar('Vos idées de cadeaux'),
      bottomNavigationBar: const AppBottomNav(current: 3),
      body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
        Text(tr('Une attention qui lui ressemble.'), style: T.serif(32)),
        const SizedBox(height: 20),
        Wrap(spacing: 8, runSpacing: 8, children: [for (final c in widget.chips) Pill(c)]),
        const SizedBox(height: 22),
        const IllustrativeNote(),
        const SizedBox(height: 14),
        Text(widget.disclaimer, style: T.sans(12, color: AppColors.gray)),
        const SizedBox(height: 22),
        if (suggestions.isEmpty && !_externalLoading && _external.isEmpty)
          Panel(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(tr('Nous n\'avons pas trouvé de cadeau qui corresponde à votre demande. Notre équipe peut le chercher pour vous.'), style: T.sans(13)),
              const SizedBox(height: 14),
              SecondaryButton('Demander un cadeau personnalisé', onPressed: () => _custom()),
            ]),
          ),
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
          _Why(s.reason),
          _CardText(s.card),
          const SizedBox(height: 14),
          SecondaryButton('Voir ce cadeau',
              onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GiftScreen(slug: s.gift.slug)))),
          const SizedBox(height: 28),
        ],
        if (_externalLoading)
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Row(children: [
              const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.magenta)),
              const SizedBox(width: 12),
              Expanded(child: Text(tr('On cherche d\'autres idées chez des boutiques en ligne…'), style: T.sans(13, color: AppColors.gray))),
            ]),
          ),
        if (_external.isNotEmpty) ...[
          Text(tr('Idées trouvées ailleurs'), style: T.serif(26)),
          const SizedBox(height: 8),
          Text(_externalDisclaimer, style: T.sans(12, color: AppColors.gray)),
          const SizedBox(height: 22),
          for (final idea in _external.take(_shown)) ...[
            if (idea.image != null) ...[NetImage(idea.image, aspect: 354 / 220), const SizedBox(height: 16)],
            Align(alignment: Alignment.centerLeft, child: Pill(tr('Sur {site}', {'site': idea.site}))),
            const SizedBox(height: 12),
            Text(idea.title, style: T.sans(17, weight: FontWeight.w600)),
            const SizedBox(height: 8),
            Text(idea.priceLabel, style: T.sans(15, weight: FontWeight.w600, color: AppColors.magenta)),
            const SizedBox(height: 14),
            _Why(idea.reason),
            _CardText(idea.card),
            const SizedBox(height: 14),
            SecondaryButton(tr('Voir sur {site}', {'site': idea.site}), icon: Icons.open_in_new, onPressed: () => openUrl(context, idea.url)),
            const SizedBox(height: 10),
            SecondaryButton('Ajouter à ma liste', icon: Icons.format_list_bulleted, onPressed: () => _addToList(idea)),
            const SizedBox(height: 10),
            PrimaryButton('Le commander via CADOTER', icon: Icons.card_giftcard, onPressed: () => _custom(
                  description: tr('Je souhaite offrir ce produit vu sur {site} : {title} — {url}', {'site': idea.site, 'title': idea.title, 'url': idea.url}),
                  budget: idea.priceFcfa,
                )),
            const SizedBox(height: 28),
          ],
          if (_shown < _external.length)
            Center(
              child: TextButton(
                onPressed: () => setState(() => _shown += 3),
                child: Text('${tr('Voir plus ({n})', {'n': _external.length - _shown})} ↓',
                    style: T.sans(13, weight: FontWeight.w600, color: AppColors.magenta)),
              ),
            ),
          const SizedBox(height: 12),
        ],
        PrimaryButton('Affiner mes critères', onPressed: () => Navigator.pop(context)),
      ]),
    );
  }

  Future<void> _addToList(ExternalIdea idea) async {
    if (!await ensureLoggedIn(context) || !mounted) return;
    List<GiftList> lists;
    try {
      lists = ((await Api.instance.get('/lists')) as List).map((e) => GiftList.fromJson(e)).toList();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
      return;
    }
    if (!mounted) return;
    if (lists.isEmpty) {
      toast(context, 'Vous n\'avez pas encore de liste.');
      SessionScope.read(context).goTab(2);
      Navigator.popUntil(context, (r) => r.isFirst);
      return;
    }
    final list = lists.length == 1
        ? lists.first
        : await showModalBottomSheet<GiftList>(
            context: context,
            builder: (ctx) => SafeArea(
              child: ListView(shrinkWrap: true, padding: const EdgeInsets.symmetric(vertical: 12), children: [
                Padding(padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 12), child: Text(tr('Ajouter à ma liste'), style: T.serif(22))),
                for (final l in lists)
                  ListTile(title: Text(l.title, style: T.sans(14)), trailing: const Icon(Icons.chevron_right), onTap: () => Navigator.pop(ctx, l)),
              ]),
            ),
          );
    if (list == null || !mounted) return;
    try {
      await Api.instance.post('/lists/${list.id}/items', {'url': idea.url, 'name': idea.title, 'price': idea.priceFcfa});
      if (mounted) toast(context, tr('Ajouté à : {title}', {'title': list.title}));
    } on ApiException catch (e) {
      if (mounted) toast(context, e.errors.values.firstOrNull?.first ?? e.message);
    }
  }
}

class _Why extends StatelessWidget {
  const _Why(this.reason);
  final String reason;

  @override
  Widget build(BuildContext context) => Panel(
        pink: true,
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Pourquoi ce cadeau ?'), style: T.sans(12, weight: FontWeight.w600, color: AppColors.magenta)),
          const SizedBox(height: 6),
          Text(reason, style: T.sans(13)),
        ]),
      );
}

/// Texte de carte de vœux rédigé par l'IA, à copier.
class _CardText extends StatelessWidget {
  const _CardText(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    if (text.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Panel(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(child: Text(tr('Texte pour la carte'), style: T.sans(12, weight: FontWeight.w600, color: AppColors.magenta))),
            TextButton.icon(
              onPressed: () async {
                await Clipboard.setData(ClipboardData(text: text));
                if (context.mounted) toast(context, 'Texte copié !');
              },
              icon: const Icon(Icons.copy, size: 16, color: AppColors.magenta),
              label: Text(tr('Copier'), style: T.sans(12, weight: FontWeight.w600, color: AppColors.magenta)),
            ),
          ]),
          SelectableText(text, style: T.sans(14).copyWith(fontStyle: FontStyle.italic, height: 1.5)),
        ]),
      ),
    );
  }
}
