# FEGH Scripts

## install-test-tools

Installiert die externen Tools fuer XRechnung-Validierung und Cross-App-Interop-Tests:

- **Java JRE** (Prueflauf, bietet Installation an, wenn nicht vorhanden)
- **KoSIT Validator** + **XRechnung-Konfiguration** (offiziell, KoSIT e. V.)
- **dufs** (kleiner WebDAV-Server als lokale HiDrive-Simulation)

Alles landet in `~/.fegh-tools/` (bzw. `%USERPROFILE%\.fegh-tools\`).
Keine Systemaenderung — vollstaendig pro Nutzer und reversibel.

## Nutzung

### macOS / Linux (Bash)

```bash
bash scripts/install-test-tools.sh
```

Das Script erkennt das Betriebssystem und fragt zur Bestaetigung nach.
Wenn Homebrew (macOS) oder apt/dnf/pacman (Linux) verfuegbar sind,
wird Java auf Wunsch automatisch mitinstalliert. Ansonsten zeigt es
die Download-Links fuer die manuelle Installation.

### Windows (PowerShell)

```powershell
powershell -ExecutionPolicy Bypass -File scripts\install-test-tools.ps1
```

Java wird ueber `winget` oder `choco` installiert (wenn vorhanden),
ansonsten Hinweis auf <https://adoptium.net/>.

### Windows mit Git Bash / MSYS2 / WSL

Kannst du die Bash-Variante nutzen — funktioniert identisch.

## Nach der Installation

Das Script legt `~/.fegh-tools.env` (bzw. `.env.ps1` unter Windows) mit
den wichtigsten Umgebungsvariablen ab:

- `FEGH_KOSIT_JAR` — Pfad zur Validator-JAR
- `FEGH_XRECHNUNG_SCENARIO` — Pfad zur `scenarios.xml`
- `FEGH_WEBDAV_URL` / `_USER` / `_PASS` / `_DIR` — dufs-Defaults

Aktivierung:

```bash
# Bash:
source ~/.fegh-tools.env

# PowerShell:
. $HOME\.fegh-tools.env.ps1
```

Die Flutter-Integration-Tests lesen diese Variablen automatisch.

## Deinstallation

```bash
rm -rf ~/.fegh-tools ~/.fegh-tools.env*
```

(oder das entsprechende Verzeichnis im User-Profil unter Windows).
