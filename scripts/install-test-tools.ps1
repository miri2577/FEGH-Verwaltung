# FEGH Test-Tools Installer (Windows PowerShell)
# -----------------------------------------------
# Installiert KoSIT Validator + XRechnung-Konfiguration + dufs (WebDAV)
# fuer XRechnung-Validierung und Cross-App-Interop-Tests.
#
# Nutzung (PowerShell):
#   powershell -ExecutionPolicy Bypass -File scripts\install-test-tools.ps1

$ErrorActionPreference = 'Stop'

# --- Konstanten --------------------------------------------------
$ValidatorVersion = '1.5.0'
$ValidatorUrl     = "https://github.com/itplr-kosit/validator/releases/download/v$ValidatorVersion/validator-$ValidatorVersion-distribution.zip"
$XRechnungCfgUrl  = 'https://github.com/itplr-kosit/validator-configuration-xrechnung/releases/download/release-2024-06-20/validator-configuration-xrechnung_3.0.2_2024-06-20.zip'
$DufsVersion      = 'v0.43.0'
$DufsUrl          = "https://github.com/sigoden/dufs/releases/download/$DufsVersion/dufs-$DufsVersion-x86_64-pc-windows-msvc.zip"

$InstallRoot = Join-Path $HOME '.fegh-tools'
$KositHome   = Join-Path $InstallRoot 'kosit'
$BinDir      = Join-Path $InstallRoot 'bin'
$SampleDir   = Join-Path $InstallRoot 'samples'
$EnvFile     = Join-Path $HOME '.fegh-tools.env.ps1'

$SampleUrl   = 'https://raw.githubusercontent.com/itplr-kosit/xrechnung-testsuite/master/src/test/business-cases/standard/01.01a-INVOICE_ubl.xml'

# --- Helpers ----------------------------------------------------
function Write-Step { param($msg) Write-Host ""; Write-Host "==> $msg" -ForegroundColor Cyan }
function Write-OK   { param($msg) Write-Host "OK " -ForegroundColor Green -NoNewline; Write-Host $msg }
function Write-Warn2{ param($msg) Write-Host "!! " -ForegroundColor Yellow -NoNewline; Write-Host $msg }
function Write-Err2 { param($msg) Write-Host "KO " -ForegroundColor Red -NoNewline; Write-Host $msg }

function Test-Command { param($name) return [bool](Get-Command $name -ErrorAction SilentlyContinue) }

function Confirm-Yes {
    param($prompt)
    $ans = Read-Host "$prompt (y/N)"
    return $ans -match '^[Yy]$'
}

function Download-File {
    param($url, $out)
    Write-Host "    Download: $url"
    Invoke-WebRequest -Uri $url -OutFile $out -UseBasicParsing
}

# --- Start ------------------------------------------------------
Write-Host ""
Write-Host "===== FEGH Test-Tools Installer =====" -ForegroundColor White
Write-Host "Installiert KoSIT Validator + XRechnung-Konfig + dufs (WebDAV)"
Write-Host "nach: $InstallRoot"
Write-Host ""
Write-Host "Plattform: Windows (PowerShell)"
Write-Host ""
Write-Host "Tipp: Auf macOS/Linux benutze die Bash-Variante:"
Write-Host "      bash scripts/install-test-tools.sh"
Write-Host ""

# --- Java pruefen ----------------------------------------------
Write-Step "Java pruefen"
if (Test-Command java) {
    # Java schreibt -version nach stderr. PowerShell 5.1 produziert
    # einen NativeCommandError bei 2>&1 und bricht mit ErrorAction=Stop
    # ab; deshalb via cmd.exe umleiten.
    $ver = (cmd /c 'java -version 2>&1') | Select-Object -First 1
    Write-OK "Java vorhanden: $ver"
} else {
    Write-Warn2 "Java (JRE 11+) wurde nicht gefunden."
    if (Test-Command winget) {
        Write-Host "Vorschlag: winget install EclipseAdoptium.Temurin.21.JRE"
        if (Confirm-Yes "Jetzt installieren?") {
            winget install --id EclipseAdoptium.Temurin.21.JRE -e --silent
            Write-Warn2 "Starte PowerShell neu, damit PATH aktualisiert ist."
        }
    } elseif (Test-Command choco) {
        Write-Host "Vorschlag: choco install temurin21 -y"
        if (Confirm-Yes "Jetzt installieren?") {
            choco install temurin21 -y
        }
    } else {
        Write-Host "Bitte manuell installieren: https://adoptium.net/"
    }
}

# --- Verzeichnisse anlegen -------------------------------------
New-Item -ItemType Directory -Path $InstallRoot -Force | Out-Null
New-Item -ItemType Directory -Path $KositHome   -Force | Out-Null
New-Item -ItemType Directory -Path $BinDir      -Force | Out-Null
New-Item -ItemType Directory -Path $SampleDir   -Force | Out-Null

# --- KoSIT Validator -------------------------------------------
Write-Step "KoSIT Validator + XRechnung-Konfiguration"
$validatorJar = Join-Path $KositHome "validationtool-$ValidatorVersion-standalone.jar"
if (Test-Path $validatorJar) {
    Write-OK "Validator $ValidatorVersion bereits da."
} else {
    $tmpZip = Join-Path $KositHome 'validator.zip'
    Download-File $ValidatorUrl $tmpZip
    Expand-Archive -Path $tmpZip -DestinationPath $KositHome -Force
    Remove-Item $tmpZip
    Write-OK "Validator $ValidatorVersion installiert."
}

$xrCfgDir = Join-Path $KositHome 'validator-configuration-xrechnung'
if (Test-Path $xrCfgDir) {
    Write-OK "XRechnung-Konfiguration bereits da."
} else {
    $tmpZip = Join-Path $KositHome 'xrechnung.zip'
    Download-File $XRechnungCfgUrl $tmpZip
    Expand-Archive -Path $tmpZip -DestinationPath $xrCfgDir -Force
    Remove-Item $tmpZip
    Write-OK "XRechnung-Konfiguration installiert."
}

$scenarioFile = Get-ChildItem -Path $xrCfgDir -Recurse -Filter 'scenarios.xml' -ErrorAction SilentlyContinue | Select-Object -First 1
if ($scenarioFile) {
    Write-OK "Scenarios-Datei gefunden: $($scenarioFile.FullName)"
    $scenarioPath = $scenarioFile.FullName
    $scenarioRepo = Split-Path $scenarioPath
} else {
    Write-Warn2 "scenarios.xml nicht gefunden - bitte Inhalt pruefen."
    $scenarioPath = ''
    $scenarioRepo = ''
}

# --- dufs ------------------------------------------------------
Write-Step "dufs (WebDAV-Server)"
$dufsExe = Join-Path $BinDir 'dufs.exe'
if (Test-Command dufs) {
    Write-OK "dufs vorhanden: $((Get-Command dufs).Source)"
} elseif (Test-Path $dufsExe) {
    Write-OK "dufs vorhanden: $dufsExe"
} else {
    $tmpZip = Join-Path $BinDir 'dufs.zip'
    Download-File $DufsUrl $tmpZip
    Expand-Archive -Path $tmpZip -DestinationPath $BinDir -Force
    Remove-Item $tmpZip
    if (Test-Path $dufsExe) {
        Write-OK "dufs installiert nach $BinDir"
    } else {
        Write-Err2 "dufs-Binary nicht gefunden nach Entpacken."
    }
}

# --- Sample-Rechnung ------------------------------------------
Write-Step "XRechnung-Sample herunterladen"
$sampleFile = Join-Path $SampleDir 'xrechnung-sample.xml'
if (Test-Path $sampleFile) {
    Write-OK "Sample bereits da: $sampleFile"
} else {
    try {
        Download-File $SampleUrl $sampleFile
        Write-OK "Sample geladen: $sampleFile"
    } catch {
        Write-Warn2 "Sample-Download fehlgeschlagen (kein Netz?). Validierung kann spaeter manuell getestet werden."
    }
}

# --- Env-Datei schreiben ---------------------------------------
Write-Step "Env-Datei schreiben"

$envLines = @()
$envLines += '# FEGH Test-Tools'
$envLines += '# Aktivieren (PowerShell):  . ' + $EnvFile
$envLines += ''
$envLines += "`$env:FEGH_KOSIT_HOME         = '$KositHome'"
$envLines += "`$env:FEGH_KOSIT_JAR          = '$validatorJar'"
$envLines += "`$env:FEGH_XRECHNUNG_SCENARIO = '$scenarioPath'"
$envLines += "`$env:FEGH_XRECHNUNG_REPO     = '$scenarioRepo'"
$envLines += ''
$envLines += "`$env:FEGH_WEBDAV_URL  = 'http://localhost:5000'"
$envLines += "`$env:FEGH_WEBDAV_USER = 'fegh-test'"
$envLines += "`$env:FEGH_WEBDAV_PASS = 'fegh-test'"
$envLines += "`$env:FEGH_WEBDAV_DIR  = Join-Path `$env:TEMP 'fegh-webdav'"
$envLines += ''
$envLines += "`$env:FEGH_XRECHNUNG_SAMPLE = '$sampleFile'"
$envLines += ''
$envLines += "if (-not (`$env:Path -split ';' | Where-Object { `$_ -eq '$BinDir' })) {"
$envLines += "    `$env:Path = '$BinDir;' + `$env:Path"
$envLines += '}'

Set-Content -Path $EnvFile -Value $envLines -Encoding UTF8
Write-OK "Env-Datei geschrieben: $EnvFile"

# --- Abschluss -------------------------------------------------
Write-Host ""
Write-Host "========================================================="
Write-Host " Fertig. Naechste Schritte:"
Write-Host "========================================================="
Write-Host ""
Write-Host "1) Env aktivieren in jedem neuen Terminal:"
Write-Host "     . $EnvFile" -ForegroundColor White
Write-Host ""
Write-Host "   Dauerhaft in dein PowerShell-Profil einbinden:"
Write-Host "     New-Item -Path `$PROFILE -ItemType File -Force | Out-Null"
Write-Host "     Add-Content `$PROFILE `". $EnvFile`""
Write-Host ""
Write-Host "2) WebDAV-Server starten in eigenem Terminal:"
Write-Host '     New-Item -ItemType Directory -Force -Path $env:FEGH_WEBDAV_DIR | Out-Null'
Write-Host '     dufs $env:FEGH_WEBDAV_DIR --auth "${env:FEGH_WEBDAV_USER}:${env:FEGH_WEBDAV_PASS}@/:rw" --port 5000'
Write-Host ""
Write-Host "3) Smoke-Test XRechnung-Validator (mitgeliefertes Sample):"
Write-Host '     java -jar $env:FEGH_KOSIT_JAR -r $env:FEGH_XRECHNUNG_REPO -s $env:FEGH_XRECHNUNG_SCENARIO $env:FEGH_XRECHNUNG_SAMPLE'
Write-Host "   Erwartet: <accepted>true</accepted> im Report."
Write-Host ""
Write-Host "4) Flutter-Tests ausfuehren:"
Write-Host "     flutter test test/xrechnung_kosit_test.dart"
Write-Host "     flutter test test/cross_app_interop_test.dart"
Write-Host "     Diese Tests bauen wir im naechsten Schritt."
Write-Host ""
Write-Host "========================================================="
