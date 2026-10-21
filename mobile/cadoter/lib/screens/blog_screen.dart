import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BlogScreen extends StatelessWidget {
  const BlogScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inspirations', style: TextStyle(color: Color(0xFF30232C), fontSize: 14)),
        centerTitle: false, elevation: 0, backgroundColor: Colors.white,
        automaticallyImplyLeading: true, leading: const BackButton(),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Articles', style: const TextStyle(fontSize: 34, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
            const SizedBox(height: 15),
            Text('Trouvez l\'inspiration pour chaque moment de vie.', style: const TextStyle(fontSize: 14, color: Color(0xFF786C74), height: 1.35)),
            const SizedBox(height: 22),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const ['Tous', 'Inspirations', 'Conseils', 'Fêtes']
                  .map((t) => _chip(t, t == 'Tous'))
                  .toList(),
            ),
            const SizedBox(height: 30),
            ..._articles.map((a) => _article(a)).toList(),
          ],
        ),
      ),
    );
  }

  final List<Map<String, String>> _articles = const [
    {'title': 'Un moment rien qu\'à lui', 'cat': 'Fête des pères', 'body': 'Des idées pour célébrer votre père avec attention.'},
    {'title': 'Tendresse en bouquet', 'cat': 'Fête des mères', 'body': 'Offrez douceur et fleurs à votre maman.'},
    {'title': 'Douceurs de fin d\'année', 'cat': 'Noël', 'body': 'Cadeaux de Noël pour toute la famille.'},
  ];

  Widget _chip(String label, bool selected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
      decoration: BoxDecoration(
        color: selected ? AppColors.magenta : Colors.white,
        border: Border.all(color: selected ? AppColors.magenta : const Color(0xFFE9E1E5), width: 1),
        borderRadius: BorderRadius.circular(100),
      ),
      child: Text(label, style: TextStyle(fontSize: 12, color: selected ? Colors.white : const Color(0xFF30232C))),
    );
  }

  Widget _article(Map<String, String> a) {
    return Container(
      margin: const EdgeInsets.only(bottom: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(width: double.infinity, height: 190, color: AppColors.cream),
          const SizedBox(height: 10),
          Text(a['cat']!, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: AppColors.magenta)),
          const SizedBox(height: 6),
          Text(a['title']!, style: const TextStyle(fontSize: 24, fontFamily: 'DM Serif Display', color: Color(0xFF30232C), height: 1.35)),
          const SizedBox(height: 6),
          Text(a['body']!, style: const TextStyle(fontSize: 12, color: Color(0xFF786C74), height: 1.35)),
        ],
      ),
    );
  }
}
