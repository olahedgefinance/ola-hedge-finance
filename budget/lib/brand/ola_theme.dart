import 'package:flutter/material.dart';

/// ÓLA foundation tokens. Brand swatches are not interchangeable with text roles.
abstract final class OlaPalette {
  static const midnight = Color(0xFF0B1220);
  static const emerald = Color(0xFF16A37A);
  static const mint = Color(0xFF6EE7C7);
  static const blue = Color(0xFF3B82F6);
  static const gold = Color(0xFFD6A84B);
  static const canvas = Color(0xFFF8FAFC);
  static const white = Color(0xFFFFFFFF);
  static const darkSurface = Color(0xFF172235);
  static const mutedLight = Color(0xFF475569);
  static const mutedDark = Color(0xFFCBD5E1);
  static const outline = Color(0xFF64748B);
  static const successLight = Color(0xFF087F5B);
  static const errorLight = Color(0xFFB42318);
  static const errorDark = Color(0xFFFDA29B);
  static const warningLight = Color(0xFF805B00);
  static const infoLight = Color(0xFF1D4ED8);
}

abstract final class OlaSpacing {
  static const xxs = 4.0;
  static const xs = 8.0;
  static const sm = 12.0;
  static const md = 16.0;
  static const lg = 24.0;
  static const xl = 32.0;
  static const xxl = 48.0;
  static const xxxl = 64.0;
}

abstract final class OlaRadii {
  static const sm = 8.0;
  static const md = 12.0;
  static const lg = 16.0;
  static const xl = 24.0;

  /// StadiumBorder stays a pill at any control height.
  static const pill = StadiumBorder();
}

abstract final class OlaElevation {
  static const flat = 0.0;
  static const raised = 1.0;
  static const overlay = 3.0;
}

abstract final class OlaTheme {
  static const fontFamily = 'Inter';

  /// Explicit text/background pairs: Emerald uses Midnight text, not white.
  static ColorScheme colorScheme(Brightness brightness) {
    final dark = brightness == Brightness.dark;
    return ColorScheme(
      brightness: brightness,
      primary: dark ? OlaPalette.emerald : OlaPalette.successLight,
      onPrimary: dark ? OlaPalette.midnight : OlaPalette.white,
      primaryContainer:
          dark ? const Color(0xFF123D35) : const Color(0xFFDDF8EF),
      onPrimaryContainer: dark ? OlaPalette.mint : OlaPalette.midnight,
      secondary: dark ? OlaPalette.mint : OlaPalette.successLight,
      onSecondary: dark ? OlaPalette.midnight : OlaPalette.white,
      secondaryContainer:
          dark ? const Color(0xFF153A35) : const Color(0xFFDBF4ED),
      onSecondaryContainer: dark ? OlaPalette.mint : OlaPalette.midnight,
      tertiary: dark ? OlaPalette.gold : OlaPalette.warningLight,
      onTertiary: dark ? OlaPalette.midnight : OlaPalette.white,
      tertiaryContainer:
          dark ? const Color(0xFF3F3218) : const Color(0xFFF7EBCF),
      onTertiaryContainer: dark ? const Color(0xFFF7EBCF) : OlaPalette.midnight,
      error: dark ? OlaPalette.errorDark : OlaPalette.errorLight,
      onError: dark ? OlaPalette.midnight : OlaPalette.white,
      errorContainer: dark ? const Color(0xFF501C19) : const Color(0xFFFEE4E2),
      onErrorContainer:
          dark ? const Color(0xFFFEE4E2) : const Color(0xFF501C19),
      background: dark ? OlaPalette.midnight : OlaPalette.canvas,
      onBackground: dark ? OlaPalette.canvas : OlaPalette.midnight,
      surface: dark ? OlaPalette.darkSurface : OlaPalette.white,
      onSurface: dark ? OlaPalette.canvas : OlaPalette.midnight,
      surfaceVariant: dark ? const Color(0xFF253247) : const Color(0xFFE2E8F0),
      onSurfaceVariant: dark ? OlaPalette.mutedDark : OlaPalette.mutedLight,
      outline: dark ? const Color(0xFF94A3B8) : OlaPalette.outline,
      outlineVariant: dark ? OlaPalette.outline : const Color(0xFFCBD5E1),
      shadow: OlaPalette.midnight,
      scrim: OlaPalette.midnight,
      inverseSurface: dark ? OlaPalette.canvas : OlaPalette.darkSurface,
      onInverseSurface: dark ? OlaPalette.midnight : OlaPalette.canvas,
      inversePrimary: dark ? OlaPalette.successLight : OlaPalette.mint,
      surfaceTint: Colors.transparent,
    );
  }

  /// Apply only shared surface foundations; individual screen layouts stay intact.
  static ThemeData applySurfaces(ThemeData theme) => theme.copyWith(
        cardTheme: const CardTheme(
          elevation: OlaElevation.flat,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(OlaRadii.lg)),
          ),
        ),
        dialogTheme: const DialogTheme(
          elevation: OlaElevation.overlay,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(OlaRadii.xl)),
          ),
        ),
      );
}
