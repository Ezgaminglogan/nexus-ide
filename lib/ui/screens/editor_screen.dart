import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/xml.dart';

import '../../core/core.dart';
import '../widgets/web_designer.dart';
import '../widgets/widgets.dart';
import 'preview_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.language});
  final Language language;

  @override
  State<EditorScreen> createState() => _EditorScreenState();
}

class _EditorScreenState extends State<EditorScreen> {
  final _session = RunSession();
  late final Language _lang = widget.language;
  late final _code = NexusCodeController(text: RunSession.load(_lang), language: _lang.mode)
    ..autocompleter.setCustomWords(_lang.words);

  // Arduino only.
  bool get _arduino => _lang.id == 'arduino';
  Board _board = boards.first;
  List<Port> _ports = const [];
  String? _port;
  int _baud = 9600;

  // Web / PHP only.
  bool get _web => _lang.id == 'web';
  bool get _php => _lang.id == 'php';
  bool _design = false;
  late final File _designFile = File('${RunSession.workDir(_lang).path}/design.json');
  late final List<DesignRow> _rows = _designFile.existsSync() ? designFromJson(_designFile.readAsStringSync()) : [];

  // The open file; Web and PHP folders can hold more (VS Code-style tabs).
  late String _file = _lang.fileName;
  bool get _multi => _web || _php;
  static final _exts = {'html': xml, 'css': css, 'js': javascript, 'php': php};

  List<String> get _files {
    final dir = RunSession.workDir(_lang);
    final names = dir.existsSync()
        ? [for (final f in dir.listSync().whereType<File>()) f.uri.pathSegments.last].where((n) => _exts.containsKey(n.split('.').last)).toList()
        : <String>[];
    return {_lang.fileName, ...names..sort(), _file}.toList(); // main file first
  }

  Future<void> _open(String file) async {
    await RunSession.save(_lang, _code.fullText, _file);
    setState(() {
      _file = file;
      _design = false;
    });
    _code
      ..language = _exts[file.split('.').last] ?? _lang.mode
      ..fullText = RunSession.load(_lang, file);
  }

  Future<void> _newFile() async {
    final name = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New file'),
        content: TextField(
          controller: name,
          autofocus: true,
          decoration: InputDecoration(hintText: _php ? 'about.php' : 'style.css', helperText: '.html  .css  .js  .php'),
          onSubmitted: (_) => Navigator.pop(context, true),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Create')),
        ],
      ),
    );
    final file = name.text.trim();
    if (ok != true || file.isEmpty) return;
    // Plain names only: no folders, so a student can't write outside the workspace.
    if (!RegExp(r'^[\w-]+\.(html|css|js|php)$').hasMatch(file)) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Use a name like page.html, style.css, app.js or about.php')));
      return;
    }
    final f = File('${RunSession.workDir(_lang).path}/$file');
    if (!f.existsSync()) f..createSync(recursive: true)..writeAsStringSync('');
    await _open(file);
  }

  Future<void> _preview() async {
    await RunSession.save(_lang, _code.fullText, _file);
    // The open page if it is one, else the main page.
    if (_php) return mounted ? openPreview(context, Uri.parse('$phpUrl${_file.endsWith('.php') ? _file : ''}')) : null;
    final page = _file.endsWith('.html') ? _file : _lang.fileName;
    if (mounted) await openPreview(context, File('${RunSession.workDir(_lang).path}/$page').absolute.uri);
  }

  void _designChanged() {
    _code.fullText = designToHtml(_rows);
    RunSession.save(_lang, _code.fullText);
    _designFile.writeAsStringSync(designToJson(_rows));
  }

  // The terminal shows only while something runs or has printed; clearing it hides it.
  bool _console = false;
  void _consoleChanged() {
    final show = _session.running || !_session.console.isEmpty;
    if (show != _console) setState(() => _console = show);
  }

  @override
  void initState() {
    super.initState();
    _session
      ..addListener(_consoleChanged)
      ..console.addListener(_consoleChanged);
    if (_arduino) _refreshPorts();
  }

  Future<void> _refreshPorts() async {
    final ports = await listPorts();
    if (!mounted) return;
    setState(() {
      _ports = ports;
      if (!ports.any((p) => p.address == _port)) _port = ports.isEmpty ? null : ports.first.address;
      _board = boardFor(ports.where((p) => p.address == _port).firstOrNull?.fqbn) ?? _board; // auto-detect
    });
  }

  Map<String, String> get _vars =>
      {'fqbn': _board.fqbn, 'port': _port ?? '', 'baud': '$_baud', 'variant': _board.variant, 'board': _board.define};

  // Phones: bundled avr-gcc (ATmega328P boards) + USB OTG; the PC goes through arduino-cli.
  static final _phone = Platform.isAndroid;

  /// Phone build steps, after writing what they compile; null (with a message) if this board can't.
  List<Step>? _phoneBuild() {
    if (_board.otgBaud == null) {
      _session.console
        ..clear()
        ..add('${_board.name} uploads from the lab PCs only. On phones, use an Uno or Nano.\n');
      return null;
    }
    final dir = Directory('${RunSession.workDir(_lang).path}/build')..createSync(recursive: true);
    File('${dir.path}/sketch.cpp').writeAsStringSync(sketchCpp(_code.fullText));
    return phoneBuildSteps;
  }

  void _run() {
    if (!_session.running) _session.run(_lang, _code.fullText, file: _file);
  }

  void _verify() {
    final steps = _phone ? _phoneBuild() : verifySteps;
    if (steps != null) _session.run(_lang, _code.fullText, steps: steps, vars: _vars, runLabel: 'Verifying sketch…');
  }

  void _needPort(void Function() action) {
    if (_port != null) return action();
    _session.console
      ..clear()
      ..add('Connect a board and pick its port first.\n');
    _refreshPorts();
  }

  void _upload() => _needPort(() {
        final label = 'Uploading to ${_board.name} on $_port…';
        if (!_phone) {
          _session.run(_lang, _code.fullText, steps: uploadSteps, vars: _vars, runLabel: label);
          return;
        }
        final steps = _phoneBuild();
        if (steps == null) return;
        final hex = '${RunSession.workDir(_lang).path}/$phoneHex';
        _session.run(_lang, _code.fullText, steps: steps, vars: _vars, runLabel: label, then: otgUpload(_port!, {_board.otgBaud!, 115200, 57600}.toList(), hex));
      });

  void _monitor() => _needPort(() {
        final label = 'Serial Monitor on $_port @ $_baud baud (press Stop to close)';
        _phone
            ? _session.run(_lang, _code.fullText, steps: const [], runLabel: label, then: otgMonitor(_port!, _baud))
            : _session.run(_lang, _code.fullText, steps: monitorSteps, vars: _vars, runLabel: label);
      });

  void _format() => _code.format(braces: _lang.braces);

  @override
  void dispose() {
    RunSession.save(_lang, _code.fullText, _file);
    _session.dispose();
    _code.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): _arduino ? _upload : (_web ? _preview : _run),
        const SingleActivator(LogicalKeyboardKey.keyF, shift: true, alt: true): _format,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): () => RunSession.save(_lang, _code.fullText, _file),
      },
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) => Scaffold(
          appBar: AppBar(
            titleSpacing: 0,
            title: Row(children: [
              LanguageBadge(_lang, size: 26),
              const SizedBox(width: 10),
              Flexible(child: Text(_file, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontFamily: 'monospace'))),
            ]),
            actions: [
              IconButton(tooltip: 'Format (Shift+Alt+F)', onPressed: _format, icon: const Icon(Icons.auto_fix_high_rounded)),
              if (_arduino)
                IconButton(tooltip: 'Verify (compile)', onPressed: _session.running ? null : _verify, icon: const Icon(Icons.check_circle_outline_rounded)),
              if (_php)
                IconButton(tooltip: 'Preview (start the server first)', onPressed: _session.running ? _preview : null, icon: const Icon(Icons.open_in_browser)),
              Padding(
                padding: const EdgeInsets.only(right: 10, left: 4),
                child: _arduino
                    ? RunButton(running: _session.running, onRun: _upload, onStop: _session.stop, label: 'Upload', icon: Icons.upload_rounded)
                    : _web
                        ? RunButton(running: false, onRun: _preview, onStop: () {}, label: 'Preview', icon: Icons.visibility_outlined)
                        : RunButton(running: _session.running, onRun: _run, onStop: _session.stop, label: _php ? 'Serve' : 'Run'),
              ),
            ],
          ),
          body: Column(children: [
            if (_arduino)
              ArduinoBar(
                board: _board,
                ports: _ports,
                port: _port,
                baud: _baud,
                onBoard: (b) => setState(() => _board = b),
                onPort: (p) => setState(() {
                  _port = p;
                  _board = boardFor(_ports.where((x) => x.address == p).firstOrNull?.fqbn) ?? _board;
                }),
                onBaud: (b) => setState(() => _baud = b),
                onRefresh: _refreshPorts,
                onMonitor: _monitor,
              ),
            if (_multi)
              SizedBox(
                height: 40,
                child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 8), children: [
                  for (final f in _files)
                    Padding(
                      padding: const EdgeInsets.only(right: 6, top: 4),
                      child: ChoiceChip(label: Text(f), selected: f == _file, onSelected: (_) => f == _file ? null : _open(f)),
                    ),
                  IconButton(tooltip: 'New file', onPressed: _newFile, icon: const Icon(Icons.note_add_outlined, size: 20)),
                ]),
              ),
            if (_web && _file == _lang.fileName)
              Padding(
                padding: const EdgeInsets.all(8),
                child: SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, icon: Icon(Icons.code), label: Text('Code')),
                    ButtonSegment(value: true, icon: Icon(Icons.dashboard_customize_outlined), label: Text('Design')),
                  ],
                  selected: {_design},
                  onSelectionChanged: (s) => setState(() => _design = s.first),
                ),
              ),
            if (_web && _design)
              Expanded(child: WebDesigner(rows: _rows, onChanged: _designChanged))
            else ...[
              Expanded(flex: 3, child: CodePane(controller: _code)),
              if (Platform.isAndroid || Platform.isIOS) KeyBar(controller: _code, braces: _lang.braces),
            ],
            if (!_web && _console)
              Expanded(
                flex: 2,
                child: ConsoleView(buffer: _session.console, onInput: _session.send, inputEnabled: _session.running),
              ),
          ]),
        ),
      ),
    );
  }
}
