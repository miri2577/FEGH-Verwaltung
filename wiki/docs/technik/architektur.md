# Architektur

!!! info "Work in Progress"
    Diese Seite wird im Rahmen der Phase-B-Dokumentation ausgebaut.

Ueberblick ueber den Gesamt-Stack:

- Flutter 3.9.2 / Dart 3
- State-Management: Riverpod (Verwaltung), Provider (Doku)
- Persistenz: SharedPreferences + verschluesselte Cloud-Records (AES-256-GCM)
- Cloud-Adapter: HiDrive, Nextcloud, ownCloud, generisches WebDAV
- Shared-Packages: `fegh_crypto`, `fegh_cloud`, `fegh_billing`, `fegh_compliance`

Details siehe [Shared-Packages](shared-packages.md) und
[Zusammenspiel mit FEGH-Dokumentation](zusammenspiel.md).
