import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/web_design.dart';

void main() {
  test('rows become wrapping flex rows with their alignment, text escaped', () {
    final rows = [
      DesignRow([Block(BlockKind.heading, text: 'Hi <b>')], align: 'center'),
      DesignRow([Block(BlockKind.button), Block(BlockKind.input)], align: 'right'),
    ];
    final html = designToHtml(rows);
    expect(html, contains('<meta name="viewport" content="width=device-width, initial-scale=1">'));
    expect(html, contains('flex-wrap: wrap'));
    expect(html, contains('justify-content: center">\n    <h1 style="color: #222222">Hi &lt;b&gt;</h1>'));
    expect(html, contains('justify-content: flex-end">\n    <button>Click me</button>\n    <input placeholder="Type here">'));
  });

  test('design survives a JSON round trip; broken JSON starts empty', () {
    final rows = [DesignRow([Block(BlockKind.link, color: '#ff0000')], align: 'center')];
    final back = designFromJson(designToJson(rows));
    expect(designToHtml(back), designToHtml(rows));
    expect(designFromJson('not json'), isEmpty);
  });
}
