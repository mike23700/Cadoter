import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';
import 'create_list_screen.dart';
import 'order_screen.dart';
import 'wrapping_screen.dart';

/// « Mobile · Fiche cadeau »
class GiftScreen extends StatefulWidget {
  const GiftScreen({super.key, required this.slug});
  final String slug;

  @override
  State<GiftScreen> createState() => _GiftScreenState();
}

class _GiftScreenState extends State<GiftScreen> {
  List<GiftList> _lists = [];
  int? _listId;
  Wrapping? _wrap;
  bool _busy = false;

  Future<Gift> _load() async {
    final gift = Gift.fromJson(await Api.instance.get('/gifts/${Uri.encodeComponent(widget.slug)}'));
    await _loadLists();
    return gift;
  }

  Future<void> _loadLists() async {
    if (!SessionScope.read(context).isLoggedIn) return;
    try {
      _lists = ((await Api.instance.get('/lists')) as List).map((e) => GiftList.fromJson(e)).toList();
      _listId ??= _lists.isNotEmpty ? _lists.first.id : null;
    } catch (_) {}
  }

  Future<void> _add(Gift gift) async {
    if (!await ensureLoggedIn(context)) return;
    if (_lists.isEmpty) await _loadLists();
    if (!mounted) return;
    if (_lists.isEmpty) {
      final created = await Navigator.push<GiftList>(context, MaterialPageRoute(builder: (_) => const CreateListScreen()));
      if (created == null) return;
      _lists = [created];
      _listId = created.id;
    }
    setState(() => _busy = true);
    try {
      await Api.instance.post('/lists/$_listId/items', {'gift_id': gift.id});
      if (mounted) toast(context, '« ${gift.name} » ajouté à votre liste.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    _wrap ??= session.meta.wrappings.isNotEmpty ? session.meta.wrappings.first : null;
    return Scaffold(
      appBar: const TopBar('Le cadeau'),
      bottomNavigationBar: const AppBottomNav(current: 1),
      body: ApiBuilder<Gift>(
        load: _load,
        builder: (context, gift, _) => StatefulBuilder(builder: (context, setLocal) {
          final fav = session.favorites.contains(gift.id);
          return ListView(padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 28), children: [
            NetImage(gift.imageUrl, aspect: 354 / 300),
            const SizedBox(height: 22),
            Align(alignment: Alignment.centerLeft, child: StatusBadge(gift.available ? 'Disponible' : 'Indisponible', ok: gift.available)),
            const SizedBox(height: 18),
            Text(gift.name, style: T.serif(34)),
            const SizedBox(height: 18),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(formatPrice(gift.price, gift.currency), style: T.sans(20, weight: FontWeight.w600, color: AppColors.magenta)),
              const Spacer(),
              Flexible(child: Text(gift.place, textAlign: TextAlign.right, style: T.sans(12, color: AppColors.gray))),
            ]),
            if (gift.description != null) ...[
              const SizedBox(height: 18),
              Text(gift.description!, style: T.sans(14, color: AppColors.gray)),
            ],
            const SizedBox(height: 18),
            const IllustrativeNote(),
            const SizedBox(height: 22),
            if (_lists.length > 1)
              DropdownField(
                label: 'Ajouter à une liste',
                value: '$_listId',
                items: _lists.map((l) => '${l.id}').toList(),
                display: (id) => _lists.firstWhere((l) => '${l.id}' == id).title,
                onChanged: (v) => setLocal(() => _listId = int.tryParse(v ?? '')),
              )
            else if (_lists.length == 1)
              Padding(
                padding: const EdgeInsets.only(bottom: 14),
                child: Text('Ajouter à : ${_lists.first.title}', style: T.sans(12, weight: FontWeight.w600)),
              ),
            PrimaryButton('Ajouter à ma liste', icon: Icons.add, loading: _busy, onPressed: () => _add(gift)),
            const SizedBox(height: 12),
            SecondaryButton('Commander ce cadeau', onPressed: gift.available
                ? () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(gift: gift, wrapping: _wrap)))
                : null),
            const SizedBox(height: 22),
            if (_wrap != null)
              Panel(
                padding: const EdgeInsets.all(16),
                child: Row(children: [
                  NetImage(_wrap!.imageUrl, width: 86, height: 90, radius: 14),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text('La touche finale', style: T.sans(14, weight: FontWeight.w600)),
                      const SizedBox(height: 6),
                      Text(_wrap!.detail, style: T.sans(12, color: AppColors.gray)),
                      const SizedBox(height: 6),
                      GestureDetector(
                        onTap: () async {
                          final w = await Navigator.push<Wrapping?>(
                              context, MaterialPageRoute(builder: (_) => WrappingScreen(selected: _wrap)));
                          if (w != null) setLocal(() => _wrap = w);
                        },
                        child: Text('Choisir mon emballage →', style: T.sans(12, color: AppColors.magenta)),
                      ),
                    ]),
                  ),
                ]),
              ),
            const SizedBox(height: 22),
            SecondaryButton(fav ? 'Retirer de mes favoris' : 'Enregistrer dans mes favoris', onPressed: () async {
              if (!await ensureLoggedIn(context)) return;
              if (!context.mounted) return;
              try {
                final now = await SessionScope.read(context).toggleFavorite(gift);
                if (context.mounted) toast(context, now ? 'Ajouté à vos favoris.' : 'Retiré de vos favoris.');
              } on ApiException catch (e) {
                if (context.mounted) toast(context, e.message);
              }
            }),
          ]);
        }),
      ),
    );
  }
}
