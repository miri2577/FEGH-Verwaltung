import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AppTheme {
  // Corporate Colors - Eingliederungshilfe Color Scheme
  static const primaryColor = Color(0xFF4A6FA5); // Gedämpftes Blau wie in der Eingliederungshilfe-App
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

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      // Color Scheme
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

      // AppBar Theme
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        systemOverlayStyle: SystemUiOverlayStyle.light,
        titleTextStyle: TextStyle(
          color: Colors.white,
          fontSize: 20,
          fontWeight: FontWeight.w500,
        ),
      ),

      // Card Theme - Moderne Cards mit abgerundeten Ecken
      cardTheme: CardThemeData(
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: Colors.grey.shade200,
            width: 1,
          ),
        ),
        color: cardColor,
        shadowColor: Colors.black.withOpacity(0.05),
        surfaceTintColor: Colors.transparent,
      ),

      // Tab Bar Theme
      tabBarTheme: const TabBarThemeData(
        labelColor: primaryColor,
        unselectedLabelColor: Colors.grey,
        indicatorColor: primaryColor,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
        ),
        unselectedLabelStyle: TextStyle(
          fontWeight: FontWeight.w400,
          fontSize: 14,
        ),
      ),

      // Data Table Theme
      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(Color(0xFFF5F5F5)),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return primaryColor.withOpacity(0.1);
          }
          return null;
        }),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFF37474F),
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFF212121),
        ),
        horizontalMargin: 24,
        columnSpacing: 56,
        dividerThickness: 1,
      ),

      // Button Themes - Moderne abgerundete Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          elevation: 0,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: BorderSide(color: primaryColor, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),

      // Input Decoration Theme - Moderne Input Fields
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey.shade300, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: errorColor, width: 2),
        ),
        filled: true,
        fillColor: Colors.grey.shade50,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        labelStyle: TextStyle(
          color: Colors.grey[700],
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
        hintStyle: TextStyle(
          color: Colors.grey[500],
          fontSize: 14,
        ),
        floatingLabelStyle: const TextStyle(
          color: primaryColor,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Typography
      textTheme: const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w400,
          letterSpacing: -0.25,
          color: Color(0xFF1C1B1F),
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: Color(0xFF1C1B1F),
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w400,
          letterSpacing: 0,
          color: Color(0xFF1C1B1F),
        ),
        headlineLarge: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFF1C1B1F),
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFF1C1B1F),
        ),
        headlineSmall: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          letterSpacing: 0,
          color: Color(0xFF1C1B1F),
        ),
        titleLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: Color(0xFF1C1B1F),
        ),
        titleMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFF1C1B1F),
        ),
        titleSmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFF1C1B1F),
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.5,
          color: Color(0xFF1C1B1F),
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.25,
          color: Color(0xFF1C1B1F),
        ),
        bodySmall: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          letterSpacing: 0.4,
          color: Color(0xFF49454F),
        ),
        labelLarge: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.1,
          color: Color(0xFF1C1B1F),
        ),
        labelMedium: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFF1C1B1F),
        ),
        labelSmall: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.5,
          color: Color(0xFF1C1B1F),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: Color(0xFF49454F),
        size: 24,
      ),

      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE0E0E0),
        thickness: 1,
        space: 1,
      ),

      // List Tile Theme
      listTileTheme: const ListTileThemeData(
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        dense: true,
        visualDensity: VisualDensity.compact,
      ),
    );
  }

  static ThemeData get darkTheme {
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

      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: darkSurfaceColor,
        foregroundColor: Color(0xFFE6E1E5),
        systemOverlayStyle: SystemUiOverlayStyle.light,
      ),

      cardTheme: const CardThemeData(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
        color: darkCardColor,
        shadowColor: Colors.black54,
      ),

      dataTableTheme: DataTableThemeData(
        headingRowColor: MaterialStateProperty.all(Color(0xFF37474F)),
        dataRowColor: MaterialStateProperty.resolveWith((states) {
          if (states.contains(MaterialState.selected)) {
            return Color(0xFF90CAF9).withOpacity(0.1);
          }
          return null;
        }),
        headingTextStyle: const TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 14,
          color: Color(0xFFE6E1E5),
        ),
        dataTextStyle: const TextStyle(
          fontSize: 14,
          color: Color(0xFFE6E1E5),
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF49454F)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: Color(0xFF90CAF9), width: 2),
        ),
        filled: true,
        fillColor: const Color(0xFF2D2D2D),
        contentPadding: const EdgeInsets.all(16),
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