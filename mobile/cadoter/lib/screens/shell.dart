import 'package:flutter/material.dart';

import '../core/session.dart';
import '../widgets/common.dart';
import 'account_screen.dart';
import 'assistant_screen.dart';
import 'catalogue_screen.dart';
import 'home_screen.dart';
import 'lists_screen.dart';

/// Conteneur principal à 5 onglets.
class Shell extends StatelessWidget {
  const Shell({super.key});

  @override
  Widget build(BuildContext context) {
    final tab = SessionScope.of(context).tab;
    return Scaffold(
      body: IndexedStack(index: tab, children: const [
        HomeScreen(),
        CatalogueScreen(),
        ListsScreen(),
        AssistantScreen(),
        AccountScreen(),
      ]),
      bottomNavigationBar: AppBottomNav(current: tab, inShell: true),
    );
  }
}
