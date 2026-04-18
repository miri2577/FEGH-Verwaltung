# Cloud-Storage

!!! info "Work in Progress"
    Diese Seite wird im Rahmen der Phase-B-Dokumentation ausgebaut.

Die Verwaltung unterstuetzt vier Cloud-Provider ueber den Shared-Adapter `fegh_cloud`:

- **HiDrive** (STRATO) &mdash; WebDAV mit Content-Type-Eigenheiten bei MKCOL
- **Nextcloud** &mdash; Standard-WebDAV
- **ownCloud** &mdash; Standard-WebDAV
- **Generisches WebDAV** &mdash; beliebige RFC-4918-konforme Server

Alle Daten werden client-seitig mit AES-256-GCM verschluesselt
(DEK-Wrapping, PBKDF2-MEK aus Sync-Passphrase).
