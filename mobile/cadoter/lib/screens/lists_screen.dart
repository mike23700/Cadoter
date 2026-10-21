import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';
import 'create_list_screen.dart';
import 'my_list_screen.dart';
import 'shared_list_screen.dart';

/// « Mobile · Mes listes »
class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  Future<List<GiftList>>? _future;
  int? _userId;

  Future<List<GiftList>> _load() async =>
      ((await Api.instance.get('/lists')) as List).map((e) => GiftList.fromJson(e)).toList();

  Future<void> _reload() async {
    final f = _load();
    setState(() => _future = f);
    await f.catchError((_) => <GiftList>[]);
  }

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    // Recharge à la connexion / changement de compte
    if (session.user?.id != _userId) {
      _userId = session.user?.id;
      _future = session.isLoggedIn ? _load() : null;
    }

    return Scaffold(
      appBar: TopBar('Mes listes', showBack: false, onMore: () => _openByCode(context)),
      body: RefreshIndicator(
        color: AppColors.magenta,
        onRefresh: session.isLoggedIn ? _reload : () async {},
        child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
          Text('Vos envies méritent d’être partagées.', style: T.serif(32)),
          const SizedBox(height: 22),
          Panel(
            child: Column(children: [
              _step(Icons.format_list_bulleted, 'Je crée ma liste'),
              _step(Icons.link, 'J’ajoute des produits'),
              _step(Icons.send_outlined, 'Je partage ma liste', last: true),
            ]),
          ),
          const SizedBox(height: 22),
          Text('Tous vos sites marchands favoris, sans limite. Vos proches réservent pour éviter les doublons.',
              style: T.sans(14, color: AppColors.gray)),
          const SizedBox(height: 22),
          PrimaryButton('Créer une liste', icon: Icons.add, onPressed: () async {
            if (!await ensureLoggedIn(context) || !context.mounted) return;
            final created = await Navigator.push<GiftList>(context, MaterialPageRoute(builder: (_) => const CreateListScreen()));
            if (created != null && context.mounted) {
              await _reload();
              if (context.mounted) Navigator.push(context, MaterialPageRoute(builder: (_) => MyListScreen(listId: created.id)));
            }
          }),
          const SizedBox(height: 22),
          if (!session.isLoggedIn)
            Panel(
              pink: true,
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Connectez-vous pour retrouver vos listes.', style: T.sans(14, weight: FontWeight.w600)),
                const SizedBox(height: 14),
                SecondaryButton('Se connecter', onPressed: () => ensureLoggedIn(context)),
              ]),
            )
          else
            FutureBuilder<List<GiftList>>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) return const Loader();
                if (snap.hasError) return ErrorRetry('${snap.error}', onRetry: _reload);
                final lists = snap.data!;
                if (lists.isEmpty) {
                  return Text('Vous n’avez pas encore de liste.', style: T.sans(13, color: AppColors.gray));
                }
                return Column(children: [for (final l in lists) _ListCard(list: l, onChanged: _reload)]);
              },
            ),
          const SizedBox(height: 18),
          Text('Un mariage, une naissance, une dot… ou une liste de soutien à un proche.', style: T.sans(12, color: AppColors.gray)),
        ]),
      ),
    );
  }

  Widget _step(IconData icon, String label, {bool last = false}) => Padding(
        padding: EdgeInsets.only(bottom: last ? 0 : 18),
        child: Row(children: [
          Icon(icon, color: AppColors.magenta, size: 22),
          const SizedBox(width: 14),
          Text(label, style: T.sans(14, weight: FontWeight.w600)),
        ]),
      );

  /// Ouvrir la liste d'un proche à partir de son lien ou de son code.
  Future<void> _openByCode(BuildContext context) async {
    final ctrl = TextEditingController();
    final code = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Ouvrir la liste d’un proche', style: T.serif(22)),
        content: TextField(controller: ctrl, decoration: const InputDecoration(hintText: 'cadoter.com/l/aicha-anniversaire')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          TextButton(onPressed: () => Navigator.pop(ctx, ctrl.text), child: const Text('Ouvrir')),
        ],
      ),
    );
    final c = code?.trim().split('/').where((s) => s.isNotEmpty).lastOrNull;
    if (c != null && context.mounted) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => SharedListScreen(code: c)));
    }
  }
}

class _ListCard extends StatelessWidget {
  const _ListCard({required this.list, required this.onChanged});
  final GiftList list;
  final Future<void> Function() onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 28),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetImage(list.imageUrl, aspect: 354 / 190),
          const SizedBox(height: 22),
          Text(list.title, style: T.serif(26)),
          const SizedBox(height: 14),
          Text('${formatDate(list.eventDate ?? list.createdAt)} · ${list.total} cadeau${list.total > 1 ? 'x' : ''} · ${list.reserved} réservé${list.reserved > 1 ? 's' : ''}',
              style: T.sans(13, color: AppColors.gray)),
          const SizedBox(height: 14),
          StatusBadge(list.isLocked ? 'Lien protégé' : 'Lien partagé'),
          const SizedBox(height: 18),
          SecondaryButton('Gérer ma liste', onPressed: () async {
            await Navigator.push(context, MaterialPageRoute(builder: (_) => MyListScreen(listId: list.id)));
            onChanged();
          }),
        ]),
      );
}
