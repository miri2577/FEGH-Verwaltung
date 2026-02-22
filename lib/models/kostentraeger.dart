// Berliner Kostenträger für Eingliederungshilfe und Familienhilfe
class Kostentraeger {
  static const List<String> alle = [
    ...jugendaemter,
    ...sozialaemter,
    ...krankenkassen,
    ...sonstige,
  ];

  static const List<String> jugendaemter = [
    'JA Charl.-Wilm.',
    'JA Friedr.-Kreuz.',
    'JA Lichtenberg',
    'JA Marzahn-Hellers.',
    'JA Mitte',
    'JA Neukölln',
    'JA Pankow',
    'JA Reinickendorf',
    'JA Spandau',
    'JA Steglitz-Zehlen.',
    'JA Tempel.-Schön.',
    'JA Treptow-Köpen.',
  ];

  static const List<String> sozialaemter = [
    'SA Charl.-Wilm.',
    'SA Friedr.-Kreuz.',
    'SA Lichtenberg',
    'SA Marzahn-Hellers.',
    'SA Mitte',
    'SA Neukölln',
    'SA Pankow',
    'SA Reinickendorf',
    'SA Spandau',
    'SA Steglitz-Zehlen.',
    'SA Tempel.-Schön.',
    'SA Treptow-Köpen.',
    'LAGeSo - Eingl.hilfe',
  ];

  static const List<String> krankenkassen = [
    'AOK Nordost',
    'Barmer',
    'Techniker Krankenkasse',
    'DAK-Gesundheit',
    'IKK Brandenburg Berlin',
    'BKK VBU',
    'HEK',
    'Knappschaft',
    'Private KV',
  ];

  static const List<String> sonstige = [
    'AA Berlin Mitte',
    'AA Berlin Nord',
    'AA Berlin Süd',
    'Jobcenter Berlin',
    'DRV Bund',
    'DRV Berlin-Brand.',
    'Berufsgenossensch.',
    'Eigenfinanzierung',
    'Sonstige',
  ];

  // Zuordnung zu Hilfe-Typen
  static List<String> getFuerHilfeTyp(String? hilfeTyp) {
    switch (hilfeTyp) {
      case 'familienhilfe':
        return [...jugendaemter, ...sonstige];
      case 'eingliederungshilfe':
        return [...sozialaemter, ...krankenkassen, ...sonstige];
      default:
        return alle;
    }
  }
}
