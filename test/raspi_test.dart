import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/raspi.dart';
import 'package:nexus_ide/core/settings.dart';
import 'package:nexus_ide/core/toolchains.dart';
import 'package:nexus_ide/ui/widgets/pi3d.dart';
import 'package:nexus_ide/ui/widgets/raspi_panel.dart';
import 'package:path/path.dart' as p;

void main() {
  test('parseState reads pins, skips junk', () {
    expect(parseState('18 out 1\n17 in 0 up\nnonsense\n'), [
      (pin: 18, output: true, high: true, pullUp: false),
      (pin: 17, output: false, high: false, pullUp: true),
    ]);
    expect(parseState(''), isEmpty);
  });

  test('stand-in RPi.GPIO: outputs reach the state file, held buttons reach input() (pull-up reads LOW)', () async {
    final dir = Directory.systemTemp.createTempSync('raspi').path;
    for (final e in raspiFiles.entries) {
      File(p.join(dir, e.key))
        ..createSync(recursive: true)
        ..writeAsStringSync(e.value);
    }
    writePressed(dir, {17});
    File(p.join(dir, 'main.py')).writeAsStringSync('''
import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BOARD)
GPIO.setup(12, GPIO.OUT)            # physical 12 = GPIO 18
GPIO.setup(11, GPIO.IN, pull_up_down=GPIO.PUD_UP)  # physical 11 = GPIO 17
GPIO.output(12, GPIO.HIGH)
print(GPIO.input(11))
''');
    final ProcessResult r;
    try {
      r = await Process.run('python', ['-u', 'main.py'], workingDirectory: dir);
    } on ProcessException {
      markTestSkipped('python not on PATH');
      return;
    }
    expect(r.stderr, '');
    expect((r.stdout as String).trim(), '0'); // pressed + pull-up = LOW
    expect(readState(dir), [
      (pin: 17, output: false, high: false, pullUp: true),
      (pin: 18, output: true, high: true, pullUp: false),
    ]);
  });

  testWidgets('pin panel: lit LED for a HIGH output, hold-button writes the press for GPIO.input', (tester) async {
    final dir = Directory.systemTemp.createTempSync('raspi_ui').path;
    File(p.join(dir, stateFile)).writeAsStringSync('18 out 1\n17 in 0 up');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RaspiPanel(dir: dir, running: true))));
    await tester.pump(const Duration(milliseconds: 150)); // one poll

    expect(find.text('ON'), findsOneWidget);
    expect(find.text('GPIO 18 · pin 12'), findsOneWidget);
    final hold = await tester.startGesture(tester.getCenter(find.text('Hold button')));
    await tester.pump();
    expect(File(p.join(dir, inputFile)).readAsStringSync(), '17');
    await hold.up();
    await tester.pump();
    expect(File(p.join(dir, inputFile)).readAsStringSync(), '');
  });

  testWidgets('3D board: the model loads, live pins sit on its header, holding an input pin presses it, dragging turns it', (tester) async {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('raspi3d').path;
    Settings.reset();
    Settings.instance.set('raspi.3d', true);
    tester.view.physicalSize = const Size(900, 600);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    final dir = Directory.systemTemp.createTempSync('raspi_ui3d').path;
    File(p.join(dir, stateFile)).writeAsStringSync('18 out 1\n17 in 0 up');
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: RaspiPanel(dir: dir, running: true))));
    for (var i = 0; i < 20 && find.byKey(const Key('pin-11')).evaluate().isEmpty; i++) {
      await tester.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 100))); // reading the model and its texture
      await tester.pump(const Duration(milliseconds: 120));
    }
    expect(find.byType(Pi3DBoard), findsOneWidget);
    expect(find.text(piModelCredit), findsOneWidget);
    expect(find.byKey(const Key('pin-1')), findsOneWidget);
    expect(find.byKey(const Key('pin-40')), findsOneWidget);

    // GPIO 17 is physical pin 11: hold it on the 3D header.
    final hold = await tester.startGesture(tester.getCenter(find.byKey(const Key('pin-11'))));
    await tester.pump();
    expect(File(p.join(dir, inputFile)).readAsStringSync(), '17');
    await hold.up();
    await tester.pump();
    expect(File(p.join(dir, inputFile)).readAsStringSync(), '');

    final before = tester.getCenter(find.byKey(const Key('pin-12')));
    await tester.drag(find.byKey(const Key('pi3d')), const Offset(100, 30));
    await tester.pump();
    expect(tester.getCenter(find.byKey(const Key('pin-12'))), isNot(before)); // the pins turn with the board

    await tester.tap(find.text('2D'));
    await tester.pump();
    expect(find.byType(Pi3DBoard), findsNothing);
    expect(Settings.instance.get('raspi.3d', true), isFalse);
    await tester.pump(const Duration(seconds: 1)); // let the double-tap (reset view) timer run out
  });
}
