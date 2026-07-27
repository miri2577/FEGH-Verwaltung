# FEGH-Verwaltung

Träger- und Personalverwaltung für Einrichtungen der **Eingliederungshilfe** (SGB IX).
Sie deckt beide Seiten eines Trägers ab: **Personal** (Mitarbeiter, Teams, Dienst- und
Schichtplanung, Urlaub, Zeitnachweise, Kapazität) und **Klienten** (Stammdaten,
Medikation inkl. BtM, Kassenbuch, Wohnraum) samt **Abrechnung** an Kostenträger.

> **Prototyp / Beta.** Ausschließlich mit **fiktiven** Demodaten entwickeln – keine echten
> personenbezogenen (Art.-9-DSGVO-) Daten eingeben, solange die organisatorischen
> Datenschutz-Dokumente nicht vorliegen.

## Konzept

- **Flutter-Multiplattform** (Windows · Linux · macOS · Web · mobil), Riverpod-State,
  rollenbasierte Sichtbarkeit (RBAC: orgAdmin · pvAdmin · teamLead · teamMember · orgAuditor).
- **Ende-zu-Ende-verschlüsselte Cloud-Ablage** (AES-256-GCM, ein Data-Encryption-Key je
  Datensatz, gewrappt mit einem Team-/Org-Key). Der Speicheranbieter sieht nur Ciphertext.
- **Cloud-Sync/Backup** über WebDAV (STRATO HiDrive oder self-hosted Nextcloud/ownCloud),
  hierarchisches `FeghPaths`-Layout unter `organizations/<org>/…`.
- **Geteilte Basis** im Monorepo [`fegh-shared`](https://github.com/miri2577/fegh-shared)
  (Krypto, Cloud, Billing/XRechnung, Compliance, Chat, Core, PDF, OIDC) – gemeinsam mit der
  Schwester-App **FEGH-Dokumentation**.

## Zusammenspiel mit FEGH-Dokumentation

Beide Apps teilen dieselben Kern-Modelle (Employee, Client, Shift, Team) aus `fegh_core`
und dasselbe verschlüsselte Wire-Format – sie können, denselben Team-Key vorausgesetzt,
dieselben Cloud-Daten lesen und schreiben:

- **FEGH-Verwaltung** pflegt Mitarbeiter, Teams, Dienstpläne und Klienten-Stammdaten und
  rechnet gegenüber den Kostenträgern ab.
- **FEGH-Dokumentation** (Feld-/Betreuungskräfte) dokumentiert Verläufe, erfasst Arbeitszeit
  und liefert die Grundlage für Abrechnung und Kapazität.

## Fachlicher Umfang

- **Personal**: Mitarbeiter-Stammdaten, Teams/Standorte, Dienst-/Schichtplanung mit
  Konfliktprüfung und Schichttausch, Urlaub/Abwesenheit, Zeitnachweise
- **Kapazität**: Auslastung je Team; **Sollbesetzung bedarfsgetrieben** aus dem
  wöchentlichen FLS-Bedarf der Klienten (HBG) statt aus Kopfzahlen
- **Klienten**: Stammdaten, Medikationspläne und -gabe, **BtM-Bestand**, Klienten-Kassenbuch,
  Wohnraum-Verwaltung
- **Abrechnung nach Berliner Modell 2026**: Fachleistungsstunden, **kalkulatorische
  Leistungseinheit (kLE) je Kalendertag**, **HBG-Kontingent (1–12)**, Erbringungsfiktion
  (§ 18), XRechnung 3.0 (UBL)
- **System**: RBAC/Policies, Audit-Log, Admin-Konsole (Health/Repair), Backup/Restore,
  OIDC-SSO, verschlüsselter Team-Chat

## Entwicklung

```bash
flutter pub get
flutter run -d windows      # oder -d macos / -d linux / -d chrome
```

Lokal an den geteilten Paketen arbeiten: `pubspec_overrides.yaml` mit Pfad-Overrides auf einen
Nebenordner-Klon von `fegh-shared` (gitignored):

```yaml
dependency_overrides:
  fegh_core:
    path: ../fegh-shared/fegh_core
  # … übrige fegh_*-Pakete analog
```

Tests: `flutter test`.

## Lizenz

[AGPL-3.0](LICENSE).
