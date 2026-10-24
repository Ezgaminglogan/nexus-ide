import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';

void main() {
  test('parsePorts lists serial ports, naming detected boards', () {
    const json = '''
{
  "detected_ports": [
    {
      "matching_boards": [{"name": "Arduino Uno", "fqbn": "arduino:avr:uno"}],
      "port": {"address": "COM3", "label": "COM3", "protocol": "serial", "protocol_label": "Serial Port (USB)"}
    },
    {
      "port": {"address": "COM5", "label": "COM5", "protocol": "serial", "protocol_label": "Serial Port (USB)"}
    },
    {
      "port": {"address": "192.168.1.9", "label": "esp", "protocol": "network"}
    }
  ]
}''';
    expect(parsePorts(json), [
      (address: 'COM3', label: 'COM3 · Arduino Uno', fqbn: 'arduino:avr:uno'),
      (address: 'COM5', label: 'COM5', fqbn: null),
    ]);
  });

  test('parsePorts on no boards or bad output returns empty', () {
    expect(parsePorts('{"detected_ports": []}'), isEmpty);
    expect(parsePorts('not json'), isEmpty);
  });

  test('arduino-cli folders follow the toolchain folder (USB drive letter can change)', () {
    Toolchains.toolsDir = r'E:\nexus\toolchains';
    final env = arduinoEnv(Toolchains.toolsDir);
    expect(env['ARDUINO_DIRECTORIES_DATA'], startsWith(r'E:\nexus\toolchains'));
    expect(env['ARDUINO_DIRECTORIES_USER'], startsWith(r'E:\nexus\toolchains'));
    expect(env['ARDUINO_DIRECTORIES_DOWNLOADS'], startsWith(r'E:\nexus\toolchains'));
    final ino = languages.firstWhere((l) => l.id == 'arduino');
    expect(Toolchains.envFor(ino, 'arduino-cli')['ARDUINO_DIRECTORIES_DATA'], env['ARDUINO_DIRECTORIES_DATA']);
  });

  test('boards include Uno, Nano, Nano (old bootloader), Mega with exact FQBNs', () {
    expect(boards.map((b) => b.fqbn), [
      'arduino:avr:uno',
      'arduino:avr:nano',
      'arduino:avr:nano:cpu=atmega328old',
      'arduino:avr:mega',
    ]);
  });

  test('sketchCpp declares helpers before the first function, keeps line numbers', () {
    const ino = '#define LED 13\nstruct P { int x; };\n\nvoid setup() {\n  blink(LED);\n}\n\nvoid loop() {}\n\n'
        'void blink(int pin) {\n  if (pin) {\n  }\n}\nP make(const char *s,\n    int n) {\n  return P{n};\n}\n';
    final cpp = sketchCpp(ino);
    expect(cpp, startsWith('#include <Arduino.h>\n#line 1 "arduino.ino"\n#define LED 13\nstruct P { int x; };\n\n'));
    expect(cpp, contains('void setup(); void loop(); void blink(int pin); P make(const char *s,\n    int n);\n#line 4\nvoid setup() {'));
    expect(cpp, isNot(contains('if (pin);')));
    expect(sketchCpp('int x;\n'), '#include <Arduino.h>\n#line 1 "arduino.ino"\nint x;\n');
  });

  test('phone build: every STK500 board has a variant; Mega stays PC-only', () {
    expect(boards.where((b) => b.otgBaud != null).map((b) => b.otgBaud), [115200, 115200, 57600]);
    expect(boards.last.otgBaud, isNull);
  });

  test('board auto-detect: genuine USB IDs and arduino-cli FQBNs pick the board, clones stay unknown', () {
    expect(boardFor(usbBoards[0x23410043])!.name, 'Arduino Uno');
    expect(boardFor(usbBoards[0x2a030042])!.name, 'Arduino Mega 2560');
    expect(usbBoards[0x1a867523], isNull); // CH340 clone
    expect(boardFor(null), isNull);
    expect(boardFor('arduino:avr:nano:cpu=atmega328old')!.otgBaud, 57600);
  });
}

