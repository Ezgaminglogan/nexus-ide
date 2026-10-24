import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/main.dart';

void main() {
  setUp(() => Toolchains.workRoot = Directory.systemTemp.createTempSync('nexus_ws').path);

  testWidgets('home shows the language tiles in order and the developer credit', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NexusApp(ready: Future.value()));
    await tester.pumpAndSettle();

    final labels = ['C', 'Arduino', 'Python', 'Java', 'C#', 'Web', 'PHP'];
    for (final l in labels) {
      expect(find.text(l), findsWidgets);
    }
    expect(languages.map((l) => l.label), labels);
    expect(find.textContaining('Logan M. Panucat', findRichText: true), findsOneWidget);
    expect(find.text('CTU Naga Extension Campus · works offline'), findsOneWidget);
  });

  testWidgets('tapping C opens the editor with its template and a Run (F5) button', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NexusApp(ready: Future.value()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Programming fundamentals'));
    await tester.pumpAndSettle();

    expect(find.text('main.c'), findsOneWidget);
    expect(find.text('Run (F5)'), findsOneWidget);
    expect(find.textContaining('Hello, CTU Naga!', findRichText: true), findsWidgets);
  });

  testWidgets('Arduino editor shows the board picker, Upload and the Blink sketch', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NexusApp(ready: Future.value()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Sketch · Verify · Upload'));
    await tester.pumpAndSettle();

    expect(find.text('arduino.ino'), findsOneWidget);
    expect(find.text('Upload'), findsOneWidget);
    expect(find.text('Arduino Uno'), findsOneWidget);
    expect(find.text('Serial Monitor'), findsOneWidget);
    expect(find.textContaining('LED_BUILTIN', findRichText: true), findsWidgets);
  });

  testWidgets('Web designer: tapping a control adds it and rewrites index.html', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NexusApp(ready: Future.value()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('HTML · CSS · JS · Designer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Design'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Heading'));
    await tester.pumpAndSettle();

    expect(find.text('My Heading'), findsOneWidget); // on the design canvas
    await tester.tap(find.text('Code'));
    await tester.pumpAndSettle();
    expect(find.textContaining('<h1 style="color: #222222">My Heading</h1>', findRichText: true), findsWidgets);
  });

  testWidgets('PHP: terminal hidden until a run; New file adds a tab and opens it', (tester) async {
    tester.view.physicalSize = const Size(1280, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(NexusApp(ready: Future.value()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Server pages · MySQL'));
    await tester.pumpAndSettle();

    expect(find.text('TERMINAL'), findsNothing);
    await tester.tap(find.byTooltip('New file'));
    await tester.pumpAndSettle();
    await tester.enterText(find.descendant(of: find.byType(AlertDialog), matching: find.byType(TextField)), 'about.php');
    await tester.tap(find.text('Create'));
    for (var i = 0; i < 5; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50))); // real file IO in _open
      await tester.pump();
    }

    expect(find.widgetWithText(ChoiceChip, 'about.php'), findsOneWidget);
    expect(find.widgetWithText(ChoiceChip, 'index.php'), findsOneWidget);
    expect(File('${Toolchains.workRoot}/php/about.php').existsSync(), isTrue);
  });
}

