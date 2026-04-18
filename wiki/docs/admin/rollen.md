# Rollen und Berechtigungen

!!! info "Work in Progress"
    Diese Seite wird im Rahmen der Phase-B-Dokumentation ausgebaut.

Die FEGH-Apps nutzen fuenf Rollen (RBAC), die in `roles.json` auf der Cloud gepflegt werden:

| Rolle | Bedeutung |
|-------|-----------|
| `orgAdmin` | Volladministration, kann Organisation und Admins verwalten |
| `pvAdmin` | Personalverwaltungs-Admin, keine Organisationsaenderungen |
| `teamLead` | Team-Leitung, sieht eigenes Team und dessen Klienten |
| `teamMember` | Mitarbeiter, sieht nur eigene Klienten |
| `orgAuditor` | Read-only, fuer Revision und Controlling |
