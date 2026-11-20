import 'package:flutter/material.dart';

import '../../art/icons.dart';
import '../../models/item.dart';

GameIconType itemIcon(Item item) => switch (item) {
      Item.wheat => GameIconType.wheat,
      Item.flour => GameIconType.flour,
      Item.bread => GameIconType.bread,
    };

const Map<String, GameIconType> _tokens = {
  'coin': GameIconType.coin,
  'wheat': GameIconType.wheat,
  'flour': GameIconType.flour,
  'bread': GameIconType.bread,
};

final RegExp _tokenPattern = RegExp(r'\{(\w+)\}');

/// Text where "{coin}", "{wheat}", "{flour}" and "{bread}" are shown as icons.
class IconText extends StatelessWidget {
  const IconText(
    this.text, {
    super.key,
    required this.style,
    this.textAlign = TextAlign.center,
    this.iconScale = 1.25,
  });

  final String text;
  final TextStyle style;
  final TextAlign textAlign;
  final double iconScale;

  @override
  Widget build(BuildContext context) {
    final iconSize = (style.fontSize ?? 16) * iconScale;
    final spans = <InlineSpan>[];
    var last = 0;
    for (final m in _tokenPattern.allMatches(text)) {
      final type = _tokens[m.group(1)];
      if (type == null) continue;
      if (m.start > last) spans.add(TextSpan(text: text.substring(last, m.start)));
      spans.add(WidgetSpan(
        alignment: PlaceholderAlignment.middle,
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: iconSize * 0.08),
          child: GameIcon(type, size: iconSize),
        ),
      ));
      last = m.end;
    }
    if (last < text.length) spans.add(TextSpan(text: text.substring(last)));
    return Text.rich(TextSpan(style: style, children: spans), textAlign: textAlign);
  }
}
