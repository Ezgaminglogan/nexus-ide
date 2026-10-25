import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'console_buffer.dart';
import 'runner.dart';
import 'toolchains.dart';

/// A step done in Dart instead of a process (phone OTG upload / Serial Monitor). It writes to
/// [RunSession.console], may set [RunSession.input], and [stopped] completes on Stop.
typedef DartStep = Future<void> Function(RunSession s, Future<void> stopped);

/// Where a run is. Shown next to the output, never inside it.
enum RunState { idle, preparing, running, finished, failed, stopped }

/// Save -> compile -> run pipeline for one editor. The UI listens to this, [console] and [build].
///
/// Three channels, kept apart where they are produced (never by matching words in the text, so a
/// program may print "Compiling..." and still see it):
/// - [console]: what the program prints, plus the compiler's messages when a build FAILS;
/// - [build]: Build Details: commands, compiler output, exit codes, timings;
/// - [state] / [detail]: Preparing, Running, Finished, Failed, Stopped (with the exit code or reason).
/// Every run is a new session: its output is cleared when it starts, and anything an earlier run
/// still delivers afterwards is dropped.
class RunSession extends ChangeNotifier {
  final console = ConsoleBuffer();
  final build = ConsoleBuffer(maxLines: 4000);
  RunState state = RunState.idle;
  String detail = ''; // "Exit code 0 · 1.2 s", "Timed out after 120 s", "Cannot start gcc"...
  String action = 'Running'; // what the program step is: Running, Uploading to Uno..., Serial Monitor...
  RunHandle? _handle;
  Completer<void>? _stop; // completes on Stop while a DartStep runs
  bool _stopped = false, _starting = false;
  int _session = 0;

  /// Where typed console lines go while a DartStep runs (else: the program's stdin).
  void Function(String line)? input;

  bool get running => _starting || state == RunState.preparing || state == RunState.running;

  /// A program (or the Serial Monitor) is running and can be typed to.
  bool get acceptsInput => state == RunState.running;

  static Directory workDir(Language lang) => Directory(p.joinAll([Toolchains.workRoot, ...lang.dir.split('/')]));

  /// Last saved code of [file] (default: the main file) for [lang]; the main file falls back
  /// to the template when missing or emptied.
  static String load(Language lang, [String? file]) {
    final f = File(p.join(workDir(lang).path, file ?? lang.fileName));
    final code = f.existsSync() ? f.readAsStringSync() : '';
    return code.trim().isEmpty && (file ?? lang.fileName) == lang.fileName ? lang.template : code;
  }

  static Future<void> save(Language lang, String code, [String? file]) async {
    final dir = workDir(lang)..createSync(recursive: true);
    await File(p.join(dir.path, file ?? lang.fileName)).writeAsString(code);
    // NEXUS-owned helpers (headers, csproj, the Pi's RPi/GPIO.py): rewritten so app updates reach them.
    for (final e in lang.extraFiles.entries) {
      await (File(p.join(dir.path, e.key))..parent.createSync(recursive: true)).writeAsString(e.value);
    }
  }

  /// Saves [code], then runs [steps] (default: the language's own) in order. Earlier steps are the
  /// build: their output goes to [build], and to [console] only when they fail. The last step (or
  /// [then]) is the program, whose output is [console]. A failed build never runs anything.
  /// A second call while one is still starting is ignored (double taps); a call while one runs
  /// stops it first.
  Future<void> run(Language lang, String code,
      {List<Step>? steps, Map<String, String> vars = const {}, String runLabel = 'Running', DartStep? then, String? file}) async {
    if (_starting) return;
    _starting = true;
    notifyListeners();
    try {
      await stop(); // also frees main.exe so the linker can overwrite it, and the serial port
    } finally {
      _starting = false;
    }
    final session = ++_session;
    bool live() => session == _session;
    void out(String s) {
      if (live()) console.add(s);
    }

    void log(String s) {
      if (live()) build.add(s);
    }

    void set(RunState st, [String d = '']) {
      if (!live()) return;
      state = st;
      detail = d;
      notifyListeners();
    }

    _stopped = false;
    input = null;
    action = runLabel;
    console.clear();
    build.clear();
    set(RunState.preparing);
    final started = DateTime.now();
    String took() => '${(DateTime.now().difference(started).inMilliseconds / 1000).toStringAsFixed(1)} s';
    try {
      await save(lang, code, file);
      final cwd = workDir(lang).path;
      final all = Toolchains.stepsFor(lang, steps: steps, vars: vars);
      if (all.isEmpty && then == null) {
        return set(RunState.failed, '${lang.label} runs on Android phones and the lab PCs. iPhones only allow the Web tile.');
      }
      for (var i = 0; i < all.length; i++) {
        if (!live() || _stopped) return;
        final step = all[i];
        final last = i == all.length - 1 && then == null;
        final exe = Toolchains.resolve(step.tool, cwd);
        // <tools> keeps the command readable on phones; the full path is Toolchains.toolsDir.
        final command = '${p.basename(exe)} ${step.args.join(' ').replaceAll(Toolchains.toolsDir, '<tools>')}';
        log('${last ? '► Run' : '● Build step ${i + 1}'}: $command\n');
        if (last) set(RunState.running);
        try {
          _handle = await runTool(exe, step.args, cwd: cwd, env: Toolchains.envFor(lang, exe), timeout: last ? null : const Duration(minutes: 2));
        } on ProcessException catch (e) {
          log('  cannot start: ${e.message}\n');
          return set(RunState.failed, 'Cannot start "${step.tool}". Put it at ${Toolchains.bundledPath(step.tool)} or on PATH.');
        }
        final h = _handle!;
        if (!live()) {
          await h.kill(); // a newer run took over while this one was starting
          return;
        }
        final compilerSaid = StringBuffer();
        await h.output.forEach((s) {
          if (last) return out(s);
          compilerSaid.write(s);
          log(s);
        });
        final exit = await h.exitCode;
        log('  exit code $exit · ${took()}\n');
        if (!live()) return;
        if (_stopped) return set(RunState.stopped, last ? 'Stopped.' : 'Stopped while building.');
        if (h.endedBy != null) return set(last ? RunState.stopped : RunState.failed, h.endedBy!);
        if (exit != 0) {
          if (last) return set(RunState.failed, 'Exited with code $exit.');
          out(compilerSaid.toString()); // the diagnostics belong in front of the student
          return set(RunState.failed, 'Build failed (exit code $exit), so nothing was run.');
        }
      }
      if (then != null && live() && !_stopped) {
        log('► $runLabel\n');
        set(RunState.running);
        _stop = Completer();
        try {
          await then(this, _stop!.future);
        } catch (e) {
          log('  $e\n');
          return set(RunState.failed, '$e');
        }
        return set(_stopped ? RunState.stopped : RunState.finished, _stopped ? 'Stopped.' : 'Done · ${took()}');
      }
      set(RunState.finished, 'Exit code 0 · ${took()}');
    } finally {
      if (live()) {
        _handle = null;
        _stop = null;
        input = null;
        notifyListeners();
      }
    }
  }

  /// Shows [message] as the result without running anything ("Connect a board first").
  void notice(String message) {
    _session++;
    console.clear();
    build.clear();
    state = RunState.failed;
    detail = message;
    notifyListeners();
  }

  Future<void> stop() async {
    _stopped = true;
    if (_stop?.isCompleted == false) _stop!.complete();
    await _handle?.kill();
  }

  /// Sends one line to the running program; echoed, because pipes don't echo typing.
  void send(String line) {
    if (!acceptsInput) return;
    console.add('$line\n');
    (input ?? _handle?.send)?.call(line);
  }

  @override
  void dispose() {
    _session++;
    _handle?.kill();
    console.dispose();
    build.dispose();
    super.dispose();
  }
}
