import 'dart:async';

import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'custom_gift_screen.dart';
import 'gift_screen.dart';

/// « Mobile · Catalogue cadeaux »
class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key, this.initialQuery, this.initialOccasion, this.standalone = false});
  final String? initialQuery;
  final String? initialOccasion;
  final bool standalone;

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  static const _budgets = [10000, 20000, 30000, 40000, 50000, 100000];
  late final _q = TextEditingController(text: widget.initialQuery);
  int? _budget;
  String? _city;
  String? _forWho;
  late String? _occasion = widget.initialOccasion;
  Timer? _debounce;
  late Future<List<Gift>> _gifts = _load();

  Future<List<Gift>> _load() async {
    final params = {
      if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
      if (_budget != null) 'budget': '$_budget',
      'city': ?_city,
      'for_who': ?_forWho,
      'occasion': ?_occasion,
    };
    final qs = params.isEmpty ? '' : '?${Uri(queryParameters: params).query}';
    return ((await Api.instance.get('/gifts$qs')) as List).map((e) => Gift.fromJson(e)).toList();
  }

  void _refresh() => setState(() => _gifts = _load());

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = SessionScope.of(context).meta;
    final body = ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
      Text(tr('La bonne attention, au bon endroit.'), style: T.serif(32)),
      const SizedBox(height: 24),
      const FieldLabel('Rechercher par nom'),
      TextField(
        controller: _q,
        style: T.sans(13),
        textInputAction: TextInputAction.search,
        decoration: InputDecoration(hintText: tr('Quel cadeau cherchez-vous ?')),
        onChanged: (_) {
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 400), _refresh);
        },
      ),
      const SizedBox(height: 22),
      Row(children: [
        Expanded(
          child: DropdownField(
            label: 'Budget',
            value: _budget?.toString() ?? '',
            items: ['', ..._budgets.map((b) => '$b')],
            display: (v) => v.isEmpty ? tr('Tous') : tr('{price} max.', {'price': formatPrice(int.parse(v))}),
            onChanged: (v) { _budget = (v == null || v.isEmpty) ? null : int.parse(v); _refresh(); },
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: DropdownField(
            label: 'Ville',
            value: _city ?? '',
            items: ['', ...meta.cities],
            display: (v) => v.isEmpty ? tr('Toutes') : v,
            onChanged: (v) { _city = (v == null || v.isEmpty) ? null : v; _refresh(); },
          ),
        ),
      ]),
      Wrap(spacing: 8, runSpacing: 10, children: [
        Pill('Tous', selected: _forWho == null, onTap: () { _forWho = null; _refresh(); }),
        for (final f in meta.forWho) Pill(f, selected: _forWho == f, onTap: () { _forWho = f; _refresh(); }),
      ]),
      if (_occasion != null) ...[
        const SizedBox(height: 12),
        Align(alignment: Alignment.centerLeft, child: Pill('${tr(_occasion!)} ×', selected: true, onTap: () { _occasion = null; _refresh(); })),
      ],
      const SizedBox(height: 26),
      const IllustrativeNote(),
      const SizedBox(height: 18),
      FutureBuilder<List<Gift>>(
        future: _gifts,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Loader();
          if (snap.hasError) return ErrorRetry('${snap.error}', onRetry: _refresh);
          final gifts = snap.data!;
          if (gifts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(tr('Aucun cadeau ne correspond à ces critères.'), textAlign: TextAlign.center, style: T.sans(13, color: AppColors.gray)),
            );
          }
          return GiftGrid(
            gifts: gifts,
            wideLast: true,
            onTap: (g) => Navigator.push(context, MaterialPageRoute(builder: (_) => GiftScreen(slug: g.slug))),
          );
        },
      ),
      const SizedBox(height: 26),
      SecondaryButton('Besoin d’un cadeau personnalisé ?',
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const CustomGiftScreen()))),
    ]);

    if (widget.standalone) {
      return Scaffold(appBar: const TopBar('Les cadeaux'), body: body, bottomNavigationBar: const AppBottomNav(current: 1));
    }
    return Scaffold(appBar: const TopBar('Les cadeaux', showBack: false), body: body);
  }
}
