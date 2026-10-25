import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/main.dart';

Language lang(String id) => languages.firstWhere((l) => l.id == id);

/// Real file IO runs outside the test's fake clock: let it finish between frames.
Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 12; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('reset').path;
    Settings.reset();
  });

  test('starterFor: one shared skeleton per file type; unknown types get none', () {
    final web = lang('web'), c = lang('c');
    expect(starterFor(c, 'main.c'), c.template); // main file: the language's own template
    expect(starterFor(c, 'main.c'), contains('int main(void)'));
    expect(starterFor(lang('arduino'), 'arduino.ino'), allOf(contains('void setup()'), contains('void loop()')));
    expect(starterFor(lang('java'), 'Main.java'), contains('public static void main(String[] args)'));
    expect(starterFor(lang('java'), 'shapes/Circle.java'), startsWith('public class Circle {')); // class named like the file
    expect(starterFor(web, 'about.html'), allOf(startsWith('<!DOCTYPE html>'), contains('<meta charset="utf-8">'), contains('<title>about</title>'), contains('<body>')));
    expect(starterFor(web, 'css/site.css'), contains('body {'));
    expect(starterFor(web, 'app.js'), contains('<script src="app.js">'));
    expect(starterFor(lang('php'), 'about.php'), startsWith('<?php'));
    expect(starterFor(lang('raspi'), 'main.py'), contains('import RPi.GPIO as GPIO'));
    expect(starterFor(lang('csharp'), 'Program.cs'), contains('static void Main()'));
    expect(starterFor(web, 'logo.png'), isNull);
    expect(starterFor(web, 'README'), isNull);
  });

  testWidgets('Reset: Cancel and Escape change nothing; Reset restores and saves the starter; Undo brings back the exact code', (t) async {
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final dir = Directory('${Toolchains.workRoot}/c')..createSync(recursive: true);
    const mine = '#include <stdio.h>\nint main(void) {\n    printf("my work\\n");\n    return 0;\n}\n';
    File('${dir.path}/main.c').writeAsStringSync(mine);
    File('${dir.path}/notes.txt').writeAsStringSync('keep me');

    await t.pumpWidget(NexusApp(ready: Future.value()));
    await settle(t);
    await t.tap(find.text('Programming fundamentals'));
    await settle(t);
    final code = t.widget<EditableText>(find.byType(EditableText).first).controller;
    expect(code.text, contains('my work'));

    // Cancel: nothing changes.
    await t.tap(find.byTooltip('Reset to Starter Code (puts the starter template back in this file; asks first)'));
    await settle(t);
    expect(find.text('Reset to starter code?'), findsOneWidget);
    expect(find.textContaining('‘main.c’'), findsOneWidget);
    expect(find.textContaining('default C starter template'), findsOneWidget);
    expect(Focus.of(t.element(find.text('Cancel'))).hasFocus, isTrue); // Cancel has focus first
    await t.tap(find.text('Cancel'));
    await settle(t);
    expect(code.text, contains('my work'));

    // Escape: nothing changes.
    await t.tap(find.byTooltip('Reset to Starter Code (puts the starter template back in this file; asks first)'));
    await settle(t);
    await t.sendKeyEvent(LogicalKeyboardKey.escape);
    await settle(t);
    expect(find.text('Reset to starter code?'), findsNothing);
    expect(code.text, contains('my work'));
    expect(File('${dir.path}/main.c').readAsStringSync(), mine);

    // Reset: starter in the editor and on disk, a recovery copy, other files untouched.
    await t.tap(find.byTooltip('Reset to Starter Code (puts the starter template back in this file; asks first)'));
    await settle(t);
    await t.tap(find.text('Reset to Starter Code'));
    await settle(t);
    expect(code.text, lang('c').template);
    expect(code.selection.baseOffset, 0);
    expect(File('${dir.path}/main.c').readAsStringSync(), lang('c').template);
    expect(File('${dir.path}/notes.txt').readAsStringSync(), 'keep me');
    final copies = Directory('${Toolchains.workRoot}/.nexus/recovery').listSync(recursive: true).whereType<File>().toList();
    expect(copies.single.readAsStringSync(), mine);

    // Undo: the exact previous code, in the editor and on disk.
    await t.tap(find.text('Undo'));
    await settle(t);
    expect(code.text, mine);
    expect(File('${dir.path}/main.c').readAsStringSync(), mine);

    // The message with Undo closes by itself after its 10 seconds (Flutter keeps action snack bars otherwise).
    await t.tap(find.byTooltip('Reset to Starter Code (puts the starter template back in this file; asks first)'));
    await settle(t);
    await t.tap(find.text('Reset to Starter Code'));
    await settle(t);
    expect(find.text('Undo'), findsOneWidget);
    for (var i = 0; i < 12; i++) {
      await t.pump(const Duration(seconds: 1));
    }
    await t.pumpAndSettle();
    expect(find.text('Undo'), findsNothing);
  });

  testWidgets('Reset refuses file types with no starter template, leaving them as they are', (t) async {
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    final dir = Directory('${Toolchains.workRoot}/web')..createSync(recursive: true);
    File('${dir.path}/index.html').writeAsStringSync(lang('web').template);
    File('${dir.path}/data.json').writeAsStringSync('{"a": 1}');
    await t.pumpWidget(NexusApp(ready: Future.value()));
    await settle(t);
    await t.tap(find.text('HTML · CSS · JS · Designer'));
    await settle(t);
    await t.tap(find.text('data.json'));
    await settle(t);
    await t.tap(find.byTooltip('Reset to Starter Code (puts the starter template back in this file; asks first)'));
    await settle(t);
    expect(find.text('No starter template'), findsOneWidget);
    await t.tap(find.text('OK'));
    await settle(t);
    expect(File('${dir.path}/data.json').readAsStringSync(), '{"a": 1}');
  });
}
