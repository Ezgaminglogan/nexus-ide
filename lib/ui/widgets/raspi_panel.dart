import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/raspi.dart';
import '../theme.dart';

/// The Raspberry Pi's 40-pin header, live: output pins glow when HIGH, input pins are buttons
/// to tap and hold. Polls the stand-in GPIO's state file 10x a second (see raspi.dart).
class RaspiPanel extends StatefulWidget {
  const RaspiPanel({super.key, required this.dir, required this.running});
  final String dir;
  final bool running;

  @override
  State<RaspiPanel> createState() => _RaspiPanelState();
}

class _RaspiPanelState extends State<RaspiPanel> {
  List<PinState> _pins = const [];
  final _pressed = <int>{};
  Timer? _poll;

  @override
  void initState() {
    super.initState();
    writePressed(widget.dir, {});
    _poll = Timer.periodic(const Duration(milliseconds: 100), (_) {
      final pins = readState(widget.dir);
      if (pins.toString() != _pins.toString()) setState(() => _pins = pins);
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    super.dispose();
  }

  void _press(int pin, bool down) {
    setState(() => down ? _pressed.add(pin) : _pressed.remove(pin));
    writePressed(widget.dir, _pressed);
  }

  static const _led = Color(0xFFFF3B3B);

  PinState? _state(int gpio) => _pins.where((s) => s.pin == gpio).firstOrNull;

  Widget _dot(int physical) {
    final what = header[physical]!;
    final s = what is int ? _state(what) : null;
    final color = switch (what) {
      '5V' => const Color(0xFFD9443A),
      '3V3' => const Color(0xFFE08A2C),
      'GND' => const Color(0xFF2A2F3E),
      _ when s == null => const Color(0xFF5C6680),
      _ when s.output => s.high ? _led : const Color(0xFF5A1E1E),
      _ => _pressed.contains(what) ? const Color(0xFF6FA0FF) : const Color(0xFF2F5BD3),
    };
    return Tooltip(
      message: what is int ? 'Pin $physical · GPIO $what' : 'Pin $physical · $what',
      child: Container(
        width: 18,
        height: 18,
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: s != null && s.output && s.high ? const [BoxShadow(color: _led, blurRadius: 8)] : null,
        ),
      ),
    );
  }

  Widget _pinCard(PinState s) {
    final physical = header.entries.firstWhere((e) => e.value == s.pin).key;
    final label = Text('GPIO ${s.pin} · pin $physical', style: const TextStyle(fontSize: 12, color: Nx.muted));
    if (s.output) {
      return Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(Icons.lightbulb, color: s.high ? _led : const Color(0xFF5A1E1E), size: 22),
        const SizedBox(width: 6),
        label,
        const SizedBox(width: 6),
        Text(s.high ? 'ON' : 'OFF', style: TextStyle(fontWeight: FontWeight.w700, color: s.high ? _led : Nx.muted)),
      ]);
    }
    final down = _pressed.contains(s.pin);
    return GestureDetector(
      onTapDown: (_) => _press(s.pin, true),
      onTapUp: (_) => _press(s.pin, false),
      onTapCancel: () => _press(s.pin, false),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: down ? const Color(0xFF2F5BD3) : Nx.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: const Color(0xFF2F5BD3)),
        ),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.radio_button_checked, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(down ? 'Pressed' : 'Hold button', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          label,
        ]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xFF0E1322),
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
        Row(children: [
          const Text('RASPBERRY PI · GPIO', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Nx.muted, fontWeight: FontWeight.w600)),
          const Spacer(),
          if (!widget.running) const Text('Run to see the pins', style: TextStyle(fontSize: 11, color: Nx.muted)),
        ]),
        const SizedBox(height: 6),
        // The header as it sits on the board: even pins on top, pin 1 bottom-left.
        FittedBox(
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(color: const Color(0xFF14532D), borderRadius: BorderRadius.circular(6)),
            child: Column(children: [
              Row(children: [for (var i = 2; i <= 40; i += 2) _dot(i)]),
              Row(children: [for (var i = 1; i <= 39; i += 2) _dot(i)]),
            ]),
          ),
        ),
        if (_pins.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(spacing: 14, runSpacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [for (final s in _pins) _pinCard(s)]),
        ],
      ]),
    );
  }
}
