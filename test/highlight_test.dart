import 'package:flutter_test/flutter_test.dart';
import 'package:highlight/highlight_core.dart';
import 'package:highlight/languages/xml.dart';
import 'package:nexus_ide/core/toolchains.dart';

/// Every highlight class used anywhere in [nodes].
Set<String> classes(List<Node>? nodes) => {
      for (final n in nodes ?? const <Node>[]) ...{?n.className, ...classes(n.children)},
    };

void main() {
  test('.php/.html (xml mode, as main.dart registers it): HTML and the PHP inside it are highlighted', () {
    registerHighlighting();
    highlight.registerLanguage('xml', xml);
    const page = '<?php \$n = 1; echo "hi"; ?>\n<style>body { color: red; }</style>\n<script>let x = 1;</script>\n<p class="a">Hi</p>';
    final found = classes(highlight.parse(page, language: 'xml').nodes);
    expect(found, containsAll(['tag', 'name', 'attr', 'string'])); // HTML
    expect(found, contains('php')); // the <?php ?> block went to the PHP grammar
    expect(found, contains('keyword')); // echo inside <?php ?>
  });
}
