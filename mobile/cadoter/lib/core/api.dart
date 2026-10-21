import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

/// URL de l'API Laravel. Surcharge : `flutter run --dart-define=API_URL=http://192.168.1.10:8001/api`
/// Par défaut : 10.0.2.2 = machine hôte vue depuis l'émulateur Android.
String get apiUrl {
  const fromEnv = String.fromEnvironment('API_URL');
  if (fromEnv.isNotEmpty) return fromEnv;
  if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8001/api';
  return 'http://localhost:8001/api';
}

/// Les URL d'images renvoyées par l'API pointent sur localhost : on les réécrit vers l'hôte de l'API.
String? fixUrl(String? url) {
  if (url == null) return null;
  final api = Uri.parse(apiUrl);
  final u = Uri.tryParse(url);
  if (u == null || (u.host != 'localhost' && u.host != '127.0.0.1')) return url;
  return u.replace(host: api.host, port: api.port).toString();
}

class ApiException implements Exception {
  ApiException(this.message, {this.status = 0, this.errors = const {}, this.data});
  final String message;
  final int status;
  final Map<String, List<String>> errors;
  final dynamic data;

  String? field(String name) => errors[name]?.first;

  @override
  String toString() => message;
}

class Api {
  Api._();
  static final instance = Api._();
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'cadoter_token';
  String? _token;

  Future<String?> loadToken() async => _token = await _storage.read(key: _tokenKey);

  Future<void> setToken(String? token) async {
    _token = token;
    token == null ? await _storage.delete(key: _tokenKey) : await _storage.write(key: _tokenKey, value: token);
  }

  bool get hasToken => _token != null;

  Map<String, String> _headers([Map<String, String>? extra]) => {
        'Accept': 'application/json',
        if (_token != null) 'Authorization': 'Bearer $_token',
        ...?extra,
      };

  Future<dynamic> get(String path, {Map<String, String>? headers}) =>
      _send(() => http.get(Uri.parse('$apiUrl$path'), headers: _headers(headers)));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send(() => http.post(
        Uri.parse('$apiUrl$path'),
        headers: _headers({'Content-Type': 'application/json'}),
        body: jsonEncode(body ?? {}),
      ));

  Future<dynamic> put(String path, Map<String, dynamic> body) => _send(() => http.put(
        Uri.parse('$apiUrl$path'),
        headers: _headers({'Content-Type': 'application/json'}),
        body: jsonEncode(body),
      ));

  Future<dynamic> delete(String path) => _send(() => http.delete(Uri.parse('$apiUrl$path'), headers: _headers()));

  /// Envoi multipart (création de liste avec image).
  Future<dynamic> multipart(String path, Map<String, String> fields, {File? file, String fileField = 'image'}) =>
      _send(() async {
        final req = http.MultipartRequest('POST', Uri.parse('$apiUrl$path'))
          ..headers.addAll(_headers())
          ..fields.addAll(fields);
        if (file != null) req.files.add(await http.MultipartFile.fromPath(fileField, file.path));
        return http.Response.fromStream(await req.send());
      });

  Future<dynamic> _send(Future<http.Response> Function() call) async {
    http.Response res;
    try {
      res = await call().timeout(const Duration(seconds: 20));
    } catch (_) {
      throw ApiException('Impossible de joindre le serveur. Vérifiez votre connexion.');
    }
    if (res.statusCode == 204) return null;
    dynamic data;
    try {
      data = jsonDecode(utf8.decode(res.bodyBytes));
    } catch (_) {
      data = null;
    }
    if (res.statusCode >= 400) {
      if (res.statusCode == 401) await setToken(null);
      final errors = <String, List<String>>{};
      if (data is Map && data['errors'] is Map) {
        (data['errors'] as Map).forEach((k, v) => errors['$k'] = List<String>.from(v as List));
      }
      throw ApiException(
        data is Map && data['message'] is String ? data['message'] as String : 'Une erreur est survenue.',
        status: res.statusCode,
        errors: errors,
        data: data,
      );
    }
    return data;
  }
}

// ---------------------------------------------------------------- Modèles

int? _int(dynamic v) => v == null ? null : (v is int ? v : int.tryParse('$v'));

class User {
  User({required this.id, required this.name, required this.email, this.phone, required this.role});
  final int id;
  final String name;
  final String email;
  final String? phone;
  final String role;

  String get firstName => name.split(' ').first;
  String get initials => name.trim().split(RegExp(r'\s+')).take(2).map((p) => p[0].toUpperCase()).join();

  factory User.fromJson(Map<String, dynamic> j) =>
      User(id: j['id'], name: j['name'], email: j['email'], phone: j['phone'], role: j['role'] ?? 'user');
}

class Gift {
  Gift({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
    required this.price,
    required this.currency,
    required this.city,
    this.area,
    this.imageUrl,
    required this.available,
    this.forWho = const [],
    this.occasions = const [],
  });
  final int id;
  final String name;
  final String slug;
  final String? description;
  final int price;
  final String currency;
  final String city;
  final String? area;
  final String? imageUrl;
  final bool available;
  final List<String> forWho;
  final List<String> occasions;

  String get place => [city, area].whereType<String>().where((s) => s.isNotEmpty).join(' · ');

  factory Gift.fromJson(Map<String, dynamic> j) => Gift(
        id: j['id'],
        name: j['name'],
        slug: j['slug'],
        description: j['description'],
        price: _int(j['price']) ?? 0,
        currency: j['currency'] ?? 'FCFA',
        city: j['city'] ?? '',
        area: j['area'],
        imageUrl: fixUrl(j['image_url']),
        available: j['available'] ?? true,
        forWho: List<String>.from(j['for_who'] ?? const []),
        occasions: List<String>.from(j['occasions'] ?? const []),
      );
}

class ListItem {
  ListItem({
    required this.id,
    required this.status,
    this.giftId,
    this.giftSlug,
    required this.name,
    this.price,
    required this.currency,
    this.city,
    this.area,
    this.imageUrl,
    this.externalUrl,
    this.reservedBy,
  });
  final int id;
  final String status;
  final int? giftId;
  final String? giftSlug;
  final String name;
  final int? price;
  final String currency;
  final String? city;
  final String? area;
  final String? imageUrl;
  final String? externalUrl;
  final String? reservedBy;

  bool get isAvailable => status == 'Disponible';

  factory ListItem.fromJson(Map<String, dynamic> j) => ListItem(
        id: j['id'],
        status: j['status'],
        giftId: j['gift_id'],
        giftSlug: j['gift_slug'],
        name: j['name'] ?? 'Produit',
        price: _int(j['price']),
        currency: j['currency'] ?? 'FCFA',
        city: j['city'],
        area: j['area'],
        imageUrl: fixUrl(j['image_url']),
        externalUrl: j['external_url'],
        reservedBy: j['reserved_by_name'],
      );
}

class GiftList {
  GiftList({
    required this.id,
    required this.code,
    required this.title,
    this.description,
    required this.occasion,
    this.imageUrl,
    this.eventDate,
    required this.createdAt,
    required this.isLocked,
    this.accessCode,
    this.ownerName,
    required this.items,
    required this.total,
    required this.reserved,
    required this.available,
  });
  final int id;
  final String code;
  final String title;
  final String? description;
  final String occasion;
  final String? imageUrl;
  final DateTime? eventDate;
  final DateTime createdAt;
  final bool isLocked;
  final String? accessCode;
  final String? ownerName;
  final List<ListItem> items;
  final int total;
  final int reserved;
  final int available;

  /// Lien public à partager (domaine de production).
  String get shareUrl => 'cadoter.com/l/$code';

  factory GiftList.fromJson(Map<String, dynamic> j) {
    final counts = (j['counts'] ?? {}) as Map;
    return GiftList(
      id: j['id'],
      code: j['code'],
      title: j['title'],
      description: j['description'],
      occasion: j['occasion'] ?? '',
      imageUrl: fixUrl(j['image_url']),
      eventDate: j['event_date'] != null ? DateTime.tryParse(j['event_date']) : null,
      createdAt: DateTime.tryParse(j['created_at'] ?? '') ?? DateTime.now(),
      isLocked: j['is_locked'] ?? false,
      accessCode: j['access_code'],
      ownerName: j['owner_name'],
      items: (j['items'] as List? ?? []).map((e) => ListItem.fromJson(e)).toList(),
      total: _int(counts['total']) ?? 0,
      reserved: _int(counts['reserved']) ?? 0,
      available: _int(counts['available']) ?? 0,
    );
  }
}

class Wrapping {
  Wrapping({required this.id, required this.name, required this.detail, this.imageUrl, this.price = 0});
  final int id;
  final String name;
  final String detail;
  final String? imageUrl;
  final int price;

  factory Wrapping.fromJson(Map<String, dynamic> j) => Wrapping(
      id: j['id'], name: j['name'], detail: j['detail'] ?? '', imageUrl: fixUrl(j['image_url']), price: _int(j['price']) ?? 0);
}

class Meta {
  Meta({required this.occasions, required this.forWho, required this.cities, required this.wrappings});
  final List<String> occasions;
  final List<String> forWho;
  final List<String> cities;
  final List<Wrapping> wrappings;

  static final fallback = Meta(
    occasions: const ['Anniversaire', 'Mariage', 'Naissance', 'Dot', 'Décès · Soutenir un proche', 'Autre'],
    forWho: const ['Enfants', 'Parents', 'Couple', 'Ami(e)s', 'Collègue', 'Famille'],
    cities: const ['Abidjan'],
    wrappings: const [],
  );

  factory Meta.fromJson(Map<String, dynamic> j) => Meta(
        occasions: List<String>.from(j['occasions'] ?? const []),
        forWho: List<String>.from(j['for_who'] ?? const []),
        cities: List<String>.from(j['cities'] ?? const []),
        wrappings: (j['wrappings'] as List? ?? []).map((e) => Wrapping.fromJson(e)).toList(),
      );
}

class Suggestion {
  Suggestion(this.gift, this.reason);
  final Gift gift;
  final String reason;
}

// ---------------------------------------------------------------- Formats

String formatPrice(int? n, [String currency = 'FCFA']) {
  if (n == null) return 'Prix à confirmer';
  final s = n.toString().replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (_) => ' ');
  return '$s $currency';
}

const _months = ['janvier', 'février', 'mars', 'avril', 'mai', 'juin', 'juillet', 'août', 'septembre', 'octobre', 'novembre', 'décembre'];
String formatDate(DateTime d) => '${d.day} ${_months[d.month - 1]}';
