import 'package:flutter/material.dart';

import '../core/api.dart';
import '../core/i18n.dart';
import '../core/session.dart';
import '../core/theme.dart';
import '../widgets/common.dart';
import 'wrapping_screen.dart';

/// Commande d'un cadeau (paiement Mobile Money confirmé ensuite par l'équipe / l'agrégateur).
class OrderScreen extends StatefulWidget {
  const OrderScreen({super.key, required this.gift, this.wrapping, this.listItemId});
  final Gift gift;
  final Wrapping? wrapping;
  final int? listItemId;

  @override
  State<OrderScreen> createState() => _OrderScreenState();
}

class _OrderScreenState extends State<OrderScreen> {
  final _form = GlobalKey<FormState>();
  late final _user = SessionScope.read(context).user;
  late final _name = TextEditingController(text: _user?.name);
  late final _phone = TextEditingController(text: _user?.phone);
  late final _city = TextEditingController(text: widget.gift.city);
  final _address = TextEditingController();
  final _message = TextEditingController();
  late Wrapping? _wrap = widget.wrapping;
  String _payment = 'orange_money';
  bool _busy = false;
  ApiException? _error;

  Future<void> _submit() async {
    if (!_form.currentState!.validate()) return;
    setState(() { _busy = true; _error = null; });
    try {
      final res = await Api.instance.post('/orders', {
        'gift_id': widget.gift.id,
        'list_item_id': widget.listItemId,
        'wrapping_id': _wrap?.id,
        'customer_name': _name.text.trim(),
        'customer_phone': _phone.text.trim(),
        'customer_email': _user?.email,
        'delivery_city': _city.text.trim(),
        'delivery_address': _address.text.trim(),
        'message': _message.text.trim(),
        'payment_method': _payment,
      });
      if (!mounted) return;
      await showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text(tr('Merci pour cette belle attention.'), style: T.serif(22)),
          content: Text('${res['message']}\n\n${tr('Référence :')} ${res['order']['reference']}', style: T.sans(13)),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: Text(tr('OK')))],
        ),
      );
      if (mounted) Navigator.pop(context, true);
    } on ApiException catch (e) {
      setState(() => _error = e);
      if (e.errors.isEmpty && mounted) toast(context, e.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  String? _req(String? v) => (v ?? '').trim().isEmpty ? tr('Champ obligatoire.') : null;

  @override
  Widget build(BuildContext context) {
    final g = widget.gift;
    final total = g.price + (_wrap?.price ?? 0);
    return Scaffold(
      appBar: const TopBar('Commander'),
      body: Form(
        key: _form,
        child: ListView(padding: const EdgeInsets.fromLTRB(kGutter, 8, kGutter, 28), children: [
          Panel(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              NetImage(g.imageUrl, width: 80, height: 80, radius: 14),
              const SizedBox(width: 14),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(g.name, style: T.sans(14, weight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(g.place, style: T.sans(12, color: AppColors.gray)),
                  const SizedBox(height: 6),
                  Text(formatPrice(g.price, g.currency), style: T.sans(14, weight: FontWeight.w600, color: AppColors.magenta)),
                ]),
              ),
            ]),
          ),
          const SizedBox(height: 26),
          LabeledField(label: 'Nom *', controller: _name, validator: _req, errorText: _error?.field('customer_name')),
          LabeledField(label: 'Téléphone Mobile Money *', controller: _phone, keyboard: TextInputType.phone, validator: _req, hint: '+225 07 00 00 00 00', errorText: _error?.field('customer_phone')),
          LabeledField(label: 'Ville de livraison', controller: _city),
          LabeledField(
            label: 'Lieu de livraison *',
            controller: _address,
            hint: 'Quartier, rue et point de repère',
            validator: _req,
            errorText: _error?.field('delivery_address'),
          ),
          LabeledField(label: 'Petit mot (facultatif)', controller: _message, maxLines: 3, hint: 'Joyeux anniversaire !'),
          const FieldLabel('Emballage'),
          GestureDetector(
            onTap: () async {
              final w = await Navigator.push<Wrapping?>(context, MaterialPageRoute(builder: (_) => WrappingScreen(selected: _wrap)));
              if (mounted) setState(() => _wrap = w);
            },
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(border: Border.all(color: AppColors.border), borderRadius: BorderRadius.circular(12)),
              child: Row(children: [
                Expanded(child: Text(_wrap?.name ?? tr('Sans emballage'), style: T.sans(13))),
                Text(tr('Changer'), style: T.sans(12, color: AppColors.magenta, weight: FontWeight.w600)),
              ]),
            ),
          ),
          const SizedBox(height: 20),
          const FieldLabel('Paiement *'),
          Wrap(spacing: 8, children: [
            Pill('Orange Money', selected: _payment == 'orange_money', onTap: () => setState(() => _payment = 'orange_money')),
            Pill('MTN Mobile Money', selected: _payment == 'mtn_momo', onTap: () => setState(() => _payment = 'mtn_momo')),
          ]),
          const SizedBox(height: 26),
          PrimaryButton('Commander · ${formatPrice(total, g.currency)}', loading: _busy, onPressed: _submit),
          const SizedBox(height: 14),
          Text(tr('Vous recevrez une demande de paiement Mobile Money. La facture est émise par la boutique.'),
              style: T.sans(11, color: AppColors.gray)),
        ]),
      ),
    );
  }
}
