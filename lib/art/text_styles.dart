import 'package:flutter/painting.dart';

import 'palette.dart';

/// Text styles using the bundled, rounded "Fredoka" font.
class AppText {
  AppText._();

  static const String family = 'Fredoka';

  /// Dark drop shadow that makes white text pop like a cartoon label.
  static const List<Shadow> popShadow = [
    Shadow(color: Color(0x8C3A1E0C), offset: Offset(0, 2)),
  ];

  /// [weight] 300–700. Fredoka is a variable font, so the weight is applied
  /// through the 'wght' axis as well as [FontWeight].
  static TextStyle style(
    double size, {
    double weight = 600,
    Color color = Palette.text,
    List<Shadow>? shadows,
    double? height,
  }) {
    return TextStyle(
      fontFamily: family,
      fontSize: size,
      fontWeight: FontWeight.values[((weight / 100).round() - 1).clamp(0, 8)],
      fontVariations: [FontVariation('wght', weight)],
      color: color,
      shadows: shadows,
      height: height,
    );
  }

  static TextStyle light(double size, {double weight = 600}) => style(
    size,
    weight: weight,
    color: const Color(0xFFFFFFFF),
    shadows: popShadow,
  );
}
