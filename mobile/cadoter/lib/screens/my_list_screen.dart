import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'create_list_screen.dart';
import 'shared_list_screen.dart';

/// « Mobile · Liste éditable »
class MyListScreen extends StatefulWidget {
  const MyListScreen({super.key, required this.listId});
  final int listId;

  @override
  State<MyListScreen> createState() => _MyListScreenState();
}

class _MyListScreenState extends State<MyListScreen> {
  final _url = TextEditingController();
  GiftList? _list;
  Object? _error;
  bool _adding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final l = GiftList.fromJson(await Api.instance.get('/lists/${widget.listId}'));
      if (mounted) setState(() { _list = l; _error = null; });
    } catch (e) {
      if (mounted) setState(() => _error = e);
    }
  }

  Future<void> _addLink() async {
    var url = _url.text.trim();
    if (url.isEmpty) return;
    if (!url.startsWith('http')) url = 'https://$url';
    setState(() => _adding = true);
    try {
      await Api.instance.post('/lists/${widget.listId}/items', {'url': url});
      _url.clear();
      await _load();
      if (mounted) toast(context, 'Produit ajouté à votre liste.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.field('url') ?? e.message);
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }

  Future<void> _itemAction(ListItem item) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          if (!item.isAvailable) ListTile(leading: const Icon(Icons.undo), title: Text(tr('Remettre disponible')), onTap: () => Navigator.pop(ctx, 'Disponible')),
          if (item.status != 'Réservé') ListTile(leading: const Icon(Icons.bookmark_outline), title: Text(tr('Marquer réservé')), onTap: () => Navigator.pop(ctx, 'Réservé')),
          if (item.status != 'Indisponible') ListTile(leading: const Icon(Icons.block), title: Text(tr('Marquer indisponible')), onTap: () => Navigator.pop(ctx, 'Indisponible')),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: Text(tr('Retirer de la liste'), style: TextStyle(color: AppColors.error)),
            onTap: () => Navigator.pop(ctx, 'remove'),
          ),
        ]),
      ),
    );
    if (action == null) return;
    try {
      if (action == 'remove') {
        await Api.instance.delete('/lists/${widget.listId}/items/${item.id}');
      } else {
        await Api.instance.put('/lists/${widget.listId}/items/${item.id}', {'status': action});
      }
      await _load();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _more() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(leading: const Icon(Icons.visibility_outlined), title: Text(tr('Voir comme un proche')), onTap: () => Navigator.pop(ctx, 'view')),
          ListTile(
            leading: const Icon(Icons.delete_outline, color: AppColors.error),
            title: Text(tr('Supprimer la liste'), style: TextStyle(color: AppColors.error)),
            onTap: () => Navigator.pop(ctx, 'delete'),
          ),
        ]),
      ),
    );
    if (!mounted || _list == null) return;
    if (action == 'view') {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SharedListScreen(code: _list!.code, accessCode: _list!.accessCode)));
    } else if (action == 'delete') {
      final ok = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(tr('Supprimer cette liste ?')),
          content: Text(tr('« {title} » sera définitivement supprimée.', {'title': _list!.title})),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annuler'))),
            TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Supprimer'), style: TextStyle(color: AppColors.error))),
          ],
        ),
      );
      if (ok == true) {
        await Api.instance.delete('/lists/${_list!.id}');
        if (mounted) Navigator.pop(context);
      }
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.push<GiftList>(context, MaterialPageRoute(builder: (_) => CreateListScreen(list: _list)));
    if (updated != null) _load();
  }

  Future<void> _copy() async {
    await Clipboard.setData(ClipboardData(text: 'https://${_list!.shareUrl}'));
    if (mounted) toast(context, 'Lien copié ! Collez-le dans WhatsApp, SMS…');
  }

  @override
  Widget build(BuildContext context) {
    final l = _list;
    return Scaffold(
      appBar: TopBar('Ma liste', onMore: _more),
      bottomNavigationBar: const AppBottomNav(current: 2),
      body: l == null
          ? (_error != null ? ErrorRetry('$_error', onRetry: _load) : const Loader())
          : RefreshIndicator(
              color: AppColors.magenta,
              onRefresh: _load,
              child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 24), children: [
                NetImage(l.imageUrl, aspect: 354 / 155),
                const SizedBox(height: 26),
                Text(l.title, style: T.serif(32)),
                if (l.description != null) ...[
                  const SizedBox(height: 16),
                  Text(l.description!, style: T.sans(14, color: AppColors.gray)),
                ],
                const SizedBox(height: 22),
                Row(children: [
                  Expanded(child: SecondaryButton('Modifier', onPressed: _edit)),
                  const SizedBox(width: 12),
                  Expanded(child: PrimaryButton('Partager', icon: Icons.share_outlined, onPressed: _copy)),
                ]),
                const SizedBox(height: 26),
                const FieldLabel('Ajouter depuis un site marchand'),
                TextField(
                  controller: _url,
                  keyboardType: TextInputType.url,
                  style: T.sans(13),
                  decoration: InputDecoration(hintText: tr('https://boutique.exemple/produit')),
                ),
                const SizedBox(height: 12),
                Text(tr('Tous vos sites favoris, sans limitation de produits.'), style: T.sans(11, color: AppColors.gray)),
                const SizedBox(height: 16),
                _adding ? const Loader() : SecondaryButton('Ajouter ce lien', onPressed: _addLink),
                const SizedBox(height: 26),
                const IllustrativeNote(),
                const SizedBox(height: 12),
                if (l.items.isEmpty)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 24),
                    child: Text(tr('Votre liste est vide. Ajoutez un lien ou un cadeau du catalogue.'), style: T.sans(13, color: AppColors.gray)),
                  ),
                for (final item in l.items)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
                    child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NetImage(item.imageUrl, width: 80, height: 90, radius: 16),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 4),
                          Text(item.name, style: T.sans(14, weight: FontWeight.w600)),
                          if (item.sellerName != null) ...[
                            const SizedBox(height: 5),
                            Text('Vendu par ${item.sellerName}', style: T.sans(11, color: AppColors.gray)),
                          ],
                          const SizedBox(height: 6),
                          Text(formatPrice(item.price, item.currency), style: T.sans(12, color: AppColors.magenta)),
                          const SizedBox(height: 8),
                          StatusBadge(item.status == 'Réservé' ? tr('Réservé par {name}', {'name': item.reservedBy ?? tr('un proche')}) : item.status, ok: item.isAvailable),
                        ]),
                      ),
                      IconButton(icon: const Icon(Icons.more_vert), onPressed: () => _itemAction(item)),
                    ]),
                  ),
                const SizedBox(height: 26),
                const FieldLabel('Lien de partage'),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
                  child: Text(l.shareUrl, style: T.sans(13, color: AppColors.gray)),
                ),
                if (l.isLocked) ...[
                  const SizedBox(height: 8),
                  Text(tr('Protégée par le code {code}', {'code': l.accessCode}), style: T.sans(11, color: AppColors.gray)),
                ],
                const SizedBox(height: 18),
                PrimaryButton('Copier le lien', icon: Icons.copy, onPressed: _copy),
              ]),
            ),
    );
  }
}
