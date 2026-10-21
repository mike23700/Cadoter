class Gift {
  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String currency;
  final String country;
  final String city;
  final String shop;
  final String category;
  final String forWho;
  final List<String> occasions;
  final String status; // Disponible / Réservé / Indisponible
  final bool external;
  final String? externalUrl;

  Gift({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.currency,
    required this.country,
    required this.city,
    required this.shop,
    required this.category,
    required this.forWho,
    required this.occasions,
    this.status = 'Disponible',
    this.external = false,
    this.externalUrl,
  });

  factory Gift.fromJson(Map<String, dynamic> json) => Gift(
        id: json['id'] as String,
        name: json['name'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String,
        price: (json['price'] as num).toDouble(),
        currency: json['currency'] as String,
        country: json['country'] as String,
        city: json['city'] as String,
        shop: json['shop'] as String,
        category: json['category'] as String,
        forWho: json['forWho'] as String,
        occasions: List<String>.from(json['occasions'] ?? []),
        status: json['status'] as String? ?? 'Disponible',
        external: json['external'] as bool? ?? false,
        externalUrl: json['externalUrl'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'imageUrl': imageUrl,
        'price': price,
        'currency': currency,
        'country': country,
        'city': city,
        'shop': shop,
        'category': category,
        'forWho': forWho,
        'occasions': occasions,
        'status': status,
        'external': external,
        'externalUrl': externalUrl,
      };
}

class GiftList {
  final String id;
  final String title;
  final String description;
  final String imageUrl;
  final String occasion;
  final String ownerId;
  final String? accessCode;
  final DateTime createdAt;
  final List<Gift> gifts;

  GiftList({
    required this.id,
    required this.title,
    required this.description,
    required this.imageUrl,
    required this.occasion,
    required this.ownerId,
    this.accessCode,
    required this.createdAt,
    this.gifts = const [],
  });

  int get reservedCount => gifts.where((g) => g.status == 'Réservé').length;
  int get availableCount => gifts.where((g) => g.status == 'Disponible').length;

  factory GiftList.fromJson(Map<String, dynamic> json) => GiftList(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        imageUrl: json['imageUrl'] as String,
        occasion: json['occasion'] as String,
        ownerId: json['ownerId'] as String,
        accessCode: json['accessCode'] as String?,
        createdAt: DateTime.parse(json['createdAt'] as String),
        gifts: (json['gifts'] as List<dynamic>?)
                ?.map((e) => Gift.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'description': description,
        'imageUrl': imageUrl,
        'occasion': occasion,
        'ownerId': ownerId,
        'accessCode': accessCode,
        'createdAt': createdAt.toIso8601String(),
        'gifts': gifts.map((g) => g.toJson()).toList(),
      };
}
