import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/gift.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final List<Gift> _featured = [
    Gift(
      id: '1', name: 'Bouquet de fleurs séchées',
      description: 'Bouquet raffiné, fleurs séchées, papier ivoire.',
      imageUrl: 'https://picsum.photos/seed/a/400/300',
      price: 25000, currency: 'FCFA', country: 'Sénégal', city: 'Dakar',
      shop: 'Fleurs d\'Ici', category: 'Déco', forWho: 'Parents',
      occasions: ['Anniversaire', 'Fête des mères'], status: 'Disponible',
    ),
    Gift(
      id: '2', name: 'Tasse et théière ivoire',
      description: 'Service à thé en céramique, doux et chaleureux.',
      imageUrl: 'https://picsum.photos/seed/b/400/300',
      price: 18500, currency: 'FCFA', country: 'Sénégal', city: 'Dakar',
      shop: 'Maison Céramique', category: 'Maison', forWho: 'Parents',
      occasions: ['Anniversaire', 'Noël'], status: 'Disponible',
    ),
    Gift(
      id: '3', name: 'Enceinte portable sage',
      description: 'Enceinte compacte, tissu texturé, son doux.',
      imageUrl: 'https://picsum.photos/seed/c/400/300',
      price: 32000, currency: 'FCFA', country: 'Sénégal', city: 'Dakar',
      shop: 'Tech Store', category: 'High-tech', forWho: 'Ami(e)s',
      occasions: ['Anniversaire'], status: 'Disponible',
    ),
  ];

  final List<String> _occasions = [
    'Anniversaire', 'Mariage', 'Naissance', 'Dot',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Promesse
              Container(
                padding: const EdgeInsets.all(20),
                color: AppColors.cream,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('À qui faire plaisir',
                        style: GoogleFontsStyle.magentaSmall),
                    const SizedBox(height: 8),
                    Text('Offrez le cadeau qui fait vraiment plaisir',
                        style: GoogleFontsStyle.bigSerif),
                    const SizedBox(height: 12),
                    Text('Créez une liste, partagez le lien, et laissez vos proches choisir sans jamais offrir deux fois la même chose.',
                        style: GoogleFontsStyle.bodyGray),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: _bigButton('Créer ma liste', true),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _bigButton('Voir le catalogue', false),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              // Recherche
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Container(width: 22, height: 22, decoration: BoxDecoration(
                          color: AppColors.magenta.withOpacity(0.1),
                          border: Border.all(color: AppColors.magenta, width: 1.7),
                          shape: BoxShape.circle,
                        )),
                        const SizedBox(width: 12),
                        Expanded(child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Nom du cadeau...',
                            border: InputBorder.none,
                            hintStyle: GoogleFontsStyle.bodyDark,
                            isDense: true,
                          ),
                        )),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Budget', style: GoogleFontsStyle.labelDark),
                              const SizedBox(height: 4),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Ex. 15 000 FCFA',
                                  border: InputBorder.none,
                                  hintStyle: GoogleFontsStyle.bodyGray,
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Localisation', style: GoogleFontsStyle.labelDark),
                              const SizedBox(height: 4),
                              TextField(
                                decoration: InputDecoration(
                                  hintText: 'Ville, pays',
                                  border: InputBorder.none,
                                  hintStyle: GoogleFontsStyle.bodyGray,
                                  isDense: true,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/catalogue'),
                        child: const Text('Rechercher'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),
              // Occasions
              Text('Occasions', style: GoogleFontsStyle.sectionTitle),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _occasions.map((o) => _occasionChip(o)).toList(),
              ),
              const SizedBox(height: 30),
              // Sélection
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Sélection pour vous', style: GoogleFontsStyle.sectionTitle),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/catalogue'),
                    child: Text('Voir tout →', style: GoogleFontsStyle.magentaSmallBold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 340,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: _featured.map((g) => _giftCard(g)).toList(),
                ),
              ),
              const SizedBox(height: 40),
              // Blog preview
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Journal & inspirations', style: GoogleFontsStyle.sectionTitle),
                  TextButton(
                    onPressed: () => Navigator.pushNamed(context, '/blog'),
                    child: Text('Tous les articles →', style: GoogleFontsStyle.magentaSmallBold),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 380,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  children: const [
                    _BlogCard(title: 'Fête des pères', subtitle: 'Un moment rien qu\'à lui'),
                    _BlogCard(title: 'Fête des mères', subtitle: 'Tendresse en bouquet'),
                    _BlogCard(title: 'Noël', subtitle: 'Douceurs de fin d\'année'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bigButton(String label, bool primary) {
    return SizedBox(
      height: 48,
      child: primary
          ? ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/create-list'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.magenta,
                foregroundColor: AppColors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Créer ma liste'),
            )
          : OutlinedButton(
              onPressed: () => Navigator.pushNamed(context, '/catalogue'),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Voir le catalogue'),
            ),
    );
  }

  Widget _occasionChip(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppColors.cream,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 22, height: 22, decoration: BoxDecoration(
            color: AppColors.magenta.withOpacity(0.1),
            border: Border.all(color: AppColors.magenta, width: 1.7),
            shape: BoxShape.circle,
          )),
          const SizedBox(width: 12),
          Text(label, style: const TextStyle(
            fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.dark,
          )),
        ],
      ),
    );
  }

  Widget _giftCard(Gift gift) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 170, height: 150,
            decoration: BoxDecoration(
              color: AppColors.cream, borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: NetworkImage(gift.imageUrl), fit: BoxFit.cover),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.dispoBg, borderRadius: BorderRadius.circular(8),
            ),
            child: Text(gift.status,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF356C55))),
          ),
          const SizedBox(height: 6),
          Text(gift.name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.dark),
              maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 4),
          Text('${gift.price.toInt()} ${gift.currency}',
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.magenta)),
          const SizedBox(height: 6),
          GestureDetector(
            onTap: () => Navigator.pushNamed(context, '/gift', arguments: gift),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.white,
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [Text('Réserver'), SizedBox(width: 6), Icon(Icons.card_giftcard, size: 14)],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class GoogleFontsStyle {
  static const TextStyle magentaSmall = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC90091), fontFamily: 'Inter',
  );
  static const TextStyle magentaSmallBold = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFFC90091),
  );
  static const TextStyle bigSerif = TextStyle(
    fontSize: 35, fontFamily: 'DM Serif Display', fontWeight: FontWeight.w400, color: Color(0xFF30232C), height: 1.35,
  );
  static const TextStyle bodyGray = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF786C74), height: 1.35,
  );
  static const TextStyle bodyDark = TextStyle(
    fontSize: 14, fontWeight: FontWeight.w400, color: Color(0xFF30232C),
  );
  static const TextStyle labelDark = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF30232C),
  );
  static const TextStyle sectionTitle = TextStyle(
    fontSize: 23, fontFamily: 'DM Serif Display', fontWeight: FontWeight.w400, color: Color(0xFF30232C),
  );
}

class _BlogCard extends StatelessWidget {
  final String title, subtitle;
  const _BlogCard({required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: 170, height: 150, color: AppColors.cream),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF30232C), height: 1.35)),
          const SizedBox(height: 4),
          Text(subtitle, style: const TextStyle(fontSize: 12, color: Color(0xFF786C74))),
        ],
      ),
    );
  }
}
