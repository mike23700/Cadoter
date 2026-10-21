import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key});

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final List<String> _occasions = ['Anniversaire', 'Mariage', 'Naissance', 'Dot', 'Autre', 'Soutien'];
  String? _selected;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Créer une liste', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Anniversaire Aïcha', style: const TextStyle(fontSize: 32, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 22),
            Text('Créez une liste pour célébrer un moment spécial. Ajoutez des cadeaux et partagez le lien avec vos proches.',
                style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 22),
            // Titre
            _field('Titre de la liste', 'Nom de la liste'),
            const SizedBox(height: 22),
            // Description
            _field('Description', 'Parlez de l\'événement...', maxLines: 4),
            const SizedBox(height: 22),
            // Image de couverture
            Text('Image de couverture', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
            const SizedBox(height: 8),
            Container(
              width: double.infinity, height: 86,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFE9E1E5)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(width: 22, height: 22, decoration: BoxDecoration(
                    color: AppColors.magenta.withOpacity(0.1),
                    border: Border.all(color: AppColors.magenta, width: 1.7),
                    shape: BoxShape.circle,
                  )),
                  const SizedBox(height: 12),
                  Text('Importer une image', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.magenta)),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text('JPG/PNG, 5 Mo max', style: const TextStyle(fontSize: 11, color: Color(0xFF786C74))),
            const SizedBox(height: 22),
            // Choix d'occasion
            Text('Choix d\'occasion', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _occasions.map((o) => _pill(o, _selected == o, () => setState(() => _selected = o))).toList(),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.magenta, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 13),
                ),
                child: const Text('Créer la liste', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field(String label, String hint, {int maxLines = 1}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF30232C))),
        const SizedBox(height: 7),
        TextField(
          maxLines: maxLines,
          decoration: InputDecoration(
            hintText: hint, hintStyle: const TextStyle(fontSize: 13, color: Color(0xFF786C74)),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFFE9E1E5))),
            filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.all(13),
          ),
        ),
      ],
    );
  }

  Widget _pill(String label, bool selected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? AppColors.magenta : Colors.white,
          border: Border.all(color: selected ? AppColors.magenta : const Color(0xFFE9E1E5), width: 1),
          borderRadius: BorderRadius.circular(100),
        ),
        child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : const Color(0xFF30232C))),
      ),
    );
  }
}
