import 'package:flutter/material.dart';

/// Tema Material 3 — verde tinta + ámbar, tipografía Manrope local.
///
/// Tokens de diseño con lenguaje "ride moderno": tarjetas de alto contraste,
/// radios generosos, sombras suaves y botones de acción grandes y limpios.
abstract final class AppTheme {
  static const Color seed = Color(0xFF0B3D2E);
  static const Color accent = Color(0xFFF5A623);
  static const Color lightSurface = Color(0xFFF5F6F4);
  static const Color darkSurface = Color(0xFF101412);
  static const String fontFamily = 'Manrope';

  /// Radios de los elementos principales.
  static const double radiusCard = 20;
  static const double radiusButton = 16;
  static const double radiusInput = 14;
  static const double radiusSheet = 24;

  /// Altura mínima de botones de acción primarios.
  static const double buttonHeight = 56;
  static const double buttonHeightLarge = 60;

  static ThemeData get light => _buildTheme(Brightness.light);

  static ThemeData get dark => _buildTheme(Brightness.dark);

  static ThemeData _buildTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    final baseScheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: brightness,
    );

    final colorScheme = baseScheme.copyWith(
      secondary: accent,
      onSecondary: Colors.black,
      secondaryContainer: accent.withValues(alpha: isDark ? 0.24 : 0.18),
      onSecondaryContainer: isDark ? accent : const Color(0xFF3D2900),
      tertiary: accent,
      surface: isDark ? darkSurface : lightSurface,
      surfaceContainerHighest:
          isDark ? const Color(0xFF2A332F) : const Color(0xFFE8EBE9),
      surfaceContainerLow:
          isDark ? const Color(0xFF1A211E) : const Color(0xFFF0F2F1),
      surfaceContainer: isDark ? const Color(0xFF1E2623) : Colors.white,
      onSurface: isDark ? const Color(0xFFE6ECE9) : baseScheme.onSurface,
      onSurfaceVariant:
          isDark ? const Color(0xFFB4BFB9) : baseScheme.onSurfaceVariant,
      outline: isDark ? const Color(0xFF5C6B64) : baseScheme.outline,
      outlineVariant:
          isDark ? const Color(0xFF3D4844) : baseScheme.outlineVariant,
      errorContainer:
          isDark ? const Color(0xFF4A1F1F) : baseScheme.errorContainer,
      onErrorContainer:
          isDark ? const Color(0xFFFFDAD6) : baseScheme.onErrorContainer,
    );

    final baseText = ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: fontFamily,
        );
    final textTheme = baseText.copyWith(
      displayLarge: baseText.displayLarge?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: colorScheme.onSurface,
      ),
      displayMedium: baseText.displayMedium?.copyWith(
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        color: colorScheme.onSurface,
      ),
      headlineLarge: baseText.headlineLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineMedium: baseText.headlineMedium?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      headlineSmall: baseText.headlineSmall?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleLarge: baseText.titleLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
      titleMedium: baseText.titleMedium?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      titleSmall: baseText.titleSmall?.copyWith(
        fontWeight: FontWeight.w600,
        color: colorScheme.onSurface,
      ),
      bodyLarge: baseText.bodyLarge?.copyWith(
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      bodyMedium: baseText.bodyMedium?.copyWith(
        height: 1.35,
        color: colorScheme.onSurface,
      ),
      bodySmall: baseText.bodySmall?.copyWith(
        color: colorScheme.onSurfaceVariant,
      ),
      labelLarge: baseText.labelLarge?.copyWith(
        fontWeight: FontWeight.w700,
        color: colorScheme.onSurface,
      ),
    );

    final cardColor = isDark ? colorScheme.surfaceContainerLow : Colors.white;
    final fieldFillColor =
        isDark ? colorScheme.surfaceContainerHighest : Colors.white;
    final navBarColor = isDark ? colorScheme.surfaceContainer : Colors.white;

    final cardShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(radiusCard),
      side: BorderSide(
        color: colorScheme.outlineVariant.withValues(alpha: 0.55),
      ),
    );

    return ThemeData(
      useMaterial3: true,
      fontFamily: fontFamily,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: colorScheme.surface,
      textTheme: textTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: colorScheme.surface,
        foregroundColor: colorScheme.onSurface,
        elevation: 0,
        centerTitle: false,
        scrolledUnderElevation: 0,
        iconTheme: IconThemeData(color: colorScheme.onSurface),
        titleTextStyle: textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w700,
          color: colorScheme.onSurface,
        ),
      ),
      cardTheme: CardThemeData(
        color: cardColor,
        elevation: isDark ? 0 : 2,
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.10),
        shape: cardShape,
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size.fromHeight(buttonHeight),
          foregroundColor: isDark ? Colors.white : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w700,
            fontSize: 16,
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size.fromHeight(buttonHeight),
          foregroundColor: colorScheme.onSurface,
          backgroundColor: isDark ? colorScheme.surfaceContainerHighest : null,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
          side: BorderSide(color: colorScheme.outline),
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: isDark ? accent : colorScheme.primary,
          textStyle: const TextStyle(
            fontFamily: fontFamily,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: fieldFillColor,
        labelStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        hintStyle: TextStyle(color: colorScheme.onSurfaceVariant),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.outlineVariant),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(
            color: isDark ? accent : colorScheme.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(radiusInput),
          borderSide: BorderSide(color: colorScheme.error),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: colorScheme.secondaryContainer,
        labelStyle: TextStyle(
          fontFamily: fontFamily,
          color: colorScheme.onSecondaryContainer,
          fontWeight: FontWeight.w600,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: navBarColor,
        indicatorColor: (isDark ? accent : colorScheme.primary)
            .withValues(alpha: isDark ? 0.22 : 0.14),
        elevation: isDark ? 0 : 2,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontFamily: fontFamily,
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected
                ? (isDark ? accent : colorScheme.primary)
                : colorScheme.onSurfaceVariant,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected
                ? (isDark ? accent : colorScheme.primary)
                : colorScheme.onSurfaceVariant,
          );
        }),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return isDark ? accent : colorScheme.primary;
          }
          return colorScheme.outline;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return (isDark ? accent : colorScheme.primary)
                .withValues(alpha: 0.35);
          }
          return colorScheme.surfaceContainerHighest;
        }),
      ),
      dividerTheme: DividerThemeData(
        color: colorScheme.outlineVariant.withValues(alpha: 0.6),
        space: 1,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: colorScheme.inverseSurface,
        contentTextStyle: TextStyle(
          fontFamily: fontFamily,
          color: colorScheme.onInverseSurface,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        // Sombra suave tipo sheet elevado de apps de ride.
        shadowColor: Colors.black.withValues(alpha: isDark ? 0 : 0.14),
        elevation: isDark ? 0 : 8,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: colorScheme.onSurfaceVariant,
        textColor: colorScheme.onSurface,
      ),
      iconTheme: IconThemeData(color: colorScheme.onSurfaceVariant),
    );
  }
}
