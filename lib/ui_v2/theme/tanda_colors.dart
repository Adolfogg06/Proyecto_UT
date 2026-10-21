import 'package:flutter/material.dart';

/// Paleta del rediseño "Última Tanda" — ver design_handoff_ultima_tanda/README.md.
/// Expuesta como [ThemeExtension] para leerse con
/// `Theme.of(context).extension<TandaColors>()!` desde cualquier widget v2,
/// sin tocar el [ColorScheme] que usan las pantallas v1.
class TandaColors extends ThemeExtension<TandaColors> {
  final Color bg;
  final Color surface;
  final Color ink;
  final Color muted;
  final Color line;
  final Color green;
  final Color onGreen;
  final Color greenSoft;
  final Color greenLine;
  final Color red;
  final Color yellow;
  final Color ph1;
  final Color ph2;

  const TandaColors({
    required this.bg,
    required this.surface,
    required this.ink,
    required this.muted,
    required this.line,
    required this.green,
    required this.onGreen,
    required this.greenSoft,
    required this.greenLine,
    required this.red,
    required this.yellow,
    required this.ph1,
    required this.ph2,
  });

  /// Opción 1a "Urbano".
  static const light = TandaColors(
    bg: Color(0xFFF4F5F2),
    surface: Color(0xFFFFFFFF),
    ink: Color(0xFF161A17),
    muted: Color(0xFF5E665F),
    line: Color(0xFFE4E7E2),
    green: Color(0xFF17A05D),
    onGreen: Color(0xFFFFFFFF),
    greenSoft: Color(0xFFE3F4EA),
    greenLine: Color(0xFFC9E8D5),
    red: Color(0xFFEE4B57),
    yellow: Color(0xFFF5B82E),
    ph1: Color(0xFFE9ECE6),
    ph2: Color(0xFFDFE3DC),
  );

  /// Opción 1b "Noche".
  static const dark = TandaColors(
    bg: Color(0xFF0F1210),
    surface: Color(0xFF191D1A),
    ink: Color(0xFFF1F3EF),
    muted: Color(0xFF9BA49C),
    line: Color(0xFF2A2F2B),
    green: Color(0xFF2BC274),
    onGreen: Color(0xFF07170D),
    greenSoft: Color(0xFF16291D),
    greenLine: Color(0xFF24432F),
    red: Color(0xFFFF5C68),
    yellow: Color(0xFFFFC940),
    ph1: Color(0xFF222823),
    ph2: Color(0xFF1B201C),
  );

  @override
  TandaColors copyWith({
    Color? bg,
    Color? surface,
    Color? ink,
    Color? muted,
    Color? line,
    Color? green,
    Color? onGreen,
    Color? greenSoft,
    Color? greenLine,
    Color? red,
    Color? yellow,
    Color? ph1,
    Color? ph2,
  }) {
    return TandaColors(
      bg: bg ?? this.bg,
      surface: surface ?? this.surface,
      ink: ink ?? this.ink,
      muted: muted ?? this.muted,
      line: line ?? this.line,
      green: green ?? this.green,
      onGreen: onGreen ?? this.onGreen,
      greenSoft: greenSoft ?? this.greenSoft,
      greenLine: greenLine ?? this.greenLine,
      red: red ?? this.red,
      yellow: yellow ?? this.yellow,
      ph1: ph1 ?? this.ph1,
      ph2: ph2 ?? this.ph2,
    );
  }

  @override
  TandaColors lerp(ThemeExtension<TandaColors>? other, double t) {
    if (other is! TandaColors) return this;
    return TandaColors(
      bg: Color.lerp(bg, other.bg, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      ink: Color.lerp(ink, other.ink, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      line: Color.lerp(line, other.line, t)!,
      green: Color.lerp(green, other.green, t)!,
      onGreen: Color.lerp(onGreen, other.onGreen, t)!,
      greenSoft: Color.lerp(greenSoft, other.greenSoft, t)!,
      greenLine: Color.lerp(greenLine, other.greenLine, t)!,
      red: Color.lerp(red, other.red, t)!,
      yellow: Color.lerp(yellow, other.yellow, t)!,
      ph1: Color.lerp(ph1, other.ph1, t)!,
      ph2: Color.lerp(ph2, other.ph2, t)!,
    );
  }
}

/// Atajo: `context.tanda.green`, etc.
extension TandaColorsX on BuildContext {
  TandaColors get tanda => Theme.of(this).extension<TandaColors>() ?? TandaColors.light;
}
