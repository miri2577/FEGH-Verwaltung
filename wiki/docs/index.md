# FEGH-Verwaltung

Die FEGH-Verwaltung ist ein **stationaeres Desktop-Admin-Werkzeug** fuer Traeger der Eingliederungshilfe nach SGB IX. Sie ergaenzt die mobile [FEGH-Dokumentation](https://miri2577.github.io/FEGH-Dokumentation/), indem sie die administrative Seite abdeckt: Personalverwaltung, Teams, Dienstplanung, Rechnungsstellung, Berichte, Klient-gebundene Module (Medikation, Wohnraum, Kassenbuch) und Backup.

## Wer nutzt die App?

Die App ist **rollenbasiert mehrbenutzerfaehig** und kann stationaer von mehreren Personen gleichzeitig genutzt werden:

- **Admins** (Org-Admin, PV-Admin) sehen das volle Admin-Dashboard mit Rechnungen, Kapazitaetsanalyse, Berichten und Backup.
- **Team-Leitungen** pflegen Mitarbeiter-Stammdaten, Dienstplanung, Klient-Medikation.
- **Mitarbeiter** landen im Bildschirm *Meine Arbeit* mit eigenen Schichten, offenen Medikationsgaben und Kassenbuch-Eintraegen.
- **Auditoren** haben einen zeitlich und team-bezogen begrenzten Lesezugriff.

## Zusammenspiel mit FEGH-Dokumentation

Die [Doku-App](https://miri2577.github.io/FEGH-Dokumentation/) ist das mobile Feld-Tool fuer die Fachkraft unterwegs: Klientenakte, Termine, Arbeitszeiterfassung, Fachleistungsstunden, Berichte. Die Verwaltung ist der stationaere Gegenspieler — gemeinsam teilen sich beide Apps:

- Dieselbe **Cloud-Struktur** (HiDrive, Nextcloud, ownCloud, generisches WebDAV)
- Dasselbe **Verschluesselungsschema** (`fegh_crypto`, AES-256-GCM + DEK-Wrapping)
- Dasselbe **Rollen- und Berechtigungsmodell** (`roles.json`)
- Dasselbe **Audit-Log** (`fegh_compliance`)
- Dasselbe **PDF-Design-System** (`fegh_pdf_kit`)
- Dasselbe **Rechnungs-Format** XRechnung UBL 2.1 (`fegh_billing`)
- Dasselbe **Backup-Wire-Format** (`fegh_backup`)

Mehr dazu unter [Zusammenspiel mit FEGH-Dokumentation](technik/zusammenspiel.md).

## Wann welche App?

| Aufgabe | Doku-App | Verwaltung |
|---|---|---|
| Klientendaten erfassen / bearbeiten | ✅ (Feld) | ✅ (Office) |
| Termine dokumentieren | ✅ | — |
| Wirkungsmessung (GAS/POS, ICF/TIB) | ✅ | — |
| Arbeitszeit erfassen | ✅ | — |
| Mitarbeiter-Stammdaten pflegen | — | ✅ |
| Teams verwalten | beschraenkt | ✅ |
| Dienstplan erstellen (mit ArbZG-Konflikten) | — | ✅ |
| Urlaub / Abwesenheiten | — | ✅ |
| Kapazitaetsanalyse | — | ✅ |
| Rechnungen (XRechnung) | — | ✅ |
| Medikation verabreichen + Plan | — | ✅ (stationaer) |
| Wohnraum + Kassenbuch | — | ✅ (stationaer) |
| Provisioning per QR | eingeschraenkt | ✅ (primaer) |
| Backup der gesamten Organisation | — | ✅ |

## Die wichtigsten Bereiche

- **[Erste Schritte](anleitung/erste-schritte.md)** — Ersteinrichtung, Cloud-Verbindung, erstes Team.
- **[Mitarbeiter-Einladung per QR](admin/einladung.md)** — Neue Mitarbeiter ohne manuelle Konfiguration aufnehmen.
- **[Rollen und Berechtigungen](admin/rollen.md)** — Wer sieht was.
- **[Rechnungsmodul](features/rechnungen.md)** — XRechnung-konforme Fakturierung fuer Kostentraeger.
- **[Audit-Log](features/audit.md)** — Revisionssichere Protokollierung.
- **[Backup und Recovery](features/backup.md)** — Verschluesselte Voll-Backups per Passwort.
- **[Architektur](technik/architektur.md)** — Technischer Ueberblick.

## Links

- [FEGH-Dokumentation Wiki](https://miri2577.github.io/FEGH-Dokumentation/)
- [Verwaltung auf GitHub](https://github.com/miri2577/FEGH-Verwaltung)
- [Dokumentation auf GitHub](https://github.com/miri2577/FEGH-Dokumentation)
