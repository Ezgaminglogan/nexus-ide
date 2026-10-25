// The Android terminal flow with real programs (Python, GCC) on this PC: the phone's full-screen
// terminal is switched on by EditorScreen.terminalScreen, the same switch Platform.isAndroid sets.
// This checks the layout and lifecycle in Flutter's test engine; it is not a test on a device.
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/main.dart';
import 'package:nexus_ide/ui/screens/editor_screen.dart';
import 'package:nexus_ide/ui/screens/terminal_screen.dart';
import 'package:nexus_ide/ui/widgets/widgets.dart';

Future<void> pumpFor(WidgetTester t, {int times = 10}) async {
  for (var i = 0; i < times; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 60)); // also runs the console's 50 ms flush timer
  }
}

/// Waits (real time) until [ok] holds, pumping frames; fails after ~[seconds].
Future<void> until(WidgetTester t, bool Function() ok, String what, {int seconds = 40}) async {
  final end = DateTime.now().add(Duration(seconds: seconds));
  while (!ok()) {
    if (DateTime.now().isAfter(end)) {
      final views = find.byType(ConsoleView).evaluate().map((e) => (e.widget as ConsoleView).session).followedBy(
          find.byType(TerminalScreen).evaluate().map((e) => (e.widget as TerminalScreen).session));
      fail('Timed out waiting for: $what\n${views.map((s) => '${s.state} ${s.detail}\nbuild: ${s.build.lines.join('|')}\nout: ${s.console.lines.join('|')}').join('\n')}');
    }
    await pumpFor(t, times: 1);
  }
}

String output(WidgetTester t) => find.byKey(const Key('terminal-output')).evaluate().isEmpty
    ? ''
    : find
            .descendant(of: find.byKey(const Key('terminal-output')), matching: find.byType(RichText))
            .evaluate()
            .map((e) => (e.widget as RichText).text.toPlainText())
            .join('\n');

/// Types into the code editor the way the editor itself replaces text (enterText would go
/// through the code field's diffing, which isn't what a keyboard does).
Future<void> setCode(WidgetTester t, String code) async {
  (t.widget<EditableText>(find.byType(EditableText).first).controller as dynamic).fullText = code;
  await pumpFor(t, times: 2);
}

RunSession session(WidgetTester t) => t.widget<TerminalScreen>(find.byType(TerminalScreen)).session;

/// The run state shown on the terminal screen, or null while that screen isn't open yet.
RunState? state(WidgetTester t) => find.byType(TerminalScreen).evaluate().isEmpty ? null : session(t).state;

Future<void> openTile(WidgetTester t, String blurb) async {
  await t.pumpWidget(NexusApp(ready: Future.value()));
  await pumpFor(t);
  await t.ensureVisible(find.text(blurb));
  await t.tap(find.text(blurb));
  await pumpFor(t);
}

void main() {
  setUp(() {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('terminal').path;
    Toolchains.toolsDir = '${Directory.current.path}/toolchains';
    Settings.reset();
  });
  tearDown(() => EditorScreen.terminalScreen = Platform.isAndroid);

  testWidgets('Android flow: new file, edit, Run, answer two prompts, back to the editor, reopen, Run again, Stop', (t) async {
    EditorScreen.terminalScreen = true;
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    t.view.devicePixelRatio = 2.6;
    addTearDown(t.view.reset);
    await openTile(t, 'Scripts and data');

    // A new runnable module made with the Add File dialog, then used from main.py.
    await t.tap(find.byTooltip('Files (explorer)'));
    await pumpFor(t);
    await t.tap(find.byTooltip('New file'));
    await pumpFor(t);
    await t.enterText(find.byKey(const Key('new-file-name')), 'greet');
    await t.pump();
    expect(find.text('greet.py'), findsOneWidget);
    await t.tap(find.byKey(const Key('new-file-create')));
    await pumpFor(t);
    expect(File('${Toolchains.workRoot}/python/greet.py').readAsStringSync(), contains('def main():'));
    await setCode(t, 'def hello(name):\n    return "Hello, " + name + "!"\n');
    await pumpFor(t);
    await t.tap(find.text('main.py').first); // switching tabs saves greet.py
    await pumpFor(t);
    const program = 'import greet\n'
        'name = input("Enter your name: ")\n'
        'print("Compiling...")  # the student\'s own text: must stay visible\n'
        'age = int(input("Age: "))\n'
        'print(greet.hello(name), "Next year:", age + 1)\n';
    await setCode(t, program);
    await pumpFor(t);

    await t.tap(find.byType(RunButton));
    await pumpFor(t);
    expect(find.byType(TerminalScreen), findsOneWidget); // its own screen, not a split
    expect(find.byKey(const Key('back-to-editor')), findsOneWidget);
    await until(t, () => output(t).contains('Enter your name:'), 'the first prompt');
    expect(find.text('Running'), findsOneWidget); // status chip, outside the output

    await t.enterText(find.byKey(const Key('terminal-input')), 'Logan');
    await t.tap(find.byTooltip('Send'));
    await until(t, () => output(t).contains('Age:'), 'the second prompt');
    await t.enterText(find.byKey(const Key('terminal-input')), '19');
    await t.tap(find.byTooltip('Send'));
    await until(t, () => session(t).state == RunState.finished, 'the program to finish');
    await pumpFor(t);
    final text = output(t);
    expect(text, contains('Enter your name: Logan'));
    expect(text, contains('Compiling...'));
    expect(text, contains('Hello, Logan! Next year: 20'));
    expect(text, isNot(contains('Build step')));
    expect(text, isNot(contains('Finished'))); // status is in the toolbar, not the output
    expect(find.text('Finished'), findsOneWidget);

    // Rotate: still there.
    t.view.physicalSize = const Size(915 * 2.6, 412 * 2.6);
    await pumpFor(t);
    expect(output(t), contains('Hello, Logan!'));
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    await pumpFor(t);

    // Back to the editor: same file, same text; the terminal can be reopened with the same output.
    await t.tap(find.byKey(const Key('back-to-editor')));
    await pumpFor(t);
    expect(find.byType(TerminalScreen), findsNothing);
    final code = t.widget<EditableText>(find.byType(EditableText).first).controller;
    expect(code.text, program);
    await t.tap(find.byKey(const Key('open-terminal')));
    await pumpFor(t);
    expect(output(t), contains('Hello, Logan!'));

    // Run Again starts a fresh session: the old output is gone.
    await t.tap(find.byKey(const Key('terminal-run-again')));
    await until(t, () => !output(t).contains('Hello, Logan!') && output(t).contains('Enter your name:'), 'a fresh second run');

    // Back while it waits for input: it keeps running; reopen and Stop it.
    await t.tap(find.byKey(const Key('back-to-editor')));
    await pumpFor(t);
    await t.tap(find.byKey(const Key('open-terminal')));
    await pumpFor(t);
    expect(session(t).state, RunState.running);
    await t.tap(find.byKey(const Key('terminal-stop')));
    await until(t, () => session(t).state == RunState.stopped, 'Stop');
    expect(find.text('Stopped'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 3)));

  testWidgets('a compile error shows the compiler message with a tappable location; nothing old runs', (t) async {
    EditorScreen.terminalScreen = true;
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    t.view.devicePixelRatio = 2.6;
    addTearDown(t.view.reset);
    await openTile(t, 'Programming fundamentals');
    // First a good build, so an old main.exe exists.
    await setCode(t, '#include <stdio.h>\nint main(void) {\n    printf("OLD BUILD\\n");\n    return 0;\n}\n');
    await t.tap(find.byType(RunButton));
    await until(t, () => state(t) == RunState.finished, 'the first build', seconds: 90);
    await t.tap(find.byKey(const Key('back-to-editor')));
    await pumpFor(t);

    await setCode(t, '#include <stdio.h>\nint main(void) {\n    printf("%d\\n", missing);\n    return 0;\n}\n');
    await t.tap(find.byType(RunButton));
    await until(t, () => state(t) == RunState.failed, 'the failed build', seconds: 90);
    await pumpFor(t);
    expect(output(t), contains("'missing' undeclared"));
    expect(output(t), isNot(contains('OLD BUILD')));
    expect(find.textContaining('Build failed'), findsOneWidget);

    await t.tap(find.textContaining('↗ main.c:3', findRichText: true).first);
    await pumpFor(t);
    expect(find.byType(TerminalScreen), findsNothing);
    final code = t.widget<EditableText>(find.byType(EditableText).first).controller;
    expect(code.text.substring(0, code.selection.baseOffset).split('\n').length, 3); // cursor on line 3
  }, timeout: const Timeout(Duration(minutes: 4)));

  testWidgets('runtime error: traceback stays in the output with a tappable line; status says Failed', (t) async {
    EditorScreen.terminalScreen = true;
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    t.view.devicePixelRatio = 2.6;
    addTearDown(t.view.reset);
    await openTile(t, 'Scripts and data');
    await setCode(t, 'print("before")\nx = int("abc")\n');
    await t.tap(find.byType(RunButton));
    await until(t, () => state(t) == RunState.failed, 'the crash');
    await pumpFor(t);
    expect(output(t), allOf(contains('before'), contains('ValueError')));
    expect(find.text('Exited with code 1.'), findsOneWidget);
    expect(find.textContaining('↗ main.py:2', findRichText: true), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('long output follows the end; scrolling up keeps your place and offers a jump back', (t) async {
    EditorScreen.terminalScreen = true;
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    t.view.devicePixelRatio = 2.6;
    addTearDown(t.view.reset);
    await openTile(t, 'Scripts and data');
    await setCode(t, 'for i in range(1500):\n    print("line", i)\n');
    await t.tap(find.byType(RunButton));
    await until(t, () => state(t) == RunState.finished, 'the long output');
    await pumpFor(t);
    expect(find.text('line 1499'), findsOneWidget); // followed to the end
    expect(find.byTooltip('Jump to the latest output'), findsNothing);
    await t.drag(find.byKey(const Key('terminal-output')), const Offset(0, 900));
    await pumpFor(t);
    expect(find.text('line 1499'), findsNothing);
    expect(find.byTooltip('Jump to the latest output'), findsOneWidget);
    await t.tap(find.byTooltip('Jump to the latest output'));
    await pumpFor(t);
    expect(find.text('line 1499'), findsOneWidget);
  }, timeout: const Timeout(Duration(minutes: 2)));

  testWidgets('desktop keeps the docked terminal (no separate screen)', (t) async {
    EditorScreen.terminalScreen = false;
    t.view.physicalSize = const Size(1400, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    await openTile(t, 'Scripts and data');
    await setCode(t, 'print("docked")\n');
    await t.tap(find.byType(RunButton));
    await until(t, () => output(t).contains('docked'), 'output in the docked terminal');
    expect(find.byType(TerminalScreen), findsNothing);
    expect(find.text('TERMINAL'), findsOneWidget);
    expect(find.byType(EditableText), findsWidgets); // the editor is still on screen beside it
  }, timeout: const Timeout(Duration(minutes: 2)));
}
