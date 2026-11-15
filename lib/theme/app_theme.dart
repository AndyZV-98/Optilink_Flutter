import 'package:flutter/material.dart';

/// Paleta de la app.
abstract final class AppColors {
  /// Azul de la marca.
  static const Color primary = Color(0xFF1D4ED8);
  static const Color primaryDark = Color(0xFF1E3A8A);

  /// Tinte claro del azul, para fondos de selección y de imágenes vacías.
  static const Color primarySoft = Color(0xFFEAF1FF);

  /// Turquesa de acento; se usa junto al azul en el logo y en degradados.
  static const Color accent = Color(0xFF0EA5A4);

  /// Texto principal.
  static const Color ink = Color(0xFF0F172A);

  /// Texto secundario.
  static const Color muted = Color(0xFF64748B);

  /// Bordes y separadores.
  static const Color line = Color(0xFFE2E8F0);

  /// Fondo de las pantallas.
  static const Color background = Color(0xFFF5F7FB);

  /// Fondo de tarjetas, barras y campos.
  static const Color surface = Color(0xFFFFFFFF);

  static const Color success = Color(0xFF15803D);
  static const Color successSoft = Color(0xFFDCFCE7);
  static const Color warning = Color(0xFFB45309);
  static const Color warningSoft = Color(0xFFFEF3C7);
  static const Color danger = Color(0xFFB91C1C);
  static const Color dangerSoft = Color(0xFFFEE2E2);
  static const Color violet = Color(0xFF6D28D9);
  static const Color violetSoft = Color(0xFFEDE9FE);
  static const Color neutralSoft = Color(0xFFF1F5F9);
}

/// Radios de las esquinas.
abstract final class AppRadius {
  static const double card = 16;
  static const double control = 12;
  static const double pill = 999;
}

/// Tema visual de OptiLink: fondo claro, tarjetas blancas con borde fino en
/// lugar de sombras, y el azul de la marca para las acciones.
ThemeData buildAppTheme() {
  final scheme =
      ColorScheme.fromSeed(
        seedColor: AppColors.primary,
        brightness: Brightness.light,
      ).copyWith(
        primary: AppColors.primary,
        onPrimary: Colors.white,
        primaryContainer: AppColors.primarySoft,
        onPrimaryContainer: AppColors.primaryDark,
        secondary: AppColors.accent,
        surface: AppColors.surface,
        onSurface: AppColors.ink,
        onSurfaceVariant: AppColors.muted,
        outline: AppColors.line,
        outlineVariant: AppColors.line,
        error: AppColors.danger,
        surfaceTint: Colors.transparent,
      );

  final base = ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    fontFamily: 'Inter',
    scaffoldBackgroundColor: AppColors.background,
  );

  final textTheme = base.textTheme
      .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
      .copyWith(
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.6,
          color: AppColors.ink,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.4,
          color: AppColors.ink,
        ),
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: -0.3,
          color: AppColors.ink,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: AppColors.ink,
        ),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(
          height: 1.4,
          color: AppColors.ink,
        ),
      );

  final controlShape = RoundedRectangleBorder(
    borderRadius: BorderRadius.circular(AppRadius.control),
  );
  const buttonText = TextStyle(
    fontFamily: 'Inter',
    fontSize: 15,
    fontWeight: FontWeight.w600,
  );

  OutlineInputBorder inputBorder(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppRadius.control),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  return base.copyWith(
    textTheme: textTheme,
    appBarTheme: const AppBarTheme(
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 19,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: AppColors.ink,
      ),
      shape: Border(bottom: BorderSide(color: AppColors.line)),
    ),
    cardTheme: CardThemeData(
      color: AppColors.surface,
      elevation: 0,
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.card),
        side: const BorderSide(color: AppColors.line),
      ),
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.line,
      thickness: 1,
      space: 1,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: controlShape,
        textStyle: buttonText,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 50),
        padding: const EdgeInsets.symmetric(horizontal: 20),
        shape: controlShape,
        side: const BorderSide(color: AppColors.line),
        foregroundColor: AppColors.ink,
        backgroundColor: AppColors.surface,
        textStyle: buttonText,
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: AppColors.primary,
        textStyle: buttonText.copyWith(fontSize: 14),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      labelStyle: const TextStyle(color: AppColors.muted),
      hintStyle: const TextStyle(color: AppColors.muted),
      helperStyle: const TextStyle(color: AppColors.muted),
      prefixIconColor: AppColors.muted,
      suffixIconColor: AppColors.muted,
      border: inputBorder(AppColors.line),
      enabledBorder: inputBorder(AppColors.line),
      focusedBorder: inputBorder(AppColors.primary, 1.6),
      errorBorder: inputBorder(AppColors.danger),
      focusedErrorBorder: inputBorder(AppColors.danger, 1.6),
    ),
    chipTheme: const ChipThemeData(
      backgroundColor: AppColors.surface,
      selectedColor: AppColors.primary,
      showCheckmark: false,
      side: BorderSide(color: AppColors.line),
      shape: StadiumBorder(),
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      labelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: AppColors.ink,
      ),
      secondaryLabelStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      ),
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySoft,
      elevation: 0,
      height: 68,
      labelTextStyle: WidgetStateProperty.resolveWith(
        (states) => TextStyle(
          fontFamily: 'Inter',
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
      iconTheme: WidgetStateProperty.resolveWith(
        (states) => IconThemeData(
          color: states.contains(WidgetState.selected)
              ? AppColors.primary
              : AppColors.muted,
        ),
      ),
    ),
    navigationRailTheme: const NavigationRailThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primarySoft,
      selectedIconTheme: IconThemeData(color: AppColors.primary),
      unselectedIconTheme: IconThemeData(color: AppColors.muted),
      selectedLabelTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.primary,
      ),
      unselectedLabelTextStyle: TextStyle(
        fontFamily: 'Inter',
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: AppColors.muted,
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.ink,
      contentTextStyle: const TextStyle(
        fontFamily: 'Inter',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: Colors.white,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.control),
      ),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
    ),
    listTileTheme: const ListTileThemeData(iconColor: AppColors.muted),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
    drawerTheme: const DrawerThemeData(backgroundColor: AppColors.surface),
  );
}
