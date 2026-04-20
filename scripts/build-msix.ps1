# FEGH-Verwaltung MSIX-Build
# --------------------------
# Baut die Windows-Release-Version und packt sie als MSIX fuer
# Enterprise-Deployment (Intune, MDM, Sideload).
#
# Nutzung (PowerShell):
#   powershell -ExecutionPolicy Bypass -File scripts\build-msix.ps1

$ErrorActionPreference = 'Stop'

Write-Host "===== FEGH-Verwaltung MSIX-Build =====" -ForegroundColor Cyan

# 1. Abhaengigkeiten aktualisieren
Write-Host "`n1/4 Dependencies aktualisieren..." -ForegroundColor Yellow
flutter pub get
if ($LASTEXITCODE -ne 0) { throw "pub get fehlgeschlagen" }

# 2. Windows Release-Build
Write-Host "`n2/4 Windows Release-Build..." -ForegroundColor Yellow
flutter build windows --release
if ($LASTEXITCODE -ne 0) { throw "flutter build fehlgeschlagen" }

# 3. MSIX-Paket erzeugen
Write-Host "`n3/4 MSIX-Paket erzeugen..." -ForegroundColor Yellow
flutter pub run msix:create
if ($LASTEXITCODE -ne 0) { throw "msix:create fehlgeschlagen" }

# 4. Erfolgsmeldung + Pfad zum MSIX
$msix = Get-ChildItem -Path "build\windows\x64\runner\Release" -Filter "*.msix" -ErrorAction SilentlyContinue | Select-Object -First 1
if (-not $msix) {
    $msix = Get-ChildItem -Path "build\windows\runner\Release" -Filter "*.msix" -ErrorAction SilentlyContinue | Select-Object -First 1
}

if ($msix) {
    Write-Host "`n===== Fertig =====" -ForegroundColor Green
    Write-Host "MSIX-Paket: $($msix.FullName)"
    Write-Host "Groesse:    $([math]::Round($msix.Length / 1MB, 1)) MB"
    Write-Host ""
    Write-Host "Naechste Schritte:"
    Write-Host "  - Lokal testen: Doppelklick auf MSIX -> 'App installieren'"
    Write-Host "  - Intune:       MSIX in Intune-Portal hochladen (Win32-App)"
    Write-Host "  - Gruppenrichtlinie: ADMX-Template aus scripts\intune\ nutzen"
} else {
    Write-Warning "MSIX-Paket nicht gefunden — Build-Output pruefen"
}
