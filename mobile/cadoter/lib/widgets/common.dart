import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';

const kGutter = 24.0;

/// Logo + cloche (écrans d'accueil et de présentation).
class BrandHeader extends StatelessWidget {
  const BrandHeader({super.key, this.trailing});
  final Widget? trailing;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(kGutter, 12, 14, 8),
        child: Row(children: [
          Image.asset('assets/images/logo.png', height: 44),
          const Spacer(),
          trailing ?? IconButton(onPressed: () {}, icon: const Icon(Icons.notifications_none_rounded, color: AppColors.dark)),
        ]),
      );
}

/// Barre « ← Titre … » des écrans secondaires.
class TopBar extends StatelessWidget implements PreferredSizeWidget {
  const TopBar(this.title, {super.key, this.onMore, this.showBack = true});
  final String title;
  final VoidCallback? onMore;
  final bool showBack;

  @override
  Size get preferredSize => const Size.fromHeight(60);

  @override
  Widget build(BuildContext context) => AppBar(
        backgroundColor: AppColors.white,
        surfaceTintColor: AppColors.white,
        elevation: 0,
        centerTitle: true,
        automaticallyImplyLeading: false,
        leading: showBack && Navigator.canPop(context)
            ? IconButton(icon: const Icon(Icons.arrow_back, color: AppColors.dark), onPressed: () => Navigator.pop(context))
            : null,
        title: Text(tr(title), style: T.sans(15, weight: FontWeight.w600)),
        actions: [IconButton(icon: const Icon(Icons.more_horiz, color: AppColors.dark), onPressed: onMore ?? () {})],
      );
}

/// Barre de navigation basse (5 onglets). Depuis un écran poussé, revient à l'accueil puis change d'onglet.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.current, this.inShell = false});
  final int current;
  final bool inShell;

  static const items = [
    (Icons.home_outlined, 'Accueil'),
    (Icons.card_giftcard_outlined, 'Cadeaux'),
    (Icons.format_list_bulleted, 'Mes listes'),
    (Icons.auto_awesome_outlined, 'Assistante'),
    (Icons.person_outline, 'Compte'),
  ];

  @override
  Widget build(BuildContext context) => Container(
        decoration: const BoxDecoration(color: AppColors.white, border: Border(top: BorderSide(color: AppColors.border))),
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 62,
            child: Row(
              children: [
                for (var i = 0; i < items.length; i++)
                  Expanded(
                    child: InkWell(
                      onTap: () {
                        SessionScope.read(context).goTab(i);
                        if (!inShell) Navigator.of(context).popUntil((r) => r.isFirst);
                      },
                      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Icon(items[i].$1, size: 22, color: i == current ? AppColors.magenta : AppColors.gray),
                        const SizedBox(height: 4),
                        Text(tr(items[i].$2),
                            style: T.sans(10,
                                color: i == current ? AppColors.magenta : AppColors.gray,
                                weight: i == current ? FontWeight.w600 : FontWeight.w400)),
                      ]),
                    ),
                  ),
              ],
            ),
          ),
        ),
      );
}

class PrimaryButton extends StatelessWidget {
  const PrimaryButton(this.label, {super.key, this.onPressed, this.icon, this.loading = false});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final bool loading;

  @override
  Widget build(BuildContext context) => ElevatedButton(
        onPressed: loading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          disabledBackgroundColor: AppColors.magenta.withValues(alpha: .45),
          disabledForegroundColor: AppColors.white,
        ),
        child: loading
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.white))
            : Row(mainAxisSize: MainAxisSize.min, children: [
                Flexible(child: Text(tr(label), overflow: TextOverflow.ellipsis)),
                if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 18)],
              ]),
      );
}

class SecondaryButton extends StatelessWidget {
  const SecondaryButton(this.label, {super.key, this.onPressed, this.icon});
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) => OutlinedButton(
        onPressed: onPressed,
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Flexible(child: Text(tr(label), overflow: TextOverflow.ellipsis)),
          if (icon != null) ...[const SizedBox(width: 10), Icon(icon, size: 18, color: AppColors.magenta)],
        ]),
      );
}

class Pill extends StatelessWidget {
  const Pill(this.label, {super.key, this.selected = false, this.onTap});
  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: selected ? AppColors.magenta : AppColors.white,
        shape: StadiumBorder(side: BorderSide(color: selected ? AppColors.magenta : AppColors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 8),
            child: Text(tr(label), style: T.sans(12, color: selected ? AppColors.white : AppColors.dark)),
          ),
        ),
      );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge(this.label, {super.key, this.ok = true});
  final String label;
  final bool ok;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(color: ok ? AppColors.dispoBg : AppColors.cream, borderRadius: BorderRadius.circular(8)),
        child: Text(tr(label), style: T.sans(11, weight: FontWeight.w600, color: ok ? AppColors.dispoText : AppColors.gray)),
      );
}

/// Image réseau (ou asset si le chemin commence par assets/) avec coins arrondis et repli.
class NetImage extends StatelessWidget {
  const NetImage(this.url, {super.key, this.height, this.width, this.radius = 20, this.aspect});
  final String? url;
  final double? height;
  final double? width;
  final double radius;
  final double? aspect;

  @override
  Widget build(BuildContext context) {
    Widget placeholder() => Container(
          color: AppColors.cream,
          alignment: Alignment.center,
          child: const Icon(Icons.card_giftcard, color: AppColors.gray),
        );
    Widget img;
    if (url == null) {
      img = placeholder();
    } else if (url!.startsWith('assets/')) {
      img = Image.asset(url!, fit: BoxFit.cover);
    } else {
      img = Image.network(url!, fit: BoxFit.cover, errorBuilder: (_, _, _) => placeholder(),
          loadingBuilder: (_, child, p) => p == null ? child : Container(color: AppColors.cream));
    }
    img = ClipRRect(borderRadius: BorderRadius.circular(radius), child: SizedBox(height: height, width: width, child: img));
    return aspect != null ? AspectRatio(aspectRatio: aspect!, child: img) : img;
  }
}

class GiftTile extends StatelessWidget {
  const GiftTile(this.gift, {super.key, this.onTap, this.aspect = 1});
  final Gift gift;
  final VoidCallback? onTap;
  final double aspect;

  @override
  Widget build(BuildContext context) => GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          NetImage(gift.imageUrl, aspect: aspect, radius: 16),
          const SizedBox(height: 12),
          StatusBadge(gift.available ? 'Disponible' : 'Indisponible', ok: gift.available),
          const SizedBox(height: 10),
          Text(gift.name, style: T.sans(14, weight: FontWeight.w600), maxLines: 2, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 6),
          Text(gift.place, style: T.sans(12, color: AppColors.gray)),
          const SizedBox(height: 8),
          Text(formatPrice(gift.price, gift.currency), style: T.sans(15, weight: FontWeight.w600, color: AppColors.magenta)),
        ]),
      );
}

/// Grille 2 colonnes à hauteur libre (pas de débordement quelle que soit la taille de police).
/// Un dernier élément impair est affiché en pleine largeur, comme dans la maquette du catalogue.
class GiftGrid extends StatelessWidget {
  const GiftGrid({super.key, required this.gifts, required this.onTap, this.wideLast = false});
  final List<Gift> gifts;
  final void Function(Gift) onTap;
  final bool wideLast;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    final pairs = wideLast ? gifts.length ~/ 2 * 2 : gifts.length;
    for (var i = 0; i < pairs; i += 2) {
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 22),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: GiftTile(gifts[i], onTap: () => onTap(gifts[i]))),
          const SizedBox(width: 14),
          Expanded(child: i + 1 < pairs ? GiftTile(gifts[i + 1], onTap: () => onTap(gifts[i + 1])) : const SizedBox()),
        ]),
      ));
    }
    if (wideLast && gifts.length.isOdd) {
      rows.add(GiftTile(gifts.last, aspect: 354 / 150, onTap: () => onTap(gifts.last)));
    }
    return Column(children: rows);
  }
}

class FieldLabel extends StatelessWidget {
  const FieldLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) =>
      Padding(padding: const EdgeInsets.only(bottom: 8), child: Text(tr(text), style: T.sans(12, weight: FontWeight.w600)));
}

/// Champ de formulaire libellé (TextFormField).
class LabeledField extends StatelessWidget {
  const LabeledField({
    super.key,
    required this.label,
    required this.controller,
    this.hint,
    this.keyboard,
    this.obscure = false,
    this.maxLines = 1,
    this.validator,
    this.errorText,
    this.autofill,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboard;
  final bool obscure;
  final int maxLines;
  final String? Function(String?)? validator;
  final String? errorText;
  final Iterable<String>? autofill;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FieldLabel(label),
          TextFormField(
            controller: controller,
            keyboardType: keyboard,
            obscureText: obscure,
            maxLines: obscure ? 1 : maxLines,
            minLines: maxLines > 1 ? 3 : 1,
            validator: validator,
            autofillHints: autofill,
            style: T.sans(13),
            decoration: InputDecoration(hintText: hint == null ? null : tr(hint!), errorText: errorText),
          ),
        ]),
      );
}

class DropdownField extends StatelessWidget {
  const DropdownField({super.key, required this.label, required this.value, required this.items, required this.onChanged, this.display});
  final String label;
  final String? value;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String Function(String)? display;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          FieldLabel(label),
          DropdownButtonFormField<String>(
            initialValue: items.contains(value) ? value : null,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.dark),
            style: T.sans(13),
            items: items.map((e) => DropdownMenuItem(value: e, child: Text(display?.call(e) ?? tr(e)))).toList(),
            onChanged: onChanged,
          ),
        ]),
      );
}

class Eyebrow extends StatelessWidget {
  const Eyebrow(this.text, {super.key, this.color = AppColors.gray});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(tr(text).toUpperCase(), style: T.eyebrow(color: color));
}

class IllustrativeNote extends StatelessWidget {
  const IllustrativeNote({super.key});

  @override
  Widget build(BuildContext context) =>
      Text(tr('Exemples de cadeaux · Prix et lieux illustratifs'), style: T.sans(11, color: AppColors.gray));
}

/// Encart crème/rose arrondi.
class Panel extends StatelessWidget {
  const Panel({super.key, required this.child, this.pink = false, this.padding = const EdgeInsets.all(20)});
  final Widget child;
  final bool pink;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: padding,
        decoration: BoxDecoration(color: pink ? AppColors.pinkBg : AppColors.cream, borderRadius: BorderRadius.circular(20)),
        child: child,
      );
}

class ErrorRetry extends StatelessWidget {
  const ErrorRetry(this.message, {super.key, this.onRetry});
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.all(kGutter),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Text(tr(message), textAlign: TextAlign.center, style: T.sans(13, color: AppColors.gray)),
          if (onRetry != null) TextButton(onPressed: onRetry, child: Text(tr('Réessayer'), style: T.sans(13, color: AppColors.magenta, weight: FontWeight.w600))),
        ]),
      );
}

class Loader extends StatelessWidget {
  const Loader({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator(color: AppColors.magenta)));
}

void toast(BuildContext context, String message) =>
    ScaffoldMessenger.of(context)..hideCurrentSnackBar()..showSnackBar(SnackBar(content: Text(tr(message))));

/// Charge des données de l'API avec états chargement / erreur.
class ApiBuilder<D> extends StatefulWidget {
  const ApiBuilder({super.key, required this.load, required this.builder});
  final Future<D> Function() load;
  final Widget Function(BuildContext, D data, Future<void> Function() reload) builder;

  @override
  State<ApiBuilder<D>> createState() => _ApiBuilderState<D>();
}

class _ApiBuilderState<D> extends State<ApiBuilder<D>> {
  late Future<D> _future = widget.load();

  Future<void> _reload() async {
    final f = widget.load();
    setState(() => _future = f);
    await f.catchError((_) => null as D);
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<D>(
        future: _future,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) return const Loader();
          if (snap.hasError) return ErrorRetry('${snap.error}', onRetry: _reload);
          return widget.builder(context, snap.data as D, _reload);
        },
      );
}
