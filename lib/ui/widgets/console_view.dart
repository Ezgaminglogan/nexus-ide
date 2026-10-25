import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/console_buffer.dart';
import '../../core/run_session.dart';
import '../theme.dart';

/// Terminal pieces shared by the docked terminal (PCs) and the full-screen one (Android):
/// a status chip, program output that follows new lines (unless you scrolled up), an input line,
/// and Build Details. Program output, build messages and status come from separate channels of
/// [RunSession]; nothing here sorts lines by what they say.

const termMono = TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 13, height: 1.35, color: Color(0xFFD6DCEA));

/// A place in the student's code named by a compiler or runtime message.
typedef SourceLocation = ({String file, int line});

/// Turns a path in a message into a workspace file, or null if it isn't one.
typedef LocateFile = String? Function(String path);

final _locationPatterns = [
  RegExp(r'File "([^"]+)", line (\d+)'), // Python
  RegExp(r'ERROR in (\S+) \(at line (\d+)\)'), // ecj (Java on phones)
  RegExp(r'in (\S+\.php) on line (\d+)'), // PHP
  RegExp(r'((?:[A-Za-z]:)?[^\s:()"]+\.(?:c|h|cpp|ino|java|cs|py|php|js))(?::|\()(\d+)'), // gcc, tcc, javac, csc, arduino-cli
];

/// The first source location in [line] that is a file of this project.
SourceLocation? findLocation(String line, LocateFile locate) {
  for (final re in _locationPatterns) {
    for (final m in re.allMatches(line)) {
      final file = locate(m[1]!);
      if (file != null) return (file: file, line: int.parse(m[2]!));
    }
  }
  return null;
}

class RunStatusChip extends StatelessWidget {
  const RunStatusChip(this.session, {super.key});
  final RunSession session;

  static (String, Color, IconData) look(RunSession s) => switch (s.state) {
        RunState.idle => ('Ready', Nx.muted, Icons.circle_outlined),
        RunState.preparing => ('Preparing', const Color(0xFF8FB0FF), Icons.hourglass_top),
        RunState.running => (s.action, Nx.run, Icons.play_circle_outline),
        RunState.finished => ('Finished', Nx.run, Icons.check_circle_outline),
        RunState.failed => ('Failed', Nx.stop, Icons.error_outline),
        RunState.stopped => ('Stopped', const Color(0xFFFFB224), Icons.stop_circle_outlined),
      };

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = look(session);
    return Container(
      key: const Key('run-status'),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        session.state == RunState.preparing
            ? SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: color))
            : Icon(icon, size: 14, color: color),
        const SizedBox(width: 5),
        Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color))),
      ]),
    );
  }
}

/// Exit code, time or reason under the toolbar, outside the program's output.
class RunDetailLine extends StatelessWidget {
  const RunDetailLine(this.session, {super.key});
  final RunSession session;

  @override
  Widget build(BuildContext context) {
    final text = switch (session.state) {
      RunState.preparing => 'Saving and building…',
      RunState.running => session.detail.isEmpty ? 'Type input below when your program asks for it.' : session.detail,
      _ => session.detail,
    };
    if (text.isEmpty) return const SizedBox();
    final color = session.state == RunState.failed ? Nx.stop : Nx.muted;
    return Container(
      width: double.infinity,
      color: const Color(0xFF10162A),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Text(text, key: const Key('run-detail'), style: TextStyle(fontSize: 12.5, color: color)),
    );
  }
}

Future<void> showBuildDetails(BuildContext context, RunSession session) => showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF0B0F1A),
      builder: (context) => SafeArea(
        child: SizedBox(
          height: MediaQuery.sizeOf(context).height * 0.7,
          child: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 8, 0),
              child: Row(children: [
                const Expanded(child: Text('Build details', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700))),
                IconButton(
                  tooltip: 'Copy build details',
                  onPressed: () => Clipboard.setData(ClipboardData(text: session.build.lines.join('\n'))),
                  icon: const Icon(Icons.copy, size: 18),
                ),
                IconButton(tooltip: 'Close', onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ]),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Text('Commands NEXUS ran, compiler messages, exit codes and times for the last run.', style: TextStyle(fontSize: 12.5, color: Nx.muted)),
            ),
            Expanded(
              child: ListenableBuilder(
                listenable: session.build,
                builder: (context, _) => session.build.isEmpty
                    ? const Center(child: Text('Nothing has been built yet.', style: TextStyle(color: Nx.muted)))
                    : SingleChildScrollView(
                        padding: const EdgeInsets.all(16),
                        child: SelectableText(session.build.lines.join('\n'), style: termMono.copyWith(fontSize: 12)),
                      ),
              ),
            ),
          ]),
        ),
      ),
    );

/// Program output. Follows new lines while you are at the bottom; scroll up and it stays where
/// you are reading, with a button back to the latest output. Error locations are tappable.
class TerminalOutput extends StatefulWidget {
  const TerminalOutput({super.key, required this.buffer, this.locate, this.onOpen, this.fontSize = 13});
  final ConsoleBuffer buffer;
  final LocateFile? locate;
  final ValueChanged<SourceLocation>? onOpen;
  final double fontSize;

  @override
  State<TerminalOutput> createState() => _TerminalOutputState();
}

class _TerminalOutputState extends State<TerminalOutput> {
  final _scroll = ScrollController();
  bool _follow = true;

  @override
  void initState() {
    super.initState();
    widget.buffer.addListener(_changed);
  }

  @override
  void didUpdateWidget(TerminalOutput old) {
    super.didUpdateWidget(old);
    if (old.buffer != widget.buffer) {
      old.buffer.removeListener(_changed);
      widget.buffer.addListener(_changed);
    }
  }

  void _changed() {
    if (widget.buffer.isEmpty) _follow = true; // a new run starts at the top
    if (_follow) WidgetsBinding.instance.addPostFrameCallback((_) => _toEnd());
  }

  void _toEnd() {
    if (_scroll.hasClients) _scroll.jumpTo(_scroll.position.maxScrollExtent);
  }

  @override
  void dispose() {
    widget.buffer.removeListener(_changed);
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final style = termMono.copyWith(fontSize: widget.fontSize);
    return Stack(children: [
      NotificationListener<ScrollNotification>(
        onNotification: (n) {
          if (n is UserScrollNotification || n is ScrollUpdateNotification && n.dragDetails != null) {
            final atEnd = n.metrics.pixels >= n.metrics.maxScrollExtent - 24;
            if (atEnd != _follow) setState(() => _follow = atEnd);
          }
          return false;
        },
        child: ListenableBuilder(
          listenable: widget.buffer,
          builder: (context, _) {
            final lines = widget.buffer.lines;
            return SelectionArea(
              child: ListView.builder(
                key: const Key('terminal-output'),
                controller: _scroll,
                padding: const EdgeInsets.fromLTRB(12, 6, 12, 12),
                itemCount: lines.length,
                itemBuilder: (_, i) {
                  final line = lines.elementAt(i);
                  final at = widget.locate == null ? null : findLocation(line, widget.locate!);
                  if (at == null) return Text(line, style: style);
                  return InkWell(
                    onTap: widget.onOpen == null ? null : () => widget.onOpen!(at),
                    child: Text.rich(TextSpan(children: [
                      TextSpan(text: line, style: style.copyWith(color: const Color(0xFFFF8A8A), decoration: TextDecoration.underline)),
                      TextSpan(text: '  ↗ ${at.file}:${at.line}', style: style.copyWith(color: const Color(0xFF8FB0FF), fontSize: widget.fontSize - 1)),
                    ])),
                  );
                },
              ),
            );
          },
        ),
      ),
      if (!_follow)
        Positioned(
          right: 12,
          bottom: 12,
          child: FloatingActionButton.small(
            heroTag: null,
            tooltip: 'Jump to the latest output',
            onPressed: () {
              setState(() => _follow = true);
              _toEnd();
            },
            child: const Icon(Icons.vertical_align_bottom),
          ),
        ),
    ]);
  }
}

/// The line that feeds the running program's stdin. Keeps focus after Enter, so a program that
/// asks several questions can be answered one after another.
class TerminalInput extends StatefulWidget {
  const TerminalInput({super.key, required this.session, this.big = false});
  final RunSession session;
  final bool big;

  @override
  State<TerminalInput> createState() => _TerminalInputState();
}

class _TerminalInputState extends State<TerminalInput> {
  final _input = TextEditingController();
  final _focus = FocusNode();

  @override
  void dispose() {
    _input.dispose();
    _focus.dispose();
    super.dispose();
  }

  void _send() {
    widget.session.send(_input.text);
    _input.clear();
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final on = widget.session.acceptsInput;
    return Container(
      color: const Color(0xFF10162A),
      child: Row(children: [
        Expanded(
          child: TextField(
            key: const Key('terminal-input'),
            controller: _input,
            focusNode: _focus,
            enabled: on,
            style: termMono.copyWith(fontSize: widget.big ? 15 : 13),
            textInputAction: TextInputAction.send,
            decoration: InputDecoration(
              hintText: on ? 'Type input for your program, then Enter' : 'Input opens while a program runs',
              hintStyle: const TextStyle(color: Color(0xFF5C6680)),
              prefixText: '› ',
              isDense: true,
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: widget.big ? 14 : 10),
            ),
            onSubmitted: (_) => _send(),
          ),
        ),
        if (widget.big)
          IconButton(tooltip: 'Send', onPressed: on ? _send : null, icon: const Icon(Icons.send_rounded)),
      ]),
    );
  }
}

/// The docked terminal on PCs (and narrow non-Android windows): header with status, Build
/// details and Clear; output; input.
class ConsoleView extends StatelessWidget {
  const ConsoleView({super.key, required this.session, this.locate, this.onOpen});
  final RunSession session;
  final LocateFile? locate;
  final ValueChanged<SourceLocation>? onOpen;

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF0B0F1A),
      child: ListenableBuilder(
        listenable: session,
        builder: (context, _) => Column(children: [
          Container(
            height: 34,
            padding: const EdgeInsets.only(left: 12),
            decoration: const BoxDecoration(border: Border(top: BorderSide(color: Nx.line))),
            child: Row(children: [
              const Text('TERMINAL', style: TextStyle(fontSize: 11, letterSpacing: 1.2, color: Nx.muted, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Flexible(child: RunStatusChip(session)),
              const Spacer(),
              IconButton(
                tooltip: 'Build details',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                onPressed: () => showBuildDetails(context, session),
                icon: const Icon(Icons.receipt_long_outlined, color: Nx.muted),
              ),
              IconButton(
                tooltip: 'Clear output',
                iconSize: 16,
                visualDensity: VisualDensity.compact,
                onPressed: session.console.clear,
                icon: const Icon(Icons.delete_sweep_outlined, color: Nx.muted),
              ),
            ]),
          ),
          RunDetailLine(session),
          Expanded(child: TerminalOutput(buffer: session.console, locate: locate, onOpen: onOpen)),
          TerminalInput(session: session),
        ]),
      ),
    );
  }
}
