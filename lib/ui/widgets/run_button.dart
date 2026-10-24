import 'dart:io';

import 'package:flutter/material.dart';

import '../theme.dart';

/// Green pill that becomes a red Stop while something runs.
/// The F5 hint only shows on PCs (phones have no F5 key).
class RunButton extends StatelessWidget {
  const RunButton({super.key, required this.running, required this.onRun, required this.onStop, this.label = 'Run', this.icon = Icons.play_arrow_rounded});
  final bool running;
  final VoidCallback onRun, onStop;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final hint = Platform.isAndroid || Platform.isIOS || label != 'Run' ? '' : ' (F5)';
    return FilledButton.icon(
      onPressed: running ? onStop : onRun,
      style: FilledButton.styleFrom(
        backgroundColor: running ? Nx.stop : Nx.run,
        foregroundColor: running ? Colors.white : const Color(0xFF05351B),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        textStyle: const TextStyle(fontWeight: FontWeight.w700),
      ),
      icon: Icon(running ? Icons.stop_rounded : icon),
      label: Text(running ? 'Stop' : '$label$hint'),
    );
  }
}
