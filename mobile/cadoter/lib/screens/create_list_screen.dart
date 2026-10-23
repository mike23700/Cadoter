import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// « Mobile · Création de liste ». Avec [list], modifie une liste existante. Renvoie la liste enregistrée.
class CreateListScreen extends StatefulWidget {
  const CreateListScreen({super.key, this.list});
  final GiftList? list;

  @override
  State<CreateListScreen> createState() => _CreateListScreenState();
}

class _CreateListScreenState extends State<CreateListScreen> {
  final _form = GlobalKey<FormState>();
  late final _title = TextEditingController(text: widget.list?.title);
  late final _desc = TextEditingController(text: widget.list?.description);
  late final _code = TextEditingController(text: widget.list?.accessCode);
  late String _occasion = widget.list?.occasion ?? 'Anniversaire';
  File? _image;
  bool _busy = false;
  ApiException? _error;

  bool get _editing => widget.list != null;

  Future<void> _pick() async {
    final x = await ImagePicker().pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    final f = File(x.path);
    if (await f.length() > 5 * 1024 * 1024) {
      if (mounted) toast(context, 'L’image ne doit pas dépasser 5 Mo.');
      return;
    }
    setState(() => _image = f);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final fields = {
        'title': _title.text.trim(),
        'description': _desc.text.trim(),
        'occasion': _occasion,
        if (_editing) 'access_code': _code.text.trim(),
      };
      final res = await Api.instance.multipart(_editing ? '/lists/${widget.list!.id}/update' : '/lists', fields, file: _image);
      if (mounted) Navigator.pop(context, GiftList.fromJson(res));
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (mounted) toast(context, e.errors.values.firstOrNull?.first ?? e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final occasions = SessionScope.of(context).meta.occasions;
    return Scaffold(
      appBar: TopBar(_editing ? 'Modifier ma liste' : 'Nouvelle liste'),
      bottomNavigationBar: const AppBottomNav(current: 2),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
          Text(tr('Une liste à votre image.'), style: T.serif(32)),
          const SizedBox(height: 16),
          Text(tr('Rassemblez vos envies. Vos proches choisiront ce qui leur fait plaisir.'), style: T.sans(14, color: AppColors.gray)),
          const SizedBox(height: 26),
          LabeledField(
            label: 'Titre de la liste *', controller: _title, hint: 'Mon anniversaire', errorText: _error?.field('title'),
            validator: (v) => (v ?? '').trim().isEmpty ? tr('Donnez un titre à votre liste.') : null,
          ),
          LabeledField(label: 'Description', controller: _desc, maxLines: 3, hint: 'Quelques envies pour mes 30 ans…'),
          const FieldLabel('Image de la liste'),
          GestureDetector(
            onTap: _pick,
            child: Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                border: Border.all(color: AppColors.border),
                borderRadius: BorderRadius.circular(14),
              ),
              child: _image != null
                  ? ClipRRect(borderRadius: BorderRadius.circular(10), child: Image.file(_image!, height: 140, width: double.infinity, fit: BoxFit.cover))
                  : Row(children: [
                      const Icon(Icons.add_photo_alternate_outlined, color: AppColors.magenta),
                      const SizedBox(width: 14),
                      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(_editing ? 'Changer l’image' : 'Ajouter une image', style: T.sans(14, weight: FontWeight.w600)),
                        const SizedBox(height: 4),
                        Text(tr('JPG ou PNG · 5 Mo maximum'), style: T.sans(11, color: AppColors.gray)),
                      ]),
                    ]),
            ),
          ),
          const SizedBox(height: 24),
          const FieldLabel('Occasion *'),
          Wrap(spacing: 8, runSpacing: 10, children: [
            for (final o in occasions) Pill(o, selected: _occasion == o, onTap: () => setState(() => _occasion = o)),
          ]),
          const SizedBox(height: 18),
          Text(tr('Pour un deuil, une présentation sobre et un message de soutien seront privilégiés. * Champ obligatoire.'),
              style: T.sans(11, color: AppColors.gray)),
          if (_editing) ...[
            const SizedBox(height: 22),
            LabeledField(label: 'Code d’accès (facultatif)', controller: _code, hint: 'Laisser vide pour un lien public'),
          ],
          const SizedBox(height: 26),
          PrimaryButton(_editing ? 'Enregistrer' : 'Créer ma liste', loading: _busy, onPressed: _submit),
        ]),
      ),
    );
  }
}
