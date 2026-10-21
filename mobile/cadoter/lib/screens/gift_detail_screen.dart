import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../models/gift.dart';

class GiftDetailScreen extends StatelessWidget {
  final Gift gift;
  const GiftDetailScreen({super.key, required this.gift});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fiche cadeau', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Galerie
            Container(
              width: double.infinity, height: 300,
              decoration: BoxDecoration(color: AppColors.cream, borderRadius: BorderRadius.circular(20),
                image: DecorationImage(image: NetworkImage(gift.imageUrl), fit: BoxFit.cover)),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Container(width: 85, height: 100, color: AppColors.cream),
                const SizedBox(width: 14),
                Container(width: 85, height: 100, color: AppColors.cream),
              ],
            ),
            const SizedBox(height: 8),
            Text('3 photos disponibles', style: const TextStyle(fontSize: 11, color: Color(0xFF786C74))),
            const SizedBox(height: 23),
            // Dispo
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
              decoration: BoxDecoration(color: AppColors.dispoBg, borderRadius: BorderRadius.circular(8)),
              child: const Text('Disponible', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF356C55))),
            ),
            const SizedBox(height: 23),
            // Titre
            Text(gift.name, style: const TextStyle(fontSize: 51, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 23),
            // Prix
            Row(
              children: [
                Text('${gift.price.toInt()} ${gift.currency}',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 21, color: AppColors.magenta, height: 1.35)),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${gift.shop}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C), height: 1.35)),
                      const SizedBox(height: 4),
                      Text('${gift.city}, ${gift.country}', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74), height: 1.35)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Text(gift.description,
                style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 14),
            Text('À vérifier auprès du marchand : disponibilité, retrait ou livraison.',
                style: const TextStyle(fontSize: 11, color: Color(0xFF786C74))),
            const SizedBox(height: 30),
            // Quantité
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Quantité', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                const SizedBox(height: 7),
                TextField(
                  decoration: InputDecoration(
                    hintText: '1', hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF786C74)),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9E1E5))),
                    filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            // Actions
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.magenta, foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Text('Réserver', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      SizedBox(width: 6), Icon(Icons.card_giftcard, size: 18, color: Colors.white),
                    ]),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppColors.magenta),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                    ),
                    child: const Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(Icons.favorite_border, size: 18, color: AppColors.magenta),
                      SizedBox(width: 6), Text('Favoris', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.magenta)),
                    ]),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 23),
            // Emballage suggéré
            Container(
              padding: const EdgeInsets.all(16),
              color: AppColors.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Emballage suggéré', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Container(width: 85, height: 90, color: AppColors.cream),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Rosé signature', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                            const SizedBox(height: 6),
                            Text('Papier mat rose poudré, ruban satin magenta.', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74), height: 1.35)),
                            const SizedBox(height: 6),
                            Text('+ 3 000 FCFA', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.magenta)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 23),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFE9E1E5)),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Text('Ajouter à une liste', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                ]),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
