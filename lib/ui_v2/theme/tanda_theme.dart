import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'tanda_colors.dart';

/// Radios, del README (sección "Radios"). Nombrados por donde se usan.
class TandaRadii {
  static const card = 22.0;
  static const cardCompact = 20.0;
  static const pickupWindowBlock = 20.0;
  static const box = 16.0;
  static const searchInput = 14.0;
  static const imageCompact = 14.0;
  static const chip = 19.0;
  static const tag = 14.0;
  static const cta = 31.0; // alto 62 — pastilla completa
  static const slider = 32.0; // alto 64 — pastilla completa
  static const detailSheet = 26.0;
}

/// Espaciado, del README (sección "Espaciado").
class TandaSpacing {
  static const screenMargin = 20.0;
  static const cardGap = 14.0;
  static const chipGap = 8.0;
  static const cardPaddingH = 16.0;
  static const cardPaddingTop = 14.0;
  static const cardPaddingBottom = 16.0;
  static const detailBlockGap = 18.0;
}

/// Texto monoespaciado (JetBrains Mono) — código de recogida, reloj en vivo,
/// cuenta atrás. No forma parte del [TextTheme] general porque el resto de
/// la UI usa Archivo; se aplica puntualmente donde el diseño lo pide.
TextStyle tandaMono({
  required double fontSize,
  FontWeight fontWeight = FontWeight.w500,
  Color? color,
  double? letterSpacing,
}) {
  return GoogleFonts.jetBrainsMono(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: letterSpacing,
  );
}

class TandaTheme {
  static ThemeData _base(TandaColors c, Brightness brightness) {
    // No usamos GoogleFonts.archivoTextTheme(): en este entorno resuelve al
    // TextTheme de otro paquete (`material_ui`), no al de
    // `package:flutter/material.dart`. Tomamos solo el nombre de familia y
    // lo aplicamos sobre el TextTheme real de Flutter.
    final archivoFamily = GoogleFonts.archivo().fontFamily;
    final TextTheme textTheme = ThemeData(brightness: brightness).textTheme.apply(
          fontFamily: archivoFamily,
          bodyColor: c.ink,
          displayColor: c.ink,
        );

    final colorScheme = ColorScheme.fromSeed(
      seedColor: c.green,
      brightness: brightness,
      primary: c.green,
      onPrimary: c.onGreen,
      surface: c.surface,
      onSurface: c.ink,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: colorScheme,
      scaffoldBackgroundColor: c.bg,
      textTheme: textTheme,
      fontFamily: GoogleFonts.archivo().fontFamily,
      extensions: [c],
      appBarTheme: AppBarTheme(
        backgroundColor: c.bg,
        foregroundColor: c.ink,
        elevation: 0,
        centerTitle: false,
        surfaceTintColor: Colors.transparent,
      ),
      cardTheme: CardThemeData(
        color: c.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(TandaRadii.card),
          side: BorderSide(color: c.line),
        ),
        clipBehavior: Clip.antiAlias,
      ),
      dividerTheme: DividerThemeData(color: c.line, thickness: 1, space: 1),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: c.surface,
        hintStyle: TextStyle(color: c.muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TandaRadii.searchInput),
          borderSide: BorderSide(color: c.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TandaRadii.searchInput),
          borderSide: BorderSide(color: c.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(TandaRadii.searchInput),
          borderSide: BorderSide(color: c.green, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: c.green,
          foregroundColor: c.onGreen,
          disabledBackgroundColor: c.line,
          disabledForegroundColor: c.muted,
          minimumSize: const Size.fromHeight(62),
          textStyle: GoogleFonts.archivo(fontSize: 18, fontWeight: FontWeight.w800),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(TandaRadii.cta)),
          elevation: 0,
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: c.surface,
        surfaceTintColor: Colors.transparent,
        indicatorColor: Colors.transparent,
        height: 84,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return GoogleFonts.archivo(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: selected ? c.green : c.muted,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(color: selected ? c.green : c.muted);
        }),
      ),
    );
  }

  static ThemeData light() => _base(TandaColors.light, Brightness.light);
  static ThemeData dark() => _base(TandaColors.dark, Brightness.dark);
}
