enum UIDensityPreset { compact, standard, comfortable }

enum TabDisplayMode { iconAndText, iconOnly, textOnly }

enum CardStyle { outlined, elevated, flat }

enum TableDensity { compact, standard, comfortable }

class UICustomization {
  final UIDensityPreset densityPreset;
  final double fontScale;
  final double lineHeightScale;
  final double spacingScale;
  final double tableRowHeight;
  final TabDisplayMode tabDisplayMode;
  final CardStyle cardStyle;
  final TableDensity tableDensity;

  const UICustomization({
    this.densityPreset = UIDensityPreset.standard,
    this.fontScale = 1.0,
    this.lineHeightScale = 1.2,
    this.spacingScale = 1.0,
    this.tableRowHeight = 48,
    this.tabDisplayMode = TabDisplayMode.iconAndText,
    this.cardStyle = CardStyle.outlined,
    this.tableDensity = TableDensity.standard,
  });

  const UICustomization.defaultSettings()
      : densityPreset = UIDensityPreset.standard,
        fontScale = 1.0,
        lineHeightScale = 1.2,
        spacingScale = 1.0,
        tableRowHeight = 48,
        tabDisplayMode = TabDisplayMode.iconAndText,
        cardStyle = CardStyle.outlined,
        tableDensity = TableDensity.standard;

  /// Derived scale factors from density preset
  double get borderRadiusScale {
    switch (densityPreset) {
      case UIDensityPreset.compact:
        return 0.7;
      case UIDensityPreset.standard:
        return 1.0;
      case UIDensityPreset.comfortable:
        return 1.2;
    }
  }

  double get iconScale {
    switch (densityPreset) {
      case UIDensityPreset.compact:
        return 0.85;
      case UIDensityPreset.standard:
        return 1.0;
      case UIDensityPreset.comfortable:
        return 1.15;
    }
  }

  /// Create UICustomization from a density preset, resetting sliders to preset defaults
  factory UICustomization.fromPreset(UIDensityPreset preset) {
    switch (preset) {
      case UIDensityPreset.compact:
        return const UICustomization(
          densityPreset: UIDensityPreset.compact,
          fontScale: 0.85,
          lineHeightScale: 1.1,
          spacingScale: 0.75,
          tableRowHeight: 36,
          tableDensity: TableDensity.compact,
        );
      case UIDensityPreset.standard:
        return const UICustomization();
      case UIDensityPreset.comfortable:
        return const UICustomization(
          densityPreset: UIDensityPreset.comfortable,
          fontScale: 1.15,
          lineHeightScale: 1.4,
          spacingScale: 1.25,
          tableRowHeight: 56,
          tableDensity: TableDensity.comfortable,
        );
    }
  }

  UICustomization copyWith({
    UIDensityPreset? densityPreset,
    double? fontScale,
    double? lineHeightScale,
    double? spacingScale,
    double? tableRowHeight,
    TabDisplayMode? tabDisplayMode,
    CardStyle? cardStyle,
    TableDensity? tableDensity,
  }) {
    return UICustomization(
      densityPreset: densityPreset ?? this.densityPreset,
      fontScale: fontScale ?? this.fontScale,
      lineHeightScale: lineHeightScale ?? this.lineHeightScale,
      spacingScale: spacingScale ?? this.spacingScale,
      tableRowHeight: tableRowHeight ?? this.tableRowHeight,
      tabDisplayMode: tabDisplayMode ?? this.tabDisplayMode,
      cardStyle: cardStyle ?? this.cardStyle,
      tableDensity: tableDensity ?? this.tableDensity,
    );
  }

  Map<String, dynamic> toJson() => {
        'densityPreset': densityPreset.index,
        'fontScale': fontScale,
        'lineHeightScale': lineHeightScale,
        'spacingScale': spacingScale,
        'tableRowHeight': tableRowHeight,
        'tabDisplayMode': tabDisplayMode.index,
        'cardStyle': cardStyle.index,
        'tableDensity': tableDensity.index,
      };

  factory UICustomization.fromJson(Map<String, dynamic> json) {
    return UICustomization(
      densityPreset: UIDensityPreset.values[json['densityPreset'] as int? ?? 1],
      fontScale: (json['fontScale'] as num?)?.toDouble() ?? 1.0,
      lineHeightScale: (json['lineHeightScale'] as num?)?.toDouble() ?? 1.2,
      spacingScale: (json['spacingScale'] as num?)?.toDouble() ?? 1.0,
      tableRowHeight: (json['tableRowHeight'] as num?)?.toDouble() ?? 48,
      tabDisplayMode:
          TabDisplayMode.values[json['tabDisplayMode'] as int? ?? 0],
      cardStyle: CardStyle.values[json['cardStyle'] as int? ?? 0],
      tableDensity: TableDensity.values[json['tableDensity'] as int? ?? 1],
    );
  }
}
