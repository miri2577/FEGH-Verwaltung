# Organisation einrichten

Der initiale Aufbau einer Organisation ist die **wichtigste
Admin-Aktion** der gesamten Betriebslaufzeit. Was hier falsch laeuft,
ist spaeter schwer zu reparieren (Schluesselrotation, Namens-
Migrationen, Cross-Sync-Konflikte). Dieses Kapitel fuehrt den
Prozess Schritt fuer Schritt durch.

## Funktionsweise im Detail

### Das Problem, das wir loesen

Bei FEGH ist "Organisation" keine Tabellenzeile, sondern ein
komplettes **kryptographisches und organisatorisches Framework**:

- Einen verschluesselten Wurzel-Ordner auf der Cloud
- Einen Master-Encryption-Key (MEK), aus dem alle Team-Keys
  abgeleitet werden
- Eine Rollen-Datei (roles.json), die Zugriffe auf Team-Ebene
  steuert
- Recovery-Codes fuer den Notfall
- Eine Stammdaten-Definition (Name, Bundesland, USt-ID, IBAN)

Ohne sauberen Setup gibt es spaeter entweder **kein Team**, **kein
Rechte-Gefuege** oder **keine Verschluesselungsbasis**. Einmal
gemacht, haelt das Fundament jahrelang — deshalb diese detailierte
Anleitung.

### Konkretes Szenario: Assistenz gGmbH richtet sich ein

**Montag 09:00 — Inhaberin Frau Dr. M. und Einrichtungsleitung Anja
sitzen zusammen.**

Die Einrichtung ist neu, Tag 1. Nichts existiert. Ziel bis Ende
der Woche: produktionsreifes Setup fuer das erste Team
"WG Hauptstrasse" mit 5 Mitarbeitern.

**Schritt 1 — Cloud-Infrastruktur (09:15).**

Frau Dr. M. hat sich fuer einen **WebDAV-kompatiblen Cloud-Speicher**
entschieden. Die App unterstuetzt:

- **STRATO HiDrive** (deutscher Anbieter, DSGVO-AV-Vertrag)
- **Nextcloud** (selbst gehostet oder als Managed Service bei
  Anbietern wie Hetzner, IONOS, Your Secure Cloud)
- **ownCloud** (selbst gehostet, enterprise-orientiert)
- **Generischer WebDAV** (eigener Server, z. B. `dufs`, Apache mod_dav)

Fuer kleinere Einrichtungen eignet sich HiDrive (keine Server-
Administration noetig); fuer groessere Traeger mit eigener
IT-Abteilung ist Nextcloud wirtschaftlich attraktiver.

Frau Dr. M. hat einen HiDrive-Business-Account abgeschlossen.
Im Cloud-Kundenportal erzeugt sie ein **dediziertes App-Passwort**
fuer die FEGH-App (nicht ihr Haupt-Login — Trennung der Zugaenge).
Bei Nextcloud/ownCloud laeuft das analog ueber "App-Passwoerter"
oder "Application Tokens".

**Schritt 2 — Verwaltungs-App installieren und Setup-Wizard
starten (09:40).**

Anja startet die Verwaltungs-App auf ihrem Dienst-PC. Setup-Wizard
laeuft:

1. **Organisations-Stammdaten**: Name "Assistenz gGmbH", Adresse,
   USt-ID `DE123456789`, Bundesland **Berlin**, Logo hochladen.
2. **Cloud-Zugang**: Provider-Typ (HiDrive / Nextcloud / ownCloud /
   Generic WebDAV), Base-URL, Benutzername, App-Passwort, Root-Pfad
   `/eingliederungshilfe/`.
3. **Verbindung testen**: App prueft TLS, PROPFIND, MKCOL, PUT,
   DELETE → gruener Haken.
4. **Verzeichnisstruktur anlegen**: App erzeugt automatisch
   die FEGH-Standard-Struktur im Cloud-Root:
   ```
   /eingliederungshilfe/organizations/assistenz-ggmbh/
     administration/
       users/roles.json
       teams/
       audit/
     teams/
     backup/
   ```
5. **Master Encryption Key (MEK)** generieren — **kritischster
   Schritt**:
   - App wuerfelt 32 zufaellige Bytes (AES-256)
   - Daraus wird ein **Recovery-Paket** erzeugt: 10 Einloesungs-Codes
     plus eine QR-Code-Variante
   - **Anja druckt das Recovery-Paket** und versiegelt es in einem
     Briefumschlag → Tresor
   - Der MEK selbst wird verschluesselt mit Anjas Login-Passwort +
     PBKDF2 in ihr `flutter_secure_storage` gelegt
6. **Erste Admin-Rolle**: Anja wird als `orgAdmin` in `roles.json`
   eingetragen.

**Schritt 3 — Erstes Team anlegen (11:00).**

Anja oeffnet `Verwaltung → Teams → Neu`:

1. Name "WG Hauptstrasse"
2. Standort, Budget, Teamleitung (Anja selbst uebergangsweise, spaeter
   Lars)
3. Speichern → App erzeugt im Cloud-Speicher den Team-Ordner,
   generiert Team-Key, verschluesselt ihn mit MEK, legt ihn unter
   `administration/teams/hauptstrasse/team-key.bin` ab.
4. Audit-Event `team.created`.

**Schritt 4 — Abrechnungsdefaults setzen (11:30).**

`Einstellungen → Abrechnung`:

- Default-FLS-Stundensatz: 52,00 EUR
- Kalkulationsfaktor: 1,33
- Jahreskapazitaets-Budget pro Team: 300.000 EUR

**Schritt 5 — Erste Rechnungs-Empfaenger pflegen (11:45).**

`Berichte → Rechnungen → Empfaenger`:

- Name "Sozialamt Friedrichshain-Kreuzberg"
- Leitweg-ID 991-01234-44
- Adresse, Email
- Spaeter pro Klient die Fallnummer zuordnen

**Schritt 6 — Admin-Gesundheitscheck (12:00).**

`Admin-Console → Tools → Health-Check`:

- Cloud-Zugang: OK
- Ordnerstruktur: vollstaendig
- MEK vorhanden: ja
- roles.json vorhanden: ja
- Backup aktiviert: ja

Alle gruen → Setup ist abgeschlossen. Einrichtung ist
produktionsreif.

**Mittwoch 10:00 — Erster Mitarbeiter wird eingeladen.**

Anja laedt Lars ein (`Admin-Console → Mitarbeiter einladen`) und
uebergibt ihm physisch den QR-Code + PIN. Ab dem Moment ist das
Team einsatzfaehig.

### Warum die Reihenfolge so genau?

Jeder Schritt baut auf dem vorigen:

1. **Cloud zuerst**, weil ohne Cloud kein Team-Ordner angelegt werden kann.
2. **Stammdaten vor MEK**, weil der MEK organisationsbezogen ist
   (wird bei Migration mit der Org verschoben).
3. **MEK vor Team**, weil Team-Key mit MEK verschluesselt wird.
4. **Admin-Rolle vor Team-Leitung**, weil nur Admin Teams anlegen darf.
5. **Team vor Rollen-Zuordnung**, weil Rollen Team-IDs referenzieren.
6. **Abrechnungsdefaults vor erster Rechnung**, weil sonst
   falsche Saetze persistiert wuerden.
7. **Health-Check zuletzt**, weil er das Gesamtbild validiert.

### Was man nicht uebersehen darf

- **Recovery-Paket physisch sichern**: ein verlorener MEK bedeutet
  den Verlust aller verschluesselten Daten. Das Recovery-Paket ist
  der einzige Rueckweg. Nicht digital speichern (Screenshot des QR
  auf dem PC ist fast so schlecht wie kein Backup).
- **Backup einschalten**: `Einstellungen → Sicherheit → Backup`
  aktivieren. Default: 24h-Rhythmus, Ablage in der Cloud unter
  `backup/`.
- **Cloud-App-Passwort rotieren koennen**: das App-Passwort, das
  in der FEGH-App gespeichert ist, soll **nicht** das Haupt-Passwort
  des Cloud-Accounts sein. So kann es bei Kompromittierung
  schmerzfrei rotiert werden — der Haupt-Account bleibt erreichbar.
- **Bundesland richtig setzen**: aendert spaeter die Verfuegbarkeit
  von Bedarfsinstrument-Dropdowns. Falsches Bundesland → falsche
  Berichte.

### Rechtlicher Hintergrund

- **Art. 32 DSGVO** — Sicherheit der Verarbeitung. Die Einrichtungs-
  Kette (MEK → Team-Key → Daten) dokumentiert Sicherheit in
  Schichten.
- **Art. 30 DSGVO** — Verzeichnis der Verarbeitungstaetigkeiten; der
  Einrichtungs-Setup ist dessen Grundlage.
- **§67a SGB X** — Sozialgeheimnis; die kryptographische Trennung
  ueber Teams realisiert das technisch.
- **IT-SiG 2.0** — Bei KRITIS-Einrichtungen: Nachweis des Schutz-
  bedarfs; der Setup-Wizard erzeugt Screenshots, die als Nachweis
  dienen.

## Typische Stolpersteine

| Problem | Ursache | Loesung |
|---------|---------|---------|
| Cloud-Test schlaegt fehl | App-Passwort nicht neu erzeugt | im Cloud-Kundenportal App-Passwort/Application-Token neu anlegen |
| MEK-Dialog zeigt keine Recovery-Codes | Zwischenspeicherfehler | App neu starten, erneut starten |
| Team-Anlage bricht ab | roles.json nicht schreibbar | Cloud-Quota pruefen, TLS-Zertifikat, Schreibrechte auf Root-Pfad |
| Audit-Tab leer | Audit-Logger noch nicht initialisiert | mindestens eine Aktion (Login/Logout) ausloesen |
