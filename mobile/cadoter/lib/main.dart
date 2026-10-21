import 'package:flutter/material.dart';
import 'package:cadoter/theme/app_theme.dart';
import 'package:cadoter/screens/splash_screen.dart';
import 'package:cadoter/screens/home_screen.dart';
import 'package:cadoter/screens/catalogue_screen.dart';
import 'package:cadoter/screens/gift_detail_screen.dart';
import 'package:cadoter/screens/lists_screen.dart';
import 'package:cadoter/screens/account_screen.dart';
import 'package:cadoter/screens/login_screen.dart';
import 'package:cadoter/screens/signup_screen.dart';
import 'package:cadoter/screens/language_screen.dart';
import 'package:cadoter/screens/onboarding_screen.dart';
import 'package:cadoter/screens/assistant_screen.dart';
import 'package:cadoter/screens/custom_gift_screen.dart';
import 'package:cadoter/screens/wrapping_screen.dart';
import 'package:cadoter/screens/blog_screen.dart';
import 'models/gift.dart';

void main() {
  runApp(const CadotterApp());
}

class CadotterApp extends StatelessWidget {
  const CadotterApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'CADOTER',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/login': (context) => const LoginScreen(),
        '/signup': (context) => const SignupScreen(),
        '/language': (context) => const LanguageScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => const HomeScreen(),
        '/catalogue': (context) => const CatalogueScreen(),
        '/lists': (context) => const ListsScreen(),
        '/account': (context) => const AccountScreen(),
        '/assistant': (context) => const AssistantScreen(),
        '/custom-gift': (context) => const CustomGiftScreen(),
        '/wrapping': (context) => const WrappingScreen(),
        '/blog': (context) => const BlogScreen(),
      },
      onGenerateRoute: (settings) {
        if (settings.name == '/gift') {
          final gift = settings.arguments as Gift;
          return MaterialPageRoute(
            builder: (context) => GiftDetailScreen(gift: gift),
          );
        }
        return null;
      },
    );
  }
}

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _selectedIndex = 0;

  final List<Widget> _pages = const [
    HomeScreen(),
    CatalogueScreen(),
    ListsScreen(),
    AssistantScreen(),
    AccountScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (i) => setState(() => _selectedIndex = i),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: AppColors.magenta,
        unselectedItemColor: AppColors.gray,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Accueil'),
          BottomNavigationBarItem(icon: Icon(Icons.card_giftcard), label: 'Cadeaux'),
          BottomNavigationBarItem(icon: Icon(Icons.list), label: 'Listes'),
          BottomNavigationBarItem(icon: Icon(Icons.auto_stories), label: 'Assistante'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Compte'),
        ],
      ),
    );
  }
}
