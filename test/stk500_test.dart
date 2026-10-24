import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/stk500.dart';

void main() {
  test('parseHex fills gaps with 0xFF, honours extended addresses, stops at EOF', () {
    const hex = ':0400000001020304F2\n'
        ':02000600AABB93\n' // data at 6..7, gap at 4..5
        ':020000021000EC\n' // extended segment base 0x10000
        ':01000000CC33\n'
        ':00000001FF\n'
        ':01000000DD22\n'; // after EOF: ignored
    final img = parseHex(hex);
    expect(img.sublist(0, 8), [1, 2, 3, 4, 0xFF, 0xFF, 0xAA, 0xBB]);
    expect(img.length, 0x10001);
    expect(img[0x10000], 0xCC);
  });

  test('parseHex rejects bad checksums and garbage', () {
    expect(() => parseHex(':0400000001020304F3'), throwsFormatException);
    expect(() => parseHex('hello'), throwsFormatException);
    expect(() => parseHex(':05000000010203F2'), throwsFormatException); // length byte lies
  });

  test('packet framing: word address, page header, EOP', () {
    expect(loadAddress(0x0180), [0x55, 0xC0, 0x00, 0x20]); // byte 0x180 = word 0xC0
    expect(loadAddress(0x7E00), [0x55, 0x00, 0x3F, 0x20]);
    final page = progPage(List.filled(128, 7));
    expect(page.sublist(0, 4), [0x64, 0x00, 0x80, 0x46]);
    expect(page.length, 4 + 128 + 1);
    expect(page.last, 0x20);
  });

  test('Stk500 syncs past junk, flashes padded pages, leaves', () async {
    final rx = StreamController<Uint8List>();
    final sent = <List<int>>[];
    var junk = 2; // first sync attempts get no answer, like a bootloader still starting
    final stk = Stk500((d) async {
      sent.add(d);
      if (d[0] == 0x30 && junk-- > 0) return;
      scheduleMicrotask(() => rx.add(Uint8List.fromList([0x14, 0x10])));
    }, rx.stream);

    await stk.sync();
    final image = Uint8List.fromList(List.generate(130, (i) => i & 0xFF)); // 2 pages, 2nd mostly padding
    final progress = <double>[];
    await stk.flash(image, progress: progress.add);
    await stk.close();

    final cmds = sent.where((c) => c[0] != 0x30).toList();
    expect(cmds.map((c) => c[0]), [0x50, 0x55, 0x64, 0x55, 0x64, 0x51]);
    expect(cmds[3], loadAddress(128));
    expect(cmds[4].sublist(4, 6), [128, 129]);
    expect(cmds[4].sublist(6, 132), everyElement(0xFF));
    expect(progress.last, 1.0);
  });

  test('Stk500 gives up with a helpful error when the board stays silent', () async {
    final stk = Stk500((_) async {}, const Stream.empty());
    await expectLater(stk.sync(tries: 2), throwsA(isA<TimeoutException>()));
  });
}
