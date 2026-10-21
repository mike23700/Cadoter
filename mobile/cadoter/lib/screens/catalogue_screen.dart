import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/gift.dart';

class CatalogueScreen extends StatefulWidget {
  const CatalogueScreen({super.key});

  @override
  State<CatalogueScreen> createState() => _CatalogueScreenState();
}

class _CatalogueScreenState extends State<CatalogueScreen> {
  final List<Gift> _gifts = [
    Gift(id: '1', name: 'Bouquet de fleurs séchées', description: 'Bouquet raffiné, fleurs séchées, papier ivoire.',
        imageUrl: 'https://picsum.photos/seed/a/400/300', price: 25000, currency: 'FCFA', country: 'Sénégal', city: 'Dakar',
        shop: 'Fleurs d\'Ici', category: 'Déco', forWho: 'Parents', occasions: ['Anniversaire','Fête des mères'], status: 'Disponible'),
    Gift(id: '2', name: 'Tasse et théière ivoire', description: 'Service à thé en céramique, doux et chaleureux.',
        imageUrl: 'https://picsum.photos/seed/b/400/300', price: 18500, currency: 'FCFA', country: 'Sénégal', city: 'Dakar',
        shop: 'Maison Céramique', category: 'Maison', forWho: 'Parents', occasions: ['Anniversaire','Noël'], status: 'Disponible'),
    Gift(id: '3', name: 'Enceinte portable sage', description: 'Enceinte compacte, tissu texturé, son doux.',
        imageUrl: 'https://picsum.photos/seed/c/400/300', price: 32000, currency: 'FCFA', country: 'Sénégal', city: 'Dakar',
        shop: 'Tech Store', category: 'High-tech', forWho: 'Ami(e)s', occasions: ['Anniversaire'], status: 'Disponible'),
    Gift(id: '4', name: 'Couverture en laine', description: 'Plaid doux, tons crème, fait main.',
        imageUrl: 'https://picsum.photos/seed/d/400/300', price: 22000, currency: 'FCFA', country: 'Sénégal', city: 'Dakar',
        shop: 'Tissage d\'Ici', category: 'Maison', forWho: 'Famille', occasions: ['Mariage','Naissance'], status: 'Réservé'),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catalogue', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Trouvez le cadeau idéal', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74))),
                const SizedBox(height: 8),
                Text('Notre catalogue de cadeaux', style: const TextStyle(fontSize: 52, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
                const SizedBox(height: 8),
                Text('Découvrez notre sélection de cadeaux disponibles et réservez celui qui fera plaisir.',
                    style: const TextStyle(fontSize: 17, color: Color(0xFF786C74), height: 1.35)),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 20),
                  padding: const EdgeInsets.all(22),
                  color: AppColors.cream,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Filtrer', style: const TextStyle(fontSize: 21, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
                      const SizedBox(height: 22),
                      _field('Recherche', 'Nom du cadeau...'),
                      const SizedBox(height: 22),
                      _field('Budget max', 'Ex. 50 000 FCFA'),
                      const SizedBox(height: 22),
                      _field('Ville', 'Ville'),
                      const SizedBox(height: 16),
                      const Text('Disponibilité', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                      const SizedBox(height: 8),
                      _chip('Tous les produits disponibles', true),
                      _chip('Réservés', false),
                      _chip('Indisponibles', false),
                      const SizedBox(height: 22),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(onPressed: () {}, child: const Text('Appliquer les filtres')),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(onPressed: () {}, child: const Text('Afficher 12 produits')),
                      ),
                    ],
                  ),
                ),
              ),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          _pill('Anniversaire', true),
                          const SizedBox(width: 10),
                          _pill('Disponible', false),
                          const Spacer(),
                          Text('80 produits trouvés', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Text('Trier par : Pertinence', style: const TextStyle(fontSize: 11, color: Color(0xFF786C74))),
                    ),
                    const SizedBox(height: 16),
                    Expanded(
                      child: GridView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2, childAspectRatio: 0.75, crossAxisSpacing: 14, mainAxisSpacing: 24,
                        ),
                        itemCount: _gifts.length,
                        itemBuilder: (context, i) => _giftCard(_gifts[i]),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      margin: const EdgeInsets.symmetric(horizontal: 20),
                      padding: const EdgeInsets.all(26),
                      color: AppColors.pinkBg,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Cadeau sur mesure', style: const TextStyle(fontSize: 27, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
                          const SizedBox(height: 8),
                          Text('Vous ne trouvez pas ? Décrivez le cadeau idéal, notre équipe vous recontacte.',
                              style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              onPressed: () => Navigator.pushNamed(context, '/custom-gift'),
                              child: const Text('Je veux un cadeau personnalisé'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _field(String label, String hint) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
        const SizedBox(height: 7),
        TextField(
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF786C74)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9E1E5))),
            filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(13),
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, bool active) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: active ? AppColors.magenta : Colors.white,
        border: Border.all(color: active ? AppColors.magenta : const Color(0xFFE9E1E5), width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: active ? Colors.white : const Color(0xFF30232C))),
    );
  }

  Widget _chip(String label, bool selected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.magenta : Colors.white,
        border: Border.all(color: selected ? AppColors.magenta : const Color(0xFFE9E1E5), width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : const Color(0xFF30232C))),
    );
  }

  Widget _giftCard(Gift gift) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20),
              image: DecorationImage(image: NetworkImage(gift.imageUrl), fit: BoxFit.cover)),
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
          decoration: BoxDecoration(color: AppColors.dispoBg, borderRadius: BorderRadius.circular(8)),
          child: Text(gift.status,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF356C55))),
        ),
        const SizedBox(height: 8),
        Text(gift.name, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: Color(0xFF30232C), height: 1.35), maxLines: 1, overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text('${gift.price.toInt()} ${gift.currency}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.magenta, height: 1.35)),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () => Navigator.pushNamed(context, '/gift', arguments: gift),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: Colors.white, border: Border.all(color: const Color(0xFFE9E1E5)), borderRadius: BorderRadius.circular(12)),
            child: const Center(child: Text('Réserver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C)))),
          ),
        ),
      ],
    );
  }
}
