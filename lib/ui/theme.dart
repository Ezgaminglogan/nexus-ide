import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../core/toolchains.dart';

/// NEXUS dark palette (VS Code-like). One place to tweak colors.
abstract final class Nx {
  static const bg = Color(0xFF0F1424);
  static const surface = Color(0xFF1A2238);
  static const line = Color(0xFF24304F);
  static const muted = Color(0xFF9AA6C4);
  static const run = Color(0xFF3DDC84);
  static const stop = Color(0xFFE5484D);

  static ThemeData theme() => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: bg,
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF3B6BFF), brightness: Brightness.dark, surface: bg),
        appBarTheme: const AppBarTheme(backgroundColor: Color(0xFF141B2F), elevation: 0, scrolledUnderElevation: 0),
      );
}

/// Hugeicons glyph per language id (no C# glyph in the set: code square).
const _icons = <String, List<List<dynamic>>>{
  'c': HugeIcons.strokeRoundedCProgramming,
  'arduino': HugeIcons.strokeRoundedChip02,
  'python': HugeIcons.strokeRoundedPython,
  'java': HugeIcons.strokeRoundedJava,
  'csharp': HugeIcons.strokeRoundedCodeSquare,
  'web': HugeIcons.strokeRoundedHtml5,
  'php': HugeIcons.strokeRoundedPhp,
};

/// Rounded colored square with the language's icon (tiles, editor title).
class LanguageBadge extends StatelessWidget {
  const LanguageBadge(this.lang, {super.key, this.size = 28});
  final Language lang;
  final double size;

  @override
  Widget build(BuildContext context) {
    final c = Color(lang.color);
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(color: c, borderRadius: BorderRadius.circular(size * 0.28)),
      child: HugeIcon(
        icon: _icons[lang.id] ?? HugeIcons.strokeRoundedCodeSquare,
        size: size * 0.6,
        color: c.computeLuminance() > 0.5 ? Colors.black87 : Colors.white,
      ),
    );
  }
}
