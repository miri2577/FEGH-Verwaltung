#!/usr/bin/env bash
# FEGH Test-Tools Installer
# -------------------------
# Installiert KoSIT Validator + XRechnung-Konfiguration + dufs (WebDAV)
# fuer XRechnung-Validierung und Cross-App-Interop-Tests.
#
# Laeuft auf:
#   - macOS (brew optional)
#   - Linux (apt, dnf, pacman werden erkannt)
#   - Windows (Git Bash / MSYS2 / WSL)
#
# Nutzung:
#   bash scripts/install-test-tools.sh

set -euo pipefail

# ── Konstanten ────────────────────────────────────────────────
VALIDATOR_VERSION="1.5.0"
VALIDATOR_URL="https://github.com/itplr-kosit/validator/releases/download/v${VALIDATOR_VERSION}/validator-${VALIDATOR_VERSION}-distribution.zip"

XRECHNUNG_CFG_FILE="validator-configuration-xrechnung_3.0.2_2024-06-20.zip"
XRECHNUNG_CFG_URL="https://github.com/itplr-kosit/validator-configuration-xrechnung/releases/download/release-2024-06-20/${XRECHNUNG_CFG_FILE}"

DUFS_VERSION="v0.43.0"

INSTALL_ROOT="${HOME}/.fegh-tools"
KOSIT_HOME="${INSTALL_ROOT}/kosit"
BIN_DIR="${INSTALL_ROOT}/bin"
ENV_FILE="${HOME}/.fegh-tools.env"

# ── Farben ────────────────────────────────────────────────────
GREEN="\033[0;32m"
YELLOW="\033[0;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

ok()   { echo -e "${GREEN}OK${RESET} $*"; }
warn() { echo -e "${YELLOW}!!${RESET} $*"; }
err()  { echo -e "${RED}KO${RESET} $*"; }
step() { echo -e "\n${BOLD}==> $*${RESET}"; }

# ── Erkennung + Auswahl ───────────────────────────────────────

detect_os() {
  case "$(uname -s)" in
    Linux*)                   echo "linux" ;;
    Darwin*)                  echo "mac" ;;
    MINGW*|MSYS*|CYGWIN*)     echo "windows" ;;
    *)                        echo "unknown" ;;
  esac
}

choose_os() {
  local detected="$1"
  echo
  echo "Erkanntes Betriebssystem: ${BOLD}${detected}${RESET}"
  echo
  echo "Plattform auswaehlen:"
  echo "  1) macOS"
  echo "  2) Linux"
  echo "  3) Windows (Git Bash / MSYS2 / WSL)"
  echo "  4) Auto (${detected})"
  echo
  read -r -p "Auswahl [4]: " choice
  choice="${choice:-4}"
  case "$choice" in
    1) echo "mac" ;;
    2) echo "linux" ;;
    3) echo "windows" ;;
    4) echo "$detected" ;;
    *) err "Ungueltige Auswahl"; exit 1 ;;
  esac
}

# ── Helfer ────────────────────────────────────────────────────

need_cmd() {
  command -v "$1" >/dev/null 2>&1
}

dl() {
  local url="$1" out="$2"
  if need_cmd curl; then
    curl -fL --progress-bar -o "$out" "$url"
  elif need_cmd wget; then
    wget -q --show-progress -O "$out" "$url"
  else
    err "Weder curl noch wget gefunden — bitte einen installieren."
    exit 1
  fi
}

extract_zip() {
  local archive="$1" target="$2"
  mkdir -p "$target"
  if need_cmd unzip; then
    unzip -q -o "$archive" -d "$target"
  elif need_cmd 7z; then
    7z x -y "-o$target" "$archive" >/dev/null
  else
    err "Weder unzip noch 7z gefunden — Entpacken nicht moeglich."
    exit 1
  fi
}

confirm() {
  local prompt="$1"
  read -r -p "$prompt (y/N): " yn
  [[ "$yn" =~ ^[Yy]$ ]]
}

# ── Java ──────────────────────────────────────────────────────

check_java() {
  step "Java pruefen"
  if need_cmd java; then
    ok "Java vorhanden: $(java -version 2>&1 | head -n1)"
    return
  fi
  warn "Java (JRE 11+) wurde nicht gefunden."
  case "$OS" in
    mac)
      if need_cmd brew; then
        echo "Vorschlag: ${BOLD}brew install --cask temurin@21${RESET}"
        confirm "Jetzt installieren?" && brew install --cask temurin@21
      else
        echo "Bitte manuell installieren: https://adoptium.net/"
      fi
      ;;
    linux)
      if need_cmd apt-get; then
        echo "Vorschlag: ${BOLD}sudo apt install -y openjdk-21-jre${RESET}"
        confirm "Jetzt installieren?" && sudo apt-get update && sudo apt-get install -y openjdk-21-jre
      elif need_cmd dnf; then
        echo "Vorschlag: ${BOLD}sudo dnf install -y java-21-openjdk${RESET}"
        confirm "Jetzt installieren?" && sudo dnf install -y java-21-openjdk
      elif need_cmd pacman; then
        echo "Vorschlag: ${BOLD}sudo pacman -S --noconfirm jre21-openjdk${RESET}"
        confirm "Jetzt installieren?" && sudo pacman -S --noconfirm jre21-openjdk
      else
        echo "Kein bekannter Paketmanager — bitte Java 21 manuell installieren."
      fi
      ;;
    windows)
      echo "Bitte installieren von: https://adoptium.net/"
      echo "Oder per ${BOLD}winget install EclipseAdoptium.Temurin.21.JRE${RESET}"
      echo "(in PowerShell, neues Terminal danach oeffnen)"
      ;;
    *)
      err "Unbekanntes OS — Java bitte manuell einrichten."
      ;;
  esac
  if need_cmd java; then
    ok "Java jetzt vorhanden."
  else
    warn "Java fehlt noch. Installer weiterlaufen lassen — pruefe spaeter nochmal."
  fi
}

# ── KoSIT ─────────────────────────────────────────────────────

install_kosit() {
  step "KoSIT Validator + XRechnung-Konfiguration"
  mkdir -p "$KOSIT_HOME"
  cd "$KOSIT_HOME"

  local jar="validationtool-${VALIDATOR_VERSION}-standalone.jar"
  if [ -f "$jar" ]; then
    ok "Validator $VALIDATOR_VERSION bereits da."
  else
    echo "Lade Validator …"
    dl "$VALIDATOR_URL" validator.zip
    extract_zip validator.zip .
    rm -f validator.zip
    ok "Validator $VALIDATOR_VERSION installiert."
  fi

  if [ -d "validator-configuration-xrechnung" ]; then
    ok "XRechnung-Konfiguration bereits da."
  else
    echo "Lade XRechnung-Konfiguration …"
    dl "$XRECHNUNG_CFG_URL" xrechnung-cfg.zip
    extract_zip xrechnung-cfg.zip validator-configuration-xrechnung
    rm -f xrechnung-cfg.zip
    ok "XRechnung-Konfiguration installiert."
  fi

  local scenario
  scenario="$(find "$KOSIT_HOME/validator-configuration-xrechnung" -name "scenarios.xml" | head -n1)"
  if [ -n "$scenario" ]; then
    ok "Scenarios-Datei gefunden: $scenario"
    FEGH_XRECHNUNG_SCENARIO="$scenario"
  else
    warn "scenarios.xml nicht gefunden — bitte Inhalt pruefen."
    FEGH_XRECHNUNG_SCENARIO=""
  fi
}

# ── dufs ──────────────────────────────────────────────────────

install_dufs() {
  step "dufs (WebDAV-Server)"
  if need_cmd dufs; then
    ok "dufs vorhanden: $(command -v dufs)"
    return
  fi

  case "$OS" in
    mac)
      if need_cmd brew; then
        brew install dufs && return
      fi
      ;;
    linux|windows)
      ;;
    *)
      err "Unbekanntes OS — dufs bitte manuell installieren."
      return
      ;;
  esac

  mkdir -p "$BIN_DIR"
  cd "$BIN_DIR"
  local arch suffix archive
  arch="$(uname -m)"
  case "$OS" in
    mac)
      case "$arch" in
        arm64)   suffix="aarch64-apple-darwin.tar.gz" ;;
        x86_64)  suffix="x86_64-apple-darwin.tar.gz" ;;
        *)       err "Unbekannte Mac-Architektur: $arch"; return ;;
      esac
      ;;
    linux)
      case "$arch" in
        x86_64|amd64) suffix="x86_64-unknown-linux-musl.tar.gz" ;;
        aarch64|arm64) suffix="aarch64-unknown-linux-musl.tar.gz" ;;
        armv7l)       suffix="armv7-unknown-linux-musleabihf.tar.gz" ;;
        *)            err "Unbekannte Linux-Architektur: $arch"; return ;;
      esac
      ;;
    windows)
      suffix="x86_64-pc-windows-msvc.zip"
      ;;
  esac

  archive="dufs.${suffix##*.}"
  [[ "$suffix" == *.tar.gz ]] && archive="dufs.tar.gz"

  echo "Lade dufs $DUFS_VERSION ($suffix) …"
  dl "https://github.com/sigoden/dufs/releases/download/${DUFS_VERSION}/dufs-${DUFS_VERSION}-${suffix}" "$archive"

  if [[ "$suffix" == *.zip ]]; then
    extract_zip "$archive" .
  else
    tar xf "$archive"
  fi
  rm -f "$archive"
  chmod +x "$BIN_DIR"/dufs* 2>/dev/null || true
  ok "dufs installiert nach $BIN_DIR"
}

# ── Env-Datei schreiben ──────────────────────────────────────

write_env() {
  step "Env-Datei schreiben"
  local jar="$KOSIT_HOME/validationtool-${VALIDATOR_VERSION}-standalone.jar"
  cat > "$ENV_FILE" <<EOF
# FEGH Test-Tools — $(date +%F)
# Aktivieren:  source $ENV_FILE

export FEGH_KOSIT_HOME="$KOSIT_HOME"
export FEGH_KOSIT_JAR="$jar"
export FEGH_XRECHNUNG_SCENARIO="${FEGH_XRECHNUNG_SCENARIO:-}"

export FEGH_WEBDAV_URL="http://localhost:5000"
export FEGH_WEBDAV_USER="fegh-test"
export FEGH_WEBDAV_PASS="fegh-test"
export FEGH_WEBDAV_DIR="\${TMPDIR:-/tmp}/fegh-webdav"

# dufs nach PATH (nur wenn nicht systemweit installiert)
case ":\$PATH:" in
  *:$BIN_DIR:*) ;;
  *) export PATH="$BIN_DIR:\$PATH" ;;
esac
EOF
  ok "Env-Datei geschrieben: $ENV_FILE"
}

# ── Abschluss ─────────────────────────────────────────────────

print_next_steps() {
  cat <<EOF

=========================================================
 Fertig. Naechste Schritte:
=========================================================

1) Env aktivieren (in jedem neuen Terminal):
     ${BOLD}source $ENV_FILE${RESET}

   Optional dauerhaft einbinden — haenge das an ~/.bashrc oder
   ~/.zshrc:
     source $ENV_FILE

2) WebDAV-Server starten (eigenes Terminal):
     mkdir -p "\$FEGH_WEBDAV_DIR"
     dufs "\$FEGH_WEBDAV_DIR" \\
       --auth "\$FEGH_WEBDAV_USER:\$FEGH_WEBDAV_PASS@/:rw" \\
       --port 5000

3) XRechnung-XML validieren:
     java -jar "\$FEGH_KOSIT_JAR" \\
       -r "\$FEGH_XRECHNUNG_SCENARIO" \\
       <pfad/zur/rechnung.xml>

4) Flutter-Tests ausfuehren (greifen die Env-Variablen auf):
     flutter test test/xrechnung_kosit_test.dart
     flutter test test/cross_app_interop_test.dart
     (Diese Tests bauen wir im naechsten Schritt.)

=========================================================
EOF
}

# ── Main ─────────────────────────────────────────────────────

main() {
  echo
  echo "===== FEGH Test-Tools Installer ====="
  echo "Installiert KoSIT Validator + XRechnung-Konfig + dufs (WebDAV)"
  echo "nach: ${BOLD}$INSTALL_ROOT${RESET}"

  local detected
  detected="$(detect_os)"
  OS="$(choose_os "$detected")"

  case "$OS" in
    mac|linux|windows) ok "Ziel: $OS" ;;
    *) err "Unbekanntes OS — Abbruch."; exit 1 ;;
  esac

  check_java
  install_kosit
  install_dufs
  write_env
  print_next_steps
}

main "$@"
