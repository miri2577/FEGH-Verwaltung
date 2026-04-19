// Integrationstest: XRechnung-XML wird gegen den KoSIT-Validator geprueft.
//
// Startet den **echten** KoSIT Validator als Java-Subprozess. Benoetigt:
//   - Java 11+ im PATH
//   - `FEGH_KOSIT_JAR`            — Pfad zur validationtool-*-standalone.jar
//   - `FEGH_XRECHNUNG_SCENARIO`   — Pfad zur scenarios.xml
//   - `FEGH_XRECHNUNG_REPO`       — Verzeichnis der scenarios.xml (+ resources/)
//
// Wenn die Variablen nicht gesetzt sind, wird der Test per `skip`
// uebersprungen — die Suite bleibt gruen auch ohne installierte Tools.
// Setup siehe Wiki "Technik → Test-Tools einrichten" oder
// `scripts/install-test-tools.{sh,ps1}`.
@Tags(['integration'])
library;

import 'dart:io';

import 'package:fegh_billing/fegh_billing.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

void main() {
  final kositJar = Platform.environment['FEGH_KOSIT_JAR'];
  final scenario = Platform.environment['FEGH_XRECHNUNG_SCENARIO'];
  final repo = Platform.environment['FEGH_XRECHNUNG_REPO'];
  final available = _isFile(kositJar) && _isFile(scenario) && _isDir(repo);

  group('XRechnung KoSIT-Validierung', () {
    test('buildXml erzeugt ACCEPTABLE Report', () async {
      final service = XRechnungService(rechnungssteller: _sampleSteller());
      final xml = service.buildXml(
        rechnung: _sampleRechnung(),
        empfaenger: _sampleEmpfaenger(),
      );

      final tmpDir =
          Directory.systemTemp.createTempSync('fegh-xrechnung-test-');
      addTearDown(() => tmpDir.deleteSync(recursive: true));
      final xmlFile = File(p.join(tmpDir.path, 'rechnung.xml'))
        ..writeAsStringSync(xml);

      final reportDir = Directory(p.join(tmpDir.path, 'report'))
        ..createSync();
      final result = await Process.run(
        'java',
        [
          '-jar', kositJar!,
          '-r', repo!,
          '-s', scenario!,
          '-o', reportDir.path,
          xmlFile.path,
        ],
        workingDirectory: tmpDir.path,
      );

      final stdout = result.stdout.toString();
      final rejected = stdout.contains('Rejected:  1') ||
          !stdout.contains('Acceptable:  1');

      // Bei Fehler: Report-XML (oder html) ausgeben, damit die konkrete
      // Regel/Schema-Violation sichtbar ist.
      String reportDump = '';
      if (rejected) {
        final reportFiles = reportDir.listSync().whereType<File>().toList();
        for (final f in reportFiles) {
          reportDump +=
              '\n--- ${p.basename(f.path)} ---\n${f.readAsStringSync()}';
        }
      }

      expect(result.exitCode, 0,
          reason: 'KoSIT Validator fehlgeschlagen.\n'
              'stdout:\n$stdout\nstderr:\n${result.stderr}\n'
              'report:$reportDump');
      expect(stdout, contains('Validation successful'),
          reason: 'Report zeigt keinen Erfolg.\n'
              'stdout:\n$stdout\nreport:$reportDump');
      expect(stdout, contains('ACCEPTABLE'));
      expect(stdout, isNot(contains('Rejected:  1')));
    }, skip: available ? null : 'KoSIT-Tools nicht verfuegbar — setze '
        'FEGH_KOSIT_JAR, FEGH_XRECHNUNG_SCENARIO, FEGH_XRECHNUNG_REPO '
        '(siehe scripts/install-test-tools).');
  });
}

// ── Fixture-Helpers ─────────────────────────────────────────

Rechnung _sampleRechnung() {
  return Rechnung(
    id: 'test-rechnung',
    rechnungsnummer: 'TEST-2026-0001',
    rechnungsdatum: DateTime(2026, 4, 30),
    leistungsVon: DateTime(2026, 4, 1),
    leistungsBis: DateTime(2026, 4, 30),
    empfaengerId: 'empf-1',
    positionen: [
      RechnungsPosition(
        id: 'pos-1',
        bezeichnung: 'Fachleistungsstunde Eingliederungshilfe',
        menge: 10,
        einheit: 'Stunde',
        einzelpreis: 72.50,
        steuerprozent: 0,
        leistungszeitraumVon: '2026-04-01',
        leistungszeitraumBis: '2026-04-30',
        clientName: 'Max Mustermann',
        fallnummer: 'EGH-2026-12345',
      ),
    ],
    bemerkung: 'Integrationstest',
    ustBefreiung: UstBefreiungsgrund.par4Nr16h,
    erstelltAm: DateTime(2026, 4, 30),
  );
}

RechnungEmpfaenger _sampleEmpfaenger() {
  return RechnungEmpfaenger(
    id: 'empf-1',
    name: 'Sozialamt Friedrichshain-Kreuzberg',
    abteilung: 'Teilhabefachdienst',
    leitwegId: '991-01234-44',
    strasse: 'Yorckstrasse 4-11',
    plz: '10965',
    ort: 'Berlin',
    ansprechpartner: 'Anna Schmitt',
    email: 'teilhabe@example.local',
    erstelltAm: DateTime(2026, 1, 1),
  );
}

RechnungsstellerDaten _sampleSteller() {
  return const RechnungsstellerDaten(
    name: 'FEGH gGmbH',
    strasse: 'Musterstrasse 5',
    plz: '10115',
    ort: 'Berlin',
    umsatzsteuerId: 'DE123456789',
    iban: 'DE89370400440532013000',
    bic: 'COBADEFFXXX',
    kontoinhaber: 'FEGH gGmbH',
    email: 'rechnung@fegh.example',
    telefon: '+49 30 12345678',
    ansprechpartner: 'Rechnungswesen FEGH',
    elektronischeAdresse: 'rechnung@fegh.example',
  );
}

bool _isFile(String? path) =>
    path != null && path.isNotEmpty && File(path).existsSync();

bool _isDir(String? path) =>
    path != null && path.isNotEmpty && Directory(path).existsSync();
