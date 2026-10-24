import 'package:flutter/material.dart';

import '../../core/console_buffer.dart';
import '../theme.dart';

/// Program output plus an input line that feeds the program's stdin.
/// Status lines from RunSession (● ► ✓ ✗ ■) are colored so students spot results fast.
class ConsoleView extends StatefulWidget {
  const ConsoleView({super.key, required this.buffer, required this.onInput, this.inputEnabled = true});
  final ConsoleBuffer buffer;
  final ValueChanged<String> onInput;
  final bool inputEnabled;

  @override
  State<ConsoleView> createState() => _ConsoleViewState();
}

class _ConsoleViewState extends State<ConsoleView> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  static const _mono = TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 13, height: 1.35, color: Color(0xFFD6DCEA));

  static TextStyle _styleFor(String line) => switch (line.isEmpty ? '' : line[0]) {
        '✓' => _mono.copyWith(color: Nx.run, fontWeight: FontWeight.w600),
        '✗' => _mono.copyWith(color: Nx.stop, fontWeight: FontWeight.w600),
        '●' || '►' || '■' => _mono.copyWith(color: Nx.muted),
        _ => line.startsWith('Command:') ? _mono.copyWith(color: Nx.muted, fontSize: 11.5) : _mono,
      };

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B0F1A),
      child: Column(
        children: [
          Container(
            height: 30,
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Nx.line))),
            child: Row(children: [
              const Text('TERMINAL', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Nx.muted, fontWeight: FontWeight.w600)),
              const Spacer(),
              IconButton(
                tooltip: 'Clear',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                onPressed: widget.buffer.clear,
                icon: const Icon(Icons.delete_sweep_outlined, color: Nx.muted),
              ),
            ]),
          ),
          Expanded(
            child: ListenableBuilder(
              listenable: widget.buffer,
              builder: (context, _) {
                final lines = widget.buffer.lines;
                // reverse: newest line sits at the bottom and the view sticks to it for free.
                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  itemCount: lines.length,
                  itemBuilder: (_, i) {
                    final line = lines.elementAt(lines.length - 1 - i);
                    return SelectableText(line, style: _styleFor(line));
                  },
                );
              },
            ),
          ),
          TextField(
            controller: _input,
            focusNode: _focus,
            enabled: widget.inputEnabled,
            style: _mono,
            decoration: InputDecoration(
              hintText: widget.inputEnabled ? 'Type input for your program, press Enter' : 'Input opens while a program runs',
              hintStyle: const TextStyle(color: Color(0xFF5C6680)),
              prefixText: '› ',
              isDense: true,
              filled: true,
              fillColor: const Color(0xFF10162A),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            ),
            onSubmitted: (text) {
              widget.onInput(text);
              _input.clear();
              _focus.requestFocus();
            },
          ),
        ],
      ),
    );
  }
}
