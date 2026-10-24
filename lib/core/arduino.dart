import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'otg.dart';
import 'toolchains.dart';

/// Arduino through the portable arduino-cli in `toolchains/arduino/` (Windows), or on phones
/// the bundled avr-gcc (`{tools}/avr/build.sh`) plus a Dart STK500 upload over USB OTG (otg.dart).
/// Verify/Upload/Serial Monitor all run through RunSession, so Upload automatically
/// stops a running Serial Monitor first: one owner of the COM port at a time.

/// [variant]/[define] feed the phone build; [otgBaud] is the bootloader speed for phone
/// uploads (null = not STK500v1, PC only).
typedef Board = ({String name, String fqbn, String variant, String define, int? otgBaud});
/// [fqbn]: the board on this port when it can be told (arduino-cli match / USB ID), else null.
typedef Port = ({String address, String label, String? fqbn});

/// The board for a detected [fqbn] (a Nano FQBN may carry a cpu option), else null.
Board? boardFor(String? fqbn) => fqbn == null ? null : boards.where((b) => b.fqbn == fqbn).firstOrNull;

/// Genuine boards by USB vendor:product ID. Clones (CH340 0x1a86:0x7523, CP2102...) all look
/// the same, so they stay unknown and the phone upload tries both bootloader speeds instead.
const usbBoards = {
  0x23410043: 'arduino:avr:uno', 0x23410001: 'arduino:avr:uno', 0x23410243: 'arduino:avr:uno', 0x2a030043: 'arduino:avr:uno',
  0x23410010: 'arduino:avr:mega', 0x23410042: 'arduino:avr:mega', 0x2a030010: 'arduino:avr:mega', 0x2a030042: 'arduino:avr:mega',
};

const boards = <Board>[
  (name: 'Arduino Uno', fqbn: 'arduino:avr:uno', variant: 'standard', define: 'AVR_UNO', otgBaud: 115200),
  (name: 'Arduino Nano', fqbn: 'arduino:avr:nano', variant: 'eightanaloginputs', define: 'AVR_NANO', otgBaud: 115200),
  // most cheap clones
  (name: 'Nano (old bootloader)', fqbn: 'arduino:avr:nano:cpu=atmega328old', variant: 'eightanaloginputs', define: 'AVR_NANO', otgBaud: 57600),
  (name: 'Arduino Mega 2560', fqbn: 'arduino:avr:mega', variant: 'mega', define: 'AVR_MEGA2560', otgBaud: null), // STK500v2
];

const _cli = 'arduino/arduino-cli';
const _cfg = ['--config-file', '{tools}/arduino/arduino-cli.yaml'];
const _compile = (tool: _cli, args: ['compile', ..._cfg, '--fqbn', '{fqbn}', '.']);

/// Vars: {fqbn}, {port}, {baud}. The sketch folder is the workspace `arduino/` (holds arduino.ino).
const verifySteps = [_compile];
const uploadSteps = [_compile, (tool: _cli, args: ['upload', ..._cfg, '-p', '{port}', '--fqbn', '{fqbn}', '.'])];
const monitorSteps = [(tool: _cli, args: ['monitor', ..._cfg, '-p', '{port}', '--config', 'baudrate={baud}'])];

/// Phone build (ATmega328P only): needs build/sketch.cpp from [sketchCpp]. Vars: {variant}, {board}.
const phoneBuildSteps = [(tool: '/system/bin/sh', args: ['{tools}/avr/build.sh', '{variant}', '{board}'])];
const phoneHex = 'build/arduino.ino.hex';

/// What arduino-cli does to a sketch before compiling: include Arduino.h and declare every
/// function just before the first one, so students can call helpers defined below loop().
/// ponytail: regex, not ctags: only signatures starting at column 0; others need a manual prototype.
String sketchCpp(String ino) {
  final sig = RegExp(r'^([A-Za-z_][\w \t\*&:<>,]*?[ \t\*&])(\w+)\s*\(([^;{}()=]*)\)\s*\{', multiLine: true);
  const notTypes = {'else', 'return', 'if', 'for', 'while', 'switch', 'do'};
  final defs = [
    for (final m in sig.allMatches(ino))
      if (!notTypes.contains(m[1]!.trim())) m,
  ];
  const head = '#include <Arduino.h>\n#line 1 "arduino.ino"\n';
  if (defs.isEmpty) return '$head$ino';
  final at = defs.first.start;
  final line = '\n'.allMatches(ino.substring(0, at)).length + 1;
  final protos = [for (final m in defs) '${m[1]!.trim()} ${m[2]}(${m[3]!.trim()});'];
  return '$head${ino.substring(0, at)}${protos.join(' ')}\n#line $line\n${ino.substring(at)}';
}

const bauds = [9600, 19200, 38400, 57600, 115200];

/// arduino-cli's folders, rebuilt from wherever the toolchains are right now
/// (paths inside arduino-cli.yaml would break when the USB drive letter changes).
Map<String, String> arduinoEnv(String toolsDir) => {
      for (final d in ['data', 'user', 'downloads']) 'ARDUINO_DIRECTORIES_${d.toUpperCase()}': p.join(toolsDir, 'arduino', d),
    };

/// Serial ports from `arduino-cli board list --format json`, detected boards named.
List<Port> parsePorts(String json) {
  try {
    final ports = (jsonDecode(json) as Map)['detected_ports'] as List? ?? const [];
    return [
      for (final d in ports.cast<Map>())
        if ((d['port'] as Map?)?['protocol'] == 'serial')
          (
            address: d['port']['address'] as String,
            label: [d['port']['address'], ...((d['matching_boards'] as List?) ?? const []).map((b) => b['name'])].join(' · '),
            fqbn: ((d['matching_boards'] as List?) ?? const []).firstOrNull?['fqbn'] as String?,
          ),
    ];
  } on FormatException {
    return const [];
  } on TypeError {
    return const [];
  }
}

Future<List<Port>> listPorts() async {
  if (Platform.isAndroid) return listOtgPorts();
  try {
    final exe = Toolchains.resolve(_cli, '');
    final r = await Process.run(exe, ['board', 'list', '--format', 'json', '--config-file', '${Toolchains.toolsDir}/arduino/arduino-cli.yaml'],
        environment: arduinoEnv(Toolchains.toolsDir));
    return parsePorts(r.stdout as String);
  } on ProcessException {
    return const [];
  }
}
