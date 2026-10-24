import 'dart:async';
import 'dart:collection';

import 'package:flutter/foundation.dart';

/// Console text with bounded memory and at most ~20 UI rebuilds per second,
/// no matter how fast a `while(true) printf(...)` floods it.
class ConsoleBuffer extends ChangeNotifier {
  ConsoleBuffer({this.maxLines = 2000, this.maxLineLen = 4096});
  final int maxLines, maxLineLen;
  final lines = ListQueue<String>()..add('');
  final _pending = StringBuffer();
  Timer? _tick;

  bool get isEmpty => _pending.isEmpty && lines.length == 1 && lines.first.isEmpty;

  void add(String s) {
    _pending.write(s);
    _tick ??= Timer(const Duration(milliseconds: 50), _flush);
  }

  void clear() {
    _tick?.cancel();
    _tick = null;
    _pending.clear();
    lines
      ..clear()
      ..add('');
    notifyListeners();
  }

  void _flush() {
    _tick = null;
    final parts = _pending.toString().replaceAll('\r\n', '\n').split('\n');
    _pending.clear();
    lines.addLast(_clip(lines.removeLast() + parts.first));
    for (final l in parts.skip(1)) {
      lines.addLast(_clip(l));
    }
    while (lines.length > maxLines) {
      lines.removeFirst();
    }
    notifyListeners();
  }

  // printf in a loop with no '\n' would otherwise grow one line forever.
  String _clip(String l) => l.length > maxLineLen ? l.substring(l.length - maxLineLen) : l;

  @override
  void dispose() {
    _tick?.cancel();
    super.dispose();
  }
}
