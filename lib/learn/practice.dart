import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as p;

import '../core/core.dart';
import 'model.dart';

/// Checks a practice exercise by running the student's own code through the same toolchain the
/// editor uses, in the exercise's own folder (`workspace/practice/<id>/<lang>`), with time limits.
/// A result says "passed" only when a real check ran; otherwise it says what is left to check.

Language exerciseLanguage(Language base, Exercise ex) => base.practice(ex.id, '${base.label} · ${ex.title}');

/// Lower-cased, spaces collapsed: "Average:  85.0" matches "average: 85.0".
String _norm(String s) => s.replaceAll('\r', '').trim().replaceAll(RegExp(r'[ \t]+'), ' ').toLowerCase();

/// True when every expected line appears in [output], in order, each inside some output line
/// (so prompts like "Enter a score: " before the answer are fine).
bool outputMatches(String output, List<String> expect) {
  final lines = _norm(output).split('\n');
  var at = 0;
  for (final e in expect) {
    final want = _norm(e);
    final i = lines.indexWhere((l) => l.contains(want), at);
    if (i < 0) return false;
    at = i + 1;
  }
  return true;
}

class CaseResult {
  CaseResult(this.label, this.passed, {this.detail = ''});
  final String label, detail;
  final bool passed;
}

class CheckResult {
  CheckResult({required this.automatic, this.cases = const [], this.message = ''});
  final bool automatic; // false: nothing (or only compiling) was checked automatically
  final List<CaseResult> cases;
  final String message;
  bool get passed => automatic && cases.isNotEmpty && cases.every((c) => c.passed);
}

/// Lets the Stop button end a running check.
class PracticeRun {
  RunHandle? _current;
  bool stopped = false;
  Future<void> stop() async {
    stopped = true;
    await _current?.kill();
  }
}

const _compileLimit = Duration(minutes: 2), _runLimit = Duration(seconds: 10);

Future<({int code, String out, String? ended})> _exec(PracticeRun run, Language lang, Step step, String dir, Duration limit, {String input = ''}) async {
  final exe = Toolchains.resolve(step.tool, dir);
  final h = run._current = await runTool(exe, step.args, cwd: dir, env: Toolchains.envFor(lang, exe), timeout: limit);
  for (final line in input.split('\n')) {
    h.send(line); // '' sends one empty line (an "empty input" test), not nothing
  }
  h.closeInput();
  final out = StringBuffer();
  await h.output.forEach(out.write);
  final code = await h.exitCode;
  run._current = null;
  return (code: code, out: out.toString(), ended: h.endedBy);
}

/// The command that runs the program once, per platform; PHP runs as a script here, not a server.
List<Step> _steps(Language lang) {
  if (lang.id == 'php') {
    return [Platform.isAndroid ? (tool: 'bin/php', args: ['-d', 'opcache.enable_cli=0', 'index.php']) : (tool: 'php/php', args: ['index.php'])];
  }
  if (lang.id == 'csharp' && !Platform.isAndroid) {
    // Build once, then each test only runs it: `dotnet run` would rebuild inside every 10 s test.
    return [(tool: 'dotnet/dotnet', args: ['build', '-nologo', '-v', 'q']), (tool: 'dotnet/dotnet', args: ['run', '--no-build'])];
  }
  return Toolchains.stepsFor(lang);
}

/// Checks the student's file for [ex] (or [code], which then replaces it: used by the checks that
/// verify lessons and solutions).
Future<CheckResult> checkExercise(Language base, Exercise ex, PracticeRun run, {String? code}) async {
  final lang = exerciseLanguage(base, ex);
  final dir = RunSession.workDir(lang).path;
  code ??= File(p.join(dir, lang.fileName)).existsSync() ? RunSession.load(lang) : ex.starter;
  await RunSession.save(lang, code); // also writes the helpers the language needs (csproj, RPi/)

  switch (ex.kind) {
    case CheckKind.manual:
      return CheckResult(automatic: false, message: 'Nothing is checked automatically for this exercise. Use the checklist below.');

    case CheckKind.staticHtml:
      final text = [
        for (final f in Directory(dir).listSync(recursive: true).whereType<File>())
          if (RegExp(r'\.(html?|css|js)$').hasMatch(f.path)) f.readAsStringSync(),
      ].join('\n');
      return CheckResult(
        automatic: true,
        message: 'Static check: NEXUS read your code for the required parts; it did not run the page. Check how it looks with the checklist.',
        cases: [for (final (what, re) in ex.checks) CaseResult(what, RegExp(re, caseSensitive: false, multiLine: true).hasMatch(text))],
      );

    case CheckKind.compileOnly:
      final steps = Platform.isAndroid ? phoneBuildSteps : verifySteps;
      if (Platform.isAndroid) {
        Directory(p.join(dir, 'build')).createSync(recursive: true);
        File(p.join(dir, 'build', 'sketch.cpp')).writeAsStringSync(sketchCpp(code));
      }
      final all = Toolchains.stepsFor(lang, steps: steps, vars: {'fqbn': 'arduino:avr:uno', 'variant': 'standard', 'board': 'AVR_UNO'});
      final r = await _tryExec(run, lang, all.single, dir, _compileLimit);
      return CheckResult(
        automatic: false,
        cases: [CaseResult('Compiles for an Arduino Uno', r.code == 0, detail: r.code == 0 ? '' : _tail(r.out))],
        message: r.code == 0
            ? 'It compiles. What it does on a board is not checked here: upload it and use the checklist.'
            : 'It does not compile yet. Fix the first error shown, then check again.',
      );

    case CheckKind.output || CheckKind.gpio:
      final steps = _steps(lang);
      for (final s in steps.take(steps.length - 1)) {
        if (run.stopped) return CheckResult(automatic: false, message: 'Stopped.');
        final r = await _tryExec(run, lang, s, dir, _compileLimit);
        if (r.code != 0) {
          return CheckResult(automatic: true, message: 'It did not compile, so no test ran.', cases: [CaseResult('Compiles', false, detail: _tail(r.out))]);
        }
      }
      final results = <CaseResult>[];
      for (final (i, c) in ex.cases.indexed) {
        if (run.stopped) return CheckResult(automatic: false, message: 'Stopped.');
        if (ex.kind == CheckKind.gpio) writePressed(dir, c.pressed);
        final r = await _tryExec(run, lang, steps.last, dir, _runLimit, input: c.input);
        final label = 'Test ${i + 1}${c.note.isEmpty ? '' : ': ${c.note}'}';
        if (r.code == -1) {
          results.add(CaseResult(label, false, detail: r.out));
          continue;
        }
        if (r.ended != null) {
          results.add(CaseResult(label, false, detail: '${r.ended} An endless loop, or it waits for more input than the test gives.'));
          continue;
        }
        final problems = <String>[];
        if (!outputMatches(r.out, c.expect)) {
          problems.add('Expected to see:\n${c.expect.join('\n')}\n\nYour program printed:\n${_tail(r.out)}');
        }
        if (ex.kind == CheckKind.gpio) {
          final pins = {for (final s in readState(dir)) s.pin: s};
          c.pins.forEach((pin, high) {
            final got = pins[pin];
            if (got == null || !got.output) {
              problems.add('GPIO $pin was not set up as an output (GPIO.setup($pin, GPIO.OUT)).');
            } else if (got.high != high) {
              problems.add('GPIO $pin ended ${got.high ? 'HIGH' : 'LOW'}; expected ${high ? 'HIGH' : 'LOW'}.');
            }
          });
        }
        results.add(CaseResult(label, problems.isEmpty, detail: problems.join('\n\n')));
      }
      if (ex.kind == CheckKind.gpio) writePressed(dir, {});
      final n = results.where((r) => r.passed).length;
      return CheckResult(automatic: true, cases: results, message: '$n of ${results.length} tests passed.');
  }
}

/// A missing compiler or runtime is a result, not a crash.
Future<({int code, String out, String? ended})> _tryExec(PracticeRun run, Language lang, Step s, String dir, Duration limit, {String input = ''}) async {
  try {
    return await _exec(run, lang, s, dir, limit, input: input);
  } on ProcessException catch (e) {
    return (code: -1, ended: null, out: 'NEXUS could not start "${p.basename(s.tool)}" (${e.message}). The runtime for this language is missing on this device, so nothing was checked.');
  }
}

String _tail(String s) {
  final lines = s.trimRight().split('\n');
  return lines.length > 25 ? lines.sublist(lines.length - 25).join('\n') : lines.join('\n');
}

/// What actually runs each language here, checked by starting it (not guessed from the tile).
/// Returns (state, detail): state is installed / missing / simulated / built-in / unsupported.
Future<(String, String)> runtimeStatus(Language lang) async {
  if (!lang.availableHere) return ('unsupported', 'Not available on this device.');
  if (lang.id == 'web') return ('built-in', 'No compiler needed: pages open in the preview.');
  final probe = switch (lang.id) {
    _ when Platform.isAndroid => null,
    'c' => ('mingw/bin/gcc', ['--version']),
    'arduino' => ('arduino/arduino-cli', ['version']),
    'python' || 'raspi' => ('python/python', ['--version']),
    'java' => ('jdk/bin/java', ['-version']),
    'csharp' => ('dotnet/dotnet', ['--version']),
    'php' => ('php/php', ['-v']),
    _ => null,
  };
  if (probe == null) {
    // Phones: the tools come from the bundled pack; check the files are there.
    final tool = (lang.id == 'php' ? 'bin/php' : (lang.androidSteps ?? lang.steps).first.tool);
    final exists = tool.startsWith('/') ? File(tool).existsSync() : File(Toolchains.bundledPath(tool)).existsSync();
    return exists
        ? (lang.id == 'raspi' ? 'simulated' : 'installed', lang.id == 'raspi' ? 'Python with the NEXUS GPIO stand-in (no real pins).' : 'Bundled with NEXUS.')
        : ('missing', 'Not found in the NEXUS tool pack ($tool).');
  }
  try {
    final exe = Toolchains.resolve(probe.$1, '');
    final r = await Process.run(exe, probe.$2, environment: Toolchains.envFor(lang, exe)).timeout(const Duration(seconds: 20));
    final first = '${r.stdout}\n${r.stderr}'.trim().split('\n').first.trim();
    final where = File(exe).isAbsolute && File(exe).existsSync() ? 'bundled' : 'found on this PC';
    if (lang.id == 'raspi') return ('simulated', '$first ($where) with the NEXUS GPIO stand-in. No real pins.');
    return ('installed', '$first ($where)');
  } on ProcessException {
    return ('missing', '${p.basename(probe.$1)} is not bundled or installed on this PC.');
  } on TimeoutException {
    return ('missing', '${p.basename(probe.$1)} did not answer.');
  }
}
