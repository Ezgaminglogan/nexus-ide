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

  int? _hover; // physical pin under the mouse

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
    final input = s != null && !s.output && what is int;
    final hover = _hover == physical;
    return Tooltip(
      message: what is int ? 'Pin $physical · GPIO $what${input ? ' (hold to press)' : ''}' : 'Pin $physical · $what',
      child: MouseRegion(
        cursor: input ? SystemMouseCursors.click : MouseCursor.defer,
        onEnter: (_) => setState(() => _hover = physical),
        onExit: (_) => setState(() => _hover = null),
        child: GestureDetector(
          // Input pins can be pressed right on the board too.
          onTapDown: input ? (_) => _press(what, true) : null,
          onTapUp: input ? (_) => _press(what, false) : null,
          onTapCancel: input ? () => _press(what, false) : null,
          child: Container(
            width: _BoardPainter.pitch,
            height: _BoardPainter.pitch,
            alignment: Alignment.center,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(
                color: color,
                shape: BoxShape.circle,
                border: Border.all(color: hover ? Colors.white : const Color(0xFFC9A54A), width: hover ? 1.5 : 1),
                boxShadow: s != null && s.output && s.high ? const [BoxShadow(color: _led, blurRadius: 8, spreadRadius: 1)] : null,
              ),
            ),
          ),
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
        // A generic Raspberry Pi-style board (not an exact model), drawn at 420x270 and scaled to fit.
        ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 230),
          child: FittedBox(
            child: SizedBox(
              width: _BoardPainter.w,
              height: _BoardPainter.h,
              child: Stack(children: [
                const Positioned.fill(child: CustomPaint(painter: _BoardPainter())),
                // The live pins sit exactly on the painted header: even pins on the top row.
                for (var i = 1; i <= 40; i++)
                  Positioned(
                    left: _BoardPainter.headerX + ((i - 1) ~/ 2) * _BoardPainter.pitch,
                    top: _BoardPainter.headerY + (i.isEven ? 0 : _BoardPainter.pitch),
                    child: _dot(i),
                  ),
              ]),
            ),
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


/// The board: shadow and edge for thickness, a lit green PCB, mounting holes, SoC and RAM, the
/// 40-pin header base (pins are live widgets on top), and the usual ports along the edges.
class _BoardPainter extends CustomPainter {
  const _BoardPainter();

  static const w = 420.0, h = 270.0;
  static const headerX = 42.0, headerY = 12.0, pitch = 14.0; // pin 2's cell is (headerX, headerY)

  @override
  void paint(Canvas canvas, Size size) {
    const board = Rect.fromLTWH(6, 4, w - 40, h - 22);
    final r = RRect.fromRectAndRadius(board, const Radius.circular(14));
    // Thickness: soft shadow, then the darker PCB edge peeking out below the top surface.
    canvas.drawRRect(r.shift(const Offset(4, 10)), Paint()..color = Colors.black54..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8));
    canvas.drawRRect(r.shift(const Offset(0, 5)), Paint()..color = const Color(0xFF0B3D1E));
    canvas.drawRRect(
      r,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF2E8B57), Color(0xFF1E6B40), Color(0xFF175733)],
        ).createShader(board),
    );
    // Faint copper traces for texture.
    final trace = Paint()
      ..color = const Color(0x2299E6B3)
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;
    for (var i = 0; i < 6; i++) {
      canvas.drawPath(Path()..moveTo(70, 70.0 + i * 9)..lineTo(150, 70.0 + i * 9)..lineTo(170, 90.0 + i * 9)..lineTo(260, 90.0 + i * 9), trace);
    }
    // Mounting holes: gold ring, dark hole.
    for (final c in const [Offset(21, 20), Offset(348, 20), Offset(21, 232), Offset(348, 232)]) {
      canvas.drawCircle(c, 9, Paint()..color = const Color(0xFFC9A54A));
      canvas.drawCircle(c, 5.5, Paint()..color = const Color(0xFF0E1322));
    }
    _block(canvas, const Rect.fromLTWH(headerX - 4, headerY - 4, 20 * pitch + 8, 2 * pitch + 8), const Color(0xFF15161A), 2); // header base
    _block(canvas, const Rect.fromLTWH(118, 92, 64, 64), const Color(0xFF2B2F36), 3, label: 'SoC'); // processor
    _block(canvas, const Rect.fromLTWH(196, 100, 46, 48), const Color(0xFF22252B), 2, label: 'RAM');
    _block(canvas, const Rect.fromLTWH(262, 112, 26, 26), const Color(0xFF22252B), 1, label: 'Wi-Fi', small: true);
    // Ports on the right edge stick out past the board, like on the real thing.
    for (final y in const [36.0, 92.0]) {
      _block(canvas, Rect.fromLTWH(338, y, 66, 46), const Color(0xFFB8BEC8), 3, label: 'USB', dark: true);
    }
    _block(canvas, const Rect.fromLTWH(336, 150, 70, 58), const Color(0xFFAEB4BE), 3, label: 'ETH', dark: true);
    // Bottom edge: power and two micro-HDMI.
    _block(canvas, const Rect.fromLTWH(46, 236, 34, 22), const Color(0xFFB8BEC8), 2, label: 'PWR', dark: true, small: true);
    _block(canvas, const Rect.fromLTWH(100, 236, 30, 20), const Color(0xFFB8BEC8), 2, label: 'HDMI', dark: true, small: true);
    _block(canvas, const Rect.fromLTWH(146, 236, 30, 20), const Color(0xFFB8BEC8), 2, label: 'HDMI', dark: true, small: true);
    _text(canvas, 'GPIO 40-pin', const Offset(44, 52), 10, const Color(0xCCFFFFFF));
    _text(canvas, 'Raspberry Pi-style board', const Offset(60, 196), 11, const Color(0xCCFFFFFF));
  }

  /// A raised part: shadow, darker side for depth, lit top with a highlight edge.
  static void _block(Canvas c, Rect r, Color color, double depth, {String? label, bool dark = false, bool small = false}) {
    final rr = RRect.fromRectAndRadius(r, const Radius.circular(3));
    c.drawRRect(rr.shift(Offset(depth, depth + 1)), Paint()..color = Colors.black45..maskFilter = const MaskFilter.blur(BlurStyle.normal, 2));
    c.drawRRect(rr.shift(Offset(0, depth)), Paint()..color = Color.lerp(color, Colors.black, 0.45)!);
    c.drawRRect(rr, Paint()..shader = LinearGradient(begin: Alignment.topCenter, end: Alignment.bottomCenter, colors: [Color.lerp(color, Colors.white, 0.18)!, color]).createShader(r));
    c.drawRRect(rr.deflate(0.5), Paint()..color = const Color(0x33FFFFFF)..style = PaintingStyle.stroke);
    if (label != null) _text(c, label, r.center, small ? 7.5 : 10, dark ? const Color(0xFF2B2F36) : const Color(0xFFB9C0CC), center: true);
  }

  static void _text(Canvas c, String s, Offset at, double size, Color color, {bool center = false}) {
    final tp = TextPainter(
      text: TextSpan(text: s, style: TextStyle(fontSize: size, color: color, fontWeight: FontWeight.w700, letterSpacing: 0.5)),
      textDirection: TextDirection.ltr,
    )..layout();
    tp.paint(c, center ? at - Offset(tp.width / 2, tp.height / 2) : at);
  }

  @override
  bool shouldRepaint(_BoardPainter old) => false; // static art; the live pins are widgets
}
