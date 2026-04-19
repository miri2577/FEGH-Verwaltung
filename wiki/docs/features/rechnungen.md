# Rechnungsmodul

Das Rechnungsmodul der FEGH-Verwaltung erstellt und versendet **XRechnungen nach EN 16931 / UBL 2.1 (KoSIT 3.0)**. Es richtet sich primaer an Traeger, die Leistungen nach dem SGB IX (Eingliederungshilfe) an Kostentraeger wie Jugendaemter, Sozialaemter oder die Teilhabebehoerde abrechnen.

## Warum XRechnung?

Seit dem **01.01.2025** ist die E-Rechnung fuer B2B-Umsaetze in Deutschland Pflicht. Oeffentliche Auftraggeber (Bund, Laender, Kommunen) verlangen sie bereits seit 2020. Unsere Zielgruppe — Kostentraeger in der EGH — fordert zunehmend XRechnung statt PDF.

## Aufbau

Das Modul nutzt das geteilte Paket `fegh_billing`, das zwischen Doku-App und Verwaltung aufgeteilt ist:

- **Modelle**: `Rechnung`, `RechnungsPosition`, `RechnungEmpfaenger`, `Kostentraeger`, `UstBefreiungsgrund`.
- **Service**: `XRechnungService` generiert den UBL 2.1 XML-Output mit korrektem Namespace, CustomizationID `urn:cen.eu:en16931:2017#compliant#urn:xoev-de:kosit:standard:xrechnung_3.0`.
- **VATEX-DE-Codes** fuer Steuerbefreiungsgruende, insbesondere die drei EGH-typischen:

| Paragraph | VATEX-DE | Anwendung |
|-----------|----------|-----------|
| §4 Nr. 16 h UStG | `VATEX-DE-016-h` | Leistungen der Eingliederungshilfe |
| §4 Nr. 18 UStG | `VATEX-DE-018` | Leistungen der anerkannten Wohlfahrtspflege |
| §4 Nr. 25 UStG | `VATEX-DE-025` | Jugendhilfeleistungen |

## Ablauf

1. **Empfaenger anlegen** (Kostentraeger) — einmalig pro Jugendamt / Sozialamt, inkl. Leitweg-ID.
2. **Rechnung erstellen** — Klient- oder Leistungs-bezogen, Positionen manuell oder aus Fachleistungsstunden generiert.
3. **UStG-Befreiungsgrund waehlen** — meist §4 Nr. 16h UStG.
4. **XRechnung generieren** — XML-File im UBL-Format, validierbar gegen KoSIT-Schema.
5. **PDF-Begleitdokument** — per `fegh_pdf_kit` erzeugt, identisches Design wie andere Reports.

## Uebermittlung

Die XRechnung selbst wird als XML-Datei erzeugt. Die Uebermittlung an den Kostentraeger erfolgt je nach Anforderung:

- E-Mail-Anhang (XML)
- Upload im Kostentraeger-Portal
- Peppol-BIS-Format (nicht im MVP — manueller Export)

Eine direkte Peppol-Anbindung ist nicht enthalten; die erzeugte XRechnung ist aber valide Peppol-BIS-Billing-3.0.

## Nummernkreis

Rechnungsnummern folgen dem Muster `YYYY-NNNN`, fortlaufend pro Jahr. `naechsteRechnungsnummer()` des Services ermittelt die naechste freie Nummer auf Basis der bereits gespeicherten Rechnungen.

## Siehe auch

- [Shared-Packages](../technik/shared-packages.md) — Aufbau des geteilten `fegh_billing`
- [Audit-Log](audit.md) — alle Rechnungs-Aktionen sind protokolliert
