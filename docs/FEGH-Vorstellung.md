# FEGH — Fachsoftware fuer die Eingliederungshilfe

**Vorstellung fuer Geschaeftsstelle und IT-Abteilung**
Stand: 21.04.2026

---

## 1. Executive Summary

FEGH ist eine in Deutschland entwickelte Fachsoftware-Suite fuer Traeger der **Eingliederungshilfe nach SGB IX**. Sie besteht aus zwei eigenstaendigen Flutter-Applikationen:

- **FEGH-Verwaltung** (Desktop, Windows/macOS/Linux) — fuer Leitung, Verwaltung, Personalbuero.
- **FEGH-Dokumentation** (Desktop und Mobil, Android/iOS) — fuer Mitarbeitende im Dienst vor Ort und als eigenstaendiges Admin-Werkzeug kleinerer Einrichtungen.

Beide Apps teilen sich **dieselben Datenmodelle**, nutzen denselben **verschluesselten Cloud-Speicher** (WebDAV-kompatibel: HiDrive, Nextcloud, ownCloud, generisch) und sind ueber einen **Provisioning-QR** miteinander gekoppelt. Kein US-Cloud-Routing, keine Abhaengigkeit von Microsoft 365 oder Google Workspace — relevante Schutzziele aus DSGVO, § 35 SGB I (Sozialgeheimnis) und § 203 StGB (berufliche Schweigepflicht) werden auf Architekturebene erfuellt.

Die Software deckt die Kernprozesse einer EGH-Einrichtung vollstaendig ab: Teilhabeplanung, Personal- und Dienstplanung, Dokumentation, Medikation inklusive BtM-Nachweis, Wohnraum-Verwaltung mit Kassenbuch, Kapazitaetsanalyse und elektronische Rechnungsstellung per **XRechnung UBL 2.1 (CIUS der EN 16931)**.

---

## 2. Architektur im Ueberblick

### Zwei-App-Modell

| App | Zielgruppe | Plattformen | Primaerer Zweck |
|-----|-----------|-------------|-----------------|
| FEGH-Verwaltung | Leitung, Verwaltung, Personal | Windows, macOS, Linux | Stammdaten, Dienstplan, Rechnungen, Reporting |
| FEGH-Dokumentation | Fachkraefte, kleine Traeger | Android, iOS, Desktop | Doku vor Ort, Medikation, Meine Schichten, ggf. Admin |

Die Doku-App **kann die Verwaltung ersetzen** (eigener Admin-Pfad im Setup-Wizard), arbeitet aber auch reibungslos als Mitarbeiter-Client einer groesseren Installation mit dedizierter Verwaltung.

### Gemeinsame Kern-Pakete (`fegh_*`)

- **`fegh_core`** — Kernmodelle (Client, Employee, Team, Shift) + 16-Bundeslaender-Registry.
- **`fegh_cloud`** — Einheitlicher WebDAV-Adapter mit `FeghPaths`-Helper; `bootstrapDirectories()` erzeugt die kanonische Ordnerstruktur in der Cloud.
- **`fegh_crypto`** — AES-256-GCM + PBKDF2, Provisioning-Token-Format, Recovery-Codec.
- **`fegh_auth_oidc`** — OAuth 2.0 Authorization Code Flow mit PKCE (RFC 7636), Native-App-Loopback (RFC 8252), Tokens in Secure Storage.
- **`fegh_compliance`** — SIEM-Exporter in drei Formaten (Syslog RFC 5424, ArcSight CEF, ECS JSON Lines).
- **`fegh_backup`** — Verschluesselte Offline-Backups mit Recovery-Codes.
- **`fegh_pdf_kit`** — PDF-Erzeugung (Kassenbuchauszuege, Dienstplaene, Berichte).
- **`fegh_chat`** — End-to-End-verschluesselter Team-Chat ueber das **Matrix-Protokoll** (Foederation faehig, selbst hostbar).

### Datenhaltung

Jeder Datensatz wird lokal als verschluesseltes JSON im Device-Secure-Storage abgelegt und beim Sync ueber WebDAV in die gemeinsame Cloud gespiegelt. Die Verschluesselung arbeitet mit einem dreistufigen Schluessel-Layer:

- **MEK** (Master Encryption Key) — pro Einrichtung, verschluesselt die Admin-Scope-Records.
- **Team-Key** — pro Team, wird via Provisioning-QR an berechtigte Geraete verteilt; verschluesselt Team-Scope-Records (Klientendaten, Dienstplaene).
- **DEK** (Data Encryption Key) — pro Record, vom Team-Key abgeleitet.

Damit ist das **Need-to-Know-Prinzip** (DSGVO Art. 5 Abs. 1 lit. c, § 78a SGB X) bereits auf der Schluesselebene durchgesetzt: Ein Mitarbeiter aus Team A kann technisch nichts aus Team B entschluesseln, auch wenn er Zugriff auf die Cloud-Dateien erhielte.

---

## 3. Module und Funktionen

### 3.1 Klientenverwaltung und Teilhabeplanung

Stammdatenpflege, Priorisierung, Statusverlauf (`active`, `pending`, `urgent`, `archived`), Zuordnung zu Teams und Fallmanager. Fuer jeden Klienten koennen Fachleistungsstunden (FLS) mit Intervall und Auslastungsgrad verwaltet werden.

**ICF-Modul** (SGB IX § 118): Bedarfsermittlung auf Basis der **International Classification of Functioning, Disability and Health** — der gesetzlich vorgegebene Rahmen fuer Gesamtplanverfahren nach § 117–122 SGB IX.

**Rechtsgrundlagen:** SGB IX §§ 113–122 (Leistungen zur Teilhabe, Gesamtplan), BTHG 2016/2020/2023, § 630f BGB (Dokumentationspflicht analog Behandlungsvertrag).

### 3.2 Mitarbeiter und Teams

Personalakte (Employee-Modell mit Address, EmergencyContact), Teamzuordnung mit Rolle (Leitung / Mitglied), Arbeitszeit-Tracking, Stundenlohn, Status (aktiv / beurlaubt / gekuendigt). Teams bilden die zentrale Berechtigungseinheit — Team-Key ist Schluesselmaterial.

**Rechtsgrundlagen:** § 611a BGB (Arbeitsvertrag), NachwG (Nachweisgesetz), DSGVO Art. 88 / § 26 BDSG (Beschaeftigtendatenschutz).

### 3.3 Dienstplanung (D2)

Kalender-basierte Schichtplanung mit Drag-Drop-Verschiebung, Bulk-Eintraegen und **`ShiftConflictChecker`** — pruefen:

- Hoechstarbeitszeit 8 h/Tag, verlaengerbar auf 10 h (**§ 3 ArbZG**)
- Mindestruhezeit 11 h (**§ 5 ArbZG**)
- Ueberschneidungen, Doppelbelegungen
- Warnungen vs. Blocker (manche Grenzwerte sind tariflich variabel — **§ 7 ArbZG**)

Weitere Funktionen: **Tausch-Anfrage-Workflow** (Mitarbeiter → Kollege → Leitung, 6-Status-Lifecycle), **iCal-Export** pro Mitarbeiter, **Wochen-Aushang-PDF** (einrichtungsweise). Die Doku-App bietet eine Read-only-Ansicht "Meine Schichten" inklusive ICS-Export.

**Rechtsgrundlagen:** ArbZG §§ 3, 4, 5, 7; MuSchG / JArbSchG bei schutzbeduerftigen Mitarbeitergruppen.

### 3.4 Urlaub und Arbeitszeiten

Urlaubsantrag mit Genehmigungsworkflow, Saldo-Berechnung nach **BUrlG § 3** (Mindesturlaub 24 Werktage) und **BUrlG § 7** (zeitliche Festlegung). Arbeitszeiterfassung als Timesheet-Sammlung mit Stunden-KPIs und Export.

**Rechtsgrundlagen:** BUrlG, ArbZG § 16 (Aufzeichnungspflicht — durch EuGH-Urteil C-55/18 ("Stechuhr-Urteil") und BAG 1 ABR 22/21 verpflichtend auch ohne nationale Ausfuehrungsgesetze).

### 3.5 Medikation und BtM-Doku (D3)

- **Medikationsplan** pro Klient mit Verordnungen und Gaben-Quittung.
- **Bedarfsmedikation (PRN)** — ungeplante Gabe mit Pflicht-Begruendung, eigenes Audit-Event.
- **PIN-Validierung** (`MedPinService`): PBKDF2-HMAC-SHA256, 100.000 Iterationen, im `flutter_secure_storage`; Opt-In pro Mitarbeiter, max. 3 Versuche.
- **4-Augen-Prinzip** (`requiresWitness` je Verordnung): Zeuge muss unterschiedlich vom Gebenden sein, wird im Audit erfasst. Fuer BtM ist der Zeuge implizit Pflicht.
- **BtM-Bestandsliste** pro Einrichtung (abgeleitet aus Gaben + Vernichtungen) mit Low-Stock-Hinweis.
- **BtM-Vernichtungsprotokoll** nach **§ 15 BtMVV** — Pflichtfelder, optionale elektronische Unterschrift (Canvas), Zeugenangabe, Audit-Eintrag.

**Rechtsgrundlagen:** BtMG §§ 5, 6; BtMVV § 13 (Aufzeichnungspflicht Betaeubungsmittel), § 15 (Abgabe, Vernichtung mit Zeuge); ApBetrO fuer Apotheken-Schnittstelle.

### 3.6 Wohnraum und Kassenbuch (D4)

- **Wohnraum-Verwaltung**: Einrichtungen mit Zimmern, Bewohnern, Miet-Kategorien (kalt / warm).
- **Kassenbuch** mit fortlaufender Nummerierung, Saldo, PDF-Monatsauszug.
- **Canvas-Unterschrift** fuer Eintrag-Freigabe (signature-Paket), im PDF-Auszug gerendert.
- **Monatsabschluss-Rollover**: persistenter Saldo, Buchungssperre ab Abschluss, Pflicht-Unterschrift.
- **Storno-Workflow**: Gegenbuchung mit Pflicht-Grund + Unterschrift, Original bleibt markiert im Audit (keine Loeschung).
- **Mietabrechnung** mit Duplikat-Schutz (Beleg-Tag `RENT-<wohnraumId>-<YYYYMM>`).
- **Nebenkostenabrechnung** (Einmalbuchung mit Beleg-Tag `NK-<wohnraumId>-<timestamp>`).
- **Beleg-Upload** (Foto/PDF) pro Eintrag, max. 5 MB, inline persistiert.

**Rechtsgrundlagen:** § 146 AO (Ordnungsvorschriften), **GoBD** (BMF-Schreiben vom 28.11.2019 — Grundsaetze zur ordnungsmaessigen Fuehrung und Aufbewahrung von Buechern, Aufzeichnungen und Unterlagen in elektronischer Form); § 257 HGB (Aufbewahrungsfristen, Dritter Personenkreis).

### 3.7 Rechnungen und XRechnung

Erstellung und Validierung von elektronischen Rechnungen im Format **XRechnung UBL 2.1** — der deutschen CIUS (Core Invoice Usage Specification) der **EN 16931**. Integriert ist der echte **KoSIT-Schematron-Validator** (Java-Subprozess, Regression-Tests ueber 12 Business-Rules).

**Besonderheit:** Der Abrechnungsweg fuer Eingliederungshilfe laeuft **nicht** ueber § 302 SGB V (Datenaustausch mit Krankenkassen — gilt fuer Leistungserbringer im SGB V), sondern ueber **XRechnung an Bezirk / Sozialamt** als Leistungstraeger nach SGB IX / XII.

**Rechtsgrundlagen:** EN 16931, KoSIT-Spezifikation, E-Rechnungsverordnung (ERechV) fuer oeffentliche Auftraggeber, § 14 UStG (Pflichtangaben), Wachstumschancengesetz (Pflicht zur E-Rechnung B2B ab 2025/2027).

### 3.8 Team-Chat (Matrix)

Ende-zu-Ende-verschluesselter Chat ueber das **Matrix-Protokoll** (offener Standard, foederierbar). Der Chat laeuft optional gegen einen selbst gehosteten Homeserver (Synapse, Dendrite, Conduit) oder gegen oeffentliche Matrix-Server. Keine Abhaengigkeit von Signal/WhatsApp/Teams.

**Datenschutz:** Pro Team entsteht ein verschluesselter Raum (Olm/Megolm, Signal-Protokoll-Stil). Metadaten bleiben beim Homeserver — bei Selbst-Hosting auf deutschem Boden unter eigenem Datenschutzregime.

### 3.9 Dashboard, Kapazitaet, Reports

Konfigurierbares Dashboard (Kachel-Sichtbarkeit pro Benutzer persistent), KPIs fuer Klienten/Mitarbeiter/Teams/Urlaube/Stunden/FLS, Leistungsverteilung, Top-Auslastung, Aktivitaets-Feed aus dem Audit-Log.

**Kapazitaetsanalyse** mit Forecast-Chart, Team-Capacity-Grid, Workload-Distribution, Departments-Verteilung, Alerts-Panel.

**Berichte**: Monatsauszug Kassenbuch, Wochen-Aushang Dienstplan, Arbeitszeit-Exports (CSV), PDF-Exports pro Klient.

### 3.10 Admin-Konsole und Provisioning

**Verwaltung** und **Doku-Admin** bieten identische Admin-Tooling:

- **Team-Key als QR** — fuer bestehende Mitarbeiter, die ein zweites Geraet einrichten.
- **Mitarbeiter-Provisioning-QR** — der Zielgeraet erhaelt:
  - OrgId, User, Rolle, Teams
  - Team-Keys (nur fuer freigegebene Teams)
  - Cloud-Credentials (optional, per Flag ausblendbar)
  - TOTP-Seed (optional)
  - Flags (managed: true, forceInitialSync: true)

Der gesamte Token wird mit einer 6-stelligen PIN AES-256-GCM verschluesselt (PBKDF2, 10.000 Iterationen, Salt `egh-provisioning-salt-v1`). Die PIN wird dem Empfaenger ueber einen getrennten Kanal mitgeteilt — Zwei-Faktor-aehnliche Trennung.

Auf dem Telefon scannt die Doku-App den QR ueber `mobile_scanner`, gibt die PIN ein, und ist einsatzbereit — **kein manuelles Konfigurieren von Cloud, Keys, Rollen**.

**Rollenmodell (`RolesPolicyService`):** `orgAdmin`, `pvAdmin`, `teamLead`, `teamMember`, `orgAuditor`. Jede Funktion ist rollen-gated; die sichtbare Navigation wird zur Laufzeit gefiltert.

---

## 4. Datenschutz, Sicherheit, Compliance

| Schutzziel | Umsetzung |
|------------|-----------|
| Vertraulichkeit (DSGVO Art. 32 lit. a) | AES-256-GCM Ende-zu-Ende ueber WebDAV; Cloud sieht nur Ciphertext |
| Integritaet (Art. 32 lit. b) | GCM-Authentisierung; jeder Record hat MAC; Sync-Manifest mit Hash-Chain |
| Verfuegbarkeit (Art. 32 lit. b) | Lokale Kopie auf jedem Geraet, Offline-Faehigkeit; verschluesseltes Backup (`fegh_backup`) + Recovery-Codes |
| Belastbarkeit (Art. 32 lit. b) | Keine zentrale Datenbank; Ausfall der Cloud laesst Clients weiter arbeiten |
| Need-to-Know (Art. 5 Abs. 1 lit. c) | Team-Scoping auf Schluesselebene |
| Nachvollziehbarkeit (§ 35 SGB I, § 630f BGB) | Strukturiertes Audit-Log (JSON Lines) ueber alle relevanten Aktionen |
| Zweckbindung (Art. 5 Abs. 1 lit. b) | Keine Telemetrie, kein Cloud-Vendor-Lock-in, keine US-Transfers |
| Sozialgeheimnis (§ 35 SGB I) | Client- und Mitarbeiterdaten nie im Klartext ausserhalb des Secure Storage |
| Schweigepflicht (§ 203 StGB) | Schluesseltrennung auf Team-Ebene, PIN-Schutz fuer Gaben-Quittung |

### Audit-Log und SIEM-Anbindung

Alle sicherheitsrelevanten Aktionen (Anmeldung, Rolle-Change, Client-Aenderung, BtM-Vernichtung, Kassenbuch-Storno, Provisioning) werden strukturiert geloggt. Der **`SiemExporter`** exportiert auf Anforderung:

- **Syslog RFC 5424** (Standard fuer SIEM-Systeme)
- **ArcSight CEF** (HP/OpenText ArcSight)
- **ECS JSON Lines** (Elastic Common Schema — Elastic Stack, OpenSearch)

Export filterbar nach Zeitraum und Action-Prefix. Damit ist die Einbindung in ein zentrales Security Monitoring (BSI IT-Grundschutz-Baustein DER.1 "Detektion von sicherheitsrelevanten Ereignissen") ohne Eigenbau moeglich.

### Unterschriften

**Canvas-Unterschriften** (signature-Paket, Raster-Image) werden im PDF-Auszug gerendert und im Record persistiert. Sie sind keine qualifizierte elektronische Signatur (eIDAS QES), aber **fortgeschrittene elektronische Signaturen im Sinne der eIDAS-Verordnung Art. 26** — ausreichend fuer internen Nachweis und Kassenbuchpflichten nach GoBD.

---

## 5. Betrieb und Deployment (IT-Block)

### Windows-Deployment

- **MSIX-Paket** fuer Windows 10/11 via `msix`-Dart-Paket; signiert (Authenticode) oder per Intune-Paket-Policy.
- **ADMX / ADML (de-DE) Group-Policy-Templates** mit 6 zentral steuerbaren Policies:
  - Cloud-Base-URL
  - Cloud-Provider (HiDrive / Nextcloud / ownCloud / generic WebDAV)
  - OrgId
  - Auto-Update-Freigabe
  - SSO-Zwang
  - SIEM-Export-Ziel
- **Intune / Microsoft Endpoint Manager**-tauglich (App-Paket + ADMX Import).
- PowerShell-Build-Script (`scripts/build-msix.ps1`) fuer CI.

Szenario: IT kann **30 Geraete in einer Filiale mit fertigem Token-Managed-Mode** ausrollen — Mitarbeiter bekommen eine vorkonfigurierte App, muessen nur PIN eingeben.

### Mobile-Deployment

- **Android** — APK / AAB ueber Managed Google Play oder Sideload.
- **iOS** — Apple Business Manager / Apple Developer Enterprise.

### Single Sign-On (SSO)

**`fegh_auth_oidc`** implementiert OpenID Connect gegen:

- Microsoft Entra ID (frueher Azure AD)
- Keycloak
- Google Workspace
- beliebige OIDC-IdPs

Technisch:

- OAuth 2.0 Authorization Code Flow (RFC 6749)
- PKCE (RFC 7636) — keine Client-Secrets in der App
- Native-App-Loopback-Redirect (RFC 8252) — kein Webview, System-Browser bindend
- Tokens im `flutter_secure_storage`, Refresh-Flow
- 13 Unit-Tests + Admin-UI + Wiki-Seite

### Cloud-Speicher

Die App ist **Cloud-Provider-neutral**: Das WebDAV-Protokoll (RFC 4918) erlaubt jede konforme Implementierung. Getestet mit:

- Strato **HiDrive** (deutscher Anbieter, DSGVO-konform)
- **Nextcloud** (Self-Hosting in der eigenen Infrastruktur moeglich)
- **ownCloud**
- generische WebDAV-Server (z. B. Apache, nginx mit WebDAV-Modul)

Die Cloud ist ausschliesslich **Ciphertext-Speicher und Sync-Vehikel** — keine App-Logik liegt dort.

### Backup und Recovery

**`fegh_backup`** erzeugt verschluesselte Offline-Snapshots inkl. Recovery-Codes (Shamir-aehnlich zerlegbar). Fuer den Fall eines kompletten Cloud-Ausfalls oder eines kompromittierten Hauptgeraets kann der Datenbestand aus dem Backup rekonstruiert werden.

### Monitoring und Health

In der Admin-Konsole ist ein **`AdminHealthService`** integriert: Prueft Ordnerstruktur, Schreibbarkeit, `roles.json`-Vorhandensein, Drift-Analyse (Index vs. Dateien), Clients-Index-Neubau. Admin sieht auf einen Blick "Alles gruen" oder erhaelt priorisierte Fehlerliste.

---

## 6. Was die App ausdruecklich nicht macht

Transparenz ueber Grenzen gehoert zur Vorstellung genauso wie zum Umfang:

- **Keine Office-Bridge** (Outlook/Word/Excel via COM/UNO): bewusst verworfen. Widerspricht E2E-Schutzziel. Austauschformate (iCal, XRechnung UBL, XLSX, CSV, PDF) decken 90 % der Interoperabilitaet ab; Benutzer oeffnen Exports in ihrer gewaehlten Office-Suite.
- **Kein PerSEH-Konnektor** zum Zeitpunkt dieser Vorstellung: D5-Strategiepapier liegt vor, Implementierung wartet auf Referenzkunden.
- **Kein SCIM-Provisioning**: SSO via OIDC ist vorhanden; User-Lifecycle-Synchronisation aus HR/AD erfordert ein Backend und ist fuer spaetere Ausbauphase vorgesehen.
- **Kein § 302 SGB V**: Dieser Standard betrifft SGB-V-Leistungserbringer; fuer Eingliederungshilfe (SGB IX, Sozialhilfetraeger) nicht einschlaegig. Relevanter Abrechnungsweg ist XRechnung an Bezirk/Sozialamt — bereits umgesetzt.
- **Kein native WebRTC/VoIP** im Chat: Matrix-Element-Web-Fallback wird genutzt; native `flutter_webrtc`-Integration ist fuer spaeter geplant.

---

## 7. Nachweise und Literaturverzeichnis

- **Gesetze und Verordnungen:** SGB I, V, IX, X; BDSG; DSGVO; ArbZG; BUrlG; BtMG; BtMVV; AO; HGB; BGB (§§ 611a, 630a–630h); StGB § 203; UStG; ERechV.
- **Normen und Spezifikationen:** EN 16931 (E-Invoicing); XRechnung CIUS (KoSIT); eIDAS-VO (EU 910/2014); RFC 6749 (OAuth 2.0); RFC 7636 (PKCE); RFC 8252 (OAuth for Native Apps); RFC 5424 (Syslog); RFC 4918 (WebDAV); ISO 27001; BSI IT-Grundschutz.
- **Weitere:** GoBD (BMF, Stand 28.11.2019); BAG 1 ABR 22/21 (Arbeitszeiterfassung); EuGH C-55/18 (CCOO).
- **Technik-Stack:** Flutter 3.9, Dart 3, Riverpod 2.6, Matrix-Protokoll, `cryptography` 2.x, `webdav_client`, `mobile_scanner`, `flutter_secure_storage`.

---

*Dieses Dokument beschreibt den Stand 21.04.2026. Funktionen, die im laufenden Ausbau sind, stehen im internen Backlog (`docs/BACKLOG.md`) — Entwicklungsgeschwindigkeit und Verbindlichkeit von Roadmap-Punkten werden im persoenlichen Gespraech erlaeutert.*
