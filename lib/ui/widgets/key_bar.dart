import 'dart:async';

import 'package:flutter/material.dart';

import 'code_pane.dart';

/// Row of coding keys that phone keyboards hide, with arrow keys to move the cursor (hold to
/// repeat) and a Select toggle that makes the arrows select. Taps never take focus, so the
/// keyboard stays up.
class KeyBar extends StatefulWidget {
  const KeyBar({super.key, required this.controller, required this.braces});
  final NexusCodeController controller;
  final bool braces;

  @override
  State<KeyBar> createState() => _KeyBarState();
}

class _KeyBarState extends State<KeyBar> {
  static const _keys = ['{', '}', '(', ')', ';', '"', '<', '>', '=', '[', ']', '&', '*', '#'];
  bool _select = false;
  Timer? _repeat;

  @override
  void dispose() {
    _repeat?.cancel();
    super.dispose();
  }

  Widget _key(String label, VoidCallback onTap, {String? tooltip, bool on = false, bool repeat = false}) {
    final body = Material(
      color: on ? const Color(0xFF3B6BFF) : const Color(0xFF24304F),
      borderRadius: BorderRadius.circular(7),
      child: InkWell(
        borderRadius: BorderRadius.circular(7),
        onTap: onTap,
        onLongPress: repeat ? () => _repeat = Timer.periodic(const Duration(milliseconds: 70), (_) => onTap()) : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Center(
            child: Text(label, style: const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 15, color: Colors.white)),
          ),
        ),
      ),
    );
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
      child: Listener(
        onPointerUp: (_) => _repeat?.cancel(),
        onPointerCancel: (_) => _repeat?.cancel(),
        child: tooltip == null ? body : Tooltip(message: tooltip, child: body),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final c = widget.controller;
    void move({int dx = 0, int dy = 0}) => c.moveCursor(dx: dx, dy: dy, select: _select);
    return Container(
      height: 44,
      color: const Color(0xFF10162A),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          _key('←', () => move(dx: -1), tooltip: 'Left (hold to repeat)', repeat: true),
          _key('→', () => move(dx: 1), tooltip: 'Right (hold to repeat)', repeat: true),
          _key('↑', () => move(dy: -1), tooltip: 'Up (hold to repeat)', repeat: true),
          _key('↓', () => move(dy: 1), tooltip: 'Down (hold to repeat)', repeat: true),
          _key('Select', () => setState(() => _select = !_select), tooltip: 'Arrows select text while this is on', on: _select),
          _key('Tab', () => c.insertText('    ')),
          for (final k in _keys) _key(k, () => c.insertText(k)),
          _key('⇥ Format', () => c.format(braces: widget.braces)),
        ],
      ),
    );
  }
}
