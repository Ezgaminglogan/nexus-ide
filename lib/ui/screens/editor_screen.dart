import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/css.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/javascript.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/xml.dart';

import '../../core/core.dart';
import '../widgets/explorer.dart';
import '../widgets/raspi_panel.dart';
import '../widgets/web_designer.dart';
import '../widgets/widgets.dart';
import 'learn_screen.dart';
import 'preview_screen.dart';
import 'terminal_screen.dart';

class EditorScreen extends StatefulWidget {
  const EditorScreen({super.key, required this.language});
  final Language language;

  /// Android: Run opens the terminal as its own full screen instead of docking it under the
  /// editor. Decided by platform, not width (tests switch it on to check the phone flow).
  static bool terminalScreen = Platform.isAndroid;

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

  // Open files (VS Code-style tabs; paths relative to the workspace folder) and what each held when
  // last saved, so a changed tab shows a dot. Switching tabs saves, so nothing is ever lost.
  late String _file = _lang.fileName;
  late final _tabs = <String>[_lang.fileName];
  late final _saved = <String, String>{_lang.fileName: _code.fullText};
  bool _dirty = false;
  late final String _root = RunSession.workDir(_lang).path;
  static final _modes = {'html': xml, 'htm': xml, 'php': xml, 'css': css, 'js': javascript, 'py': python, 'java': java, 'cs': cs, 'c': cpp, 'h': cpp, 'ino': cpp};

  // Explorer: sidebar on PCs (toggle + drag to resize), drawer on phones. Remembered in settings.
  late bool _explorer = Settings.instance.get('explorer.visible', true);
  late double _explorerWidth = Settings.instance.get<num>('explorer.width', 250).toDouble();
  late final _expanded = Settings.instance.get<List>('explorer.expanded.${_lang.id}', const []).cast<String>().toSet();
  void _saveExpanded() => Settings.instance.set('explorer.expanded.${_lang.id}', _expanded.toList());

  bool _fullscreen = false; // phones: hide the status and navigation bars

  void _textChanged() {
    final d = _code.fullText != _saved[_file];
    if (d != _dirty) setState(() => _dirty = d);
  }

  Future<void> _saveNow() async {
    final text = _code.fullText;
    await RunSession.save(_lang, text, _file);
    _saved[_file] = text;
    if (mounted) setState(() => _dirty = false);
  }

  Future<void> _open(String rel) async {
    if (rel == _file) return;
    String text;
    try {
      text = RunSession.load(_lang, rel);
    } on FileSystemException {
      return _say('$rel can\'t be opened as text.');
    } on FormatException {
      return _say('$rel isn\'t a text file, so it can\'t be edited here.');
    }
    await _saveNow();
    setState(() {
      if (!_tabs.contains(rel)) _tabs.add(rel);
      _file = rel;
      _design = false;
      _saved[rel] = text;
    });
    _code
      ..language = _modes[rel.split('.').last.toLowerCase()] ?? _lang.mode
      ..fullText = text;
  }

  Future<void> _closeTab(String rel) async {
    if (rel == _lang.fileName) return; // the file NEXUS runs stays open
    if (rel == _file) await _open(_tabs[_tabs.indexOf(rel) - 1]); // saves it first
    setState(() => _tabs.remove(rel));
  }

  void _learn() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => LearnScreen(langId: _lang.id)));

  void _say(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  void _renamed(String from, String to) => setState(() {
        moveStarterRecords(_lang, from, to); // Reset rebuilds the same template from the new name
        for (var i = 0; i < _tabs.length; i++) {
          if (_tabs[i] == from || _tabs[i].startsWith('$from/')) _tabs[i] = to + _tabs[i].substring(from.length);
        }
        if (_file == from || _file.startsWith('$from/')) {
          _saved[to + _file.substring(from.length)] = _saved.remove(_file) ?? '';
          _file = to + _file.substring(from.length);
        }
        if (_expanded.remove(from)) _expanded.add(to);
      });

  /// A deleted file (or folder) closes its tabs without saving them back.
  void _deleted(String rel) {
    forgetStarterRecords(_lang, rel);
    final gone = _tabs.where((t) => t == rel || t.startsWith('$rel/')).toList();
    if (gone.contains(_file)) {
      _saved[_file] = _code.fullText; // don't write the deleted file back
      final keep = _tabs.firstWhere((t) => !gone.contains(t));
      _file = keep; // _open below would save the deleted file; switch directly
      _code
        ..language = _modes[keep.split('.').last.toLowerCase()] ?? _lang.mode
        ..fullText = RunSession.load(_lang, keep);
      _saved[keep] = _code.fullText;
    }
    setState(() => _tabs.removeWhere(gone.contains));
  }

  /// The language a file is written in, for messages ("the default HTML starter template").
  String _kind(String rel) => switch (rel.split('.').last.toLowerCase()) {
        'html' || 'htm' => 'HTML',
        'css' => 'CSS',
        'js' => 'JavaScript',
        'php' => 'PHP',
        'py' => _lang.id == 'raspi' ? 'Raspberry Pi Python' : 'Python',
        'java' => 'Java',
        'cs' => 'C#',
        'c' || 'h' => 'C',
        'ino' => 'Arduino',
        _ => _lang.label,
      };

  /// Reset to Starter Code: puts the starter skeleton back in ONE file, after a confirmation that
  /// names it. The file is fixed when the dialog opens, so switching tabs can't redirect it. The old
  /// code is written to workspace/.nexus/recovery first; if that fails, nothing is replaced.
  Future<void> _resetToStarter() async {
    final rel = _file; // bound now
    final name = rel.split('/').last;
    final starter = starterFor(_lang, rel, id: starterId(_lang, rel), root: _root); // the template it was made from
    if (starter == null) {
      await showDialog<void>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('No starter template'),
          content: Text('No starter template is configured for "$name", so NEXUS won\'t change it. Your code is untouched.'),
          actions: [FilledButton(autofocus: true, onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        ),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.restart_alt, color: Nx.stop),
        title: const Text('Reset to starter code?'),
        content: SizedBox(
          width: 460,
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Are you sure you want to clear the code in ‘$rel’? This will replace its current contents with the default ${_kind(rel)} starter template.'),
            const SizedBox(height: 12),
            const Text('Only this file changes. Other files, folders, settings and your learning progress stay as they are.', style: TextStyle(color: Nx.muted)),
            const SizedBox(height: 6),
            Text('The reset is saved right away${_session.running ? ', and the program that is running now is stopped' : ''}. Undo in the message that follows brings your code back.',
                style: const TextStyle(color: Nx.muted)),
          ]),
        ),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Nx.stop),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset to Starter Code'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return; // Cancel, Escape or tapping outside: nothing changes

    final before = rel == _file ? _code.fullText : RunSession.load(_lang, rel);
    try {
      final stamp = DateTime.now().toIso8601String().replaceAll(RegExp(r'[^0-9]'), '');
      File('${Toolchains.workRoot}/.nexus/recovery/${_lang.dir.replaceAll('/', '_')}/${rel.replaceAll('/', '__')}.$stamp.txt')
        ..createSync(recursive: true)
        ..writeAsStringSync(before);
    } on FileSystemException catch (e) {
      _say('Reset cancelled: NEXUS could not save a copy of your code first (${e.osError?.message ?? e.message}).');
      return;
    }
    if (_session.running) await _session.stop();
    await _replace(rel, starter);
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('$name is back to the starter code.'),
        duration: const Duration(seconds: 10),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            await _replace(rel, before);
            if (mounted) _say('$name: your code is back.');
          },
        ),
      ));
  }

  /// Writes [text] into [rel] and, if it is the open tab, the editor (cursor at the top, right
  /// syntax mode). Saves immediately, so no later save can bring back the replaced text.
  Future<void> _replace(String rel, String text) async {
    await RunSession.save(_lang, text, rel);
    _saved[rel] = text;
    if (rel != _file || !mounted) return;
    _code
      ..language = _modes[rel.split('.').last.toLowerCase()] ?? _lang.mode
      ..fullText = text
      ..selection = const TextSelection.collapsed(offset: 0);
    setState(() => _dirty = false);
  }

  void _toggleFullscreen() {
    setState(() => _fullscreen = !_fullscreen);
    SystemChrome.setEnabledSystemUIMode(_fullscreen ? SystemUiMode.immersiveSticky : SystemUiMode.edgeToEdge);
  }

  Widget _explorerPanel() => Explorer(
        root: _root,
        project: '${_lang.label} project',
        mainFile: _lang.fileName,
        selected: _file,
        expanded: _expanded,
        onOpen: (rel) {
          _open(rel);
          if (MediaQuery.sizeOf(context).width < 900) Navigator.of(context).maybePop(); // close the drawer
        },
        onRenamed: _renamed,
        onDeleted: _deleted,
        onExpandedChanged: _saveExpanded,
        language: _lang,
        onCreated: (rel, cursor) async {
          await _open(rel);
          if (rel == _file) _code.selection = TextSelection.collapsed(offset: cursor.clamp(0, _code.text.length));
          if (mounted && MediaQuery.sizeOf(context).width < 900) Navigator.of(context).maybePop(); // close the drawer
        },
      );

  Widget _tabStrip() => Container(
        height: 38,
        color: const Color(0xFF10162A),
        child: ListView(scrollDirection: Axis.horizontal, children: [
          for (final t in _tabs)
            Material(
              color: t == _file ? const Color(0xFF151A28) : Colors.transparent,
              child: InkWell(
                onTap: () => _open(t),
                child: Container(
                  padding: const EdgeInsets.only(left: 12, right: 4),
                  decoration: BoxDecoration(border: Border(top: BorderSide(color: t == _file ? Color(_lang.color) : Colors.transparent, width: 2))),
                  child: Row(children: [
                    Text(t.split('/').last, style: TextStyle(fontSize: 13, color: t == _file ? Colors.white : Nx.muted)),
                    if (t == _file && _dirty)
                      const Padding(
                        padding: EdgeInsets.only(left: 6),
                        child: Tooltip(message: 'Not saved yet (Ctrl+S, Run, or switching tabs saves)', child: Icon(Icons.circle, size: 9, color: Colors.white)),
                      ),
                    t == _lang.fileName
                        ? const SizedBox(width: 10)
                        : IconButton(tooltip: 'Close ${t.split('/').last}', iconSize: 15, visualDensity: VisualDensity.compact, onPressed: () => _closeTab(t), icon: const Icon(Icons.close)),
                  ]),
                ),
              ),
            ),
        ]),
      );

  Future<void> _preview() async {
    await _saveNow();
    // The open page if it is one, else the main page.
    if (_php) return mounted ? openPreview(context, Uri.parse('$phpUrl${_file.endsWith('.php') ? _file : ''}')) : null;
    final page = _file.endsWith('.html') ? _file : _lang.fileName;
    if (mounted) await openPreview(context, File('${RunSession.workDir(_lang).path}/$page').absolute.uri);
  }

  void _designChanged() {
    _code.fullText = designToHtml(_rows);
    _saveNow();
    _designFile.writeAsStringSync(designToJson(_rows));
  }

  /// Saves the open tab, then returns the main file's code: Run/Verify/Upload always build the
  /// file NEXUS runs, whichever tab is open.
  Future<String> _main() async {
    await _saveNow();
    return RunSession.load(_lang);
  }

  // The terminal shows only while something runs or has printed; clearing it hides it.
  bool _console = false;
  void _consoleChanged() {
    final show = _session.running || !_session.console.isEmpty || _session.state == RunState.failed;
    if (show != _console) setState(() => _console = show);
  }

  @override
  void initState() {
    super.initState();
    _session
      ..addListener(_consoleChanged)
      ..console.addListener(_consoleChanged);
    _code.addListener(_textChanged);
    beforeRestart.add(_saveNow); // an update restart saves this editor first
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
  List<Step>? _phoneBuild(String code) {
    if (_board.otgBaud == null) {
      _session.notice('${_board.name} uploads from the lab PCs only. On phones, use an Uno or Nano.');
      _showTerminal();
      return null;
    }
    final dir = Directory('${RunSession.workDir(_lang).path}/build')..createSync(recursive: true);
    File('${dir.path}/sketch.cpp').writeAsStringSync(sketchCpp(code));
    return phoneBuildSteps;
  }

  bool _launching = false; // saving before a run: a second tap must not start a second one
  VoidCallback? _again; // Run Again in the terminal screen repeats the last action (Run, Verify, Upload...)

  /// Starts [run] after saving, once, and on Android shows the terminal screen.
  Future<void> _start(Future<void> Function(String code) run) async {
    if (_launching || _session.running) return;
    _again = () => _start(run);
    _launching = true;
    try {
      final code = await _main();
      final started = run(code);
      _showTerminal();
      await started;
    } finally {
      _launching = false;
    }
  }

  Future<void> _run() => _start((code) => _session.run(_lang, code));

  // Workflows whose result is terminal output (not the Web/PHP preview).
  bool get _terminalFlow => !_web && !_php;
  bool _terminalOpen = false;

  /// Android: the terminal as its own screen over the editor (which stays as it is underneath).
  Future<void> _showTerminal() async {
    if (!EditorScreen.terminalScreen || !_terminalFlow || _terminalOpen || !mounted) return;
    _terminalOpen = true;
    await Navigator.of(context).push(MaterialPageRoute(
      builder: (_) => TerminalScreen(
        session: _session,
        fileName: _file.split('/').last,
        onRunAgain: () => (_again ?? _run)(),
        locate: _locate,
        onOpen: _goTo,
        raspiDir: _lang.id == 'raspi' ? RunSession.workDir(_lang).path : null,
      ),
    ));
    _terminalOpen = false;
  }

  /// A path from a compiler/runtime message as a file of this workspace, or null.
  String? _locate(String path) {
    final norm = path.replaceAll('\\', '/');
    final root = _root.replaceAll('\\', '/');
    var rel = norm.startsWith('$root/') ? norm.substring(root.length + 1) : norm;
    if (rel.startsWith('./')) rel = rel.substring(2);
    return File('$_root/$rel').existsSync() && !rel.startsWith('/') && !rel.contains(':') ? rel : null;
  }

  /// Opens [at]'s file with the cursor at the start of that line.
  Future<void> _goTo(SourceLocation at) async {
    await _open(at.file);
    final lines = _code.text.split('\n');
    final n = at.line.clamp(1, lines.length);
    final offset = lines.take(n - 1).fold<int>(0, (sum, l) => sum + l.length + 1);
    _code.selection = TextSelection.collapsed(offset: offset);
  }

  Future<void> _verify() => _start((code) async {
        final steps = _phone ? _phoneBuild(code) : verifySteps;
        if (steps != null) await _session.run(_lang, code, steps: steps, vars: _vars, runLabel: 'Verifying sketch…');
      });

  void _needPort(void Function() action) {
    if (_port != null) return action();
    _session.notice('Connect a board and pick its port first.');
    _showTerminal();
    _refreshPorts();
  }

  void _upload() => _needPort(() => _start((code) async {
        final label = 'Uploading to ${_board.name} on $_port…';
        if (!_phone) return _session.run(_lang, code, steps: uploadSteps, vars: _vars, runLabel: label);
        final steps = _phoneBuild(code);
        if (steps == null) return;
        final hex = '$_root/$phoneHex';
        await _session.run(_lang, code, steps: steps, vars: _vars, runLabel: label, then: otgUpload(_port!, {_board.otgBaud!, 115200, 57600}.toList(), hex));
      }));

  void _monitor() => _needPort(() => _start((code) {
        final label = 'Serial Monitor on $_port @ $_baud baud';
        return _phone
            ? _session.run(_lang, code, steps: const [], runLabel: label, then: otgMonitor(_port!, _baud))
            : _session.run(_lang, code, steps: monitorSteps, vars: _vars, runLabel: label);
      }));

  void _format() => _code.format(braces: _lang.braces);

  @override
  void dispose() {
    RunSession.save(_lang, _code.fullText, _file);
    beforeRestart.remove(_saveNow);
    if (_fullscreen) SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    _session.dispose();
    _code.dispose();
    super.dispose();
  }

  /// Phones: editor above the terminal. Wide screens (lab PCs): a VS Code-style rail to switch
  /// languages, the editor in the middle, the terminal docked on the right.
  Widget _layout(BuildContext context, List<Widget> editor) {
    final width = MediaQuery.sizeOf(context).width;
    // Android: the terminal is its own screen (Run opens it), never docked here.
    final console = !_web && _console && !(EditorScreen.terminalScreen && _terminalFlow)
        ? ConsoleView(session: _session, locate: _locate, onOpen: _goTo)
        : null;
    final pi = _lang.id == 'raspi' ? RaspiPanel(dir: RunSession.workDir(_lang).path, running: _session.running) : null;
    if (width < 900) {
      return Column(children: [...editor, ?pi, if (console != null) Expanded(flex: 2, child: console)]);
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      _rail(context),
      const VerticalDivider(width: 1, color: Nx.line),
      if (_explorer) ...[
        SizedBox(width: _explorerWidth, child: _explorerPanel()),
        // Drag to resize the explorer (remembered).
        MouseRegion(
          cursor: SystemMouseCursors.resizeColumn,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onHorizontalDragUpdate: (d) => setState(() => _explorerWidth = (_explorerWidth + d.delta.dx).clamp(170, 480)),
            onHorizontalDragEnd: (_) => Settings.instance.set('explorer.width', _explorerWidth),
            child: Container(width: 5, color: const Color(0xFF111729), alignment: Alignment.center, child: const VerticalDivider(width: 1, color: Nx.line)),
          ),
        ),
      ],
      Expanded(child: Column(children: [...editor, _statusBar()])),
      if (console != null || pi != null) ...[
        const VerticalDivider(width: 1, color: Nx.line),
        SizedBox(
          width: width * 0.36,
          child: Column(children: [?pi, Expanded(child: console ?? const ColoredBox(color: Color(0xFF0B0F1A)))]),
        ),
      ],
    ]);
  }

  /// Ln/Col and what Ctrl+F does, under the editor on PCs.
  Widget _statusBar() => ListenableBuilder(listenable: _code, builder: (context, _) => _statusLine());

  Widget _statusLine() {
    final sel = _code.selection;
    final before = sel.isValid ? _code.text.substring(0, sel.baseOffset.clamp(0, _code.text.length)) : '';
    final line = '\n'.allMatches(before).length + 1, col = before.length - before.lastIndexOf('\n');
    return Container(
      height: 24,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFF10162A),
      child: Row(children: [
        Text('Ln $line, Col $col', style: const TextStyle(fontSize: 12, color: Nx.muted)),
        const SizedBox(width: 12),
        Expanded(
          child: Text('${_file.split('.').last.toUpperCase()} · Ctrl+F find · Ctrl+S save · F5 run',
              textAlign: TextAlign.end, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, color: Nx.muted)),
        ),
      ]),
    );
  }

  Widget _rail(BuildContext context) => Container(
        width: 64,
        color: const Color(0xFF10162A),
        child: ListView(padding: const EdgeInsets.symmetric(vertical: 8), children: [
          IconButton(tooltip: 'Home', onPressed: () => Navigator.of(context).pop(), icon: const Icon(Icons.home_outlined, color: Nx.muted)),
          const SizedBox(height: 8),
          for (final l in languages)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Tooltip(
                message: l.label,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: l == _lang
                      ? null
                      : () => Navigator.of(context).pushReplacement(PageRouteBuilder(
                            transitionDuration: Duration.zero,
                            pageBuilder: (_, _, _) => EditorScreen(language: l),
                          )),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      border: Border(left: BorderSide(color: l == _lang ? Color(l.color) : Colors.transparent, width: 3)),
                    ),
                    child: Opacity(opacity: l == _lang ? 1 : 0.6, child: LanguageBadge(l, size: 36)),
                  ),
                ),
              ),
            ),
        ]),
      );

  @override
  Widget build(BuildContext context) {
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.f5): _arduino ? _upload : (_web ? _preview : _run),
        const SingleActivator(LogicalKeyboardKey.keyF, shift: true, alt: true): _format,
        const SingleActivator(LogicalKeyboardKey.keyS, control: true): _saveNow,
      },
      child: ListenableBuilder(
        listenable: _session,
        builder: (context, _) => Scaffold(
          drawer: MediaQuery.sizeOf(context).width < 900 ? Drawer(width: 300, child: SafeArea(child: _explorerPanel())) : null,
          appBar: AppBar(
            leading: const BackButton(),
            titleSpacing: 0,
            title: Row(children: [
              if (MediaQuery.sizeOf(context).width >= 440) ...[LanguageBadge(_lang, size: 26), const SizedBox(width: 10)], // phones: room for the file name
              Flexible(child: Text(_file, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 16, fontFamily: 'Consolas', fontFamilyFallback: ['monospace']))),
            ]),
            actions: [
              Builder(
                builder: (context) => IconButton(
                  tooltip: 'Files (explorer)',
                  isSelected: _explorer,
                  onPressed: () {
                    if (MediaQuery.sizeOf(context).width < 900) return Scaffold.of(context).openDrawer();
                    setState(() => _explorer = !_explorer);
                    Settings.instance.set('explorer.visible', _explorer);
                  },
                  icon: const Icon(Icons.folder_open_outlined),
                ),
              ),
              // Phones: the less frequent actions live in a ⋮ menu so the file name keeps its room.
              if (MediaQuery.sizeOf(context).width >= 600) ...[
                if (!_design) IconButton(tooltip: 'Find (Ctrl+F)', onPressed: _code.showSearch, icon: const Icon(Icons.search)),
                if (_dirty) IconButton(tooltip: 'Save (Ctrl+S)', onPressed: _saveNow, icon: const Icon(Icons.save_outlined)),
                if (Platform.isAndroid || Platform.isIOS)
                  IconButton(
                    tooltip: _fullscreen ? 'Exit fullscreen' : 'Enter fullscreen',
                    onPressed: _toggleFullscreen,
                    icon: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                  ),
                IconButton(tooltip: 'Format (Shift+Alt+F)', onPressed: _format, icon: const Icon(Icons.auto_fix_high_rounded)),
                if (!_design)
                  IconButton(
                    tooltip: 'Reset to Starter Code (puts the starter template back in this file; asks first)',
                    onPressed: _resetToStarter,
                    icon: const Icon(Icons.restart_alt),
                  ),
                IconButton(tooltip: 'Learn ${_lang.label} (lessons and practice)', onPressed: _learn, icon: const Icon(Icons.school_outlined)),
              ] else
                PopupMenuButton<VoidCallback>(
                  tooltip: 'More actions',
                  onSelected: (action) => action(),
                  itemBuilder: (_) => [
                    if (!_design) PopupMenuItem(value: _code.showSearch, child: const ListTile(leading: Icon(Icons.search), title: Text('Find'))),
                    if (_dirty) PopupMenuItem(value: _saveNow, child: const ListTile(leading: Icon(Icons.save_outlined), title: Text('Save'))),
                    PopupMenuItem(
                      value: _toggleFullscreen,
                      child: ListTile(
                        leading: Icon(_fullscreen ? Icons.fullscreen_exit : Icons.fullscreen),
                        title: Text(_fullscreen ? 'Exit fullscreen' : 'Enter fullscreen'),
                      ),
                    ),
                    PopupMenuItem(value: _format, child: const ListTile(leading: Icon(Icons.auto_fix_high_rounded), title: Text('Format code'))),
                    if (!_design)
                      PopupMenuItem(value: _resetToStarter, child: const ListTile(leading: Icon(Icons.restart_alt), title: Text('Reset to Starter Code'))),
                    PopupMenuItem(value: _learn, child: ListTile(leading: const Icon(Icons.school_outlined), title: Text('Learn ${_lang.label}'))),
                  ],
                ),
              if (EditorScreen.terminalScreen && _terminalFlow && _session.state != RunState.idle)
                IconButton(
                  key: const Key('open-terminal'),
                  tooltip: _session.running ? 'Terminal (running)' : 'Terminal (last run)',
                  onPressed: _showTerminal,
                  icon: Badge(isLabelVisible: _session.running, backgroundColor: Nx.run, smallSize: 8, child: const Icon(Icons.terminal)),
                ),
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
          body: SafeArea(top: false, child: _layout(context, [
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
            _tabStrip(),
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
          ])),
        ),
      ),
    );
  }
}
