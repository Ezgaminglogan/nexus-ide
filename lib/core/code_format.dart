import 'package:flutter/services.dart';

const _indent = '    ';

// <tag ...>, </tag>, <tag/>: 1 = closing slash, 2 = name, 3 = self-closing slash.
final _tag = RegExp(r'<(/?)([A-Za-z][\w-]*)\b[^<>]*?(/?)>');
final _comment = RegExp(r'<!--.*?-->');
final _openTagAtEnd = RegExp(r'<([A-Za-z][\w-]*)\b[^<>/]*>$'); // a line ending in an opening tag
// Elements that never have a closing tag.
const _voidTags = {'area', 'base', 'br', 'col', 'embed', 'hr', 'img', 'input', 'link', 'meta', 'source', 'track', 'wbr'};

/// Prettier-style tidy for student code.
/// [braces] (C, Arduino, Java, C#): re-indent by `{}` depth, ignoring braces in strings,
/// chars and comments; `#` lines stay at column 0. Otherwise (Python) indentation is syntax,
/// so only trailing spaces and extra blank lines are cleaned.
/// Markup (a file starting with `<`: HTML, or PHP with `<?php`) also indents by open tags, so
/// `<body>` contents sit one level in and `<style>`/`<script>` braces nest inside that.
/// ponytail: line-based brace/tag counter, not a parser; doesn't re-wrap long lines or space
/// operators, and a tag split over several lines counts on the line where it closes.
String formatCode(String text, {required bool braces}) {
  final tags = braces && text.trimLeft().startsWith('<');
  final out = <String>[];
  var depth = 0;
  var inBlock = false; // inside /* */ across lines
  for (final raw in text.replaceAll('\r\n', '\n').split('\n')) {
    final t = braces ? raw.trim() : raw.trimRight();
    if (t.isEmpty) {
      if (out.isNotEmpty && out.last.isNotEmpty) out.add('');
      continue;
    }
    if (!braces) {
      out.add(t);
      continue;
    }
    var opens = 0, closes = 0;
    String? quote;
    for (var i = 0; i < t.length; i++) {
      final c = t[i];
      if (inBlock) {
        if (c == '*' && i + 1 < t.length && t[i + 1] == '/') inBlock = false;
      } else if (quote != null) {
        if (c == '\\') {
          i++;
        } else if (c == quote) {
          quote = null;
        }
      } else if (c == '"' || c == "'") {
        quote = c;
      } else if (c == '/' && i + 1 < t.length && t[i + 1] == '/') {
        break;
      } else if (c == '/' && i + 1 < t.length && t[i + 1] == '*') {
        inBlock = true;
        i++;
      } else if (c == '{') {
        opens++;
      } else if (c == '}') {
        closes++;
      }
    }
    if (tags) {
      for (final m in _tag.allMatches(t.replaceAll(_comment, ''))) {
        if (m[1] == '/') {
          closes++;
        } else if (m[3] != '/' && !_voidTags.contains(m[2]!.toLowerCase())) {
          opens++;
        }
      }
    }
    final dedent = t.startsWith('}') || (tags && t.startsWith('</'));
    final level = t.startsWith('#') && !tags ? 0 : (dedent ? depth - 1 : depth);
    out.add('${_indent * (level < 0 ? 0 : level)}$t');
    depth = (depth + opens - closes).clamp(0, 1 << 16);
  }
  while (out.isNotEmpty && out.last.isEmpty) {
    out.removeLast();
  }
  return '${out.join('\n')}\n';
}

/// VS Code-style Enter: if [newV] is [oldV] plus a typed run ending in a newline (a key press,
/// or a phone keyboard committing "word + Enter" at once), carry the line's indent forward,
/// one level deeper after `{` or `:`. Enter between `{}` (or after an unclosed `{`) opens an
/// indented empty line with the `}` below it.
/// Returns null when nothing should change.
TextEditingValue? smartNewline(TextEditingValue oldV, TextEditingValue newV) {
  final a = oldV.text, b = newV.text;
  if (b.length <= a.length) return null;
  var p = 0;
  while (p < a.length && a[p] == b[p]) {
    p++;
  }
  var s = 0;
  while (s < a.length - p && a[a.length - 1 - s] == b[b.length - 1 - s]) {
    s++;
  }
  final inserted = b.substring(p, b.length - s);
  final caret = b.length - s;
  if (!inserted.endsWith('\n') || inserted.indexOf('\n') != inserted.length - 1) return null;
  if (newV.selection.baseOffset != caret) return null;

  final nl = caret - 1;
  final line = b.substring(b.lastIndexOf('\n', nl - 1) + 1, nl);
  final base = line.substring(0, line.length - line.trimLeft().length);
  final tag = _openTagAtEnd.firstMatch(line.trimRight()); // `<div class="x">` (HTML/PHP)
  final opens = line.trimRight().endsWith('{') || line.trimRight().endsWith(':') ||
      (tag != null && !_voidTags.contains(tag[1]!.toLowerCase()));
  final inner = opens ? '$base$_indent' : base;
  final before = b.substring(0, caret), after = b.substring(caret);

  // `}` right after the caret, or missing altogether (more `{` than `}`): put it on its own line.
  final unclosed = line.trimRight().endsWith('{') && '{'.allMatches(b).length > '}'.allMatches(b).length;
  if (opens && (after.startsWith('}') || unclosed)) {
    final close = after.startsWith('}') ? '' : '}';
    return TextEditingValue(
      text: '$before$inner\n$base$close$after',
      selection: TextSelection.collapsed(offset: caret + inner.length),
    );
  }
  if (inner.isEmpty) return null;
  return TextEditingValue(
    text: '$before$inner$after',
    selection: TextSelection.collapsed(offset: caret + inner.length),
  );
}

/// What to highlight around the caret: a bracket and its partner, or an HTML tag name and the
/// name in its matching open/close tag. Returns (start, end) ranges; empty when nothing matches.
/// ponytail: brackets inside strings/comments still count; fine for highlighting, not for parsing.
List<(int, int)> matchingPair(String text, int caret) {
  const open = '([{', close = ')]}';
  for (final at in [caret - 1, caret]) {
    if (at < 0 || at >= text.length) continue;
    final c = text[at];
    final o = open.indexOf(c), cl = close.indexOf(c);
    if (o < 0 && cl < 0) continue;
    final dir = o >= 0 ? 1 : -1, me = c, partner = o >= 0 ? close[o] : open[cl];
    var depth = 0;
    for (var i = at; i >= 0 && i < text.length; i += dir) {
      if (text[i] == me) depth++;
      if (text[i] == partner && --depth == 0) return [(at, at + 1), (i, i + 1)];
    }
    return const [];
  }
  final tags = RegExp(r'<(/?)([A-Za-z][\w-]*)').allMatches(text).toList();
  final here = tags.where((m) => m.start <= caret && caret <= m.end).firstOrNull;
  if (here == null || _voidTags.contains(here[2]!.toLowerCase())) return const [];
  final name = here[2]!, closing = here[1] == '/';
  var depth = 0;
  final scan = closing ? tags.reversed.where((m) => m.start <= here.start) : tags.where((m) => m.start >= here.start);
  for (final m in scan) {
    if (m[2] != name) continue;
    final isClose = m[1] == '/';
    if (isClose == closing) {
      depth++;
    } else if (--depth == 0) {
      return [(here.start + 1 + here[1]!.length, here.end), (m.start + 1 + m[1]!.length, m.end)];
    }
  }
  return const [];
}
