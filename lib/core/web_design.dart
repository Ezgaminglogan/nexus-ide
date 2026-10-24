import 'dart:convert';

/// The Web tile's drag-and-drop page: rows of blocks, turned into a responsive index.html.
/// Rows wrap on small screens (flex-wrap), so the same page works on phones and PCs.

enum BlockKind { heading, text, button, input, image, link }

class Block {
  Block(this.kind, {String? text, this.color = '#222222'}) : text = text ?? _defaults[kind]!;
  final BlockKind kind;
  String text; // label, placeholder, image URL or link text
  String color;

  static const _defaults = {
    BlockKind.heading: 'My Heading',
    BlockKind.text: 'Write something here.',
    BlockKind.button: 'Click me',
    BlockKind.input: 'Type here',
    BlockKind.image: 'image.png', // offline: a file in the web folder (or a link when online)
    BlockKind.link: 'Visit CTU',
  };

  Map<String, Object> toJson() => {'kind': kind.name, 'text': text, 'color': color};
  factory Block.fromJson(Map<String, dynamic> j) =>
      Block(BlockKind.values.byName(j['kind'] as String), text: j['text'] as String, color: j['color'] as String);
}

class DesignRow {
  DesignRow(this.blocks, {this.align = 'left'});
  final List<Block> blocks;
  String align; // left | center | right

  Map<String, Object> toJson() => {'align': align, 'blocks': [for (final b in blocks) b.toJson()]};
  factory DesignRow.fromJson(Map<String, dynamic> j) =>
      DesignRow([for (final b in j['blocks'] as List) Block.fromJson(b as Map<String, dynamic>)], align: j['align'] as String);
}

String designToJson(List<DesignRow> rows) => const JsonEncoder.withIndent(' ').convert([for (final r in rows) r.toJson()]);

List<DesignRow> designFromJson(String s) {
  try {
    return [for (final r in jsonDecode(s) as List) DesignRow.fromJson(r as Map<String, dynamic>)];
  } on Object {
    return []; // missing or hand-broken design.json: start empty
  }
}

String _esc(String s) => const HtmlEscape().convert(s);

String _block(Block b) {
  final t = _esc(b.text), c = 'style="color: ${_esc(b.color)}"';
  return switch (b.kind) {
    BlockKind.heading => '<h1 $c>$t</h1>',
    BlockKind.text => '<p $c>$t</p>',
    BlockKind.button => '<button>$t</button>',
    BlockKind.input => '<input placeholder="$t">',
    BlockKind.image => '<img src="$t" alt="$t">',
    BlockKind.link => '<a href="#" $c>$t</a>',
  };
}

String designToHtml(List<DesignRow> rows) {
  const justify = {'left': 'flex-start', 'center': 'center', 'right': 'flex-end'};
  final body = [
    for (final r in rows)
      '  <div class="row" style="justify-content: ${justify[r.align] ?? 'flex-start'}">\n'
          '${[for (final b in r.blocks) '    ${_block(b)}'].join('\n')}\n  </div>',
  ].join('\n');
  return '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>My Page</title>
  <!-- Made with the NEXUS designer: rows wrap on small screens. -->
  <style>
    body { font-family: sans-serif; margin: 0; padding: 16px; }
    .row { display: flex; flex-wrap: wrap; align-items: center; gap: 12px; margin-bottom: 12px; }
    h1, p { margin: 0; }
    img { max-width: 100%; border-radius: 8px; }
    button { padding: 10px 16px; border: 0; border-radius: 8px; background: #3B6BFF; color: white; }
    input { padding: 10px; border: 1px solid #ccc; border-radius: 8px; }
  </style>
</head>
<body>
$body
</body>
</html>
''';
}
