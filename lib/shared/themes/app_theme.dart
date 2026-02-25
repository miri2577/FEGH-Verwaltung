import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../models/ui_customization.dart';

class AppTheme {
  // Corporate Colors - Eingliederungshilfe Color Scheme
  static const primaryColor = Color(0xFF4A6FA5);
  static const primaryVariant = Color(0xFF2E4B72);
  static const secondaryColor = Color(0xFF5C7A9B);
  static const accentColor = Color(0xFF7B9CC2);

  // Status Colors
  static const successColor = Color(0xFF4CAF50);
  static const warningColor = Color(0xFFFF9800);
  static const errorColor = Color(0xFFD32F2F);
  static const infoColor = Color(0xFF2196F3);

  // Neutral Colors
  static const surfaceColor = Color(0xFFFAFAFA);
  static const backgroundColor = Colors.white;
  static const cardColor = Colors.white;

  // Dark Theme Colors
  static const darkSurfaceColor = Color(0xFF121212);
  static const darkBackgroundColor = Color(0xFF1E1E1E);
  static const darkCardColor = Color(0xFF2D2D2D);

  static ThemeData get lightTheme => createLightTheme();
  static ThemeData get darkTheme => createDarkTheme();

  static ThemeData createLightTheme({UICustomization ui = const UICustomization()}) {
    final fs = ui.fontScale;
    final ss = ui.spacingScale;
    final brs = ui.borderRadiusScale;
    final ics = ui.iconScale;
    final lh = ui.lineHeightScale;

    // Card style
    CardThemeData cardTheme;
    switch (ui.cardStyle) {
      case CardStyle.outlined:
        cardTheme = CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * brs),
            side: BorderSide(
              color: Colors.grey.shade200,
              width: 1,
            ),
          ),
          color: cardColor,
          shadowColor: Colors.black.withOpacity(0.05),
          surfaceTintColor: Colors.transparent,
        );
        break;
      case CardStyle.elevated:
        cardTheme = CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * brs),
          ),
          color: cardColor,
          shadowColor: Colors.black.withOpacity(0.1),
          surfaceTintColor: Colors.transparent,
        );
        break;
      case CardStyle.flat:
        cardTheme = CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20 * brs),
          ),
          color: Colors.grey.shade50,
          shadowColor: Colors.transparent,
          surfaceTintColor: Colors.transparent,
        );
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: Color(0xFFD7E4F2),
        secondary: secondaryColor,
        secondaryContainer: Color(0xFFE1EAF3),
        tertiary: accentColor,
        surface: surfaceColor,
        background: backgroundColor,
        error: errorColor,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: Color(0xFF1C1B1F),
        onBackground: Color(0xFF1C1B1F),
        onError: Colors.white,
        outline: Color(0xFF79747E),
        surfaceTint: primaryColor,
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20 * fs,
          fontWeight: FontWeight.w500,
          height: lh,
        ),
        iconTheme: IconThemeData(
          color: Colors.white,
          size: 24 * ics,
        ),
      ),

      cardTheme: cardTheme,

      tabBarTheme: TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14 * fs,
          height: lh,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14 * fs,
          height: lh,
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFFF5F5F5)),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primaryColor.withOpacity(0.1);
          }
          return null;
        }),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14 * fs,
          color: const Color(0xFF37474F),
          height: lh,
        ),
        dataTextStyle: TextStyle(
          fontSize: 14 * fs,
          color: const Color(0xFF212121),
          height: lh,
        ),
        horizontalMargin: 24 * ss,
        columnSpacing: 56 * ss,
        dividerThickness: 1,
        dataRowMinHeight: ui.tableRowHeight,
        dataRowMaxHeight: ui.tableRowHeight + 16,
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: EdgeInsets.symmetric(horizontal: 32 * ss, vertical: 16 * ss),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * brs),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14 * fs,
            height: lh,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(horizontal: 32 * ss, vertical: 16 * ss),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * brs),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14 * fs,
            height: lh,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor, width: 1.5),
          padding: EdgeInsets.symmetric(horizontal: 32 * ss, vertical: 16 * ss),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16 * brs),
          ),
          textStyle: TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14 * fs,
            height: lh,
          ),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16 * brs),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 20 * ss, vertical: 16 * ss),
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 14 * fs,
          fontWeight: FontWeight.w500,
          height: lh,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14 * fs,
          height: lh,
        ),
        floatingLabelStyle: TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
          fontSize: 14 * fs,
          height: lh,
        ),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32 * fs, fontWeight: FontWeight.w400, letterSpacing: -0.25, color: const Color(0xFF1C1B1F), height: lh),
        displayMedium: TextStyle(fontSize: 28 * fs, fontWeight: FontWeight.w400, letterSpacing: 0, color: const Color(0xFF1C1B1F), height: lh),
        displaySmall: TextStyle(fontSize: 24 * fs, fontWeight: FontWeight.w400, letterSpacing: 0, color: const Color(0xFF1C1B1F), height: lh),
        headlineLarge: TextStyle(fontSize: 22 * fs, fontWeight: FontWeight.w600, letterSpacing: 0, color: const Color(0xFF1C1B1F), height: lh),
        headlineMedium: TextStyle(fontSize: 20 * fs, fontWeight: FontWeight.w600, letterSpacing: 0, color: const Color(0xFF1C1B1F), height: lh),
        headlineSmall: TextStyle(fontSize: 18 * fs, fontWeight: FontWeight.w600, letterSpacing: 0, color: const Color(0xFF1C1B1F), height: lh),
        titleLarge: TextStyle(fontSize: 16 * fs, fontWeight: FontWeight.w600, letterSpacing: 0.15, color: const Color(0xFF1C1B1F), height: lh),
        titleMedium: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: const Color(0xFF1C1B1F), height: lh),
        titleSmall: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: const Color(0xFF1C1B1F), height: lh),
        bodyLarge: TextStyle(fontSize: 16 * fs, fontWeight: FontWeight.w400, letterSpacing: 0.5, color: const Color(0xFF1C1B1F), height: lh),
        bodyMedium: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w400, letterSpacing: 0.25, color: const Color(0xFF1C1B1F), height: lh),
        bodySmall: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w400, letterSpacing: 0.4, color: const Color(0xFF49454F), height: lh),
        labelLarge: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w500, letterSpacing: 0.1, color: const Color(0xFF1C1B1F), height: lh),
        labelMedium: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: const Color(0xFF1C1B1F), height: lh),
        labelSmall: TextStyle(fontSize: 10 * fs, fontWeight: FontWeight.w500, letterSpacing: 0.5, color: const Color(0xFF1C1B1F), height: lh),
      ),

      iconTheme: IconThemeData(
        color: const Color(0xFF49454F),
        size: 24 * ics,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16 * ss, vertical: 4 * ss),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  static ThemeData createDarkTheme({UICustomization ui = const UICustomization()}) {
    final fs = ui.fontScale;
    final ss = ui.spacingScale;
    final brs = ui.borderRadiusScale;
    final ics = ui.iconScale;
    final lh = ui.lineHeightScale;

    // Card style
    CardThemeData cardTheme;
    switch (ui.cardStyle) {
      case CardStyle.outlined:
        cardTheme = CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * brs),
            side: BorderSide(
              color: Colors.grey.shade700,
              width: 1,
            ),
          ),
          color: darkCardColor,
          shadowColor: Colors.black54,
        );
        break;
      case CardStyle.elevated:
        cardTheme = CardThemeData(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * brs),
          ),
          color: darkCardColor,
          shadowColor: Colors.black54,
        );
        break;
      case CardStyle.flat:
        cardTheme = CardThemeData(
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12 * brs),
          ),
          color: const Color(0xFF252525),
          shadowColor: Colors.transparent,
        );
        break;
    }

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF90CAF9),
        primaryContainer: Color(0xFF0D47A1),
        secondary: Color(0xFF81D4FA),
        secondaryContainer: Color(0xFF01579B),
        tertiary: accentColor,
        surface: darkSurfaceColor,
        background: darkBackgroundColor,
        error: Color(0xFFCF6679),
        onPrimary: Color(0xFF000000),
        onSecondary: Color(0xFF000000),
        onSurface: Color(0xFFE6E1E5),
        onBackground: Color(0xFFE6E1E5),
        onError: Color(0xFF000000),
        outline: Color(0xFF938F99),
        surfaceTint: Color(0xFF90CAF9),
      ),

      appBarTheme: AppBarTheme(
        elevation: 0,
        backgroundColor: darkSurfaceColor,
        foregroundColor: const Color(0xFFE6E1E5),
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          fontSize: 20 * fs,
          fontWeight: FontWeight.w500,
          color: const Color(0xFFE6E1E5),
          height: lh,
        ),
        iconTheme: IconThemeData(
          color: const Color(0xFFE6E1E5),
          size: 24 * ics,
        ),
      ),

      cardTheme: cardTheme,

      tabBarTheme: TabBarThemeData(
        labelColor: const Color(0xFF90CAF9),
        unselectedLabelColor: Colors.grey,
        indicatorColor: const Color(0xFF90CAF9),
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14 * fs,
          height: lh,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14 * fs,
          height: lh,
        ),
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: WidgetStateProperty.all(const Color(0xFF37474F)),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const Color(0xFF90CAF9).withOpacity(0.1);
          }
          return null;
        }),
        headingTextStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14 * fs,
          color: const Color(0xFFE6E1E5),
          height: lh,
        ),
        dataTextStyle: TextStyle(
          fontSize: 14 * fs,
          color: const Color(0xFFE6E1E5),
          height: lh,
        ),
        dataRowMinHeight: ui.tableRowHeight,
        dataRowMaxHeight: ui.tableRowHeight + 16,
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8 * brs),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8 * brs),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8 * brs),
          borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        contentPadding: EdgeInsets.symmetric(horizontal: 16 * ss, vertical: 16 * ss),
      ),

      textTheme: TextTheme(
        displayLarge: TextStyle(fontSize: 32 * fs, fontWeight: FontWeight.w400, color: const Color(0xFFE6E1E5), height: lh),
        displayMedium: TextStyle(fontSize: 28 * fs, fontWeight: FontWeight.w400, color: const Color(0xFFE6E1E5), height: lh),
        displaySmall: TextStyle(fontSize: 24 * fs, fontWeight: FontWeight.w400, color: const Color(0xFFE6E1E5), height: lh),
        headlineLarge: TextStyle(fontSize: 22 * fs, fontWeight: FontWeight.w600, color: const Color(0xFFE6E1E5), height: lh),
        headlineMedium: TextStyle(fontSize: 20 * fs, fontWeight: FontWeight.w600, color: const Color(0xFFE6E1E5), height: lh),
        headlineSmall: TextStyle(fontSize: 18 * fs, fontWeight: FontWeight.w600, color: const Color(0xFFE6E1E5), height: lh),
        titleLarge: TextStyle(fontSize: 16 * fs, fontWeight: FontWeight.w600, color: const Color(0xFFE6E1E5), height: lh),
        titleMedium: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w500, color: const Color(0xFFE6E1E5), height: lh),
        titleSmall: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w500, color: const Color(0xFFE6E1E5), height: lh),
        bodyLarge: TextStyle(fontSize: 16 * fs, fontWeight: FontWeight.w400, color: const Color(0xFFE6E1E5), height: lh),
        bodyMedium: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w400, color: const Color(0xFFE6E1E5), height: lh),
        bodySmall: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w400, color: const Color(0xFFB0B0B0), height: lh),
        labelLarge: TextStyle(fontSize: 14 * fs, fontWeight: FontWeight.w500, color: const Color(0xFFE6E1E5), height: lh),
        labelMedium: TextStyle(fontSize: 12 * fs, fontWeight: FontWeight.w500, color: const Color(0xFFE6E1E5), height: lh),
        labelSmall: TextStyle(fontSize: 10 * fs, fontWeight: FontWeight.w500, color: const Color(0xFFE6E1E5), height: lh),
      ),

      iconTheme: IconThemeData(
        color: const Color(0xFFE6E1E5),
        size: 24 * ics,
      ),

      dividerTheme: const DividerThemeData(
        color: Color(0xFF333333),
        thickness: 1,
        space: 1,
      ),

      listTileTheme: ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16 * ss, vertical: 4 * ss),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  // Custom Status Colors
  static MaterialColor get successSwatch {
    return MaterialColor(successColor.value, {
      50: const Color(0xFFE8F5E8),
      100: const Color(0xFFC8E6C9),
      200: const Color(0xFFA5D6A7),
      300: const Color(0xFF81C784),
      400: const Color(0xFF66BB6A),
      500: successColor,
      600: const Color(0xFF43A047),
      700: const Color(0xFF388E3C),
      800: const Color(0xFF2E7D32),
      900: const Color(0xFF1B5E20),
    });
  }

  static MaterialColor get warningSwatch {
    return MaterialColor(warningColor.value, {
      50: const Color(0xFFFFF3E0),
      100: const Color(0xFFFFE0B2),
      200: const Color(0xFFFFCC80),
      300: const Color(0xFFFFB74D),
      400: const Color(0xFFFFA726),
      500: warningColor,
      600: const Color(0xFFFB8C00),
      700: const Color(0xFFF57C00),
      800: const Color(0xFFEF6C00),
      900: const Color(0xFFE65100),
    });
  }

  static MaterialColor get errorSwatch {
    return MaterialColor(errorColor.value, {
      50: const Color(0xFFFFEBEE),
      100: const Color(0xFFFFCDD2),
      200: const Color(0xFFEF9A9A),
      300: const Color(0xFFE57373),
      400: const Color(0xFFEF5350),
      500: errorColor,
      600: const Color(0xFFE53935),
      700: const Color(0xFFD32F2F),
      800: const Color(0xFFC62828),
      900: const Color(0xFFB71C1C),
    });
  }
}
