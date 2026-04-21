import 'dart:io';

// Direkte Datei-Imports — der package:fegh_pdf_kit-Default zieht ueber
// font_cache.dart Flutter-Deps rein, die in einem reinen Dart-Script
// nicht verfuegbar sind. Die restlichen Layout-Helfer sind pure Dart.
import 'package:fegh_pdf_kit/src/design_tokens.dart';
import 'package:fegh_pdf_kit/src/layout/footer.dart';
import 'package:fegh_pdf_kit/src/layout/header.dart';
import 'package:fegh_pdf_kit/src/layout/hero.dart';
import 'package:fegh_pdf_kit/src/layout/section_heading.dart';
import 'package:fegh_pdf_kit/src/layout/signature_row.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

/// Baut das Vorstellungs-PDF im selben Design wie die App-Reports
/// (Header/Footer/Hero/SectionHeading aus fegh_pdf_kit).
///
/// Aufruf:
///   dart run bin/export_vorstellung_pdf.dart [ziel-pfad]
/// Standard-Ziel: Desktop des aktuellen Users.
Future<void> main(List<String> args) async {
  const appName = 'FEGH Apps-Suite';
  const appTagline = 'Eingliederungshilfe nach SGB IX';
  const title = 'Vorstellung';

  final regularBytes =
      await File('assets/fonts/Roboto-Regular.ttf').readAsBytes();
  final boldBytes = await File('assets/fonts/Roboto-Bold.ttf').readAsBytes();
  final theme = pw.ThemeData.withFont(
    base: pw.Font.ttf(regularBytes.buffer.asByteData()),
    bold: pw.Font.ttf(boldBytes.buffer.asByteData()),
  );
  final doc = pw.Document(theme: theme);

  doc.addPage(pw.MultiPage(
    pageFormat: PdfPageFormat.a4,
    margin: const pw.EdgeInsets.fromLTRB(50, 40, 50, 50),
    header: (_) => buildHeader(
      title: title,
      appName: appName,
      appTagline: appTagline,
    ),
    footer: buildFooter(appName: appName),
    build: (_) => _buildContent(),
  ));

  final bytes = await doc.save();
  final target = args.isNotEmpty
      ? args.first
      : _defaultDesktopPath('FEGH-Vorstellung.pdf');
  final file = File(target);
  await file.parent.create(recursive: true);
  await file.writeAsBytes(bytes);
  stdout.writeln('PDF geschrieben: $target');
}

String _defaultDesktopPath(String fileName) {
  final home = Platform.environment['USERPROFILE'] ??
      Platform.environment['HOME'] ??
      '.';
  return '$home${Platform.pathSeparator}Desktop${Platform.pathSeparator}$fileName';
}

// ═══════════════════════════════════════════════════════════════════
// INHALT
// ═══════════════════════════════════════════════════════════════════

List<pw.Widget> _buildContent() {
  return [
    pw.SizedBox(height: 16),
    buildHero(
      label: 'DOKUMENT',
      title: 'FEGH - Fachsoftware fuer die Eingliederungshilfe',
      subtitle: 'Vorstellung fuer Geschaeftsstelle und IT-Abteilung, Stand 21.04.2026',
    ),
    pw.SizedBox(height: 28),
    _paragraph(
      'FEGH ist eine in Deutschland entwickelte Fachsoftware-Suite fuer Traeger der Eingliederungshilfe nach SGB IX. '
      'Sie besteht aus zwei eigenstaendigen Flutter-Applikationen, die sich dieselben Datenmodelle teilen und ueber '
      'verschluesselten Cloud-Speicher (WebDAV-kompatibel: HiDrive, Nextcloud, ownCloud, generisch) synchronisieren. '
      'Kein US-Cloud-Routing, keine Abhaengigkeit von Microsoft 365 oder Google Workspace - die Schutzziele aus '
      'DSGVO, § 35 SGB I (Sozialgeheimnis) und § 203 StGB (berufliche Schweigepflicht) werden auf Architekturebene erfuellt.',
    ),
    pw.SizedBox(height: 18),

    // I. Architektur
    buildSectionHeading('I', 'Architektur im Ueberblick'),
    pw.SizedBox(height: 10),
    _subheading('Zwei-App-Modell'),
    _tableTwoAppOverview(),
    pw.SizedBox(height: 12),
    _paragraph(
      'Die Doku-App kann die Verwaltung ersetzen (eigener Admin-Pfad im Setup-Wizard), arbeitet aber auch '
      'reibungslos als Mitarbeiter-Client einer groesseren Installation mit dedizierter Verwaltung.',
    ),
    pw.SizedBox(height: 14),
    _subheading('Gemeinsame Kern-Pakete'),
    _bulletList([
      'fegh_core - Kernmodelle (Client, Employee, Team, Shift) + 16-Bundeslaender-Registry',
      'fegh_cloud - WebDAV-Adapter; FeghPaths-Helper erzeugt kanonische Ordnerstruktur',
      'fegh_crypto - AES-256-GCM + PBKDF2, Provisioning-Token, Recovery-Codec',
      'fegh_auth_oidc - OAuth 2.0 Authorization Code mit PKCE (RFC 7636) und Loopback (RFC 8252)',
      'fegh_compliance - SIEM-Exporter (Syslog RFC 5424, ArcSight CEF, ECS JSON Lines)',
      'fegh_backup - Verschluesselte Offline-Backups mit Recovery-Codes',
      'fegh_pdf_kit - PDF-Erzeugung im einheitlichen Behoerden-Layout (dieses Dokument)',
      'fegh_chat - End-zu-End-verschluesselter Team-Chat ueber Matrix-Protokoll',
    ]),
    pw.SizedBox(height: 14),
    _subheading('Dreistufige Schluesselhierarchie'),
    _paragraph(
      'MEK (Master Encryption Key) pro Einrichtung schuetzt Admin-Scope-Records. '
      'Team-Key pro Team wird via Provisioning-QR verteilt und verschluesselt Klientendaten und Dienstplaene. '
      'DEK (Data Encryption Key) pro Record wird vom Team-Key abgeleitet. '
      'Damit ist das Need-to-Know-Prinzip nach DSGVO Art. 5 Abs. 1 lit. c und § 78a SGB X auf Schluesselebene durchgesetzt.',
    ),
    pw.SizedBox(height: 18),

    // II. Module
    buildSectionHeading('II', 'Module und Funktionen'),
    pw.SizedBox(height: 10),

    _module(
      'Klientenverwaltung und Teilhabeplanung',
      'Stammdaten, Priorisierung, Statusverlauf, Team- und Fallmanager-Zuordnung. Fachleistungsstunden (FLS) mit '
          'Intervall und Auslastung. ICF-Modul nach § 118 SGB IX - International Classification of Functioning, der '
          'gesetzliche Rahmen fuer Gesamtplanverfahren nach §§ 117-122 SGB IX.',
      'SGB IX §§ 113-122, BTHG 2016/2020/2023, § 630f BGB (Dokumentationspflicht).',
    ),
    _module(
      'Mitarbeiter und Teams',
      'Personalakte mit Address/EmergencyContact, Teamzuordnung mit Rolle (Leitung/Mitglied), Arbeitszeit-Tracking, '
          'Stundenlohn, Status. Teams bilden die zentrale Berechtigungseinheit.',
      '§ 611a BGB, NachwG, DSGVO Art. 88 / § 26 BDSG (Beschaeftigtendatenschutz).',
    ),
    _module(
      'Dienstplanung (D2)',
      'Kalender-Planung mit Drag-Drop, Bulk-Eintraegen und ShiftConflictChecker: Hoechstarbeitszeit 8 h (verlaengerbar '
          'auf 10 h), Ruhezeit 11 h, Ueberschneidungen. Tausch-Anfrage-Workflow (Mitarbeiter - Kollege - Leitung, '
          '6-Status-Lifecycle), iCal-Export pro Mitarbeiter, Wochen-Aushang-PDF. Die Doku-App hat eine Read-only-Ansicht '
          '"Meine Schichten".',
      'ArbZG §§ 3, 4, 5, 7; MuSchG / JArbSchG.',
    ),
    _module(
      'Urlaub und Arbeitszeiten',
      'Urlaubsantrag mit Genehmigungsworkflow, Saldo nach BUrlG § 3. Arbeitszeiterfassung als Timesheet-Sammlung '
          'mit Stunden-KPIs und Export.',
      'BUrlG §§ 3, 7; ArbZG § 16 (Aufzeichnungspflicht, bestaetigt durch EuGH C-55/18 und BAG 1 ABR 22/21).',
    ),
    _module(
      'Medikation und BtM-Doku (D3)',
      'Medikationsplan mit Gabe-Quittung, Bedarfsmedikation (PRN) mit Pflicht-Begruendung. PIN-Validierung '
          '(PBKDF2-HMAC-SHA256, 100.000 Iterationen, secure_storage). 4-Augen-Prinzip mit Zeuge, fuer BtM verpflichtend. '
          'BtM-Bestandsliste pro Einrichtung, BtM-Vernichtungsprotokoll mit Zeuge und Unterschrift.',
      'BtMG §§ 5, 6; BtMVV §§ 13, 15; ApBetrO (Apotheken-Schnittstelle).',
    ),
    _module(
      'Wohnraum und Kassenbuch (D4)',
      'Wohnraum-Verwaltung mit Zimmern/Bewohnern. Kassenbuch mit fortlaufender Nummerierung, Saldo, PDF-Monatsauszug. '
          'Canvas-Unterschrift fuer Eintrag-Freigabe. Monatsabschluss-Rollover mit Buchungssperre. Storno-Workflow '
          '(Gegenbuchung mit Pflicht-Grund, Original bleibt markiert). Mietabrechnung mit Duplikat-Schutz, '
          'Nebenkostenabrechnung, Beleg-Upload max. 5 MB.',
      '§ 146 AO; GoBD (BMF-Schreiben vom 28.11.2019); § 257 HGB (Aufbewahrungsfristen).',
    ),
    _module(
      'Rechnungen und XRechnung',
      'Erstellung und Validierung von elektronischen Rechnungen in XRechnung UBL 2.1 - der deutschen CIUS der '
          'EN 16931. Integriert ist der echte KoSIT-Schematron-Validator (Java-Subprozess, 12 Regression-Tests). '
          'Abrechnungsweg ist XRechnung an Bezirk/Sozialamt - § 302 SGB V ist fuer EGH nicht einschlaegig.',
      'EN 16931, KoSIT-Spezifikation, ERechV (E-Rechnungsverordnung), § 14 UStG, Wachstumschancengesetz.',
    ),
    _module(
      'Team-Chat (Matrix)',
      'Ende-zu-Ende-verschluesselt ueber Matrix (offener Standard, foederierbar). Optional gegen selbst gehosteten '
          'Homeserver (Synapse, Dendrite, Conduit). Pro Team ein verschluesselter Raum (Olm/Megolm).',
      'Matrix.org-Spezifikation; bei Selbst-Hosting in Deutschland unter eigenem Datenschutzregime.',
    ),
    _module(
      'Dashboard, Kapazitaet, Reports',
      'Konfigurierbares Dashboard mit KPI-Kacheln, Leistungsverteilung, Top-Auslastung, Audit-Aktivitaet. '
          'Kapazitaetsanalyse mit Forecast, Team-Capacity-Grid, Workload-Distribution. PDF-Reports: Monatsauszug '
          'Kassenbuch, Wochen-Aushang Dienstplan, Arbeitszeit-Exports.',
      'Interne Entscheidungsunterstuetzung, keine direkte Norm.',
    ),
    _module(
      'Admin-Konsole und Provisioning',
      'Verwaltung und Doku-Admin bieten identische Tooling: Team-Key-QR, Mitarbeiter-Provisioning-QR (mit OrgId, '
          'User, Rolle, Teams, Team-Keys, Cloud-Credentials, TOTP, Flags). Der gesamte Token wird mit einer '
          '6-stelligen PIN AES-256-GCM verschluesselt (PBKDF2 10.000 Iterationen). Rollenmodell: orgAdmin, pvAdmin, '
          'teamLead, teamMember, orgAuditor.',
      'DSGVO Art. 32 (Zugangskontrolle); PIN als Trennung der Kanaele.',
    ),
    pw.SizedBox(height: 10),

    // III. Datenschutz
    buildSectionHeading('III', 'Datenschutz, Sicherheit, Compliance'),
    pw.SizedBox(height: 10),
    _tableSchutzziele(),
    pw.SizedBox(height: 14),
    _subheading('Audit-Log und SIEM-Anbindung'),
    _paragraph(
      'Sicherheitsrelevante Aktionen (Anmeldung, Rolle-Change, Client-Aenderung, BtM-Vernichtung, Kassenbuch-Storno, '
      'Provisioning) werden strukturiert geloggt. Der SiemExporter liefert drei Formate: Syslog RFC 5424, ArcSight CEF, '
      'ECS JSON Lines. Export filterbar nach Zeitraum und Action-Prefix - direkte Einbindung in SIEM-Systeme '
      '(BSI IT-Grundschutz-Baustein DER.1) ohne Eigenbau.',
    ),
    pw.SizedBox(height: 10),
    _subheading('Elektronische Unterschriften'),
    _paragraph(
      'Canvas-Unterschriften werden im PDF gerendert und im Record persistiert. Sie sind keine qualifizierte '
      'elektronische Signatur im Sinne eIDAS QES, erfuellen aber das Kriterium einer fortgeschrittenen elektronischen '
      'Signatur nach eIDAS Art. 26 - ausreichend fuer internen Nachweis und Kassenbuchpflichten nach GoBD.',
    ),
    pw.SizedBox(height: 18),

    // IV. Betrieb
    buildSectionHeading('IV', 'Betrieb und Deployment'),
    pw.SizedBox(height: 10),
    _subheading('Windows-Deployment'),
    _bulletList([
      'MSIX-Paket fuer Windows 10/11, signiert (Authenticode) oder per Intune-Policy',
      'ADMX/ADML (de-DE) mit 6 zentral steuerbaren Policies: Cloud-Base-URL, Cloud-Provider, OrgId, Auto-Update, SSO-Zwang, SIEM-URL',
      'Intune / Microsoft Endpoint Manager tauglich - ADMX Import und App-Paket-Deployment',
      'Szenario: 30 Geraete per Managed-Mode ausrollbar, Mitarbeiter gibt nur PIN ein',
    ]),
    pw.SizedBox(height: 10),
    _subheading('Mobile-Deployment'),
    _bulletList([
      'Android: APK/AAB ueber Managed Google Play oder Sideload',
      'iOS: Apple Business Manager / Apple Developer Enterprise',
      'Provisioning per QR-Scan im Setup-Wizard (mobile_scanner) - kein haendisches Eintippen',
    ]),
    pw.SizedBox(height: 10),
    _subheading('Single Sign-On (fegh_auth_oidc)'),
    _paragraph(
      'OpenID Connect gegen Microsoft Entra ID, Keycloak, Google Workspace oder jeden OIDC-IdP. '
      'OAuth 2.0 Authorization Code mit PKCE (RFC 7636) - keine Client-Secrets in der App. '
      'Native-App-Loopback-Redirect (RFC 8252) - kein Webview, System-Browser bindend. '
      'Tokens im flutter_secure_storage, Refresh-Flow. 13 Unit-Tests und Admin-UI.',
    ),
    pw.SizedBox(height: 10),
    _subheading('Cloud-Speicher'),
    _paragraph(
      'Cloud-Provider-neutral ueber WebDAV (RFC 4918). Getestet: Strato HiDrive (deutsch, DSGVO-konform), '
      'Nextcloud (selbst hostbar), ownCloud, generische WebDAV-Server (Apache, nginx mit WebDAV-Modul). '
      'Die Cloud ist ausschliesslich Ciphertext-Speicher und Sync-Vehikel - keine App-Logik liegt dort.',
    ),
    pw.SizedBox(height: 10),
    _subheading('Backup, Recovery und Monitoring'),
    _paragraph(
      'fegh_backup erzeugt verschluesselte Offline-Snapshots mit Recovery-Codes. AdminHealthService in der '
      'Admin-Konsole prueft Ordnerstruktur, Schreibbarkeit, roles.json, Drift-Analyse. Clients-Index-Neubau '
      'und Repair-Tools stehen bereit.',
    ),
    pw.SizedBox(height: 18),

    // V. Was die App nicht macht
    buildSectionHeading('V', 'Was die Software ausdruecklich nicht macht'),
    pw.SizedBox(height: 10),
    _bulletList([
      'Keine Office-Bridge (Outlook/Word/Excel per COM/UNO): widerspricht E2E-Schutzziel. Austauschformate (iCal, XRechnung UBL, XLSX, CSV, PDF) decken 90 % der Interoperabilitaet ab.',
      'Kein PerSEH-Konnektor in dieser Version: D5-Strategiepapier liegt vor, wartet auf Referenzkunden.',
      'Kein SCIM-Provisioning: SSO via OIDC vorhanden, User-Lifecycle-Sync aus HR/AD erfordert Backend-Endpoint.',
      'Kein § 302 SGB V: betrifft SGB-V-Leistungserbringer; fuer Eingliederungshilfe nach SGB IX/XII nicht einschlaegig.',
      'Kein natives WebRTC/VoIP im Chat: Matrix-Element-Web-Fallback; native flutter_webrtc-Integration geplant.',
    ]),
    pw.SizedBox(height: 18),

    // VI. Nachweise
    buildSectionHeading('VI', 'Nachweise und Literaturverzeichnis'),
    pw.SizedBox(height: 10),
    _subheading('Gesetze und Verordnungen'),
    _paragraph(
      'SGB I, V, IX, X - BDSG - DSGVO - ArbZG - BUrlG - BtMG - BtMVV - AO - HGB - BGB (§§ 611a, 630a-630h) - '
      'StGB § 203 - UStG - ERechV - BTHG.',
    ),
    pw.SizedBox(height: 8),
    _subheading('Normen und Spezifikationen'),
    _paragraph(
      'EN 16931 (E-Invoicing) - XRechnung CIUS (KoSIT) - eIDAS-VO (EU 910/2014) - RFC 6749 (OAuth 2.0) - '
      'RFC 7636 (PKCE) - RFC 8252 (OAuth for Native Apps) - RFC 5424 (Syslog) - RFC 4918 (WebDAV) - '
      'ISO 27001 - BSI IT-Grundschutz.',
    ),
    pw.SizedBox(height: 8),
    _subheading('Weitere Belege'),
    _paragraph(
      'GoBD (BMF, Stand 28.11.2019) - BAG 1 ABR 22/21 (Arbeitszeiterfassung) - EuGH C-55/18 (CCOO, Stechuhr-Urteil).',
    ),
    pw.SizedBox(height: 8),
    _subheading('Technik-Stack'),
    _paragraph(
      'Flutter 3.9, Dart 3, Riverpod 2.6, Matrix-Protokoll, cryptography 2.x, webdav_client, mobile_scanner, '
      'flutter_secure_storage.',
    ),
    pw.SizedBox(height: 28),
    buildSignatureRow(authorName: null),
  ];
}

// ═══════════════════════════════════════════════════════════════════
// HELPER
// ═══════════════════════════════════════════════════════════════════

pw.Widget _paragraph(String text) {
  return pw.Text(
    text,
    style: pw.TextStyle(
      fontSize: 10.5,
      color: PdfDesignTokens.text,
      lineSpacing: 2,
    ),
    textAlign: pw.TextAlign.justify,
  );
}

pw.Widget _subheading(String text) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 6),
    child: pw.Text(
      text,
      style: pw.TextStyle(
        fontSize: 11,
        fontWeight: pw.FontWeight.bold,
        color: PdfDesignTokens.primaer,
      ),
    ),
  );
}

pw.Widget _bulletList(List<String> items) {
  return pw.Column(
    crossAxisAlignment: pw.CrossAxisAlignment.start,
    children: [
      for (final s in items)
        pw.Padding(
          padding: const pw.EdgeInsets.only(bottom: 4, left: 4),
          child: pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Container(
                width: 3,
                height: 3,
                margin: const pw.EdgeInsets.only(top: 5, right: 8),
                decoration: const pw.BoxDecoration(
                  color: PdfDesignTokens.primaer,
                  shape: pw.BoxShape.circle,
                ),
              ),
              pw.Expanded(
                child: pw.Text(
                  s,
                  style: pw.TextStyle(
                    fontSize: 10,
                    color: PdfDesignTokens.text,
                    lineSpacing: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
    ],
  );
}

pw.Widget _module(String title, String body, String rechtsgrundlage) {
  return pw.Padding(
    padding: const pw.EdgeInsets.only(bottom: 12),
    child: pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          title,
          style: pw.TextStyle(
            fontSize: 11,
            fontWeight: pw.FontWeight.bold,
            color: PdfDesignTokens.primaer,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          body,
          style: pw.TextStyle(
            fontSize: 10,
            color: PdfDesignTokens.text,
            lineSpacing: 1.8,
          ),
          textAlign: pw.TextAlign.justify,
        ),
        pw.SizedBox(height: 3),
        pw.Text(
          'Rechtsgrundlage: $rechtsgrundlage',
          style: pw.TextStyle(
            fontSize: 8.5,
            color: PdfDesignTokens.muted,
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      ],
    ),
  );
}

pw.Widget _tableTwoAppOverview() {
  pw.Widget cell(String text, {bool header = false, bool first = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: header ? 9.5 : 9.5,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? PdfDesignTokens.primaer : PdfDesignTokens.text,
        ),
      ),
    );
  }

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfDesignTokens.tableHeader),
      children: [
        cell('App', header: true, first: true),
        cell('Zielgruppe', header: true),
        cell('Plattformen', header: true),
        cell('Zweck', header: true),
      ],
    ),
    pw.TableRow(children: [
      cell('FEGH-Verwaltung'),
      cell('Leitung, Verwaltung'),
      cell('Windows, macOS, Linux'),
      cell('Stammdaten, Plan, Rechnungen'),
    ]),
    pw.TableRow(children: [
      cell('FEGH-Dokumentation'),
      cell('Fachkraefte, kleine Traeger'),
      cell('Android, iOS, Desktop'),
      cell('Doku vor Ort, ggf. Admin'),
    ]),
  ];

  return pw.Table(
    border: pw.TableBorder.all(color: PdfDesignTokens.divider, width: 0.5),
    columnWidths: const {
      0: pw.FlexColumnWidth(1.4),
      1: pw.FlexColumnWidth(1.4),
      2: pw.FlexColumnWidth(1.6),
      3: pw.FlexColumnWidth(2.0),
    },
    children: rows,
  );
}

pw.Widget _tableSchutzziele() {
  pw.Widget cell(String text, {bool header = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 9,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? PdfDesignTokens.primaer : PdfDesignTokens.text,
          lineSpacing: 1.4,
        ),
      ),
    );
  }

  final data = <List<String>>[
    ['Vertraulichkeit (DSGVO Art. 32 lit. a)', 'AES-256-GCM Ende-zu-Ende ueber WebDAV; Cloud sieht nur Ciphertext'],
    ['Integritaet (Art. 32 lit. b)', 'GCM-Authentisierung; jeder Record hat MAC; Sync-Manifest mit Hash-Chain'],
    ['Verfuegbarkeit (Art. 32 lit. b)', 'Lokale Kopie auf jedem Geraet, Offline-Faehigkeit, verschluesseltes Backup'],
    ['Need-to-Know (Art. 5 Abs. 1 lit. c)', 'Team-Scoping auf Schluesselebene'],
    ['Nachvollziehbarkeit (§ 35 SGB I, § 630f BGB)', 'Strukturiertes Audit-Log (JSON Lines)'],
    ['Zweckbindung (Art. 5 Abs. 1 lit. b)', 'Keine Telemetrie, kein US-Transfer, kein Vendor-Lock-in'],
    ['Sozialgeheimnis (§ 35 SGB I)', 'Daten nie im Klartext ausserhalb Secure Storage'],
    ['Schweigepflicht (§ 203 StGB)', 'Schluesseltrennung auf Team-Ebene, PIN-Schutz fuer Gaben-Quittung'],
  ];

  final rows = <pw.TableRow>[
    pw.TableRow(
      decoration: const pw.BoxDecoration(color: PdfDesignTokens.tableHeader),
      children: [cell('Schutzziel', header: true), cell('Umsetzung', header: true)],
    ),
    for (final r in data)
      pw.TableRow(children: [cell(r[0]), cell(r[1])]),
  ];

  return pw.Table(
    border: pw.TableBorder.all(color: PdfDesignTokens.divider, width: 0.5),
    columnWidths: const {0: pw.FlexColumnWidth(1.2), 1: pw.FlexColumnWidth(1.8)},
    children: rows,
  );
}
