# Test-Tools installieren

## Worum geht's?

Fuer zwei Tests brauchst du externe Tools:

| Test | Tool | Zweck |
|------|------|-------|
| XRechnung-KoSIT-Validierung | **KoSIT Validator** (Java) + **XRechnung-Konfig** | Offizielle Schematron-Validierung der UBL-Rechnungen |
| Cross-App-Interop | **dufs** (WebDAV) | Lokale HiDrive-Simulation |

Beide Tools werden **nicht systemweit** installiert, sondern unter
`~/.fegh-tools/` (bzw. `%USERPROFILE%\.fegh-tools\`). Kein Admin-Recht
noetig, vollstaendig reversibel.

## Setup-Script starten

Das Repo enthaelt zwei Scripts unter `scripts/`:

- `install-test-tools.sh` — fuer macOS, Linux und Windows (Git Bash / MSYS2 / WSL)
- `install-test-tools.ps1` — fuer Windows (PowerShell nativ)

### macOS / Linux

```bash
bash scripts/install-test-tools.sh
```

Das Script fragt interaktiv:

```
Erkanntes Betriebssystem: mac
Plattform auswaehlen:
  1) macOS
  2) Linux
  3) Windows (Git Bash / MSYS2 / WSL)
  4) Auto (mac)
Auswahl [4]:
```

Druck Enter (akzeptiert die Auto-Erkennung) oder gib `1`/`2`/`3` ein.
Fehlendes Java wird angeboten: per `brew` (macOS) oder `apt`/`dnf`/`pacman` (Linux).

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-test-tools.ps1
```

Fehlendes Java wird per `winget` oder `choco` installiert (wenn vorhanden).

### Windows (Git Bash / MSYS2)

Du kannst die Bash-Variante nutzen — funktioniert genauso:

```bash
bash scripts/install-test-tools.sh
```

## Was das Script macht

1. **Java pruefen** (11 oder neuer). Falls nicht vorhanden, bietet es die
   Installation ueber den Paketmanager an (brew/apt/dnf/pacman/winget/choco),
   sonst Link auf <https://adoptium.net/>.
2. **KoSIT Validator 1.5.0** herunterladen und nach
   `~/.fegh-tools/kosit/` entpacken.
3. **XRechnung-Konfiguration 3.0.2** herunterladen und nach
   `~/.fegh-tools/kosit/validator-configuration-xrechnung/` entpacken.
4. **dufs v0.43.0** (WebDAV-Server) passend zur Architektur
   (x86_64 / aarch64 / armv7) herunterladen und nach
   `~/.fegh-tools/bin/` legen.
5. Eine **Env-Datei** schreiben (`~/.fegh-tools.env` bzw. `.env.ps1`),
   die die Pfade als Umgebungsvariablen exportiert.

## Aktivieren

```bash
# macOS / Linux / Git Bash:
source ~/.fegh-tools.env

# Windows PowerShell:
. $HOME\.fegh-tools.env.ps1
```

### Dauerhaft aktivieren

**macOS / Linux (Bash/Zsh):**

```bash
echo "source ~/.fegh-tools.env" >> ~/.bashrc   # bzw. ~/.zshrc
```

**Windows PowerShell:**

Das Profil existiert beim ersten Mal oft noch nicht — `-Force` legt es
samt Verzeichnis an:

```powershell
New-Item -Path $PROFILE -ItemType File -Force
Add-Content $PROFILE ". $HOME\.fegh-tools.env.ps1"
```

In der Env-Datei stehen:

- `FEGH_KOSIT_JAR` — Pfad zur Validator-JAR
- `FEGH_XRECHNUNG_SCENARIO` — Pfad zur `scenarios.xml`
- `FEGH_WEBDAV_URL`, `_USER`, `_PASS`, `_DIR` — Defaults fuer dufs

## Erster Testlauf

### XRechnung validieren

```bash
java -jar "$FEGH_KOSIT_JAR" \
  -r "$FEGH_XRECHNUNG_REPO" \
  -s "$FEGH_XRECHNUNG_SCENARIO" \
  pfad/zur/rechnung.xml
```

> `-s` nennt die Szenario-Datei; `-r` nennt das Repository-Verzeichnis
> (enthaelt `resources/` mit XSD/XSL/Schematron). Beide sind noetig —
> das Install-Script setzt `FEGH_XRECHNUNG_REPO` automatisch.

Die Validator-Konfiguration enthaelt **keine** Test-Rechnungen — die
leben im separaten Repo `itplr-kosit/xrechnung-testsuite`. Eine
offizielle Sample-Rechnung holen und validieren:

Das Install-Script legt bereits eine Sample-Rechnung nach
`~/.fegh-tools/samples/xrechnung-sample.xml` ab und exportiert den
Pfad als `FEGH_XRECHNUNG_SAMPLE`. Smoke-Test:

**Bash:**

```bash
java -jar "$FEGH_KOSIT_JAR" \
  -r "$FEGH_XRECHNUNG_REPO" \
  -s "$FEGH_XRECHNUNG_SCENARIO" \
  "$FEGH_XRECHNUNG_SAMPLE"
```

**PowerShell:**

```powershell
java -jar $env:FEGH_KOSIT_JAR -r $env:FEGH_XRECHNUNG_REPO -s $env:FEGH_XRECHNUNG_SCENARIO $env:FEGH_XRECHNUNG_SAMPLE
```

Erwartete Ausgabe: XML-Report mit `<accepted>true</accepted>`.

### dufs starten

```bash
mkdir -p "$FEGH_WEBDAV_DIR"
dufs "$FEGH_WEBDAV_DIR" \
  --auth "$FEGH_WEBDAV_USER:$FEGH_WEBDAV_PASS@/:rw" \
  --allow-all \
  --port 5000
```

> `--allow-all` schaltet PUT, DELETE und MKCOL frei. Ohne dieses Flag
> gibt dufs **HTTP 403** auf Schreibzugriffe zurueck, auch wenn die
> Auth-Regel `rw` erlaubt — `--auth` ist die Zugriffs-_Rolle_, die
> Allow-Flags steuern welche _HTTP-Methoden_ ueberhaupt aktiv sind.

Anschliessend: WebDAV-Endpoint `http://localhost:5000/` mit
`user:pass = fegh-test:fegh-test`.

## Deinstallation

```bash
rm -rf ~/.fegh-tools ~/.fegh-tools.env*
```

Windows entsprechend `Remove-Item -Recurse $HOME\.fegh-tools*`.

## Details zu den Tools

### KoSIT Validator

Das **offizielle** Validierungstool fuer elektronische Rechnungen,
herausgegeben von der Koordinierungsstelle fuer IT-Standards (KoSIT).
Es fuehrt Schema- und Schematron-Pruefungen durch und erzeugt einen
Report mit gefundenen Regelverletzungen.

Quellen:

- Validator: <https://github.com/itplr-kosit/validator>
- XRechnung-Konfiguration: <https://github.com/itplr-kosit/validator-configuration-xrechnung>

### dufs

Ein kleiner Rust-basierter HTTP/WebDAV-Server, der lokal auf einem
Port lauscht. Fuer Tests reicht das — er verhaelt sich API-kompatibel
zu HiDrive/Nextcloud/ownCloud fuer die WebDAV-Operationen, die unsere
App braucht (`PROPFIND`, `PUT`, `GET`, `MKCOL`, `DELETE`, `MOVE`).

Quelle: <https://github.com/sigoden/dufs>

## Integration mit Flutter-Tests

Die Tests `test/xrechnung_kosit_test.dart` und `test/cross_app_interop_test.dart`
lesen die Umgebungsvariablen aus der Env-Datei. Wenn sie nicht gesetzt
sind, werden die Tests als **skipped** markiert (nicht als Fehler) —
damit die Pipeline auch ohne installierte Tools gruen bleibt.
