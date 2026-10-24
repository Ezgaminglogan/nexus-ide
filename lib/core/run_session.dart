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

/// Save -> compile -> run pipeline for one editor. UI listens to this + [console].
class RunSession extends ChangeNotifier {
  final console = ConsoleBuffer();
  RunHandle? _handle;
  Completer<void>? _stop; // completes on Stop while a DartStep runs
  bool _busy = false, _stopped = false;

  /// Where typed console lines go while a DartStep runs (else: the program's stdin).
  void Function(String line)? input;

  bool get running => _busy;

  static Directory workDir(Language lang) => Directory(p.join(Toolchains.workRoot, lang.id));

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
    for (final e in lang.extraFiles.entries) {
      final f = File(p.join(dir.path, e.key));
      if (!f.existsSync()) await f.writeAsString(e.value);
    }
  }

  /// Saves [code], then runs [steps] (default: the language's own) in order.
  /// Earlier steps are shown as compiling; the last as [runLabel] (with [then], every step
  /// is compiling and [then] runs last). Commands are only printed when a step fails, so
  /// students see output, not compiler flags.
  Future<void> run(Language lang, String code,
      {List<Step>? steps, Map<String, String> vars = const {}, String runLabel = 'Running', DartStep? then, String? file}) async {
    await stop(); // also frees main.exe so the linker can overwrite it, and the serial port
    _busy = true;
    _stopped = false;
    console.clear();
    notifyListeners();
    try {
      await save(lang, code, file);
      final cwd = workDir(lang).path;
      final all = Toolchains.stepsFor(lang, steps: steps, vars: vars);
      if (all.isEmpty && then == null) {
        console.add('${lang.label} runs on Android phones and the lab PCs. iPhones only allow the Web tile.\n');
        return;
      }
      for (var i = 0; i < all.length && !_stopped; i++) {
        final step = all[i];
        final last = i == all.length - 1 && then == null;
        final exe = Toolchains.resolve(step.tool, cwd);
        // <tools> keeps the command readable on phones; the full path is Toolchains.toolsDir.
        final command = '${p.basename(exe)} ${step.args.join(' ').replaceAll(Toolchains.toolsDir, '<tools>')}';
        console.add(last ? '► $runLabel\n' : '● Compiling…\n');
        try {
          _handle = await runTool(exe, step.args,
              cwd: cwd, env: Toolchains.envFor(lang, exe), timeout: last ? null : const Duration(minutes: 2));
        } on ProcessException catch (e) {
          console.add('✗ Cannot start "${step.tool}": ${e.message}\n'
              'Put it at ${Toolchains.bundledPath(step.tool)} or on PATH.\nCommand: $command\n');
          return;
        }
        await _handle!.output.forEach(console.add);
        final exit = await _handle!.exitCode;
        if (_stopped) {
          console.add('\n■ Stopped.\n');
        } else if (exit != 0) {
          console.add('\n✗ ${last ? 'Exited' : 'Compile failed'} (exit code $exit)\nCommand: $command\n');
          return;
        } else if (!last) {
          console.add('✓ Compiled\n');
        }
      }
      if (then != null && !_stopped) {
        console.add('► $runLabel\n');
        _stop = Completer();
        try {
          await then(this, _stop!.future);
        } catch (e) {
          console.add('\n✗ $e\n');
          return;
        }
        if (_stopped) console.add('\n■ Stopped.\n');
      }
      if (!_stopped) console.add('\n✓ Finished\n');
    } finally {
      _handle = null;
      _stop = null;
      input = null;
      _busy = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    _stopped = true;
    if (_stop?.isCompleted == false) _stop!.complete();
    await _handle?.kill();
  }

  void send(String line) {
    console.add('$line\n'); // pipes don't echo what the student typed
    (input ?? _handle?.send)?.call(line);
  }

  @override
  void dispose() {
    _handle?.kill();
    console.dispose();
    super.dispose();
  }
}
