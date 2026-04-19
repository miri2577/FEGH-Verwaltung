import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:material_symbols_icons/symbols.dart';

import '../../services/med_pin_service.dart';

/// Zeigt einen PIN-Prompt fuer [employeeId]. Gibt `true` zurueck, wenn
/// der PIN korrekt war (oder wenn fuer diesen Mitarbeiter keiner gesetzt
/// ist). Gibt `false` bei Falsch-Eingabe oder Abbruch.
Future<bool> promptMedPin(
  BuildContext context, {
  required String employeeId,
  required String employeeName,
  MedPinService? service,
}) async {
  final svc = service ?? MedPinService();
  if (!await svc.isSet(employeeId)) return true;
  if (!context.mounted) return false;
  final ok = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _MedPinVerifyDialog(
      employeeId: employeeId,
      employeeName: employeeName,
      service: svc,
    ),
  );
  return ok == true;
}

class _MedPinVerifyDialog extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final MedPinService service;

  const _MedPinVerifyDialog({
    required this.employeeId,
    required this.employeeName,
    required this.service,
  });

  @override
  State<_MedPinVerifyDialog> createState() => _MedPinVerifyDialogState();
}

class _MedPinVerifyDialogState extends State<_MedPinVerifyDialog> {
  final _pin = TextEditingController();
  String? _error;
  int _tries = 0;

  @override
  void dispose() {
    _pin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Medikations-PIN'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Bestaetigung fuer: ${widget.employeeName}'),
          const SizedBox(height: 12),
          TextField(
            controller: _pin,
            autofocus: true,
            obscureText: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 8,
            decoration: InputDecoration(
              labelText: 'PIN',
              errorText: _error,
              prefixIcon: const Icon(Symbols.lock),
            ),
            onSubmitted: (_) => _verify(),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _verify,
          child: const Text('Bestaetigen'),
        ),
      ],
    );
  }

  Future<void> _verify() async {
    final pin = _pin.text.trim();
    if (pin.length < 4) {
      setState(() => _error = 'Mindestens 4 Ziffern.');
      return;
    }
    final ok = await widget.service.verifyPin(widget.employeeId, pin);
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      _tries++;
      setState(() {
        _error = 'PIN falsch. Versuch $_tries von 3.';
        _pin.clear();
      });
      if (_tries >= 3) {
        Navigator.of(context).pop(false);
      }
    }
  }
}

/// Dialog zum Setzen oder Aendern der Medikations-PIN.
///
/// Wird aus den Einstellungen oder beim ersten Gabe-Versuch aufgerufen,
/// wenn der Mitarbeiter die PIN-Option aktiviert hat.
class MedPinSetupDialog extends StatefulWidget {
  final String employeeId;
  final String employeeName;
  final MedPinService? service;
  final bool requireCurrent;

  const MedPinSetupDialog({
    super.key,
    required this.employeeId,
    required this.employeeName,
    this.service,
    this.requireCurrent = false,
  });

  @override
  State<MedPinSetupDialog> createState() => _MedPinSetupDialogState();
}

class _MedPinSetupDialogState extends State<MedPinSetupDialog> {
  final _current = TextEditingController();
  final _new = TextEditingController();
  final _repeat = TextEditingController();
  String? _error;
  late final MedPinService _svc;

  @override
  void initState() {
    super.initState();
    _svc = widget.service ?? MedPinService();
  }

  @override
  void dispose() {
    _current.dispose();
    _new.dispose();
    _repeat.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.requireCurrent
          ? 'Medikations-PIN aendern'
          : 'Medikations-PIN einrichten'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Fuer: ${widget.employeeName}'),
            const SizedBox(height: 12),
            if (widget.requireCurrent) ...[
              TextField(
                controller: _current,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                maxLength: 8,
                decoration:
                    const InputDecoration(labelText: 'Aktueller PIN'),
              ),
              const SizedBox(height: 8),
            ],
            TextField(
              controller: _new,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 8,
              decoration: const InputDecoration(labelText: 'Neuer PIN'),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _repeat,
              obscureText: true,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              maxLength: 8,
              decoration: const InputDecoration(labelText: 'PIN wiederholen'),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!,
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.error)),
            ],
            const SizedBox(height: 8),
            Text(
              'PIN wird PBKDF2-gehasht (100.000 Iterationen, SHA-256) und '
              'nur lokal im sicheren Geraetespeicher abgelegt.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.outline,
                  ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Abbrechen'),
        ),
        FilledButton(
          onPressed: _save,
          child: const Text('Speichern'),
        ),
      ],
    );
  }

  Future<void> _save() async {
    final newPin = _new.text.trim();
    final repeat = _repeat.text.trim();
    if (newPin.length < 4) {
      setState(() => _error = 'PIN muss mind. 4 Ziffern haben.');
      return;
    }
    if (newPin != repeat) {
      setState(() => _error = 'PINs stimmen nicht ueberein.');
      return;
    }
    if (widget.requireCurrent) {
      final currentOk = await _svc.verifyPin(
        widget.employeeId,
        _current.text.trim(),
      );
      if (!currentOk) {
        setState(() => _error = 'Aktueller PIN falsch.');
        return;
      }
    }
    await _svc.setPin(widget.employeeId, newPin);
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }
}
