import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class AccountScreen extends StatelessWidget {
  const AccountScreen({super.key});

  final List<_MenuItem> _items = const [
    _MenuItem(Icons.person_outline, 'Mon profil'),
    _MenuItem(Icons.list_outlined, 'Mes listes'),
    _MenuItem(Icons.history, 'Historique'),
    _MenuItem(Icons.favorite_outline, 'Favoris'),
    _MenuItem(Icons.help_outline, 'Aide / FAQ'),
    _MenuItem(Icons.contact_support, 'Contact'),
    _MenuItem(Icons.language, 'Langue : Français', subtitle: 'FR'),
    _MenuItem(Icons.privacy_tip_outlined, 'Confidentialité'),
    _MenuItem(Icons.logout, 'Déconnexion', color: AppColors.magenta),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mon compte', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          // Profil
          Container(
            padding: const EdgeInsets.all(20),
            color: AppColors.pinkBg,
            child: Row(
              children: [
                Container(
                  width: 52, height: 52,
                  decoration: BoxDecoration(color: AppColors.magenta, borderRadius: BorderRadius.circular(26)),
                  child: const Center(child: Text('AD', style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w600))),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Aïcha Diallo', style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                      const SizedBox(height: 4),
                      Text('aicha@exemple.com', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          Text("Bienvenue dans votre espace", style: const TextStyle(fontSize: 28, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
          const SizedBox(height: 22),
          // Menu compte
          Expanded(
            child: ListView.builder(
              itemCount: _items.length,
              itemBuilder: (context, i) {
                final item = _items[i];
                final isLast = i == _items.length - 1;
                return Container(
                  height: 56,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: isLast ? Colors.transparent : const Color(0xFFE9E1E5))),
                  ),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 0),
                    leading: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(
                        border: Border.all(color: (item.color ?? const Color(0xFF786C74)), width: 1.7),
                        borderRadius: BorderRadius.circular(50),
                      ),
                    ),
                    title: Row(
                      children: [
                        Expanded(child: Text(item.label,
                            style: TextStyle(fontSize: 14, color: item.color ?? const Color(0xFF30232C)))),
                        if (item.subtitle != null)
                          Text(item.subtitle!,
                              style: const TextStyle(fontSize: 10, color: Color(0xFF786C74))),
                        const Icon(Icons.chevron_right, size: 15, color: Color(0xFF30232C)),
                      ],
                    ),
                    onTap: item.label == 'Déconnexion'
                        ? () => Navigator.pushReplacementNamed(context, '/login')
                        : null,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 10),
          Center(child: Text('CADOTER — Vos belles attentions, simplement.',
              style: const TextStyle(fontSize: 11, color: Color(0xFF786C74)))),
        ],
      ),
    );
  }
}

class _MenuItem {
  final IconData icon;
  final String label;
  final String? subtitle;
  final Color? color;
  const _MenuItem(this.icon, this.label, {this.subtitle, this.color});
}
