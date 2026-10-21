import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'blog_screen.dart';
import 'catalogue_screen.dart';
import 'gift_screen.dart';

/// « Mobile · Accueil découverte »
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Gift>> _gifts = _load();

  Future<List<Gift>> _load() async =>
      ((await Api.instance.get('/gifts?featured=1&limit=6')) as List).map((e) => Gift.fromJson(e)).toList();

  void _search(BuildContext context, {String? q, String? occasion}) => Navigator.push(
      context, MaterialPageRoute(builder: (_) => CatalogueScreen(initialQuery: q, initialOccasion: occasion, standalone: true)));

  @override
  Widget build(BuildContext context) {
    final session = SessionScope.of(context);
    return SafeArea(
      child: RefreshIndicator(
        color: AppColors.magenta,
        onRefresh: () async {
          final f = _load();
          setState(() => _gifts = f);
          await f.catchError((_) => <Gift>[]);
        },
        child: ListView(padding: EdgeInsets.zero, children: [
          const BrandHeader(),
          Padding(
            padding: const EdgeInsets.fromLTRB(kGutter, 18, kGutter, 24),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow(session.isLoggedIn ? 'Bonjour ${session.user!.firstName}' : 'Bienvenue'),
              const SizedBox(height: 14),
              Text('À qui allez-vous faire plaisir ?', style: T.serif(34)),
              const SizedBox(height: 22),
              TextField(
                textInputAction: TextInputAction.search,
                onSubmitted: (q) => _search(context, q: q),
                style: T.sans(14),
                decoration: InputDecoration(
                  hintText: 'Une idée, une envie, un cadeau…',
                  prefixIcon: const Icon(Icons.search, color: AppColors.dark),
                  filled: true,
                  fillColor: AppColors.cream,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const NetImage('assets/images/hero-home-mobile.jpg', aspect: 354 / 220),
              const SizedBox(height: 20),
              Wrap(spacing: 8, runSpacing: 8, children: [
                for (final o in const ['Anniversaire', 'Mariage', 'Naissance', 'Dot']) Pill(o, onTap: () => _search(context, occasion: o)),
              ]),
              const SizedBox(height: 32),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Text('Des idées qui font plaisir', style: T.serif(22))),
                GestureDetector(
                  onTap: () => session.goTab(1),
                  child: Text('Tout voir', style: T.sans(12, color: AppColors.magenta, weight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 14),
              const IllustrativeNote(),
              const SizedBox(height: 18),
              FutureBuilder<List<Gift>>(
                future: _gifts,
                builder: (context, snap) {
                  if (snap.connectionState != ConnectionState.done) return const Loader();
                  if (snap.hasError) {
                    return ErrorRetry('${snap.error}', onRetry: () => setState(() => _gifts = _load()));
                  }
                  final gifts = snap.data!;
                  if (gifts.isEmpty) return Text('Les premiers cadeaux arrivent bientôt.', style: T.sans(13, color: AppColors.gray));
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: gifts.length.clamp(0, 4),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2, crossAxisSpacing: 14, mainAxisSpacing: 22, mainAxisExtent: 290),
                    itemBuilder: (_, i) => GiftTile(gifts[i],
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => GiftScreen(slug: gifts[i].slug)))),
                  );
                },
              ),
              const SizedBox(height: 26),
              Panel(
                pink: true,
                padding: const EdgeInsets.all(22),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const Icon(Icons.auto_awesome_outlined, color: AppColors.magenta),
                  const SizedBox(height: 14),
                  Text('En panne d’inspiration ?', style: T.serif(26)),
                  const SizedBox(height: 14),
                  Text('L’assistante IA vous aide à trouver une attention personnelle.', style: T.sans(14)),
                  const SizedBox(height: 18),
                  PrimaryButton('Trouver une idée', onPressed: () => session.goTab(3)),
                ]),
              ),
              const SizedBox(height: 22),
              SecondaryButton('Créer et partager ma liste', onPressed: () => session.goTab(2)),
              const SizedBox(height: 34),
              Row(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Expanded(child: Text('CADOTER pour vous inspirer', style: T.serif(22))),
                GestureDetector(
                  onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const BlogScreen())),
                  child: Text('Le blog', style: T.sans(12, color: AppColors.magenta, weight: FontWeight.w600)),
                ),
              ]),
              const SizedBox(height: 18),
              Text('Fête des pères, des mères, Noël : nos idées à lire.', style: T.sans(14, color: AppColors.gray)),
              const SizedBox(height: 18),
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ArticleScreen(index: 3))),
                child: Text('Soutenir un proche en deuil → Des attentions sobres et respectueuses, à son rythme.',
                    style: T.sans(12, color: AppColors.gray)),
              ),
            ]),
          ),
        ]),
      ),
    );
  }
}
