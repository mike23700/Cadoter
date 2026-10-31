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
  static const _sorts = {'': 'Notre sélection', 'price_asc': 'Prix croissant', 'price_desc': 'Prix décroissant', 'recent': 'Nouveautés'};
  late final _q = TextEditingController(text: widget.initialQuery);
  final _budgetCtrl = TextEditingController();
  int? _budget;
  String _sort = '';
  String? _city;
  String? _forWho;
  late String? _occasion = widget.initialOccasion;
  Timer? _debounce;
  static const _perPage = 24;
  final _scroll = ScrollController();
  // Pages chargées au fil du défilement (réponse paginée de /gifts?page=N)
  final List<Gift> _items = [];
  int _page = 0, _lastPage = 1, _total = 0;
  bool _loadingMore = false;
  int _generation = 0; // ignore les réponses d'anciens filtres
  late Future<void> _gifts = _loadPage(1);

  @override
  void initState() {
    super.initState();
    _scroll.addListener(() {
      if (_scroll.position.extentAfter < 600) _loadMore();
    });
  }

  Map<String, String> _params() => {
        if (_q.text.trim().isNotEmpty) 'q': _q.text.trim(),
      if (_budget != null) 'budget': '$_budget',
      'city': ?_city,
      'for_who': ?_forWho,
      'occasion': ?_occasion,
      if (_sort.isNotEmpty) 'sort': _sort,
      };

  Future<void> _loadPage(int page) async {
    final gen = _generation;
    final qs = Uri(queryParameters: {..._params(), 'page': '$page', 'per_page': '$_perPage'}).query;
    final res = await Api.instance.get('/gifts?$qs') as Map<String, dynamic>;
    if (gen != _generation || !mounted) return;
    setState(() {
      if (page == 1) _items.clear();
      _items.addAll((res['data'] as List).map((e) => Gift.fromJson(e)));
      _page = res['current_page'] as int? ?? page;
      _lastPage = res['last_page'] as int? ?? page;
      _total = res['total'] as int? ?? _items.length;
    });
    // Page suivante préchargée : elle s'affiche immédiatement au défilement
    if (_page < _lastPage) Api.instance.get('/gifts?${Uri(queryParameters: {..._params(), 'page': '${_page + 1}', 'per_page': '$_perPage'}).query}').catchError((_) => null);
  }

  Future<void> _loadMore() async {
    if (_loadingMore || _page >= _lastPage || _page == 0) return;
    setState(() => _loadingMore = true);
    try {
      await _loadPage(_page + 1);
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _loadingMore = false);
    }
  }

  /// Tout changement de filtre ou de tri repart de la première page.
  void _refresh() {
    _generation++;
    _page = 0;
    _loadingMore = false;
    setState(() => _gifts = _loadPage(1));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _q.dispose();
    _budgetCtrl.dispose();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final meta = SessionScope.of(context).meta;
    final body = ListView(controller: _scroll, padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
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
      const FieldLabel('Budget maximum (FCFA)'),
      TextField(
        controller: _budgetCtrl,
        style: T.sans(13),
        keyboardType: TextInputType.number,
        decoration: InputDecoration(hintText: tr('Ex. {n}', {'n': '40 000'})),
        onChanged: (v) {
          _budget = int.tryParse(v.replaceAll(RegExp(r'\D'), ''));
          if (_budget == 0) _budget = null;
          _debounce?.cancel();
          _debounce = Timer(const Duration(milliseconds: 500), _refresh);
        },
      ),
      const SizedBox(height: 18),
      Row(children: [
        Expanded(
          child: DropdownField(
            label: 'Type d’événement',
            value: _occasion ?? '',
            items: ['', ...{...meta.occasions, ?_occasion}],
            display: (v) => v.isEmpty ? tr('Tous') : tr(v),
            onChanged: (v) { _occasion = (v == null || v.isEmpty) ? null : v; _refresh(); },
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
      DropdownField(
        label: 'Trier',
        value: _sort,
        items: _sorts.keys.toList(),
        display: (v) => tr(_sorts[v]!),
        onChanged: (v) { _sort = v ?? ''; _refresh(); },
      ),
      Wrap(spacing: 8, runSpacing: 10, children: [
        Pill('Tous', selected: _forWho == null, onTap: () { _forWho = null; _refresh(); }),
        for (final f in meta.forWho) Pill(f, selected: _forWho == f, onTap: () { _forWho = f; _refresh(); }),
      ]),
      const SizedBox(height: 26),
      const IllustrativeNote(),
      const SizedBox(height: 18),
      FutureBuilder<void>(
        future: _gifts,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Loader();
          if (snap.hasError) return ErrorRetry('${snap.error}', onRetry: _refresh);
          final gifts = _items;
          if (gifts.isEmpty) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 30),
              child: Text(tr('Aucun cadeau ne correspond à ces critères.'), textAlign: TextAlign.center, style: T.sans(13, color: AppColors.gray)),
            );
          }
          return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(trn(_total, '{n} cadeau', '{n} cadeaux'), style: T.sans(12, color: AppColors.gray)),
            const SizedBox(height: 14),
            GiftGrid(
              gifts: gifts,
              wideLast: _page >= _lastPage,
              onTap: (g) => Navigator.push(context, MaterialPageRoute(builder: (_) => GiftScreen(slug: g.slug))),
            ),
            if (_loadingMore) const Loader(),
          ]);
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
