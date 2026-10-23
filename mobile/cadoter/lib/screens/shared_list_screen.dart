import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'order_screen.dart';

/// « Mobile · Liste partagée proche » : un proche choisit et réserve un cadeau.
class SharedListScreen extends StatefulWidget {
  const SharedListScreen({super.key, required this.code, this.accessCode});
  final String code;
  final String? accessCode;

  @override
  State<SharedListScreen> createState() => _SharedListScreenState();
}

class _SharedListScreenState extends State<SharedListScreen> {
  late String? _accessCode = widget.accessCode;
  GiftList? _list;
  String? _lockedTitle;
  Object? _error;
  int? _reserving;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Map<String, String> get _headers => _accessCode != null && _accessCode!.isNotEmpty ? {'X-Access-Code': _accessCode!} : {};

  Future<void> _load() async {
    try {
      final l = GiftList.fromJson(await Api.instance.get('/l/${Uri.encodeComponent(widget.code)}', headers: _headers));
      setState(() { _list = l; _lockedTitle = null; _error = null; });
    } on ApiException catch (e) {
      setState(() {
        if (e.status == 423) {
          _lockedTitle = (e.data is Map ? e.data['title'] : null) ?? tr('Liste protégée');
        } else {
          _error = e.status == 404 ? tr('Cette liste n’existe pas ou a été supprimée.') : e;
        }
      });
    }
  }

  Future<void> _askCode() async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_lockedTitle ?? tr('Liste protégée'), style: T.serif(22)),
        content: TextField(controller: ctrl, autofocus: true, decoration: InputDecoration(hintText: tr('Code d’accès'))),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(tr('Ouvrir')))],
      ),
    );
    if (code == null || code.isEmpty) return;
    _accessCode = code;
    await _load();
    if (_lockedTitle != null && mounted) toast(context, 'Code incorrect.');
  }

  Future<void> _reserve(ListItem item) async {
    final session = SessionScope.read(context);
    final ctrl = TextEditingController(text: session.user?.firstName);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(tr('Je réserve ce cadeau'), style: T.serif(22)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(tr('Les autres proches verront que « {name} » est déjà choisi.', {'name': item.name}), style: T.sans(13, color: AppColors.gray)),
          const SizedBox(height: 14),
          TextField(controller: ctrl, decoration: InputDecoration(hintText: tr('Votre prénom'))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(tr('Annuler'))),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text.trim()), child: Text(tr('Réserver'))),
        ],
      ),
    );
    if (name == null) return;
    setState(() => _reserving = item.id);
    try {
      await Api.instance.post('/l/${Uri.encodeComponent(widget.code)}/items/${item.id}/reserve',
          {'name': name.isEmpty ? null : name, 'access_code': _accessCode});
      if (mounted) toast(context, 'Merci ! Ce cadeau vous est réservé.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _reserving = null);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = _list;
    final first = l?.ownerName?.split(' ').first ?? tr('votre proche');
    return Scaffold(
      appBar: TopBar(l != null ? tr('La liste d’{name}', {'name': first}) : 'Liste partagée'),
      body: _lockedTitle != null
          ? Padding(
              padding: const EdgeInsets.all(kGutter),
              child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                const Icon(Icons.lock_outline, color: AppColors.magenta, size: 36),
                const SizedBox(height: 16),
                Text(_lockedTitle!, style: T.serif(28), textAlign: TextAlign.center),
                const SizedBox(height: 12),
                Text(tr('Cette liste est protégée par un code d’accès.'), style: T.sans(13, color: AppColors.gray)),
                const SizedBox(height: 22),
                PrimaryButton('Saisir le code', onPressed: _askCode),
              ]),
            )
          : l == null
              ? (_error != null ? ErrorRetry('$_error', onRetry: _load) : const Loader())
              : ListView(padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 28), children: [
                  NetImage(l.imageUrl, aspect: 354 / 175),
                  const SizedBox(height: 30),
                  Text(tr('Les envies d’{name}', {'name': first}), style: T.serif(32)),
                  if (l.description != null) ...[
                    const SizedBox(height: 16),
                    Text('« ${l.description} »', style: T.sans(14, color: AppColors.gray)),
                  ],
                  const SizedBox(height: 22),
                  Panel(
                    padding: const EdgeInsets.all(16),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(tr('Choisissez une attention.'), style: T.sans(14, weight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      Text(tr('Réserver prévient les autres proches. Cela ne vaut pas achat : vous achetez ensuite auprès du marchand.'),
                          style: T.sans(12)),
                    ]),
                  ),
                  const SizedBox(height: 22),
                  const IllustrativeNote(),
                  const SizedBox(height: 10),
                  for (final item in l.items) ...[
                    const SizedBox(height: 16),
                    Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      NetImage(item.imageUrl, width: 92, height: 104, radius: 16),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          const SizedBox(height: 4),
                          Text(item.name, style: T.sans(14, weight: FontWeight.w600)),
                          const SizedBox(height: 8),
                          Text(formatPrice(item.price, item.currency), style: T.sans(13, color: AppColors.magenta)),
                          const SizedBox(height: 10),
                          StatusBadge(item.isAvailable ? 'Disponible à réserver' : 'Réservé · indisponible', ok: item.isAvailable),
                        ]),
                      ),
                    ]),
                    const SizedBox(height: 14),
                    if (item.isAvailable) ...[
                      PrimaryButton('Je réserve ce cadeau', loading: _reserving == item.id, onPressed: () => _reserve(item)),
                      if (item.giftSlug != null)
                        TextButton(
                          onPressed: () async {
                            final gift = Gift.fromJson(await Api.instance.get('/gifts/${item.giftSlug}'));
                            if (!context.mounted) return;
                            final done = await Navigator.push<bool>(
                                context, MaterialPageRoute(builder: (_) => OrderScreen(gift: gift, listItemId: item.id)));
                            if (done == true) _load();
                          },
                          child: Text(tr('ou l’offrir directement →'), style: T.sans(12, color: AppColors.magenta)),
                        ),
                    ] else
                      Text(tr('Un proche a déjà choisi ce cadeau.'), style: T.sans(12, color: AppColors.gray)),
                    const SizedBox(height: 10),
                  ],
                  if (l.items.isEmpty) Text(tr('{name} n’a pas encore ajouté de cadeau.', {'name': first}), style: T.sans(13, color: AppColors.gray)),
                ]),
    );
  }
}
