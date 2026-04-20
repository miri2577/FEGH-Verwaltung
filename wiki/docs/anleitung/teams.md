# Teams

## Ueberblick

Teams buendeln Mitarbeiter und Klienten zu einer Arbeitsgemeinschaft — pro Wohngemeinschaft, pro Schicht-Gruppe oder pro Bereich. Ein Team hat genau eine Teamleitung, einen Budget-Rahmen und eine Mitgliederliste. Klienten werden Teams zugewiesen, damit das Team alle Rechte fuer deren Akten bekommt.

!!! note "Berechtigung"
    Teams anlegen, bearbeiten, aufloesen: Admin. Teamleitung kann Mitglieder des eigenen Teams managen (beitreten/entfernen).

## Funktionsweise im Detail

### Das Problem, das wir loesen

In mittelgrossen Einrichtungen wachsen Teams organisch: drei Wohn-
gruppen, ein mobiles Assistenz-Team, ein Tagesstruktur-Team — jedes
mit eigener Leitung, eigenen Klienten, eigenen Schluesseln
(wortwoertlich und kryptographisch). Ohne Team-Struktur waeren alle
Informationen fuer alle Mitarbeiter sichtbar — das verstoesst gegen
**Datenminimierung** (Art. 5 DSGVO): ein Mitarbeiter des Tages-
struktur-Teams braucht keinen Zugriff auf die Medikationsplaene der
Wohngruppe A.

Teams implementieren die **Trennlinie zwischen Arbeitsgruppen**
technisch: pro Team gibt es einen eigenen Verschluesselungs-
schluessel (Team-Key), der nur den Mitgliedern zur Verfuegung
steht. Daten eines Teams sind fuer andere Teams **kryptographisch
nicht entschluesselbar**, auch wenn sie den Cloud-Speicher teilen.

### Konkretes Szenario: Neues Wohnprojekt startet

**15. September — Assistenz gGmbH startet ein viertes Team.**

Admin Anja legt das Team an:

1. `Verwaltung → Teams → Neu`
2. Name: "WG Gruenstrasse"
3. Beschreibung: "Ambulant betreutes Wohnen, 5 Bewohner, 18+"
4. Standort: Gruenstrasse 12, 10115 Berlin
5. Budget (Jahr): 240.000 EUR (geschaetzte Summe der FLS-Saetze)
6. Abteilung: Eingliederungshilfe
7. Teamleitung: Lars (neu eingestellt als Leitung)
8. Mitglieder: Lars + 3 Fachkraefte (werden spaeter zugewiesen)
9. Status: Aktiv

**Was automatisch im Hintergrund passiert** (direkt beim Speichern):

1. Auf HiDrive wird eine **Ordner-Hierarchie** angelegt:
   ```
   /eingliederungshilfe/organizations/assistenz-ggmbh/teams/gruenstrasse/
     ├── clients/
     ├── schedules/
     ├── reports/
     ├── worktime/
     ├── kassenbuch/
     └── medication/
   ```
2. Ein **32-Byte AES-Key** (Team-Key) wird generiert (per
   `Random.secure()`).
3. Der Team-Key wird mit dem **Organisations-Masterkey (MEK)**
   verschluesselt und in
   `administration/teams/gruenstrasse/team-key.bin` abgelegt.
4. Ein initialer `members.json` mit Lars als Leitung wird in
   den Team-Ordner geschrieben (verschluesselt).
5. Audit-Event `team.created`.

**16. September — Lars installiert App via Provisioning-QR.**

Er bekommt von Anja einen QR-Code + PIN. Token enthaelt:
- HiDrive-Credentials der Organisation
- Organisations-ID
- Team-ID "gruenstrasse"
- **Team-Key bereits entschluesselt** (im Token, mit der PIN erneut
  verschluesselt)
- Rolle `teamLead`

Nach Scannen und PIN-Eingabe hat Lars Zugriff auf **nur** die
Ordner seines Teams. Wenn er versucht, via HTTP-Client auf einen
anderen Team-Ordner zuzugreifen, bekommt er das zwar (WebDAV-Zugang
ist auf Org-Ebene), aber die Dateien sind mit fremden Team-Keys
verschluesselt — er kann sie nicht lesen.

**20. September — Fachkraft Sabrina beitretet.**

Anja fuegt Sabrina als Mitglied hinzu:

1. Team-Detail → "Mitglied hinzufuegen" → Sabrina
2. System:
   - Schreibt neuen `members.json` (mit Sabrina drin)
   - Erzeugt neuen Provisioning-QR fuer Sabrinas Geraet
   - Im QR ist der Team-Key von "gruenstrasse" enthalten

Sabrinas Geraet erhaelt den Team-Key. Sie sieht alle Klienten,
Plaene, Berichte, Kassenbuchungen des Teams — aber nichts aus
Team "Hauptstrasse".

**31. Dezember — Lars wechselt zur Leitung des anderen Teams.**

Anja nimmt ihn aus "gruenstrasse" heraus:

1. Team-Detail → "Mitglied entfernen" → Lars
2. **Team-Key-Rotation**:
   - Neuer 32-Byte AES-Key generiert
   - Alle Dateien im Team-Ordner werden mit dem neuen Key
     re-encryptet (Cloud-Aufwand einmalig, typisch 30 sec fuer
     mittleres Team)
   - Der neue Key wird an alle verbleibenden Mitglieder-Geraete
     verteilt beim naechsten Sync
   - Lars' altes Geraet hat den **alten** Key gecached — er kann
     aeltere Datei-Kopien lokal noch lesen, aber nichts Neues mehr
     abrufen
3. Audit-Event `team.member.removed` + `team.key.rotated`.

### Team-Keys — das Kern-Sicherheitsprimitiv

Warum pro Team ein eigener Key, nicht ein Org-weiter?

- **Kompartimentierung**: Kompromittierung eines Geraetes eines
  Teams macht andere Teams nicht angreifbar.
- **Personalwechsel ohne Voll-Re-Keying**: wenn Lars das Team
  verlaesst, wird nur der Team-Key rotiert — der Org-Key bleibt
  stabil, und andere Teams muessen nichts neu verschluesseln.
- **DSGVO Art. 32 Privilegien-Minimierung**: Mitarbeiter sehen nur
  das, was fuer ihre Arbeit noetig ist — technisch erzwungen, nicht
  per Policy.

### Was der Team-Datensatz NICHT ist

- **Kein Fach-Container** — dieselbe Klientenliste kann nicht in
  zwei Teams parallel liegen (Klient ist genau einem Team zugeordnet).
- **Kein Lohn-Kostenstellen-System** — die Zuordnung
  Mitarbeiter→Team ist fachlich, nicht verguetungstechnisch. Ein
  Mitarbeiter kann in mehreren Teams sein.
- **Kein Chat-Room-Ersatz** — Matrix-Raeume und Teams sind
  gesondert; ein Team-Raum im Chat wird zusaetzlich erstellt.

### Rechtlicher Hintergrund

- **Art. 5 Abs. 1 lit. c DSGVO** — Datenminimierung. Jeder
  Mitarbeiter sieht nur Daten, die fuer seine Taetigkeit
  erforderlich sind; Teams sind das organisatorische Instrument.
- **Art. 32 DSGVO** — Sicherheit der Verarbeitung. Team-Keys sind
  die technische Umsetzung von "Privileged Access Management" auf
  Einrichtungs-Ebene.
- **§67a SGB X** — Sozialgeheimnis. Mitarbeiter duerfen Sozialdaten
  nur verarbeiten, soweit zur Aufgabenerfuellung noetig.

## Felder

| Feld | Beschreibung |
|------|-------------|
| Name | Interner Team-Name, z. B. "WG Hauptstrasse" |
| Beschreibung | Ausfuehrlicher Zweck / Abgrenzung |
| Abteilung | Organisatorische Einheit (Eingliederungshilfe, Jugendhilfe, …) |
| Standort | Primaerer Arbeitsort |
| Teamleitung | Mitarbeiter-ID der verantwortlichen Person |
| Mitglieder | Liste weiterer Mitarbeiter-IDs |
| Klienten | Liste der zugewiesenen Klienten-IDs |
| Budget | Jahresbudget in Euro (fuer Kapazitaetsplanung) |
| Status | Aktiv, Inaktiv, On Hold |

## Lifecycle

- **Neues Team** wird angelegt → erzeugt auf HiDrive einen Team-Ordner mit Unterstruktur (`clients/`, `schedules/`, `reports/`, `worktime/`)
- **Team-Key** wird automatisch generiert (AES-256) und verschluesselt in `administration/teams/<teamId>/team-key.bin` abgelegt
- **Mitglieder-Geraete** bekommen den Team-Key bei ihrem naechsten Sync und koennen ab dann Daten lesen
- **On Hold** — Team pausiert (z. B. Krankheitswelle), keine neuen Zuweisungen moeglich
- **Inaktiv** — Team aufgeloest, Historie bleibt, keine neuen Schichten mehr

## Team-Key-Handling

Der Team-Key wird nie im Klartext ausgetauscht. Fluss:

1. Admin erzeugt Team → generiert 32 Byte zufaelligen AES-Schluessel
2. Schluessel wird mit dem Organisations-Masterkey (MEK) verschluesselt und hochgeladen
3. Mitglieder-Geraete laden den verschluesselten Team-Key, entschluesseln ihn lokal mit ihrem DEK (Data Encryption Key) und cachen ihn
4. Alle klienten-/team-spezifischen Dateien werden mit diesem Key ver-/entschluesselt

Bei Ausscheiden eines Mitglieds: Team-Key wird rotiert (neuer Key, neu verteilt), alte Dateien werden neu verschluesselt.

## Integration

- **Klienten** werden Teams zugewiesen
- **Dienstplan** plant Schichten im Kontext eines Teams
- **Chat** spiegelt Teams auf Matrix-Raeume
- **Berichte** koennen team-weit aggregiert werden
