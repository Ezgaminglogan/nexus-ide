import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/raspi.dart';
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
}
