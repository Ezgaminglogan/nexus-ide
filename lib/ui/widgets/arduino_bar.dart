import 'package:flutter/material.dart';

import '../../core/arduino.dart';
import '../theme.dart';

/// Arduino IDE-style strip: board, port (+refresh), baud, Serial Monitor.
/// Pure view: the editor owns the state and runs the actions.
class ArduinoBar extends StatelessWidget {
  const ArduinoBar({
    super.key,
    required this.board,
    required this.ports,
    required this.port,
    required this.baud,
    required this.onBoard,
    required this.onPort,
    required this.onBaud,
    required this.onRefresh,
    required this.onMonitor,
  });

  final Board board;
  final List<Port> ports;
  final String? port;
  final int baud;
  final ValueChanged<Board> onBoard;
  final ValueChanged<String?> onPort;
  final ValueChanged<int> onBaud;
  final VoidCallback onRefresh, onMonitor;

  @override
  Widget build(BuildContext context) {
    Widget drop<T>(IconData icon, T? value, List<DropdownMenuItem<T>> items, ValueChanged<T?> onChanged, {String? hint}) => Padding(
          padding: const EdgeInsets.only(right: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(color: Nx.surface, borderRadius: BorderRadius.circular(10)),
            child: Row(mainAxisSize: MainAxisSize.min, children: [
              Icon(icon, size: 16, color: Nx.muted),
              const SizedBox(width: 6),
              DropdownButton<T>(
                value: value,
                items: items,
                onChanged: onChanged,
                hint: hint == null ? null : Text(hint, style: const TextStyle(color: Nx.muted)),
                underline: const SizedBox(),
                isDense: true,
                style: const TextStyle(fontSize: 13, color: Colors.white),
                dropdownColor: Nx.surface,
              ),
            ]),
          ),
        );

    return Container(
      color: const Color(0xFF141B2F),
      padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(children: [
          drop<Board>(Icons.developer_board, board, [for (final b in boards) DropdownMenuItem(value: b, child: Text(b.name))], (b) => onBoard(b!)),
          drop<String>(Icons.usb, ports.any((p) => p.address == port) ? port : null,
              [for (final p in ports) DropdownMenuItem(value: p.address, child: Text(p.label))], onPort,
              hint: ports.isEmpty ? 'No board found' : 'Pick port'),
          IconButton(tooltip: 'Refresh ports', onPressed: onRefresh, icon: const Icon(Icons.refresh, size: 20)),
          drop<int>(Icons.speed, baud, [for (final b in bauds) DropdownMenuItem(value: b, child: Text('$b baud'))], (b) => onBaud(b!)),
          OutlinedButton.icon(onPressed: onMonitor, icon: const Icon(Icons.monitor_heart_outlined, size: 18), label: const Text('Serial Monitor')),
        ]),
      ),
    );
  }
}
