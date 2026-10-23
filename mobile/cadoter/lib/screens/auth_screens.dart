import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'shell.dart';

/// Ouvre la connexion si besoin. Renvoie true si l'utilisateur est connecté au retour.
Future<bool> ensureLoggedIn(BuildContext context) async {
  if (SessionScope.read(context).isLoggedIn) return true;
  await Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
  return context.mounted && SessionScope.read(context).isLoggedIn;
}

/// « Mobile · Connexion ». Avec [gate], c'est le passage obligatoire avant l'accueil (pas de retour possible).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, this.gate = false});
  final bool gate;

  /// Remplace toute la pile par l'écran de connexion obligatoire (après onboarding ou déconnexion).
  static void openGate(BuildContext context) => Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginScreen(gate: true)), (_) => false);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _form = GlobalKey<FormState>();
  final _login = TextEditingController();
  final _password = TextEditingController();
  bool _busy = false;
  ApiException? _error;

  void _done() {
    if (widget.gate) {
      SessionScope.read(context).goTab(0);
      Navigator.of(context).pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const Shell()), (_) => false);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      await SessionScope.read(context).login(_login.text.trim(), _password.text);
      if (mounted) _done();
    } on ApiException catch (e) {
      setState(() => _error = e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: TopBar('Se connecter', showBack: !widget.gate),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 24), children: [
              const NetImage('assets/images/emballage-rose.jpg', aspect: 354 / 175),
              const SizedBox(height: 30),
              Text(tr('Heureux de vous retrouver.'), style: T.serif(34)),
              const SizedBox(height: 16),
              Text(tr('Vos envies et vos prochaines attentions vous attendent.'), style: T.sans(14, color: AppColors.gray)),
              const SizedBox(height: 26),
              LabeledField(
                label: 'Email / Téléphone',
                controller: _login,
                hint: 'aicha@exemple.com',
                keyboard: TextInputType.emailAddress,
                autofill: const [AutofillHints.username],
                errorText: _error?.field('login'),
                validator: (v) => (v ?? '').trim().isEmpty ? tr('Saisissez votre email ou téléphone.') : null,
              ),
              LabeledField(
                label: 'Mot de passe',
                controller: _password,
                hint: '••••••••••',
                obscure: true,
                autofill: const [AutofillHints.password],
                validator: (v) => (v ?? '').isEmpty ? tr('Saisissez votre mot de passe.') : null,
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: GestureDetector(
                  onTap: () => toast(context, 'Écrivez-nous à contact@cadoter.com pour réinitialiser votre mot de passe.'),
                  child: Text(tr('Mot de passe oublié ?'), style: T.sans(12, color: AppColors.magenta)),
                ),
              ),
              if (_error != null && _error!.errors.isEmpty) ...[
                const SizedBox(height: 14),
                Text(_error!.message, style: T.sans(12, color: AppColors.error)),
              ],
              const SizedBox(height: 26),
              PrimaryButton('Me connecter', loading: _busy, onPressed: _submit),
              const SizedBox(height: 22),
              SecondaryButton('Créer un compte', onPressed: () async {
                await Navigator.push(context, MaterialPageRoute(builder: (_) => const SignupScreen()));
                if (context.mounted && SessionScope.read(context).isLoggedIn) _done();
              }),
            ]),
          ),
        ),
      );
}

/// « Mobile · Inscription »
class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _terms = false;
  bool _busy = false;
  ApiException? _error;

  String? _required(String? v) => (v ?? '').trim().isEmpty ? tr('Champ obligatoire.') : null;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    if (!_terms) {
      toast(context, "Veuillez accepter les conditions d'utilisation.");
      return;
    }
    setState(() { _busy = true; _error = null; });
    try {
      await SessionScope.read(context).register({
        'name': _name.text.trim(),
        'phone': _phone.text.trim(),
        'email': _email.text.trim(),
        'password': _password.text,
        'password_confirmation': _confirm.text,
        'terms': true,
        'language': SessionScope.read(context).language,
      });
      if (mounted) Navigator.pop(context);
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (e.errors.isEmpty && mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: const TopBar('Créer mon compte'),
        body: SafeArea(
          child: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 12, kGutter, 24), children: [
              Text(tr('Bienvenue dans les belles attentions.'), style: T.serif(30)),
              const SizedBox(height: 26),
              LabeledField(label: 'Nom *', controller: _name, hint: 'Aïcha Koné', validator: _required, errorText: _error?.field('name'), autofill: const [AutofillHints.name]),
              LabeledField(label: 'Téléphone *', controller: _phone, hint: '+225 07 00 00 00 00', keyboard: TextInputType.phone, validator: _required, errorText: _error?.field('phone'), autofill: const [AutofillHints.telephoneNumber]),
              LabeledField(
                label: 'Email *', controller: _email, hint: 'aicha@exemple.com', keyboard: TextInputType.emailAddress,
                errorText: _error?.field('email'), autofill: const [AutofillHints.email],
                validator: (v) => RegExp(r'^\S+@\S+\.\S+$').hasMatch((v ?? '').trim()) ? null : tr('Email invalide.'),
              ),
              LabeledField(
                label: 'Mot de passe *', controller: _password, hint: '••••••••••', obscure: true, errorText: _error?.field('password'),
                validator: (v) => (v ?? '').length < 8 ? tr('8 caractères minimum.') : null,
              ),
              LabeledField(
                label: 'Confirmer le mot de passe *', controller: _confirm, hint: '••••••••••', obscure: true,
                validator: (v) => v != _password.text ? tr('Les mots de passe ne correspondent pas.') : null,
              ),
              Text(tr('8 caractères minimum. * Champs obligatoires.'), style: T.sans(11, color: AppColors.gray)),
              const SizedBox(height: 22),
              GestureDetector(
                onTap: () => setState(() => _terms = !_terms),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(_terms ? Icons.check_box_outlined : Icons.check_box_outline_blank, color: AppColors.magenta, size: 22),
                  const SizedBox(width: 10),
                  Expanded(child: Text(tr("J'accepte les conditions d'utilisation et la politique de confidentialité."), style: T.sans(12))),
                ]),
              ),
              const SizedBox(height: 22),
              PrimaryButton('Créer mon compte', loading: _busy, onPressed: _submit),
              const SizedBox(height: 22),
              Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Text(tr('Déjà inscrit·e ? Se connecter'), style: T.sans(12)),
                ),
              ),
            ]),
          ),
        ),
      );
}
