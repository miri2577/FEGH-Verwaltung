import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/billing_provider.dart';

/// Editor fuer einen Rechnungsempfaenger (Kostentraeger).
/// Mit Leitweg-ID-Validierung fuer XRechnung-Konformitaet.
class EmpfaengerEditorScreen extends ConsumerStatefulWidget {
  final RechnungEmpfaenger? existing;

  const EmpfaengerEditorScreen({super.key, this.existing});

  @override
  ConsumerState<EmpfaengerEditorScreen> createState() =>
      _EmpfaengerEditorScreenState();
}

class _EmpfaengerEditorScreenState
    extends ConsumerState<EmpfaengerEditorScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late final TextEditingController _abteilungCtrl;
  late final TextEditingController _ansprechCtrl;
  late final TextEditingController _strasseCtrl;
  late final TextEditingController _plzCtrl;
  late final TextEditingController _ortCtrl;
  late final TextEditingController _landCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _telefonCtrl;
  late final TextEditingController _leitwegCtrl;
  late final TextEditingController _ustCtrl;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _abteilungCtrl = TextEditingController(text: e?.abteilung ?? '');
    _ansprechCtrl = TextEditingController(text: e?.ansprechpartner ?? '');
    _strasseCtrl = TextEditingController(text: e?.strasse ?? '');
    _plzCtrl = TextEditingController(text: e?.plz ?? '');
    _ortCtrl = TextEditingController(text: e?.ort ?? '');
    _landCtrl = TextEditingController(text: e?.land ?? 'DE');
    _emailCtrl = TextEditingController(text: e?.email ?? '');
    _telefonCtrl = TextEditingController(text: e?.telefon ?? '');
    _leitwegCtrl = TextEditingController(text: e?.leitwegId ?? '');
    _ustCtrl = TextEditingController(text: e?.umsatzsteuerId ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _abteilungCtrl.dispose();
    _ansprechCtrl.dispose();
    _strasseCtrl.dispose();
    _plzCtrl.dispose();
    _ortCtrl.dispose();
    _landCtrl.dispose();
    _emailCtrl.dispose();
    _telefonCtrl.dispose();
    _leitwegCtrl.dispose();
    _ustCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final isNew = widget.existing == null;
    final e = isNew
        ? RechnungEmpfaenger.create(
            name: _nameCtrl.text.trim(),
            abteilung: _abteilungCtrl.text.trim().isEmpty
                ? null
                : _abteilungCtrl.text.trim(),
            ansprechpartner: _ansprechCtrl.text.trim().isEmpty
                ? null
                : _ansprechCtrl.text.trim(),
            strasse: _strasseCtrl.text.trim(),
            plz: _plzCtrl.text.trim(),
            ort: _ortCtrl.text.trim(),
            land: _landCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty
                ? null
                : _emailCtrl.text.trim(),
            telefon: _telefonCtrl.text.trim().isEmpty
                ? null
                : _telefonCtrl.text.trim(),
            leitwegId: _leitwegCtrl.text.trim(),
            umsatzsteuerId: _ustCtrl.text.trim().isEmpty
                ? null
                : _ustCtrl.text.trim(),
          )
        : RechnungEmpfaenger(
            id: widget.existing!.id,
            erstelltAm: widget.existing!.erstelltAm,
            name: _nameCtrl.text.trim(),
            abteilung: _abteilungCtrl.text.trim().isEmpty
                ? null
                : _abteilungCtrl.text.trim(),
            ansprechpartner: _ansprechCtrl.text.trim().isEmpty
                ? null
                : _ansprechCtrl.text.trim(),
            strasse: _strasseCtrl.text.trim(),
            plz: _plzCtrl.text.trim(),
            ort: _ortCtrl.text.trim(),
            land: _landCtrl.text.trim(),
            email: _emailCtrl.text.trim().isEmpty
                ? null
                : _emailCtrl.text.trim(),
            telefon: _telefonCtrl.text.trim().isEmpty
                ? null
                : _telefonCtrl.text.trim(),
            leitwegId: _leitwegCtrl.text.trim(),
            umsatzsteuerId: _ustCtrl.text.trim().isEmpty
                ? null
                : _ustCtrl.text.trim(),
          );

    final notifier = ref.read(empfaengerProvider.notifier);
    final ok = isNew ? await notifier.add(e) : await notifier.update(e);
    if (!mounted) return;
    if (ok) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Speichern fehlgeschlagen'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.existing == null
            ? 'Neuer Empfaenger'
            : 'Empfaenger bearbeiten'),
        actions: [
          TextButton(onPressed: _save, child: const Text('Speichern')),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _nameCtrl,
              decoration: const InputDecoration(
                labelText: 'Name *',
                hintText: 'z.B. Bezirksamt Mitte von Berlin - Soziales',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _abteilungCtrl,
              decoration: const InputDecoration(
                labelText: 'Abteilung',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ansprechCtrl,
              decoration: const InputDecoration(
                labelText: 'Ansprechpartner',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _strasseCtrl,
              decoration: const InputDecoration(
                labelText: 'Strasse + Nr. *',
                border: OutlineInputBorder(),
              ),
              validator: (v) =>
                  v == null || v.trim().isEmpty ? 'Pflichtfeld' : null,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                SizedBox(
                  width: 120,
                  child: TextFormField(
                    controller: _plzCtrl,
                    decoration: const InputDecoration(
                      labelText: 'PLZ *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Pflicht' : null,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: _ortCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Ort *',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) =>
                        v == null || v.trim().isEmpty ? 'Pflicht' : null,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _landCtrl,
              decoration: const InputDecoration(
                labelText: 'Land (ISO-Code)',
                hintText: 'DE',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _leitwegCtrl,
              decoration: const InputDecoration(
                labelText: 'Leitweg-ID *',
                hintText: 'z.B. 993-12345-67',
                helperText: 'Format: NNNNN-xxxxxxxxxxx-NN (XRechnung Pflicht)',
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Pflichtfeld';
                // Basic-Regex fuer Leitweg-ID
                final ok = RegExp(r'^[0-9]{2,12}(-[A-Za-z0-9]+)?(-[0-9]{2})?$')
                    .hasMatch(v.trim());
                return ok ? null : 'Ungueltiges Leitweg-ID-Format';
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _ustCtrl,
              decoration: const InputDecoration(
                labelText: 'USt-IdNr. (optional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _emailCtrl,
              decoration: const InputDecoration(
                labelText: 'E-Mail',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _telefonCtrl,
              decoration: const InputDecoration(
                labelText: 'Telefon',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
