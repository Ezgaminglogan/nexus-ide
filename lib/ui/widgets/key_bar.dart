import 'package:flutter/material.dart';

import 'code_pane.dart';

/// Row of coding keys that phone keyboards hide. Taps never take focus, so the keyboard stays up.
class KeyBar extends StatelessWidget {
  const KeyBar({super.key, required this.controller, required this.braces});
  final NexusCodeController controller;
  final bool braces;

  static const _keys = ['{', '}', '(', ')', ';', '"', '<', '>', '=', '[', ']', '&', '*', '#'];

  @override
  Widget build(BuildContext context) {
    Widget key(String label, VoidCallback onTap) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 5),
          child: Material(
            color: const Color(0xFF24304F),
            borderRadius: BorderRadius.circular(7),
            child: InkWell(
              borderRadius: BorderRadius.circular(7),
              onTap: onTap,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Center(
                  child: Text(label, style: const TextStyle(fontFamily: 'monospace', fontSize: 15, color: Colors.white)),
                ),
              ),
            ),
          ),
        );
    return Container(
      height: 44,
      color: const Color(0xFF10162A),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        children: [
          key('Tab', () => controller.insertText('    ')),
          for (final k in _keys) key(k, () => controller.insertText(k)),
          key('⇥ Format', () => controller.format(braces: braces)),
        ],
      ),
    );
  }
}
