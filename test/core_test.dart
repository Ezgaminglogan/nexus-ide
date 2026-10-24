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

    test('saves code, falls back to PATH, runs it', () async {
      final s = RunSession();
      await s.run(lang(win ? 'x/cmd' : 'x/cat', win ? ['/c', 'type', 'main.txt'] : ['main.txt']), 'student code');
      await settle();
      final text = s.console.lines.join('\n');
      expect(text, contains('student code'));
      expect(text, contains('► Running'));
      expect(text, contains('✓ Finished'));
      expect(text, isNot(contains('> '))); // no command echo when things work
      expect(s.running, isFalse);
    });

    test('a failing compile step shows ✗ and the command, and skips the run step', () async {
      final s = RunSession();
      final l = Language(id: 't', label: 'T', fileName: 'main.txt', mode: python, template: '', steps: [
        (tool: win ? 'x/cmd' : 'x/sh', args: win ? ['/c', 'exit', '3'] : ['-c', 'exit 3']),
        (tool: win ? 'x/cmd' : 'x/echo', args: win ? ['/c', 'echo', 'RAN'] : ['RAN']),
      ]);
      await s.run(l, '');
      await settle();
      final text = s.console.lines.join('\n');
      expect(text, contains('● Compiling…'));
      expect(text, contains('✗ Compile failed (exit code 3)'));
      expect(text, contains('Command:'));
      expect(text, isNot(contains('RAN')));
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
      expect(s.console.lines.join('\n'), contains('Cannot start "nope/no_such_tool_xyz"'));
    });
  });
}
