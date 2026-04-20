# FEGH-Projekt — Offene Punkte (Backlog)

**Stand: 19.04.2026** — wird laufend aktualisiert.

Legende: **P0** = kritisch/blockierend, **P1** = wichtig, **P2** = nice-to-have. Das Backlog wird von oben nach unten abgearbeitet.

---

## P0 — Nahtlosigkeit zwischen Doku und Verwaltung

Das groesste strukturelle Defizit: Beide Apps teilen sich Wire-Format und Cloud, aber die **Datenmodelle divergieren**. Ein Klient aus der Verwaltung kann die Doku nicht lesen (und umgekehrt).

- [x] **`fegh_core` Shared-Package** angelegt mit den Kern-Modellen
  - [x] `Client` vereinigt + 16-Laender-Registry (`Bundesland` / `BundeslandProfil`), 21 Tests
  - [x] `Employee` (+ typedef `Mitarbeiter = Employee`, `Address`, `EmergencyContact`), 10 Tests
  - [x] `Team` (vereint clientIds/budget/notes), analyze clean
  - [ ] `Shift` — bewusst zurueckgestellt (Doku hat keine Schichten; wird nachgezogen, falls die Doku Schicht-Anzeige bekommt)
- [x] **Schema-Migration** in beiden Apps — `fromJson` akzeptiert alte Doku- und Verwaltungs-Felder, `toJson` schreibt beides
- [x] **Cross-App-Lesbarkeit** in Unit-Tests abgedeckt (Legacy-Doku-JSON + Verwaltungs-JSON werden jeweils geparst)
- [x] **Einheitliche Cloud-Ordnerstruktur** — `FeghPaths` in `fegh_cloud` (15 Tests). Beide Apps bauen ihre Pfade durch denselben Helper, `bootstrapDirectories()` liefert die gemeinsame mkcol-Reihenfolge.
- [ ] **Live-Cross-App-Test**: Verwaltung schreibt Klient → Doku liest denselben Record aus Cloud (braucht laufende Test-Umgebung)

---

## P1 — Scope B/C der MVP-Module

### Medikation (D3 Scope B/C)
- [x] Bedarfsmedikation (PRN) — ungeplante Gabe mit Begruendung
- [x] PIN-Validierung fuer Gabe-Quittung — `MedPinService` (PBKDF2-HMAC-SHA256, 100k Iterationen, secure_storage), Opt-In pro Mitarbeiter, max. 3 Versuche
- [x] 4-Augen-Prinzip fuer alle Gaben — `requiresWitness` je Verordnung, BtM impliziert, Zeuge != Gebender, witnessEmployeeId in Audit
- [x] BTM-Bestandsliste pro Einrichtung (abgeleitet aus Gaben + Vernichtungen) mit Low-Stock-Hinweis
- [x] BTM-Vernichtungsprotokoll mit Zeuge (§15 BtMVV) — Pflichtfelder, optionale Unterschrift, Audit

### Kassenbuch (D4 Scope B/C)
- [x] Canvas-Unterschrift fuer Eintrag-Freigabe (`signature`-Paket)
- [x] Monatsabschluss-Rollover (persistenter Saldo, Buchungssperre ab Abschluss, Pflicht-Unterschrift)
- [x] Storno-Workflow (freigegebene Eintraege) — Gegenbuchung mit Pflicht-Grund + Unterschrift, Original bleibt im Audit
- [x] Mietabrechnung Kalt/Warm — "Miete buchen" im Wohnraum, Monatsauswahl, Duplikat-Schutz per Beleg-Tag `RENT-<wohnraumId>-<YYYYMM>`
- [x] Nebenkostenabrechnung — Dialog fuer Einmalbuchung (Betrag + Zweck), Beleg-Tag `NK-<wohnraumId>-<timestamp>`
- [x] Beleg-Upload (Foto/PDF) pro Eintrag — max. 5 MB, inline Persistenz

### Dienstplan (D2 Erweiterung)
- [x] Drag-Drop-Verschiebung im Kalender — mit `ShiftConflictChecker`, Dialog bei blockierenden Konflikten (blockt), Warn-Dialog bei Grenzfaellen (Confirm erforderlich), Rueckgaengig-Action im SnackBar
- [x] Tausch-Anfrage-Workflow (Mitarbeiter → Kollege → Teamleitung) — `ShiftSwapRequest` mit 6-Status-Lifecycle, Kollegen-Annahme + Leitungs-Freigabe, Schicht-Umbuchung bei Approve, 3-Tab-Screen
- [x] iCal-Export pro Mitarbeiter (Verwaltung-Screen + Doku "Meine Schichten")
- [x] Konflikt-Check auch im Bulk-Dialog

---

## P1 — Tests und Validierung

- [x] Wohnraum-Service Unit-Tests (12 Tests)
- [x] BTM-Service: erweiterte Test-Faelle (stockOverview, Vernichtungs-Validierung, Audit) — 11 Tests
- [x] XRechnung: echter KoSIT-Schematron-Test (Java-Subprozess, skipt ohne FEGH_KOSIT_* Env)
- [x] Cross-App-Interop-Test nach `fegh_core` (WebDAV-Roundtrip Client-JSON ueber GenericWebdavAdapter, skipt ohne dufs)

---

## P1 — Wiki-Verwaltung ausbauen

8 Stub-Seiten mit echtem Inhalt fuellen:

- [x] `anleitung/mitarbeiter.md`
- [x] `anleitung/teams.md`
- [x] `anleitung/dienstplanung.md`
- [x] `anleitung/arbeitszeiten.md`
- [x] `anleitung/urlaub.md`
- [x] `anleitung/kapazitaet.md`
- [x] `anleitung/berichte.md`
- [x] `anleitung/einstellungen.md`

Ausserdem:
- [x] Medikations-Wiki-Seite (neues Modul aus D3)
- [x] Wohnraum-Wiki-Seite + Kassenbuch-Wiki-Seite (getrennt, neue Module aus D4)
- [x] Team-Chat-Wiki-Seite (fegh_chat)

---

## P2 — UI- und Navigations-Feinschliff

- [x] Globale Suche in der AppBar — `GlobalSearchDialog` mit Debounce, Keyboard-Navigation (↑/↓/Enter/Esc), Ctrl+F / Cmd+F Shortcut, Scoring ueber Klienten/Mitarbeiter/Teams/Schichten/Rechnungen, Audit-Event `search.result_selected`
- [x] UI-Customization aufraeumen — `tabDisplayMode` aus Settings entfernt (seit NavigationRail ohne Funktion)
- [x] Dashboard-Kacheln konfigurierbar (Drag-Drop pro User) — `DashboardLayout`-Modell + `SharedPreferences`-Persistenz, ReorderableListView mit Edit-Modus, Visibility-Toggle je Kachel, Reset-Dialog
- [ ] Deep-Links via `go_router` (`/klienten/42`) — spaetere Umstellung
- [ ] Mitarbeiter-Dashboard (`MyWorkScreen`) nach Feedback verfeinern

---

## Verworfen: Office-Bridge

Ursprueng­lich als P1 geplant (tiefe Outlook/Word/Excel-Integration per COM/AppleScript/UNO). Nach Bewertung verworfen:

- Widerspricht Kernversprechen (E2E, DSGVO, keine US-Cloud) — Daten durch MS 365 routen untergraebt das Schutzziel.
- Wartungslast auf vier Stacks (Windows COM, macOS AppleScript, Linux UNO, Mobile) zu hoch.
- Austauschformate (iCal, XRechnung UBL, XLSX, CSV, PDF) decken 90 % der Interop-Wuensche bereits ab.

Fallback: Wir bleiben bei sauberen Export-Formaten; Nutzer oeffnen selbst in ihrer Office-Suite.

---

## P2 — Infrastruktur

- [ ] Native VoIP-Calls (`flutter_webrtc`) statt Element-Web-Fallback im Chat
- [ ] PerSEH-Konnektor (D5-Strategiepapier) — Referenzkunde abwarten
- [ ] CI-Pipeline fuer beide Apps (flutter test auto)
- [ ] Fegh-shared Pakete optional mit Remote (Git)
- [ ] Provisioning-End-to-End-Test (Admin erstellt Token → Mitarbeiter scannt → Cloud-Zugriff)

---

## P2 — Enterprise-Block (spaeter)

Bewusst nicht Prio 1, weil der MVP zuerst fertig werden muss. Was echte Ausschreibungen in dem Markt verlangen:

- [x] **SSO** via OIDC (Entra ID, Keycloak, Google) — neues Shared-Package `fegh_auth_oidc` mit OAuth Authorization Code + PKCE + RFC 8252 Loopback-Redirect, System-Browser (keine Webview), Tokens im secure_storage, Refresh-Flow, 13 Unit-Tests, Admin-UI (`SsoSettingsScreen`), Wiki-Seite
- [ ] **SCIM-Provisioning** (User-Lifecycle aus HR/AD) — braucht Backend-Endpoint
- [x] **MDM/Intune-Deployment** — MSIX-Paket via `msix`-Dart-Paket, ADMX-Templates (de-DE) mit 6 zentral konfigurierbaren Policies (Cloud-URL, Provider, OrgId, Auto-Update, SSO-Zwang, SIEM-URL), PowerShell-Build-Script, Wiki-Seite `admin/deployment.md`
- [x] **SIEM-Export** des Audit-Logs — `SiemExporter` in fegh_compliance, 3 Formate (Syslog RFC 5424, ArcSight CEF, ECS JSON Lines), Filter (Zeitraum + Action-Prefix), 12 Unit-Tests, Admin-UI-Einstieg als Popup-Menu
- [ ] **Schnittstellen zu Pflege-/Heimsoftware** — Vivendi, Medifox, Sinfonie (CSV/XML-Import+Export)

Anmerkung: §302 SGB V DTA ist fuer Eingliederungshilfe nicht einschlaegig (EGH ist SGB IX, Leistungstraeger sind Sozialhilfetraeger). Relevanter Abrechnungspfad ist **XRechnung UBL an Bezirk/Sozialamt** — existiert bereits.

---

## Abgeschlossen in dieser Session (19.04.2026)

- [x] D2a Dienstplan-Konflikte + Wochen-Aushang PDF
- [x] D-Nav NavigationRail mit Rollen-Gate
- [x] hidrive → cloud Rename (145 Stellen + Legacy-Migration)
- [x] D3 Medikationsmodul MVP + BtM-Zusatzdoku
- [x] D4 Wohnraum + Kassenbuch MVP + Monatsauszug PDF
- [x] Backup-Manager UI (Verwaltung)
- [x] `fegh_chat` Shared-Package (Matrix)
- [x] `fegh_backup`, `fegh_pdf_kit`, `fegh_compliance` Shared-Packages
- [x] XRechnung VATEX-Korrektur + 12 Regression-Tests
- [x] Dashboard FLS-Fortschrittsbalken-Fix + Sortierung
- [x] AppBar Dark-Mode-Kontrast-Fix
- [x] Wiki-Verwaltung: 11 Kern-Seiten mit Inhalt gefuellt
- [x] Entwicklungstagebuch Kap. 4.1–4.8 + Fallbeispiele + Grenzen-Kapitel
- [x] `fegh_core` Shared-Package: Client + Bundesland + Employee + Team (30 Unit-Tests)
- [x] Beide Apps nutzen dasselbe Client-Schema (fromJson liest Legacy-Felder)
- [x] Beide Apps nutzen dasselbe Employee-Schema
- [x] Beide Apps nutzen dasselbe Team-Schema
- [x] Beide Apps nutzen dasselbe Shift-Schema; Doku hat Read-only-Ansicht "Meine Schichten"
- [x] Einheitliche Cloud-Pfade ueber `FeghPaths` (15 Tests)
- [x] Wohnraum-Service Unit-Tests (12 Tests)
- [x] Bedarfsmedikation (PRN) mit Pflicht-Grund und eigenem Audit-Event
- [x] Konflikt-Check im Bulk-Shift-Dialog (blockierend + Warn-Confirm)
- [x] Canvas-Unterschrift Kassenbuch (Pflicht bei Freigabe, im PDF-Auszug gerendert)
- [x] iCal-Export Dienstplan (`ShiftIcsExporter` in fegh_core, 8 Tests) + Buttons in beiden Apps
- [x] Wiki-Seiten: Medikation, Wohnraum, Kassenbuch, Chat
- [x] Kassenbuch-Storno: Gegenbuchung (Pflicht-Grund + Unterschrift), Originale als storniert markiert, im PDF gekennzeichnet
- [x] Globale Suche (AppBar-Icon + Ctrl+F / Cmd+F) — Debounce, Keyboard-Navigation, Scoring ueber 5 Entitaets-Typen
- [x] UI-Customization-Cleanup: `tabDisplayMode` aus Settings entfernt (seit NavigationRail ohne Funktion)
- [x] Dashboard-Kacheln per Drag-Drop anordnen + aus-/einblenden (SharedPreferences-Persistenz, Reset-Dialog)
