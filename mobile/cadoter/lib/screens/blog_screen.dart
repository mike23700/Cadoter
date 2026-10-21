import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../widgets/common.dart';

class Article {
  const Article(this.tag, this.minutes, this.title, this.image, this.body);
  final String tag;
  final int minutes;
  final String title;
  final String image;
  final List<String> body;
}

const articles = [
  Article('Fête des pères', 4, 'Pour papa, une attention qui compte.', 'assets/images/article-papa.jpg', [
    'Les pères ont souvent du mal à dire ce qui leur ferait plaisir. Plutôt que de chercher l’objet parfait, pensez à ce qu’il aime faire : lire le journal au calme, écouter ses vieux disques, recevoir la famille le dimanche.',
    'Un rituel du thé, une enceinte pour sa musique ou un simple déjeuner partagé : l’important est que le cadeau raconte quelque chose de votre lien.',
  ]),
  Article('Fête des mères', 5, 'Lui dire merci, tout simplement.', 'assets/images/inspi-maman.jpg', [
    'Un bouquet de fleurs séchées dure des mois et rappelle votre attention à chaque regard. Ajoutez un petit mot manuscrit : c’est souvent ce qu’elle gardera le plus longtemps.',
  ]),
  Article('Noël', 4, 'Un Noël plein de petites attentions.', 'assets/images/article-noel.jpg', [
    'À Noël, les cadeaux se multiplient et les doublons aussi. Une liste partagée permet à chacun de réserver ce qu’il offre, sans gâcher la surprise.',
  ]),
  Article('Soutien', 3, 'Soutenir un proche en deuil.', 'assets/images/bouquet.jpg', [
    'Dans les moments difficiles, les gestes simples comptent : un repas apporté, des fleurs sobres, une présence.',
    'Une liste de soutien permet à l’entourage de proposer une aide concrète sans doublon, en respectant le rythme de la famille.',
  ]),
];

/// « Mobile · Blog inspirations »
class BlogScreen extends StatefulWidget {
  const BlogScreen({super.key});

  @override
  State<BlogScreen> createState() => _BlogScreenState();
}

class _BlogScreenState extends State<BlogScreen> {
  String _tag = 'Tout lire';

  @override
  Widget build(BuildContext context) {
    final tags = ['Tout lire', 'Fête des pères', 'Fête des mères', 'Noël'];
    final shown = [for (var i = 0; i < articles.length; i++) if (_tag == 'Tout lire' || articles[i].tag == _tag) i];
    return Scaffold(
      appBar: const TopBar('Inspirations'),
      bottomNavigationBar: const AppBottomNav(current: 0),
      body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
        Text('CADOTER pour vous inspirer.', style: T.serif(32)),
        const SizedBox(height: 16),
        Text('Des idées, des histoires et l’envie de faire plaisir, à votre façon.', style: T.sans(14, color: AppColors.gray)),
        const SizedBox(height: 22),
        Wrap(spacing: 8, runSpacing: 10, children: [for (final t in tags) Pill(t, selected: t == _tag, onTap: () => setState(() => _tag = t))]),
        const SizedBox(height: 26),
        for (final i in shown)
          GestureDetector(
            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ArticleScreen(index: i))),
            child: Padding(
              padding: const EdgeInsets.only(bottom: 30),
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                NetImage(articles[i].image, aspect: 354 / 190),
                const SizedBox(height: 16),
                Eyebrow('${articles[i].tag} · ${articles[i].minutes} min', color: AppColors.magenta),
                const SizedBox(height: 10),
                Text(articles[i].title, style: T.serif(24)),
                const SizedBox(height: 10),
                Text('Lire l’article →', style: T.sans(12, color: AppColors.gray)),
              ]),
            ),
          ),
      ]),
    );
  }
}

class ArticleScreen extends StatelessWidget {
  const ArticleScreen({super.key, required this.index});
  final int index;

  @override
  Widget build(BuildContext context) {
    final a = articles[index];
    return Scaffold(
      appBar: const TopBar('Inspirations'),
      body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 32), children: [
        Eyebrow('${a.tag} · ${a.minutes} min de lecture', color: AppColors.magenta),
        const SizedBox(height: 12),
        Text(a.title, style: T.serif(32)),
        const SizedBox(height: 22),
        NetImage(a.image, aspect: 354 / 200),
        const SizedBox(height: 24),
        for (final p in a.body) Padding(padding: const EdgeInsets.only(bottom: 16), child: Text(p, style: T.sans(15, height: 1.65))),
      ]),
    );
  }
}
