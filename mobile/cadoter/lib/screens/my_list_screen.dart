import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

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

  Future<void> _chooseCatalogGift() async {
    try {
      final response = await Api.instance.get('/gifts?limit=100');
      final gifts = (response as List)
          .map((item) => Gift.fromJson(Map<String, dynamic>.from(item as Map)))
          .where((gift) => gift.available)
          .toList();
      if (!mounted) return;
      if (gifts.isEmpty) {
        toast(context, 'Aucun cadeau disponible pour le moment.');
        return;
      }

      final addedIds = _list?.items.map((item) => item.giftId).whereType<int>().toSet() ?? <int>{};
      final search = TextEditingController();
      int? addingId;
      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        builder: (_) => StatefulBuilder(
          builder: (ctx, setSheetState) {
            final query = search.text.trim().toLowerCase();
            final visible = gifts.where((gift) => query.isEmpty || gift.name.toLowerCase().contains(query) || (gift.description?.toLowerCase().contains(query) ?? false)).toList();
            return SizedBox(
              height: MediaQuery.of(ctx).size.height * .82,
              child: Padding(
                padding: EdgeInsets.fromLTRB(20, 16, 20, 12 + MediaQuery.of(ctx).viewInsets.bottom),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Expanded(child: Text(tr('Choisir un cadeau'), style: T.serif(24))),
                    IconButton(onPressed: () => Navigator.pop(ctx), icon: const Icon(Icons.close)),
                  ]),
                  const SizedBox(height: 12),
                  TextField(
                    controller: search,
                    decoration: InputDecoration(prefixIcon: const Icon(Icons.search), hintText: tr('Rechercher un cadeau')),
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: visible.isEmpty
                        ? Center(child: Text(tr('Aucun cadeau ne correspond à cette recherche.'), style: T.sans(13, color: AppColors.gray)))
                        : ListView.separated(
                            itemCount: visible.length,
                            separatorBuilder: (_, __) => const Divider(height: 1),
                            itemBuilder: (ctx, index) {
                              final gift = visible[index];
                              final added = addedIds.contains(gift.id);
                              return ListTile(
                                contentPadding: const EdgeInsets.symmetric(vertical: 5),
                                leading: NetImage(gift.imageUrl, width: 58, height: 58, radius: 12),
                                title: Text(gift.name, maxLines: 2, overflow: TextOverflow.ellipsis, style: T.sans(13, weight: FontWeight.w600)),
                                subtitle: Text('${gift.sellerName} · ${formatPrice(gift.price, gift.currency)}', style: T.sans(11, color: AppColors.gray)),
                                trailing: added
                                    ? Text(tr('Déjà ajouté'), style: T.sans(11, color: AppColors.gray))
                                    : TextButton(
                                        onPressed: addingId != null ? null : () async {
                                          setSheetState(() => addingId = gift.id);
                                          try {
                                            await Api.instance.post('/lists/${widget.listId}/items', {'gift_id': gift.id});
                                            addedIds.add(gift.id);
                                            await _load();
                                            if (mounted) toast(context, 'Cadeau ajouté à votre liste.');
                                          } on ApiException catch (e) {
                                            if (mounted) toast(context, e.message);
                                          } finally {
                                            if (ctx.mounted) setSheetState(() => addingId = null);
                                          }
                                        },
                                        child: Text(addingId == gift.id ? tr('Ajout…') : tr('Ajouter')),
                                      ),
                              );
                            },
                          ),
                  ),
                ]),
              ),
            );
          },
        ),
      );
      search.dispose();
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    }
  }

  Future<void> _addManualGift() async {
    final name = TextEditingController();
    final description = TextEditingController();
    final price = TextEditingController();
    final sellerName = TextEditingController();
    File? image;
    String? error;
    bool busy = false;

    final added = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          title: Text(tr('Ajouter un cadeau manuellement'), style: T.serif(22)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              TextField(controller: name, maxLength: 190, decoration: InputDecoration(labelText: tr('Nom du cadeau *'))),
              const SizedBox(height: 12),
              TextField(controller: description, maxLength: 2000, maxLines: 4, decoration: InputDecoration(labelText: tr('Description *'), alignLabelWithHint: true)),
              const SizedBox(height: 12),
              TextField(
                controller: price,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: InputDecoration(labelText: tr('Prix approximatif (FCFA) *')),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: sellerName,
                maxLength: 190,
                decoration: InputDecoration(labelText: tr('Lieu / boutique où le cadeau est commercialisé *')),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: busy ? null : () async {
                  final picked = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
                  if (picked == null) return;
                  if (!ctx.mounted) return;
                  final file = File(picked.path);
                  if (await file.length() > 5 * 1024 * 1024) {
                    setDialogState(() => error = tr('La photo ne doit pas dépasser 5 Mo.'));
                    return;
                  }
                  setDialogState(() { image = file; error = null; });
                },
                icon: const Icon(Icons.add_photo_alternate_outlined),
                label: Text(image == null ? tr('Ajouter une photo') : tr('Changer la photo')),
              ),
              if (image != null) ...[
                const SizedBox(height: 10),
                ClipRRect(borderRadius: BorderRadius.circular(12), child: Image.file(image!, height: 150, width: double.infinity, fit: BoxFit.cover)),
              ],
              if (error != null) ...[
                const SizedBox(height: 8),
                Text(error!, style: T.sans(12, color: AppColors.error)),
              ],
            ]),
          ),
          actions: [
            TextButton(onPressed: busy ? null : () => Navigator.pop(ctx, false), child: Text(tr('Annuler'))),
            TextButton(
              onPressed: busy ? null : () async {
                final approximatePrice = int.tryParse(price.text.trim());
                if (name.text.trim().isEmpty || description.text.trim().isEmpty || approximatePrice == null || sellerName.text.trim().isEmpty || image == null) {
                  setDialogState(() => error = tr('Renseignez le nom, la description, le prix, le lieu/boutique et la photo.'));
                  return;
                }
                setDialogState(() { busy = true; error = null; });
                try {
                  await Api.instance.multipart('/lists/${widget.listId}/items/manual', {
                    'name': name.text.trim(),
                    'description': description.text.trim(),
                    'price': '$approximatePrice',
                    'seller_name': sellerName.text.trim(),
                  }, file: image);
                  if (ctx.mounted) Navigator.pop(ctx, true);
                } on ApiException catch (e) {
                  if (ctx.mounted) setDialogState(() { error = e.errors.values.firstOrNull?.first ?? e.message; busy = false; });
                }
              },
              child: busy ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : Text(tr('Ajouter')),
            ),
          ],
        ),
      ),
    );
    name.dispose();
    description.dispose();
    price.dispose();
    sellerName.dispose();
    if (added == true) {
      await _load();
      if (mounted) toast(context, 'Cadeau ajouté à votre liste.');
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
                const FieldLabel('Ajouter un cadeau à votre liste'),
                Row(children: [
                  Expanded(child: SecondaryButton('Choisir dans le catalogue', onPressed: _chooseCatalogGift)),
                  const SizedBox(width: 12),
                  Expanded(child: PrimaryButton('Ajouter manuellement', onPressed: _addManualGift)),
                ]),
                const SizedBox(height: 24),
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
                            Text(
                              item.giftId == null && item.externalUrl == null
                                  ? tr('Lieu / boutique : {name}', {'name': item.sellerName!})
                                  : tr('Vendu par {name}', {'name': item.sellerName!}),
                              style: T.sans(11, color: AppColors.gray),
                            ),
                          ],
                          if (item.description != null) ...[
                            const SizedBox(height: 6),
                            Text(item.description!, style: T.sans(12, color: AppColors.gray)),
                          ],
                          if (item.price != null) ...[
                            const SizedBox(height: 6),
                            Text(formatPrice(item.price, item.currency), style: T.sans(12, color: AppColors.magenta)),
                          ],
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
