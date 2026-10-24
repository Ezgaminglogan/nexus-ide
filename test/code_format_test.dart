import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/code_format.dart';

TextEditingValue at(String text, [int? caret]) =>
    TextEditingValue(text: text, selection: TextSelection.collapsed(offset: caret ?? text.length));

void main() {
  group('formatCode', () {
    test('re-indents a flat C program by brace depth', () {
      const flat = '#include <stdio.h>\nint main(void) {\nint n;   \nif (n > 0) {\nprintf("hi");\n}\nreturn 0;\n}';
      expect(formatCode(flat, braces: true),
          '#include <stdio.h>\nint main(void) {\n    int n;\n    if (n > 0) {\n        printf("hi");\n    }\n    return 0;\n}\n');
    });

    test('braces inside strings, chars and comments do not change depth', () {
      const src = 'void f() {\nprintf("{");\nchar c = \'}\';\n// }\n/* { */\nx();\n}';
      expect(formatCode(src, braces: true),
          'void f() {\n    printf("{");\n    char c = \'}\';\n    // }\n    /* { */\n    x();\n}\n');
    });

    test('collapses 3+ blank lines into one', () {
      expect(formatCode('a();\n\n\n\nb();', braces: true), 'a();\n\nb();\n');
    });

    test('python keeps its indentation, only trims', () {
      expect(formatCode('if x:   \n    print(1)\n\n\n\nprint(2)', braces: false),
          'if x:\n    print(1)\n\nprint(2)\n');
    });
  });

  group('formatCode markup', () {
    test('HTML indents by tags, CSS/JS braces nest inside, void tags and one-liners stay level', () {
      const flat = '<!DOCTYPE html>\n<html>\n<head>\n<meta charset="utf-8">\n<style>\nbody {\nmargin: 0;\n}\n</style>\n</head>\n'
          '<body>\n<!-- <div> in a comment -->\n<div class="cards">\n<p>Don\'t <b>stop</b></p>\n<img src="a.png">\n<br/>\n</div>\n'
          '<script>\nif (x) {\ngo();\n}\n</script>\n</body>\n</html>\n';
      expect(formatCode(flat, braces: true), '''<!DOCTYPE html>
<html>
    <head>
        <meta charset="utf-8">
        <style>
            body {
                margin: 0;
            }
        </style>
    </head>
    <body>
        <!-- <div> in a comment -->
        <div class="cards">
            <p>Don't <b>stop</b></p>
            <img src="a.png">
            <br/>
        </div>
        <script>
            if (x) {
                go();
            }
        </script>
    </body>
</html>
''');
    });

    test('PHP: code blocks by braces, echoed tags in strings balance out', () {
      const flat = '<?php\ntry {\n\$db = 1;\n} catch (Exception \$e) {\n}\n?>\n<ul>\n'
          "<?php foreach (\$g as \$x) echo '<li>' . \$x . '</li>'; ?>\n</ul>\n";
      expect(formatCode(flat, braces: true), '''<?php
try {
    \$db = 1;
} catch (Exception \$e) {
}
?>
<ul>
    <?php foreach (\$g as \$x) echo '<li>' . \$x . '</li>'; ?>
</ul>
''');
    });

    test('C stays brace-only (# lines at column 0, a < b is no tag)', () {
      expect(formatCode('#include <stdio.h>\nint main() {\nif (a<b) {\nx();\n}\n}\n', braces: true),
          '#include <stdio.h>\nint main() {\n    if (a<b) {\n        x();\n    }\n}\n');
    });
  });

  group('smartNewline', () {
    test('Enter after { indents one level deeper', () {
      final r = smartNewline(at('f() {x}', 5), at('f() {\nx}', 6))!;
      expect(r.text, 'f() {\n    x}');
      expect(r.selection.baseOffset, 10);
    });

    test('Enter after an unclosed { adds the } on its own line', () {
      final r = smartNewline(at('int main() {'), at('int main() {\n'))!;
      expect(r.text, 'int main() {\n    \n}');
      expect(r.selection.baseOffset, 'int main() {\n    '.length);
      final nested = smartNewline(at('void f() {\n    if (x) {', 23), at('void f() {\n    if (x) {\n', 24))!;
      expect(nested.text, 'void f() {\n    if (x) {\n        \n    }');
    });

    test('Enter keeps the current indent', () {
      final r = smartNewline(at('    int n;'), at('    int n;\n'))!;
      expect(r.text, '    int n;\n    ');
    });

    test('phone keyboard committing a word plus newline still indents', () {
      final r = smartNewline(at('    int n'), at('    int n;\n'))!;
      expect(r.text, '    int n;\n    ');
    });

    test('Enter between {} puts } on its own dedented line', () {
      final r = smartNewline(at('void f() {}', 10), at('void f() {\n}', 11))!;
      expect(r.text, 'void f() {\n    \n}');
      expect(r.selection.baseOffset, 15);
    });

    test('Enter after an opening tag indents; after a closed or void tag it does not', () {
      expect(smartNewline(at('<body>'), at('<body>\n'))!.text, '<body>\n    ');
      expect(smartNewline(at('    <p>hi</p>'), at('    <p>hi</p>\n'))!.text, '    <p>hi</p>\n    ');
      expect(smartNewline(at('    <br>'), at('    <br>\n'))!.text, '    <br>\n    ');
    });

    test('non-newline edits are left alone', () {
      expect(smartNewline(at('ab'), at('abc')), isNull);
    });
  });
}
