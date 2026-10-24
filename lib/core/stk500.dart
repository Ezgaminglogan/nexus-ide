import 'dart:async';
import 'dart:typed_data';

/// STK500v1, the protocol of the Uno's Optiboot and the old Nano bootloader, so phones can
/// upload over USB OTG without avrdude. Only what flashing needs: sync, enter, pages, leave.

const _eop = 0x20, _insync = 0x14, _ok = 0x10;
const pageSize = 128; // ATmega328P flash page (bytes)

/// Intel HEX -> flash image from address 0 (gaps 0xFF). Checks every record's checksum.
Uint8List parseHex(String text) {
  final out = <int>[];
  var base = 0;
  for (final raw in text.split('\n')) {
    final line = raw.trim();
    if (line.isEmpty) continue;
    if (!line.startsWith(':') || line.length.isEven) throw FormatException('Bad HEX line', line);
    final b = [for (var i = 1; i < line.length; i += 2) int.parse(line.substring(i, i + 2), radix: 16)];
    if (b.length != b[0] + 5) throw FormatException('Bad HEX record length', line);
    if (b.fold(0, (s, x) => s + x) & 0xFF != 0) throw FormatException('Bad HEX checksum', line);
    final data = b.sublist(4, b.length - 1);
    switch (b[3]) {
      case 0x00:
        final addr = base + (b[1] << 8 | b[2]);
        if (out.length < addr + data.length) out.addAll(List.filled(addr + data.length - out.length, 0xFF));
        out.setRange(addr, addr + data.length, data);
      case 0x01:
        return Uint8List.fromList(out);
      case 0x02:
        base = (data[0] << 8 | data[1]) << 4;
      case 0x04:
        base = (data[0] << 8 | data[1]) << 16;
    }
  }
  return Uint8List.fromList(out);
}

/// Load address: the bootloader counts flash in 16-bit words.
List<int> loadAddress(int byteAddr) => [0x55, (byteAddr >> 1) & 0xFF, (byteAddr >> 9) & 0xFF, _eop];

/// Program one flash page ('F' = flash).
List<int> progPage(List<int> data) => [0x64, data.length >> 8, data.length & 0xFF, 0x46, ...data, _eop];

/// Talks STK500v1 over any byte pipe ([write] out, [input] in), so tests can fake the board.
class Stk500 {
  Stk500(this._write, Stream<Uint8List> input) {
    _sub = input.listen((d) {
      _rx.addAll(d);
      _wake?.complete();
      _wake = null;
    });
  }

  final Future<void> Function(Uint8List) _write;
  late final StreamSubscription<Uint8List> _sub;
  final _rx = <int>[];
  Completer<void>? _wake;

  Future<void> close() => _sub.cancel();

  Future<List<int>> _read(int n, Duration timeout) async {
    final end = DateTime.now().add(timeout);
    while (_rx.length < n) {
      final left = end.difference(DateTime.now());
      if (left <= Duration.zero) throw TimeoutException('No reply from the board');
      _wake = Completer();
      await _wake!.future.timeout(left, onTimeout: () {});
    }
    final r = _rx.sublist(0, n);
    _rx.removeRange(0, n);
    return r;
  }

  Future<void> _cmd(List<int> c, {Duration timeout = const Duration(seconds: 1)}) async {
    await _write(Uint8List.fromList(c));
    final r = await _read(2, timeout);
    if (r[0] != _insync || r[1] != _ok) throw StateError('Board answered ${r.map((x) => x.toRadixString(16))} to 0x${c[0].toRadixString(16)}');
  }

  /// Get in sync with a freshly reset bootloader (it may still be printing junk at first).
  Future<void> sync({int tries = 10}) async {
    for (var i = 0; i < tries; i++) {
      _rx.clear();
      try {
        return await _cmd(const [0x30, _eop], timeout: const Duration(milliseconds: 300));
      } on TimeoutException {
        // retry
      } on StateError {
        // retry
      }
    }
    throw TimeoutException('Board not responding. Check the board type (Uno / Nano old bootloader) and the cable.');
  }

  /// Writes [image] page by page. [progress] gets 0..1.
  Future<void> flash(Uint8List image, {void Function(double)? progress}) async {
    await _cmd(const [0x50, _eop]); // enter programming mode
    for (var a = 0; a < image.length; a += pageSize) {
      await _cmd(loadAddress(a));
      final end = a + pageSize;
      await _cmd(progPage([...image.sublist(a, end.clamp(0, image.length)), ...List.filled((end - image.length).clamp(0, pageSize), 0xFF)]));
      progress?.call(end.clamp(0, image.length) / image.length);
    }
    await _cmd(const [0x51, _eop]); // leave: the bootloader starts the sketch
  }
}
