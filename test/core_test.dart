import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:highlight/languages/python.dart';
import 'package:nexus_ide/core/core.dart';

final win = Platform.isWindows;

Future<void> settle() => Future.delayed(const Duration(milliseconds: 120));

void main() {
  test('ConsoleBuffer joins chunks into lines and caps line count', () async {
    final b = ConsoleBuffer(maxLines: 3);
    b
      ..add('a\nb')
      ..add('c\r\nd\ne\nf');
    await settle();
    expect(b.lines.toList(), ['d', 'e', 'f']);
    b.clear();
    expect(b.lines.toList(), ['']);
  });

  test('runTool streams output', () async {
    final h = await runTool(win ? 'cmd' : 'echo', win ? ['/c', 'echo', 'hi'] : ['hi'], cwd: '.');
    expect((await h.output.join()).trim(), 'hi');
    expect(await h.exitCode, 0);
  });

  test('kill stops a long-running program', () async {
    final h = await runTool(win ? 'ping' : 'sleep', win ? ['-n', '30', '127.0.0.1'] : ['30'], cwd: '.');
    await h.kill();
    expect(await h.exitCode.timeout(const Duration(seconds: 10)), isNot(0));
  });

  group('RunSession', () {
    setUp(() {
      Toolchains.workRoot = Directory.systemTemp.createTempSync('nexus_ws').path;
      Toolchains.toolsDir = Directory.systemTemp.createTempSync('nexus_tools').path;
    });

    Language lang(String tool, List<String> args) =>
        Language(id: 't', label: 'T', fileName: 'main.txt', mode: python, template: '', steps: [(tool: tool, args: args)]);

    String out(RunSession s) => s.console.lines.join('\n');
    String log(RunSession s) => s.build.lines.join('\n');

    test('saves code, falls back to PATH, runs it; status lives outside the output', () async {
      final s = RunSession();
      await s.run(lang(win ? 'x/cmd' : 'x/cat', win ? ['/c', 'type', 'main.txt'] : ['main.txt']), 'student code');
      await settle();
      expect(out(s).trim(), 'student code'); // only what the program printed
      expect(s.state, RunState.finished);
      expect(s.detail, startsWith('Exit code 0'));
      expect(log(s), contains('► Run: ')); // the command is in Build Details
      expect(s.running, isFalse);
    });

    test('a program that prints "Compiling..." keeps it: nothing is filtered by words', () async {
      final s = RunSession();
      await s.run(lang(win ? 'x/cmd' : 'x/echo', win ? ['/c', 'echo', 'Compiling... Compiled successfully.'] : ['Compiling... Compiled successfully.']), '');
      await settle();
      expect(out(s), contains('Compiling... Compiled successfully.'));
    });

    test('a failing build shows the compiler output, keeps commands in Build Details, and runs nothing', () async {
      final s = RunSession();
      final l = Language(id: 't', label: 'T', fileName: 'main.txt', mode: python, template: '', steps: [
        (tool: win ? 'x/cmd' : 'x/sh', args: win ? ['/c', 'echo main.c:3:5: error: x undeclared && exit 3'] : ['-c', 'echo "main.c:3:5: error: x undeclared"; exit 3']),
        (tool: win ? 'x/cmd' : 'x/echo', args: win ? ['/c', 'echo', 'RAN'] : ['RAN']),
      ]);
      await s.run(l, '');
      await settle();
      expect(out(s), contains('main.c:3:5: error: x undeclared'));
      expect(out(s), isNot(contains('RAN')));
      expect(out(s), isNot(contains('Build step')));
      expect(log(s), contains('● Build step 1'));
      expect(log(s), contains('exit code 3'));
      expect(s.state, RunState.failed);
      expect(s.detail, contains('Build failed (exit code 3)'));
    });

    test('a successful build keeps compiler chatter out of the output', () async {
      final s = RunSession();
      final l = Language(id: 't', label: 'T', fileName: 'main.txt', mode: python, template: '', steps: [
        (tool: win ? 'x/cmd' : 'x/echo', args: win ? ['/c', 'echo', 'compiler says hello'] : ['compiler says hello']),
        (tool: win ? 'x/cmd' : 'x/echo', args: win ? ['/c', 'echo', 'Hello-Logan'] : ['Hello-Logan']),
      ]);
      await s.run(l, '');
      await settle();
      expect(out(s).trim(), 'Hello-Logan');
      expect(log(s), contains('compiler says hello'));
    });

    test('each run starts clean; a stopped run cannot write into the next one', () async {
      final s = RunSession();
      final slow = lang(win ? 'x/cmd' : 'x/sh', win ? ['/c', 'echo OLD && ping -n 6 127.0.0.1 >nul && echo LATE'] : ['-c', 'echo OLD; sleep 5; echo LATE']);
      final first = s.run(slow, '');
      for (var i = 0; i < 50 && !out(s).contains('OLD'); i++) {
        await settle();
      }
      expect(out(s), contains('OLD'));
      await s.run(lang(win ? 'x/cmd' : 'x/echo', win ? ['/c', 'echo', 'NEW'] : ['NEW']), '');
      await first;
      await settle();
      expect(out(s).trim(), 'NEW');
      expect(s.state, RunState.finished);
    });

    test('a second Run while the first is still starting is ignored', () async {
      final s = RunSession();
      final l = lang(win ? 'x/cmd' : 'x/echo', win ? ['/c', 'echo', 'once'] : ['once']);
      await Future.wait([s.run(l, ''), s.run(l, '')]);
      await settle();
      expect('once'.allMatches(out(s)).length, 1);
    });

    test('Stop ends the run as Stopped, outside the output', () async {
      final s = RunSession();
      final run = s.run(lang(win ? 'x/ping' : 'x/sleep', win ? ['-n', '30', '127.0.0.1'] : ['30']), '');
      for (var i = 0; i < 50 && s.state != RunState.running; i++) {
        await settle();
      }
      await s.stop();
      await run;
      expect(s.state, RunState.stopped);
      expect(out(s), isNot(contains('Stopped')));
    });

    test('stepsFor fills in the toolchain folder and variables', () {
      final l = lang('x/cc', ['-I{tools}/include', '-p', '{port}']);
      expect(Toolchains.stepsFor(l, vars: {'port': 'COM3'}).single.args,
          ['-I${Toolchains.toolsDir}/include', '-p', 'COM3']);
    });

    test('missing tool gives a readable error', () async {
      final s = RunSession();
      await s.run(lang('nope/no_such_tool_xyz', []), '');
      await settle();
      expect(s.state, RunState.failed);
      expect(s.detail, contains('Cannot start "nope/no_such_tool_xyz"'));
    });

    test('{*.c} expands to every source file, main file first, skipping generated folders', () {
      final c = languages.firstWhere((l) => l.id == 'c');
      final dir = Directory('${Toolchains.workRoot}/c')..createSync(recursive: true);
      for (final f in ['main.c', 'util.c', 'lib/math.c', 'build/gen.c', 'notes.txt']) {
        File('${dir.path}/$f')
          ..createSync(recursive: true)
          ..writeAsStringSync('');
      }
      expect(Toolchains.sourceFiles(c, 'c'), ['main.c', 'lib/math.c', 'util.c']);
    });
  });
}
