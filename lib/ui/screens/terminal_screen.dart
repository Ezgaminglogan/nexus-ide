import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../widgets/raspi_panel.dart';
import '../widgets/widgets.dart';

/// Android: the terminal as its own screen, pushed over the editor when Run starts.
/// Editor -> Run -> this screen -> Back to Editor. Going back never stops the program, and the
/// editor underneath keeps its text, cursor, scroll, open file and unsaved changes (it is the
/// route below, never rebuilt from disk). The editor's Terminal button opens this again.
class TerminalScreen extends StatelessWidget {
  const TerminalScreen({
    super.key,
    required this.session,
    required this.fileName,
    required this.onRunAgain,
    this.locate,
    this.onOpen,
    this.raspiDir,
  });

  final RunSession session;
  final String fileName;
  final VoidCallback onRunAgain;
  final LocateFile? locate;
  final ValueChanged<SourceLocation>? onOpen; // pops back to the editor at that line
  final String? raspiDir; // Raspberry Pi: the board stays visible while it runs

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: session,
      builder: (context, _) => Scaffold(
        resizeToAvoidBottomInset: true, // the input line rides above the keyboard
        backgroundColor: const Color(0xFF0B0F1A),
        appBar: AppBar(
          automaticallyImplyLeading: false,
          titleSpacing: 4,
          title: Row(children: [
            TextButton.icon(
              key: const Key('back-to-editor'),
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.arrow_back),
              label: const Text('Back to Editor'),
            ),
            const SizedBox(width: 4),
            Flexible(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(fileName, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 14, fontFamily: 'Consolas', fontFamilyFallback: ['monospace'])),
                const SizedBox(height: 2),
                RunStatusChip(session),
              ]),
            ),
          ]),
          actions: [
            session.running
                ? IconButton(
                    key: const Key('terminal-stop'),
                    tooltip: 'Stop',
                    onPressed: session.stop,
                    icon: const Icon(Icons.stop_circle_outlined, color: Nx.stop),
                  )
                : IconButton(
                    key: const Key('terminal-run-again'),
                    tooltip: 'Run again',
                    onPressed: onRunAgain,
                    icon: const Icon(Icons.replay, color: Nx.run),
                  ),
            PopupMenuButton<String>(
              tooltip: 'More',
              onSelected: (a) => switch (a) {
                'clear' => session.console.clear(),
                'copy' => Clipboard.setData(ClipboardData(text: session.console.lines.join('\n'))),
                _ => showBuildDetails(context, session),
              },
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'clear', child: ListTile(leading: Icon(Icons.delete_sweep_outlined), title: Text('Clear output'))),
                PopupMenuItem(value: 'copy', child: ListTile(leading: Icon(Icons.copy), title: Text('Copy output'))),
                PopupMenuItem(value: 'build', child: ListTile(leading: Icon(Icons.receipt_long_outlined), title: Text('Build details'))),
              ],
            ),
          ],
        ),
        body: SafeArea(
          top: false,
          child: Column(children: [
            if (raspiDir != null) RaspiPanel(dir: raspiDir!, running: session.running),
            RunDetailLine(session),
            Expanded(
              child: TerminalOutput(
                buffer: session.console,
                locate: locate,
                fontSize: 14,
                onOpen: onOpen == null
                    ? null
                    : (at) {
                        Navigator.of(context).pop();
                        onOpen!(at);
                      },
              ),
            ),
            TerminalInput(session: session, big: true),
          ]),
        ),
      ),
    );
  }
}
