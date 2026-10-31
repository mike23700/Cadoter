import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';

/// « Mon profil » : dates à célébrer, informations personnelles et mot de passe (comme sur le web).
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = SessionScope.of(context).user;
    if (user == null) return const Scaffold(appBar: TopBar('Mon profil'), body: SizedBox());
    return Scaffold(
      appBar: const TopBar('Mon profil'),
      body: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 32), children: [
        Panel(
          pink: true,
          child: Row(children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: AppColors.magenta,
              child: Text(user.initials, style: T.sans(16, color: AppColors.white, weight: FontWeight.w600)),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(user.name, style: T.sans(18, weight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text(user.email, style: T.sans(12, color: AppColors.gray)),
                const SizedBox(height: 4),
                Text('${user.phone ?? tr('Non renseigné')} · ${user.language == 'en' ? 'English' : 'Français'}',
                    style: T.sans(12, color: AppColors.gray)),
              ]),
            ),
          ]),
        ),
        const SizedBox(height: 28),
        const _ImportantDates(),
        const SizedBox(height: 28),
        const _PersonalInfo(),
        const SizedBox(height: 28),
        const _Password(),
      ]),
    );
  }
}

class _SectionHead extends StatelessWidget {
  const _SectionHead({required this.icon, required this.eyebrow, required this.title, required this.text});
  final IconData icon;
  final String eyebrow;
  final String title;
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 20),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Icon(icon, color: AppColors.magenta, size: 22),
          const SizedBox(width: 12),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Eyebrow(eyebrow),
              const SizedBox(height: 6),
              Text(tr(title), style: T.serif(22)),
              const SizedBox(height: 6),
              Text(tr(text), style: T.sans(12, color: AppColors.gray)),
            ]),
          ),
        ]),
      );
}

String? _req(String? v) => (v ?? '').trim().isEmpty ? tr('Champ obligatoire.') : null;

// ---------------------------------------------------------------- Dates à célébrer

class _ImportantDates extends StatefulWidget {
  const _ImportantDates();

  @override
  State<_ImportantDates> createState() => _ImportantDatesState();
}

class _ImportantDatesState extends State<_ImportantDates> {
  final _form = GlobalKey<FormState>();
  final _person = TextEditingController();
  final _title = TextEditingController();
  DateTime? _date;
  int? _editingId;
  int? _deletingId;
  bool _busy = false;
  ApiException? _error;
  late Future<List<ImportantDate>> _dates = _load();

  Future<List<ImportantDate>> _load() async {
    final list = ((await Api.instance.get('/important-dates')) as List).map((e) => ImportantDate.fromJson(e)).toList();
    return list..sort((a, b) => a.nextOccurrence.compareTo(b.nextOccurrence));
  }

  void _reload() => setState(() => _dates = _load());

  void _reset() {
    _person.clear();
    _title.clear();
    setState(() { _date = null; _editingId = null; _error = null; });
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: _date ?? now, firstDate: DateTime(1900), lastDate: DateTime(now.year + 10));
    if (d != null) setState(() => _date = d);
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (_date == null) {
      toast(context, 'Choisissez la date de l’événement.');
      return;
    }
    setState(() { _busy = true; _error = null; });
    final d = _date!;
    final body = {
      'person_name': _person.text.trim(),
      'title': _title.text.trim(),
      'event_date': '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}',
    };
    final editing = _editingId != null;
    try {
      editing ? await Api.instance.put('/important-dates/$_editingId', body) : await Api.instance.post('/important-dates', body);
      _reset();
      _reload();
      if (mounted) toast(context, editing ? 'Date modifiée.' : 'Date ajoutée.');
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (e.errors.isEmpty && mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  void _edit(ImportantDate d) {
    _person.text = d.personName;
    _title.text = d.title;
    setState(() { _date = d.eventDate; _editingId = d.id; _error = null; });
  }

  Future<void> _delete(ImportantDate d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        content: Text(tr('Supprimer cette date ?'), style: T.sans(14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(tr('Annuler'))),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(tr('Supprimer'), style: const TextStyle(color: AppColors.error))),
        ],
      ),
    );
    if (ok != true) return;
    setState(() => _deletingId = d.id);
    try {
      await Api.instance.delete('/important-dates/${d.id}');
      if (_editingId == d.id) _reset();
      _reload();
      if (mounted) toast(context, 'Date supprimée.');
    } on ApiException catch (e) {
      if (mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _deletingId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = SessionScope.of(context).user?.email ?? '';
    return Panel(
      child: Form(
        key: _form,
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const _SectionHead(
            icon: Icons.cake_outlined,
            eyebrow: 'Vos dates à célébrer',
            title: 'Les moments qui comptent',
            text: 'Enregistrez les anniversaires et autres événements de vos proches. Chaque date revient automatiquement chaque année.',
          ),
          LabeledField(label: 'Personne *', controller: _person, hint: 'Ex. Aïcha et Karim', validator: _req, errorText: _error?.field('person_name')),
          LabeledField(label: 'Titre de l’événement *', controller: _title, hint: 'Ex. Anniversaire de mariage', validator: _req, errorText: _error?.field('title')),
          const FieldLabel('Date de l’événement *'),
          InkWell(
            onTap: _pickDate,
            child: InputDecorator(
              decoration: InputDecoration(errorText: _error?.field('event_date'), suffixIcon: const Icon(Icons.calendar_today_outlined, size: 18)),
              child: Text(_date == null ? tr('Choisir une date') : formatFullDate(_date!),
                  style: T.sans(13, color: _date == null ? AppColors.gray : AppColors.dark)),
            ),
          ),
          const SizedBox(height: 14),
          Text(tr('Un e-mail sera envoyé à {email} une semaine avant, 3 jours avant et le jour même.', {'email': email}),
              style: T.sans(11, color: AppColors.gray)),
          const SizedBox(height: 16),
          PrimaryButton(_editingId != null ? 'Mettre à jour la date' : 'Ajouter cette date', loading: _busy, onPressed: _submit),
          if (_editingId != null) ...[
            const SizedBox(height: 10),
            SecondaryButton('Annuler', onPressed: _reset),
          ],
          const SizedBox(height: 22),
          FutureBuilder<List<ImportantDate>>(
            future: _dates,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) return const Loader();
              if (snap.hasError) return ErrorRetry('${snap.error}', onRetry: _reload);
              final dates = snap.data!;
              if (dates.isEmpty) return Text(tr('Aucune date enregistrée pour le moment.'), style: T.sans(13, color: AppColors.gray));
              return Column(children: [
                for (final d in dates)
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppColors.border))),
                    child: Row(children: [
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(tr('Prochaine date : {date}', {'date': formatFullDate(d.nextOccurrence)}),
                              style: T.sans(11, weight: FontWeight.w600, color: AppColors.magenta)),
                          const SizedBox(height: 4),
                          Text(d.title, style: T.sans(14, weight: FontWeight.w600)),
                          Text(tr('Pour {person}', {'person': d.personName}), style: T.sans(12, color: AppColors.gray)),
                        ]),
                      ),
                      IconButton(tooltip: tr('Modifier'), onPressed: () => _edit(d), icon: const Icon(Icons.edit_outlined, size: 20)),
                      IconButton(
                        tooltip: tr('Supprimer'),
                        onPressed: _deletingId == d.id ? null : () => _delete(d),
                        icon: const Icon(Icons.delete_outline, size: 20, color: AppColors.error),
                      ),
                    ]),
                  ),
              ]);
            },
          ),
        ]),
      ),
    );
  }
}

// ---------------------------------------------------------------- Informations personnelles

class _PersonalInfo extends StatefulWidget {
  const _PersonalInfo();

  @override
  State<_PersonalInfo> createState() => _PersonalInfoState();
}

class _PersonalInfoState extends State<_PersonalInfo> {
  final _form = GlobalKey<FormState>();
  late final _user = SessionScope.read(context).user!;
  late final _name = TextEditingController(text: _user.name);
  late final _email = TextEditingController(text: _user.email);
  late final _phone = TextEditingController(text: _user.phone);
  late String _language = _user.language == 'en' ? 'en' : 'fr';
  bool _busy = false;
  ApiException? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await SessionScope.read(context).updateUser({
        'name': _name.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
        'language': _language,
      });
      if (mounted) toast(context, 'Votre profil a été mis à jour.');
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (e.errors.isEmpty && mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Panel(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionHead(
              icon: Icons.person_outline,
              eyebrow: 'Coordonnées',
              title: 'Informations personnelles',
              text: 'Ces informations servent à gérer votre compte et vos commandes.',
            ),
            LabeledField(label: 'Nom complet *', controller: _name, validator: _req, errorText: _error?.field('name'), autofill: const [AutofillHints.name]),
            LabeledField(
              label: 'Adresse email *', controller: _email, keyboard: TextInputType.emailAddress, validator: _req,
              errorText: _error?.field('email'), autofill: const [AutofillHints.email],
            ),
            LabeledField(
              label: 'Téléphone', controller: _phone, keyboard: TextInputType.phone, hint: '+225 07 00 00 00 00',
              errorText: _error?.field('phone'), autofill: const [AutofillHints.telephoneNumber],
            ),
            DropdownField(
              label: 'Langue',
              value: _language,
              items: const ['fr', 'en'],
              display: (l) => l == 'en' ? 'English' : 'Français',
              onChanged: (v) => setState(() => _language = v ?? 'fr'),
            ),
            Text(tr('Les champs marqués d’un * sont obligatoires.'), style: T.sans(11, color: AppColors.gray)),
            const SizedBox(height: 16),
            PrimaryButton('Enregistrer les modifications', loading: _busy, onPressed: _submit),
          ]),
        ),
      );
}

// ---------------------------------------------------------------- Mot de passe

class _Password extends StatefulWidget {
  const _Password();

  @override
  State<_Password> createState() => _PasswordState();
}

class _PasswordState extends State<_Password> {
  final _form = GlobalKey<FormState>();
  final _current = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await SessionScope.read(context).updatePassword(_current.text, _password.text, _confirm.text);
      _current.clear();
      _password.clear();
      _confirm.clear();
      if (mounted) toast(context, 'Votre mot de passe a été modifié.');
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (e.errors.isEmpty && mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Panel(
        child: Form(
          key: _form,
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const _SectionHead(
              icon: Icons.lock_outline,
              eyebrow: 'Sécurité du compte',
              title: 'Mot de passe',
              text: 'Confirmez votre mot de passe actuel pour en choisir un nouveau.',
            ),
            LabeledField(label: 'Mot de passe actuel', controller: _current, obscure: true, validator: _req, errorText: _error?.field('current_password')),
            LabeledField(
              label: 'Nouveau mot de passe', controller: _password, obscure: true, errorText: _error?.field('password'),
              validator: (v) => (v ?? '').length < 8 ? tr('8 caractères minimum.') : null,
            ),
            LabeledField(
              label: 'Confirmer le nouveau mot de passe', controller: _confirm, obscure: true, errorText: _error?.field('password_confirmation'),
              validator: (v) => v != _password.text ? tr('Les mots de passe ne correspondent pas.') : null,
            ),
            PrimaryButton('Modifier le mot de passe', loading: _busy, onPressed: _submit),
          ]),
        ),
      );
}
