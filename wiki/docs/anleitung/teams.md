# Teams

## Ueberblick

Teams buendeln Mitarbeiter und Klienten zu einer Arbeitsgemeinschaft — pro Wohngemeinschaft, pro Schicht-Gruppe oder pro Bereich. Ein Team hat genau eine Teamleitung, einen Budget-Rahmen und eine Mitgliederliste. Klienten werden Teams zugewiesen, damit das Team alle Rechte fuer deren Akten bekommt.

!!! note "Berechtigung"
    Teams anlegen, bearbeiten, aufloesen: Admin. Teamleitung kann Mitglieder des eigenen Teams managen (beitreten/entfernen).

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
