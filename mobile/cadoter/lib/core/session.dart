import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'api.dart';

/// État global : utilisateur connecté, métadonnées du catalogue, favoris, onglet actif, langue.
class Session extends ChangeNotifier {
  final api = Api.instance;
  User? user;
  Meta meta = Meta.fallback;
  Set<int> favorites = {};
  int tab = 0;
  String language = 'fr';
  bool onboarded = false;

  bool get isLoggedIn => user != null;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    language = prefs.getString('language') ?? 'fr';
    onboarded = prefs.getBool('onboarded') ?? false;
    await api.loadToken();
    await Future.wait([_loadMeta(), if (api.hasToken) _loadUser()]);
  }

  Future<void> _loadMeta() async {
    try {
      meta = Meta.fromJson(await api.get('/meta'));
      notifyListeners();
    } catch (_) {/* hors ligne : valeurs par défaut */}
  }

  Future<void> _loadUser() async {
    try {
      user = User.fromJson(await api.get('/me'));
      await loadFavorites();
    } catch (_) {
      user = null;
    }
    notifyListeners();
  }

  Future<void> loadFavorites() async {
    try {
      final list = await api.get('/favorites') as List;
      favorites = list.map((g) => g['id'] as int).toSet();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> setLanguage(String lang) async {
    language = lang;
    (await SharedPreferences.getInstance()).setString('language', lang);
    notifyListeners();
  }

  Future<void> setOnboarded() async {
    onboarded = true;
    (await SharedPreferences.getInstance()).setBool('onboarded', true);
  }

  Future<void> _start(dynamic res) async {
    await api.setToken(res['token'] as String);
    user = User.fromJson(res['user']);
    await setOnboarded();
    await loadFavorites();
    notifyListeners();
  }

  /// Connexion par email ou téléphone.
  Future<void> login(String login, String password) async =>
      _start(await api.post('/login', {'login': login, 'password': password}));

  Future<void> register(Map<String, dynamic> data) async => _start(await api.post('/register', data));

  Future<void> logout() async {
    try {
      await api.post('/logout');
    } catch (_) {}
    await api.setToken(null);
    user = null;
    favorites = {};
    tab = 0;
    notifyListeners();
  }

  Future<bool> toggleFavorite(Gift gift) async {
    final res = await api.post('/favorites/${gift.id}');
    final fav = res['favorite'] == true;
    fav ? favorites.add(gift.id) : favorites.remove(gift.id);
    notifyListeners();
    return fav;
  }

  void goTab(int i) {
    tab = i;
    notifyListeners();
  }
}

class SessionScope extends InheritedNotifier<Session> {
  const SessionScope({super.key, required Session session, required super.child}) : super(notifier: session);

  static Session of(BuildContext context) => context.dependOnInheritedWidgetOfExactType<SessionScope>()!.notifier!;

  /// Lecture sans abonnement aux changements (dans les callbacks).
  static Session read(BuildContext context) =>
      (context.getElementForInheritedWidgetOfExactType<SessionScope>()!.widget as SessionScope).notifier!;
}
