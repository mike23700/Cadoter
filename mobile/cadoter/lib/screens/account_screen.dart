import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'auth_screens.dart';
import 'gift_screen.dart';
import 'language_screen.dart';

/// « Mobile · Compte et paramètres »
class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    final user = session.user;

    void push(Widget w) => Navigator.push(context, MaterialPageRoute(builder: (_) => w));
    void info(String title, String text) => showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(title, style: T.serif(22)),
            content: Text(text, style: T.sans(13)),
            actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );

    final rows = <(IconData, String, String?, VoidCallback)>[
      (Icons.person_outline, 'Mon profil', null, () => user == null ? ensureLoggedIn(context) : info('Mon profil', '${user.name}\n${user.email}\n${user.phone ?? ''}')),
      (Icons.format_list_bulleted, 'Mes listes', null, () => session.goTab(2)),
      (Icons.history, 'Mon historique', null, () async { if (await ensureLoggedIn(context) && context.mounted) push(const OrdersScreen()); }),
      (Icons.favorite_border, 'Mes favoris', null, () async { if (await ensureLoggedIn(context) && context.mounted) push(const FavoritesScreen()); }),
      (Icons.help_outline, 'FAQ', null, () => info('FAQ', 'Réserver un cadeau prévient les autres proches : ce n’est pas un achat. Le paiement se fait par Orange Money ou MTN Mobile Money, la facture est émise par la boutique.')),
      (Icons.mail_outline, 'Nous contacter', null, () => info('Nous contacter', 'contact@cadoter.com\nWhatsApp : +225 07 00 00 00 00')),
      (Icons.share_outlined, 'Nos réseaux sociaux', null, () => info('Nos réseaux sociaux', 'Instagram, Facebook et TikTok : @cadoter')),
      (Icons.language, 'Langue', session.language == 'fr' ? 'Français' : 'English', () => push(const LanguageScreen(fromSettings: true))),
      (Icons.verified_user_outlined, 'Politique', null, () => info('Politique de confidentialité', 'Nous collectons uniquement les données nécessaires à vos listes et commandes. Elles ne sont jamais revendues.')),
    ];

    return Scaffold(
      appBar: const TopBar('Mon compte', showBack: false),
      body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
        Panel(
          pink: true,
          child: user == null
              ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Bienvenue sur CADOTER', style: T.sans(16, weight: FontWeight.w600)),
                  const SizedBox(height: 14),
                  PrimaryButton('Se connecter', onPressed: () => ensureLoggedIn(context)),
                ])
              : Row(children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: AppColors.magenta,
                    child: Text(user.initials, style: T.sans(16, color: AppColors.white, weight: FontWeight.w600)),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(user.name, style: T.sans(18, weight: FontWeight.w600)),
                      const SizedBox(height: 4),
                      Text(user.email, style: T.sans(12, color: AppColors.gray)),
                    ]),
                  ),
                ]),
        ),
        const SizedBox(height: 30),
        Text('Votre espace, vos envies.', style: T.serif(26)),
        const SizedBox(height: 14),
        for (final r in rows) _Row(icon: r.$1, label: r.$2, extra: r.$3, onTap: r.$4),
        if (user != null)
          _Row(
            icon: Icons.logout,
            label: 'Se déconnecter',
            danger: true,
            onTap: () async {
              await session.logout();
              if (context.mounted) toast(context, 'À bientôt !');
            },
          ),
        const SizedBox(height: 28),
        Center(child: Text('CADOTER · Le bonheur d’offrir, tout simplement.', style: T.sans(11, color: AppColors.gray))),
      ]),
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.icon, required this.label, required this.onTap, this.extra, this.danger = false});
  final IconData icon;
  final String label;
  final String? extra;
  final VoidCallback onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) => InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 17),
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppColors.border))),
          child: Row(children: [
            Icon(icon, size: 21, color: danger ? AppColors.magenta : AppColors.dark),
            const SizedBox(width: 14),
            Expanded(child: Text(label, style: T.sans(14, color: danger ? AppColors.magenta : AppColors.dark))),
            if (extra != null) Text(extra!, style: T.sans(11, color: AppColors.gray)),
            const SizedBox(width: 10),
            const Icon(Icons.chevron_right, size: 20, color: AppColors.dark),
          ]),
        ),
      );
}

class FavoritesScreen extends StatelessWidget {
  const FavoritesScreen({super.key});

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('Mes favoris'),
        body: ApiBuilder<List<Gift>>(
          load: () async => ((await Api.instance.get('/favorites')) as List).map((e) => Gift.fromJson(e)).toList(),
          builder: (context, gifts, reload) => gifts.isEmpty
              ? const ErrorRetry('Aucun favori pour l’instant.')
              : GridView.builder(
                  padding: const EdgeInsets.all(kGutter),
                  itemCount: gifts.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 22, mainAxisExtent: 290),
                  itemBuilder: (_, i) => GiftTile(gifts[i], onTap: () async {
                    await Navigator.push(context, MaterialPageRoute(builder: (_) => GiftScreen(slug: gifts[i].slug)));
                    reload();
                  }),
                ),
        ),
      );
}

class OrdersScreen extends StatelessWidget {
  const OrdersScreen({super.key});

  static const _status = {'en_attente': 'En attente de paiement', 'payee': 'Payée', 'livree': 'Livrée', 'annulee': 'Annulée'};

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('Mon historique'),
        body: ApiBuilder<List<dynamic>>(
          load: () async => (await Api.instance.get('/orders/mine')) as List,
          builder: (context, orders, _) => orders.isEmpty
              ? const ErrorRetry('Aucune commande pour l’instant.')
              : ListView.separated(
                  padding: const EdgeInsets.all(kGutter),
                  itemCount: orders.length,
                  separatorBuilder: (_, _) => const Divider(color: AppColors.border),
                  itemBuilder: (_, i) {
                    final o = orders[i];
                    return ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text('${o['gift_name']} × ${o['quantity']}', style: T.sans(14, weight: FontWeight.w600)),
                      subtitle: Text('${o['reference']} · ${_status[o['status']] ?? o['status']}', style: T.sans(12, color: AppColors.gray)),
                      trailing: Text(formatPrice(o['total'] as int, o['currency'] ?? 'FCFA'),
                          style: T.sans(13, weight: FontWeight.w600, color: AppColors.magenta)),
                    );
                  },
                ),
        ),
      );
}
