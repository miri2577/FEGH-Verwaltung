# Single Sign-On via OIDC

## Ueberblick

Die Verwaltungs-App unterstuetzt Single Sign-On per **OAuth 2.0
Authorization Code Flow mit PKCE** (RFC 6749 + RFC 7636) und
**Loopback-Redirect** fuer Desktop-Apps (RFC 8252). Kompatibel mit:

- **Microsoft Entra ID** (Azure AD)
- **Keycloak**
- **Google Workspace**
- Jedem Provider mit `/.well-known/openid-configuration`

!!! note "Berechtigung"
    Konfiguration: Admin. Nutzung: alle Mitarbeiter.

## Warum OIDC?

- Kein separates Passwort fuer die FEGH-App — Mitarbeiter nutzen ihren
  bestehenden Firmen-Account.
- MFA/2FA wird durch den Identity-Provider durchgesetzt — nicht durch
  uns.
- Ausscheidende Mitarbeiter werden durch Sperren im IdP **automatisch**
  ausgesperrt — kein manuelles Loeschen in 15 Apps.
- Audit-Spur: Login-Fehler/-Erfolge fliessen sowohl ins IdP-Log als
  auch ins FEGH-Audit-Log (Action `sso.login.success` / `.failed`).

## Einrichtung im Identity-Provider

### Keycloak (Beispiel)

1. **Client erstellen** im Realm:
   - Client Type: `OpenID Connect`
   - Client ID: z. B. `fegh-verwaltung`
   - Client Authentication: **OFF** (Public Client — PKCE ersetzt das Secret)
   - Standard Flow: **ON**
2. **Redirect URIs**: `http://127.0.0.1/*`
   (Port wird pro Login-Flow dynamisch zugewiesen; das Wildcard
   erlaubt alle Loopback-Ports.)
3. **Web Origins**: `http://127.0.0.1` (falls CORS noetig)
4. **Issuer-URL**: `https://auth.example.de/realms/<realm>`

### Microsoft Entra ID

1. **App-Registrierung** erstellen, Typ "Single-Page Application" oder
   "Desktop/Mobil"
2. **Redirect-URIs** (Type: "Public Client / Native"):
   `http://localhost` (Entra ID akzeptiert dynamische Ports auf localhost)
3. **API-Berechtigungen**: `openid`, `profile`, `email` (Microsoft Graph)
4. **Issuer-URL**:
   `https://login.microsoftonline.com/<TENANT-ID>/v2.0`

### Google

1. **OAuth Client** in Google Cloud Console (Typ: "Desktop-App")
2. Redirect-URI: wird automatisch auf Loopback gesetzt
3. **Issuer-URL**: `https://accounts.google.com`

## Einrichtung in der Verwaltungs-App

1. **Admin-Konsole** → **Tools** → **SSO / OIDC einrichten**
2. Felder ausfuellen:
   - **Issuer-URL** — z. B. `https://auth.example.de/realms/fegh`
   - **Client-ID** — aus dem IdP uebernommen
   - **Scopes** — `openid profile email` (Default)
3. **Discovery testen** klicken — laedt `/.well-known/openid-configuration`
   und zeigt den Authorization-Endpunkt. Wenn das klappt, sind
   URL und TLS korrekt.
4. **Test-Login** klicken — System-Browser oeffnet die IdP-Loginseite,
   nach Anmeldung redirected auf `http://127.0.0.1:PORT/callback`
   und der Flow schliesst sich.
5. **Speichern** — Konfiguration wird im `flutter_secure_storage`
   abgelegt.

## Was hinterher passiert

- Tokens (`access_token`, `id_token`, `refresh_token`) liegen im
  sicheren Geraetespeicher (Windows DPAPI, macOS Keychain, iOS
  Keychain, Android Keystore).
- Der **interne User** wird aus dem ID-Token abgeleitet:
  bevorzugt `email`, Fallback `preferred_username`, letzte Option
  `sub`. Der Wert landet in `AuditLogger.userId`.
- Refresh-Tokens werden automatisch genutzt, bevor der Access-Token
  abläuft (1-Minuten-Puffer).

## Audit-Events

Alle SSO-Aktionen werden ins Audit-Log geschrieben:

| Action | Bedeutung |
|--------|-----------|
| `sso.config.updated` | Admin hat die Provider-Konfiguration geaendert |
| `sso.login.success` | Erfolgreicher Login — inkl. userId und sub |
| `sso.login.failed`  | Fehlgeschlagener Login — inkl. Fehlergrund |
| `sso.logout` | Tokens lokal verworfen |

Diese Events koennen via **Admin → Audit → SIEM-Export** direkt in dein
Unternehmens-SIEM (Syslog, CEF, JSON Lines) eingespeist werden.

## Sicherheit / Threat Model

- **Embedded Webviews werden nicht genutzt** (RFC 8252 §8.12 verbietet
  das ausdruecklich): ein embedded Browser gibt dem umgebenden Prozess
  Zugriff auf IdP-Cookies/Tokens. Die App oeffnet den *System-Browser*.
- **PKCE verhindert Code-Injection** — selbst wenn ein Angreifer den
  Authorization-Code auf dem Redirect-Pfad abfaengt, fehlt ihm der
  `code_verifier`, um ihn gegen Tokens einzutauschen.
- **State-Parameter** schuetzt gegen CSRF auf dem Callback-Endpunkt.
- **Loopback-IP** (`127.0.0.1`, nicht `localhost`) vermeidet DNS-
  basierte Angriffe.
- **Dynamischer Port** macht es einem parallelen Prozess schwer, den
  Callback-Server zu entern.
- **ID-Token-Signatur wird derzeit NICHT validiert** (kein JWKS-Check).
  Akzeptabel, solange der Token-Endpoint ueber TLS 1.2+ spricht und
  die Discovery-URL ueber HTTPS lief. Fuer maximale Strenge kann ein
  nachgeschalteter `jose`-Package-Validator ergaenzt werden.

## Troubleshooting

| Fehler | Ursache | Loesung |
|--------|---------|---------|
| Discovery: HTTP 404 | Issuer-URL falsch | Vergleiche mit IdP-Doku; endet NICHT mit `/` |
| `IdP-Fehler: invalid_client` | Client-ID falsch oder Client ist Confidential | Public Client setzen, Client Authentication OFF |
| `IdP-Fehler: invalid_redirect_uri` | Redirect nicht whitelisted | `http://127.0.0.1/*` hinzufuegen |
| `IdP-Fehler: access_denied` | User-Consent verweigert | Zustimmung im Browser wiederholen |
| Login-Timeout | 5 Minuten kein Callback erhalten | Browser-Tab offen gelassen? → neu versuchen |
| `State-Mismatch` | Callback wurde vor dem erwarteten Flow abgerufen | Alte Browser-Tabs mit OIDC-Callbacks schliessen |

## Geplant (P2+)

- **SCIM** — Lifecycle-Sync aus HR/AD (braucht Backend-Endpoint)
- **ID-Token-Signaturpruefung** via JWKS
- **Group-/Role-Claims mapping** auf FEGH-Rollen (Admin/Teamleitung/…)
