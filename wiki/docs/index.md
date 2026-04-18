# FEGH-Verwaltung

**Desktop-Admin-Tool fuer Eingliederungshilfe-Traeger**

FEGH-Verwaltung ist die **Buero-Schwester** der
[FEGH-Dokumentation](https://miri2577.github.io/FEGH-Dokumentation/).
Waehrend die Doku-App fuer die Arbeit am Klienten gedacht ist
(Termine, Dokumentation, Wirkungsmessung), uebernimmt die Verwaltung
alles, was Struktur, Orga und Admin-Aufgaben sind:

- Mitarbeiter-Stammdaten
- Team-Zusammensetzung und -Fuehrung
- Dienstplanung und Schicht-Zuweisung
- Urlaubs- und Abwesenheitsverwaltung
- Kapazitaetsplanung ueber alle Teams
- Rechnungsstellung und Abrechnung
- Berichtswesen (Reporting)
- Provisioning neuer Mitarbeiter (QR-Code)

## Wann welche App?

| Aufgabe | Doku-App | Verwaltung |
|---|---|---|
| Klientendaten erfassen | ✅ | - |
| Termine dokumentieren | ✅ | - |
| Wirkungsmessung (GAS/POS) | ✅ | - |
| Mitarbeiter anlegen | - | ✅ |
| Dienstplan erstellen | - | ✅ |
| Rechnungen stellen | ✅ (ab V2) | ✅ |
| Team-Admin | beides | ✅ (Komfort) |
| Provisioning neuer MA | eingeschraenkt | ✅ (primaer) |
| Kapazitaetsauswertung | - | ✅ |

Kleine Traeger (5-10 Mitarbeiter) kommen mit der **Doku-App allein**
aus. Groessere Organisationen gewinnen mit der **Verwaltung** an
Uebersicht und Buero-Komfort.

## Geteilte Basis

Beide Apps nutzen dieselben Shared-Packages:

- **`fegh_crypto`** - Wire-Format fuer EncryptedRecord und
  Provisioning-Tokens, AES-256-GCM mit DEK-Wrapping
- **`fegh_cloud`** - WebDAV-Adapter fuer HiDrive, Nextcloud,
  ownCloud, Generic WebDAV

Das heisst: Daten die eine App schreibt kann die andere lesen
(wenn dieselbe Sync-Passphrase gesetzt ist und dieselbe HiDrive-
Config genutzt wird).

## Erste Schritte

Siehe [Erste Schritte](anleitung/erste-schritte.md).

## Abgrenzung zur Doku-App

- **FEGH-Dokumentation:** iOS, Android, Windows, macOS, Web.
  Fieldwork-orientiert, einzelne Klienten im Fokus.
- **FEGH-Verwaltung:** Windows, macOS, Linux Desktop. Buero-orientiert,
  Ueberblick ueber viele Klienten/Mitarbeiter.

## Links

- [FEGH-Dokumentation Wiki](https://miri2577.github.io/FEGH-Dokumentation/) -
  Schwester-App und Master fuer Datenmodelle
- [Verwaltung GitHub](https://github.com/miri2577/FEGH-Verwaltung)
- [Dokumentation GitHub](https://github.com/miri2577/FEGH-Dokumentation)
