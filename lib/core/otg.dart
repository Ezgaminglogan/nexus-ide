import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:usb_serial/usb_serial.dart';

import 'arduino.dart' show Port, usbBoards;
import 'run_session.dart';
import 'stk500.dart';

/// Arduino over USB OTG on phones: upload (STK500v1) and Serial Monitor through usb_serial.
/// Android asks the student to allow USB access the first time each board is opened.

Future<List<Port>> listOtgPorts() async {
  try {
    return [
      for (final d in await UsbSerial.listDevices())
        (
          address: '${d.deviceId}',
          label: d.productName ?? 'USB ${d.vid?.toRadixString(16)}:${d.pid?.toRadixString(16)}',
          fqbn: usbBoards[((d.vid ?? 0) << 16) | (d.pid ?? 0)],
        ),
    ];
  } on Exception {
    return const [];
  }
}

Future<UsbPort> _open(String address, int baud) async {
  final port = await UsbSerial.createFromDeviceId(int.tryParse(address));
  if (port == null || !await port.open()) {
    throw 'Cannot open the board. Allow USB access when Android asks, then try again.';
  }
  await port.setPortParameters(baud, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
  return port;
}

/// Resets the board into its bootloader (DTR/RTS pulse, like avrdude) and flashes [hexPath].
/// Tries each of [bauds] in turn: clone Nanos ship with either bootloader (57600 or 115200).
DartStep otgUpload(String address, List<int> bauds, String hexPath) => (s, stopped) async {
      final image = parseHex(await File(hexPath).readAsString());
      final port = await _open(address, bauds.first);
      final stk = Stk500(port.write, port.inputStream!);
      try {
        for (final (i, baud) in bauds.indexed) {
          await port.setPortParameters(baud, UsbPort.DATABITS_8, UsbPort.STOPBITS_1, UsbPort.PARITY_NONE);
          await port.setDTR(false);
          await port.setRTS(false);
          await Future.delayed(const Duration(milliseconds: 250));
          await port.setDTR(true);
          await port.setRTS(true);
          await Future.delayed(const Duration(milliseconds: 50));
          try {
            await stk.sync(tries: 5);
            if (i > 0) s.console.add('Bootloader answered at $baud baud.\n');
            break;
          } on TimeoutException {
            if (i == bauds.length - 1) rethrow;
          }
        }
        var shown = -1;
        await stk.flash(image, progress: (f) {
          final pct = (f * 10).floor() * 10;
          if (pct == shown) return;
          shown = pct;
          s.console.add('$pct% ');
        });
        s.console.add('\n✓ Uploaded ${image.length} bytes\n');
      } finally {
        await stk.close();
        await port.close();
      }
    };

/// Shows what the board prints and sends typed lines, until Stop.
DartStep otgMonitor(String address, int baud) => (s, stopped) async {
      final port = await _open(address, baud);
      await port.setDTR(true); // like the PC monitor: the board restarts, so setup() output shows
      await port.setRTS(true);
      final sub = const Utf8Decoder(allowMalformed: true).bind(port.inputStream!).listen(s.console.add);
      s.input = (line) => port.write(Uint8List.fromList(utf8.encode('$line\n')));
      try {
        await stopped;
      } finally {
        await sub.cancel();
        await port.close();
      }
    };
