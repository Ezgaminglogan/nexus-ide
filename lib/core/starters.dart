import 'dart:io';

import 'package:path/path.dart' as p;

import 'settings.dart';
import 'toolchains.dart';
import 'workspace.dart' as ws;

/// Starter code for new files, Reset to Starter Code and the docs: one template system.
/// A template is picked from the file's extension AND its role in the project: the workspace's
/// main file gets the language's runnable template; every other file gets a skeleton that fits
/// next to it (no second main(), a Java class named like its file, a header guard from the name).

/// Where the cursor goes after a new file is created (removed from the text).
const _cursor = '\u{E000}';

class Starter {
  const Starter(this.id, this.label, this._build);
  final String id, label;
  final String Function(StarterContext c) _build;
}

/// The file a starter is being made for. [root] is the workspace folder (for linking the
/// stylesheets and scripts that already exist), or null when it doesn't matter.
class StarterContext {
  StarterContext(this.lang, this.rel, this.root);
  final Language lang;
  final String rel; // path inside the workspace, forward slashes
  final String? root;
  String get name => rel.split('/').last;
  String get ext => name.contains('.') ? name.substring(name.lastIndexOf('.') + 1).toLowerCase() : '';
  String get base => name.contains('.') ? name.substring(0, name.lastIndexOf('.')) : name;
  bool get isMain => rel == lang.fileName;

  /// [base] turned into a C/Java/C# identifier ("my-utils" -> "my_utils").
  String get ident {
    final s = base.replaceAll(RegExp(r'[^A-Za-z0-9_]'), '_');
    return RegExp(r'^[0-9]').hasMatch(s) ? '_$s' : s;
  }

  /// Workspace files with extension [e], as paths relative to this file's folder.
  List<String> siblings(String e) {
    if (root == null || !Directory(root!).existsSync()) return const [];
    final from = p.posix.dirname(rel);
    return [
      for (final f in Directory(root!).listSync(recursive: true).whereType<File>())
        if (f.path.toLowerCase().endsWith('.$e'))
          if (p.relative(f.path, from: root!).split(p.separator) case final parts when parts.every(ws.shown))
            p.posix.relative(parts.join('/'), from: from),
    ]..sort();
  }
}

/// The language a file is written in, for labels and messages; null when NEXUS has no template
/// for it (the file is created empty).
String? fileType(String rel, [Language? lang]) => switch (StarterContext(languages.first, rel, null).ext) {
      'c' => 'C',
      'h' => 'C header',
      'ino' => 'Arduino sketch',
      'py' => lang?.id == 'raspi' ? 'Raspberry Pi Python' : 'Python',
      'java' => 'Java',
      'cs' => 'C#',
      'html' || 'htm' => 'HTML',
      'css' => 'CSS',
      'js' => 'JavaScript',
      'php' => 'PHP',
      _ => null,
    };

String _mainLabel(Language lang) => switch (lang.id) {
      'c' => 'C console program',
      'arduino' => 'Arduino sketch: setup() and loop()',
      'raspi' => 'Raspberry Pi GPIO program',
      'python' => 'Python program',
      'java' => 'Java program: class Main with main()',
      'csharp' => 'C# console program: class Program with Main()',
      'web' => 'HTML page',
      'php' => 'PHP page with MySQL',
      _ => '${lang.label} program',
    };

/// The templates that fit [rel] in [lang]'s workspace, the usual one first. Empty: none (unknown type).
List<Starter> startersFor(Language lang, String rel) {
  final c = StarterContext(lang, rel, null);
  if (c.isMain) return [Starter('main', _mainLabel(lang), (c) => c.lang.template)];
  return switch (c.ext) {
    'c' => const [Starter('c-source', 'C source file: functions, no main()', _cSource)],
    'h' => const [Starter('c-header', 'C header: include guard and declarations', _cHeader)],
    'ino' => const [Starter('ino-tab', 'Sketch tab: helper functions (setup() and loop() stay in the main sketch)', _inoTab)],
    'py' when lang.id == 'raspi' => const [
        Starter('raspi-module', 'GPIO helper module (RPi.GPIO)', _raspiModule),
        Starter('py-script', 'General Python script', _pyScript),
      ],
    'py' => const [Starter('py-script', 'Python script with a main() function', _pyScript)],
    'java' => const [Starter('java-class', 'Java class named like the file', _javaClass)],
    'cs' => const [Starter('cs-class', 'C# class (Program.cs keeps the only Main)', _csClass)],
    'html' || 'htm' => const [Starter('html-page', 'HTML page: head, title and body', _htmlPage)],
    'css' => const [Starter('css', 'Stylesheet', _css)],
    'js' => const [Starter('js', 'Page script (runs when the page has loaded)', _js)],
    'php' => [
        if (RegExp(r'db|database|config|connect', caseSensitive: false).hasMatch(c.base))
          const Starter('php-db', 'Database connection (mysqli)', _phpDb),
        const Starter('php-page', 'PHP page with HTML', _phpPage),
        if (!RegExp(r'db|database|config|connect', caseSensitive: false).hasMatch(c.base))
          const Starter('php-db', 'Database connection (mysqli)', _phpDb),
      ],
    _ => const [],
  };
}

/// The starter text for [rel] and where the cursor should go. [id] picks one of [startersFor]
/// (unknown or null: the usual one). Null when the type has no template.
({String text, int cursor})? starterCode(Language lang, String rel, {String? id, String? root}) {
  final options = startersFor(lang, rel);
  if (options.isEmpty) return null;
  final s = options.firstWhere((s) => s.id == id, orElse: () => options.first);
  final raw = s._build(StarterContext(lang, rel, root));
  final at = raw.indexOf(_cursor);
  return (text: raw.replaceAll(_cursor, ''), cursor: at < 0 ? 0 : at);
}

/// Just the text (Reset, docs). Null when the type has no template.
String? starterFor(Language lang, String rel, {String? id, String? root}) => starterCode(lang, rel, id: id, root: root)?.text;

// ---- which template each file was made from (so Reset puts back the same kind) ----

Settings get _records => Settings.named('starters');
String _key(Language lang, String rel) => '${lang.dir}:$rel';

String? starterId(Language lang, String rel) => _records.get<String?>(_key(lang, rel), null);
void recordStarter(Language lang, String rel, String? id) => _records.set(_key(lang, rel), id);

/// A file or folder was renamed: its records follow it (the template is rebuilt from the new name).
void moveStarterRecords(Language lang, String from, String to) {
  for (final rel in [from, for (final k in _records.keys) if (k.startsWith(_key(lang, '$from/'))) k.substring(_key(lang, '').length)]) {
    final id = starterId(lang, rel);
    if (id == null) continue;
    recordStarter(lang, rel, null);
    recordStarter(lang, to + rel.substring(from.length), id);
  }
}

void forgetStarterRecords(Language lang, String rel) {
  for (final k in _records.keys.where((k) => k == _key(lang, rel) || k.startsWith(_key(lang, '$rel/'))).toList()) {
    _records.set(k, null);
  }
}

// ---- the templates ----

String _cSource(StarterContext c) {
  final header = c.siblings('h').contains('${c.base}.h') ? '#include "${c.base}.h"\n' : '';
  return '#include <stdio.h>\n$header\n'
      '/* ${c.name}: functions for main.c. NEXUS compiles every .c file in the project together,\n'
      '   so main.c keeps the only entry point. Declare these functions in a header (${c.base}.h)\n'
      '   and #include it in main.c. */\n\n$_cursor';
}

String _cHeader(StarterContext c) {
  final guard = '${c.ident.toUpperCase()}_H';
  return '#ifndef $guard\n#define $guard\n\n/* Declarations: one line per function defined in ${c.base}.c, for example\n'
      '   int add(int a, int b); */\n$_cursor\n\n#endif /* $guard */\n';
}

String _inoTab(StarterContext c) => '// ${c.name}: a tab of this sketch. Arduino joins every .ino file in the folder,\n'
    '// so setup() and loop() stay in ${c.lang.fileName}; put helper functions here.\n\n$_cursor';

String _pyScript(StarterContext c) => '"""${c.name}: import it from main.py with  import ${c.ident}"""\n\n\n'
    'def main():\n    $_cursor\n    pass\n\n\nif __name__ == "__main__":\n    main()\n';

String _raspiModule(StarterContext c) => '"""${c.name}: GPIO helpers for main.py (use: import ${c.ident}).\n'
    'Pins are BCM (GPIO) numbers; main.py calls GPIO.setmode(GPIO.BCM) first."""\n'
    'import RPi.GPIO as GPIO\n\n\ndef setup_led(pin):\n    GPIO.setup(pin, GPIO.OUT)\n\n\n'
    'def set_led(pin, on):\n    GPIO.output(pin, GPIO.HIGH if on else GPIO.LOW)\n$_cursor';

String _javaClass(StarterContext c) => 'public class ${c.base} {\n    $_cursor\n}\n';

String _csClass(StarterContext c) => 'using System;\n\nclass ${c.ident}\n{\n    $_cursor\n}\n';

String _htmlPage(StarterContext c) {
  final css = c.siblings('css'), js = c.siblings('js');
  return '<!DOCTYPE html>\n<html lang="en">\n<head>\n    <meta charset="utf-8">\n'
      '    <meta name="viewport" content="width=device-width, initial-scale=1">\n    <title>${c.base}</title>\n'
      '${css.map((f) => '    <link rel="stylesheet" href="$f">\n').join()}'
      '</head>\n<body>\n    <h1>${c.base}</h1>\n    $_cursor\n'
      '${js.map((f) => '    <script src="$f"></script>\n').join()}'
      '</body>\n</html>\n';
}

String _css(StarterContext c) => '/* ${c.name} */\n\nbody {\n    font-family: sans-serif;\n    $_cursor\n}\n';

String _js(StarterContext c) => '// ${c.name}: load it with <script src="${c.name}"></script> at the end of <body>.\n\n'
    'document.addEventListener("DOMContentLoaded", () => {\n    $_cursor\n});\n';

String _phpPage(StarterContext c) => '<?php\n// ${c.name}\n\$title = "${c.base}";\n?>\n<!DOCTYPE html>\n<html lang="en">\n<head>\n'
    '    <meta charset="utf-8">\n    <meta name="viewport" content="width=device-width, initial-scale=1">\n'
    '    <title><?= htmlspecialchars(\$title) ?></title>\n</head>\n<body>\n    <h1><?= htmlspecialchars(\$title) ?></h1>\n    $_cursor\n</body>\n</html>\n';

String _phpDb(StarterContext c) => '<?php\n// ${c.name}: the database connection. Use it in a page with  require __DIR__ . \'/${c.name}\';\n'
    '// NEXUS settings: host 127.0.0.1, user root, no password, database nexus.\n'
    'mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);\n'
    '\$db = new mysqli("127.0.0.1", "root", "", "nexus");\n\$db->set_charset("utf8mb4");\n$_cursor';
