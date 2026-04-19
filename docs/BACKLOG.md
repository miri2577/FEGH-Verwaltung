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
- [ ] **Einheitliche Cloud-Ordnerstruktur** dokumentieren und in beiden Apps per `fegh_cloud` erzeugen (Folge-Sprint)
- [ ] **Live-Cross-App-Test**: Verwaltung schreibt Klient → Doku liest denselben Record aus Cloud (braucht laufende Test-Umgebung)

---

## P1 — Scope B/C der MVP-Module

### Medikation (D3 Scope B/C)
- [ ] Bedarfsmedikation (PRN) — ungeplante Gabe mit Begruendung
- [ ] PIN-Validierung fuer Gabe-Quittung (Mitarbeiter-PIN, PBKDF2)
- [ ] 4-Augen-Prinzip fuer alle Gaben (aktuell nur BtM)
- [ ] BTM-Bestandsliste pro Einrichtung mit Nachbestellung
- [ ] BTM-Vernichtungsprotokoll mit Zeuge

### Kassenbuch (D4 Scope B/C)
- [ ] Canvas-Unterschrift fuer Eintrag-Freigabe (`signature`-Paket)
- [ ] Monatsabschluss-Rollover (persistenter Saldo, kein Neu-Berechnen)
- [ ] Storno-Workflow (freigegebene Eintraege)
- [ ] Mietabrechnung Kalt/Warm
- [ ] Nebenkostenabrechnung
- [ ] Beleg-Upload (Foto/PDF) pro Eintrag

### Dienstplan (D2 Erweiterung)
- [ ] Drag-Drop-Verschiebung im Kalender
- [ ] Tausch-Anfrage-Workflow (Mitarbeiter → Lead)
- [ ] iCal-Export pro Mitarbeiter
- [ ] Konflikt-Check auch im Bulk-Dialog

---

## P1 — Tests und Validierung

- [ ] Wohnraum-Service Unit-Tests (analog Kassenbuch)
- [ ] BTM-Service: erweiterte Test-Faelle (Bestand-Trend, Zeuge ≠ Gebender)
- [ ] XRechnung: echter KoSIT-Schematron-Test (lokales Tool oder CI-Pipeline)
- [ ] Cross-App-Interop-Test nach `fegh_core`

---

## P1 — Wiki-Verwaltung ausbauen

8 Stub-Seiten mit echtem Inhalt fuellen:

- [ ] `anleitung/mitarbeiter.md`
- [ ] `anleitung/teams.md`
- [ ] `anleitung/dienstplanung.md`
- [ ] `anleitung/arbeitszeiten.md`
- [ ] `anleitung/urlaub.md`
- [ ] `anleitung/kapazitaet.md`
- [ ] `anleitung/berichte.md`
- [ ] `anleitung/einstellungen.md`

Ausserdem:
- [ ] Medikations-Wiki-Seite (neues Modul aus D3)
- [ ] Wohnraum+Kassenbuch-Wiki-Seite (neue Module aus D4)
- [ ] Team-Chat-Wiki-Seite (fegh_chat)

---

## P2 — UI- und Navigations-Feinschliff

- [ ] Globale Suche in der AppBar (aktuell Platzhalter) — implementieren
- [ ] Deep-Links via `go_router` (`/klienten/42`) — spaetere Umstellung
- [ ] UI-Customization aufraeumen — `tabDisplayMode` ist seit D-Nav ohne Funktion
- [ ] Dashboard-Kacheln konfigurierbar (Drag-Drop pro User)
- [ ] Mitarbeiter-Dashboard (`MyWorkScreen`) nach Feedback verfeinern

---

## P2 — Infrastruktur

- [ ] Native VoIP-Calls (`flutter_webrtc`) statt Element-Web-Fallback im Chat
- [ ] PerSEH-Konnektor (D5-Strategiepapier) — Referenzkunde abwarten
- [ ] CI-Pipeline fuer beide Apps (flutter test auto)
- [ ] Fegh-shared Pakete optional mit Remote (Git)
- [ ] Provisioning-End-to-End-Test (Admin erstellt Token → Mitarbeiter scannt → Cloud-Zugriff)

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
