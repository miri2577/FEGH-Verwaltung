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

## Funktionsweise im Detail

### Was SSO/OIDC eigentlich tut

Stell dir vor: Mitarbeiterin Alice hat einen Firmen-Account bei
Microsoft 365, Keycloak oder Google Workspace. Ohne SSO muss sie sich
in jede App einzeln einloggen — inkl. der FEGH-App mit eigenem
Passwort. Mit SSO loggt sie sich **einmal** bei ihrem Firmen-Account
ein, und die FEGH-App vertraut dem.

Der groesste Vorteil entsteht beim Ausscheiden: Wenn HR ihren
Firmen-Account deaktiviert, sperrt sich die FEGH-App
**automatisch aus** — niemand muss manuell in der FEGH-
Rollenverwaltung klicken.

### Der Login-Flow in 6 Schritten

Alice klickt auf "Einloggen mit SSO":

1. **Discovery.** Die App ruft den Identity-Provider an und fragt:
   "Wo sind deine Login-Endpunkte?" Antwort: JSON-Datei mit URLs
   (`/.well-known/openid-configuration`).
2. **Lokaler Server starten.** Die App oeffnet einen winzigen
   HTTP-Server auf `127.0.0.1:<dynamischer-Port>` auf Alices PC.
   Nur die Loopback-Schnittstelle — niemand im Netzwerk kann darauf
   zugreifen.
3. **Browser oeffnen.** Der *System-Browser* (Edge/Firefox/Chrome)
   oeffnet die IdP-Login-Seite — nicht ein Browser in der App.
   Begruendet in RFC 8252 §8.12: embedded Webviews geben dem
   umgebenden Prozess Zugriff auf IdP-Cookies und sind deshalb
   ausdruecklich verboten.
4. **Alice loggt sich ein** — mit ihrem gewohnten Passwort, MFA,
   Fingerprint, alles was der IdP vorschreibt. Die FEGH-App sieht
   davon **nichts**; sie wartet einfach auf den Callback.
5. **Redirect.** Nach erfolgreichem Login leitet der IdP den Browser
   zurueck auf
   `http://127.0.0.1:<port>/callback?code=...`. Unser lokaler Server
   nimmt den Code entgegen, zeigt Alice eine "Fenster kann geschlossen
   werden"-Seite und faehrt sich sofort wieder herunter.
6. **Token-Tausch.** Die App ruft den IdP direkt an (nicht ueber den
   Browser): "Hier der Code, gib mir die echten Tokens." Antwort:
   `access_token`, `id_token`, `refresh_token`.

### Was nach dem Login auf dem PC liegt

Im sicheren Geraetespeicher (`flutter_secure_storage` → Windows
DPAPI, macOS Keychain, iOS Keychain, Android Keystore):

| Token | Zweck | Gueltigkeit |
|-------|-------|-------------|
| `access_token` | "Alice ist angemeldet" | typisch 1 Stunde |
| `id_token` | JWT mit Alices Identitaet (`sub`, `email`, `name`) | identisch mit access |
| `refresh_token` | Neue access_tokens holen ohne neuen Browser-Login | Tage bis Monate |

### PKCE — warum der Flow trotz abgefangenem Code sicher bleibt

Bevor der Browser losgeht, wuerfelt die App einen Zufallsstring (den
**Verifier**) und schickt dessen SHA-256-Hash (die **Challenge**) an
den IdP mit. Beim Token-Tausch muss die App den Original-Verifier
vorzeigen.

Falls ein Angreifer — z. B. Malware, ein feindseliger Browser-Plugin
oder ein Proxy — den `code` aus der Redirect-URL abfaengt, kann er
ihn trotzdem **nicht gegen Tokens eintauschen**: ihm fehlt der
Verifier. Der Angreifer haette mueheloser Zugang, wenn statt PKCE
ein statisches "Client Secret" im Code stehen wuerde — genau
deshalb schreibt RFC 8252 PKCE fuer Desktop-Apps vor.

### User-Mapping auf die interne FEGH-`userId`

Aus dem ID-Token extrahiert die App — in dieser Reihenfolge — einen
Identifier:

1. `email` (bevorzugt — menschenlesbar, cross-App stabil)
2. `preferred_username` (Fallback, z. B. bei Entra-ID "alice@firma")
3. `sub` (letzte Option — kryptographische ID des IdP)

Dieser Wert landet im Audit-Log als `userId` und ist der Anknuepfungs-
punkt fuer die FEGH-Rollen-Matrix.

## Was der SSO-Screen heute konkret kann

Der `Admin-Console → Tools → SSO / OIDC einrichten` bietet:

- **Drei Felder** — Issuer-URL, Client-ID, Scopes
- **Speichern** — Konfiguration landet im Secure Storage
- **Discovery testen** — prueft ob die URL stimmt und TLS funktioniert,
  ohne einen echten Login zu starten
- **Test-Login** — spielt den kompletten Flow durch und zeigt danach
  den erkannten Benutzer, Email, Name, Token-Ablauf und Scopes an
- **Logout** — Tokens lokal verwerfen
- **Audit-Events** — jede Aktion laeuft ins `audit.log`
  (`sso.config.updated`, `sso.login.success`, `sso.login.failed`,
  `sso.logout`). Damit tauchen sie auch automatisch in jedem
  SIEM-Export auf.

## Aktueller Integrationsstand — was heute NICHT passiert

Bewusste Phasung, damit SSO nicht in einem Big-Bang eingefuehrt wird:

1. **Kein Login-Zwang.** Die App verlangt beim Start **keinen**
   OIDC-Login. Der bestehende HiDrive-Username-Login ist weiter
   aktiv. Der SSO-Screen ist heute ein **Einrichtungs- und
   Test-Werkzeug** — nicht der Haupt-Loginpfad.
2. **Keine Rollen-Zuordnung aus OIDC-Groups.** Die Rollen
   (Admin/Teamleitung/Teammitglied) kommen aus `roles.json` in der
   Cloud. Bindung an OIDC-Groups (`email → roles.json`) ist noch
   nicht aktiviert.
3. **Keine ID-Token-Signaturpruefung.** Die App vertraut dem Token,
   weil er ueber HTTPS vom TLS-verifizierten Token-Endpoint kam.
   Das ist fuer Desktop-Apps etabliert, aber keine kryptographische
   Haerterung gegen einen kompromittierten IdP. Optional nachrustbar
   via `jose`-Package + JWKS-Abruf.

Diese drei Punkte sind bewusst getrennt geplant, weil ein SSO-Zwang
ein invasiver Schritt ist — Test-Accounts, Rollback-Strategie und
Break-Glass-Zugang muessen vorher durchdacht sein.

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
