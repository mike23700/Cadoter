import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ListsScreen extends StatefulWidget {
  const ListsScreen({super.key});

  @override
  State<ListsScreen> createState() => _ListsScreenState();
}

class _ListsScreenState extends State<ListsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mes listes', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: false,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/create-list'),
        backgroundColor: AppColors.magenta,
        label: const Text('Nouvelle liste', style: TextStyle(fontSize: 12, color: Colors.white)),
        icon: const Icon(Icons.add, size: 18, color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Vos listes de cadeaux', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74))),
            const SizedBox(height: 8),
            Text('Mes listes', style: const TextStyle(fontSize: 48, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 30),
            // Liste sélectionnée
            Container(
              padding: const EdgeInsets.all(22),
              color: AppColors.pinkBg,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Liste sélectionnée', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.magenta)),
                  const SizedBox(height: 10),
                  Text('Anniversaire Aïcha', style: const TextStyle(fontSize: 23, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
                  const SizedBox(height: 10),
                  Text('4 cadeaux • 2 réservés', style: const TextStyle(fontSize: 12, color: Color(0xFF786C74))),
                ],
              ),
            ),
            const SizedBox(height: 23),
            // Créer une liste
            Container(
              padding: const EdgeInsets.all(22),
              color: AppColors.cream,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Créer une liste', style: const TextStyle(fontSize: 24, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
                  const SizedBox(height: 17),
                  TextField(
                    decoration: InputDecoration(
                      hintText: 'Nom de la liste',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF786C74)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9E1E5))),
                      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(13),
                    ),
                  ),
                  const SizedBox(height: 17),
                  TextField(
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: 'Parlez de l\'événement...',
                      hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF786C74)),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9E1E5))),
                      filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(13),
                    ),
                  ),
                  const SizedBox(height: 17),
                  Row(
                    children: [
                      Expanded(child: TextField(
                        decoration: InputDecoration(
                          hintText: 'Anniversaire',
                          hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF786C74)),
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9E1E5))),
                          filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(13),
                        ),
                      )),
                      const SizedBox(width: 10),
                      Container(width: 16, height: 16, decoration: BoxDecoration(
                        color: AppColors.white, border: Border.all(color: const Color(0xFF30232C), width: 1.7),
                        borderRadius: BorderRadius.circular(50),
                      )),
                    ],
                  ),
                  const SizedBox(height: 17),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE9E1E5)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      ),
                      child: const Text('Créer la liste', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text('Une liste par événement.', style: const TextStyle(fontSize: 11, color: Color(0xFF786C74))),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/create-list'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.magenta, foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                      ),
                      child: const Text('+ Nouvelle liste', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
