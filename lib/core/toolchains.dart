import 'dart:io';

import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter/services.dart';
import 'package:highlight/highlight_core.dart' show Mode;
import 'package:highlight/languages/cpp.dart';
import 'package:highlight/languages/cs.dart';
import 'package:highlight/languages/java.dart';
import 'package:highlight/languages/php.dart';
import 'package:highlight/languages/python.dart';
import 'package:highlight/languages/xml.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'arduino.dart';

/// One command. [tool] is relative to [Toolchains.toolsDir] (no .exe),
/// or `./name` for a program built inside the workspace.
/// `{tools}` inside [args] is replaced with [Toolchains.toolsDir].
typedef Step = ({String tool, List<String> args});

class Language {
  const Language({
    required this.id,
    required this.label,
    required this.fileName,
    required this.mode,
    required this.template,
    required this.steps,
    this.androidSteps,
    this.extraFiles = const {},
    this.env,
    this.words = const [],
    this.color = 0xFF3B6BFF,
    this.blurb = '',
  });

  final String id, label, fileName, template;
  final Mode mode; // syntax highlighting + keyword autocomplete
  final List<Step> steps; // run in order, stop at first failure; last one is interactive
  final List<Step>? androidSteps; // Termux pack layout on phones; null = not available there
  final Map<String, String> extraFiles; // written into the workspace if missing
  final Map<String, String> Function(String toolsDir)? env;
  final List<String> words; // extra autocomplete (std library names)
  final String blurb; // home tile: one-line description
  final int color; // home tile / editor accent (ARGB)

  bool get braces => id != 'python';

  /// iPhones forbid running compilers (Apple's rule), so only the Web tile works there;
  /// Android needs [androidSteps].
  bool get availableHere => Platform.isIOS ? id == 'web' : !(Platform.isAndroid && androidSteps == null); // Format re-indents by braces except for Python
}

/// Where toolchains and student files live.
///
/// Windows (USB drive): `<exe dir>/toolchains/...` and `<exe dir>/workspace/<lang>/`
/// Android:             `<app support dir>/toolchains/...` and `.../workspace/<lang>/`
class Toolchains {
  static String toolsDir = 'toolchains';
  static String workRoot = 'workspace';

  static Future<void> init() async {
    if (Platform.isAndroid) {
      final base = (await getApplicationSupportDirectory()).path;
      toolsDir = p.join(base, 'toolchains');
      workRoot = p.join(base, 'workspace');
      Directory(p.join(workRoot, '.tmp', 'dalvik-cache')).createSync(recursive: true); // dalvikvm (Java) caches here
      try {
        // MainActivity.kt unzips the bundled Termux pack here (first launch / after updates only).
        // ponytail: blocks startup on first launch while unzipping; show progress if packs get big.
        toolsDir = await const MethodChannel('nexus/toolchains').invokeMethod<String>('install') ?? toolsDir;
      } on PlatformException catch (e) {
        debugPrint('[NEXUS] toolchain unpack failed: ${e.message}'); // Run then reports the missing tool
      }
      return;
    }
    var base = File(Platform.resolvedExecutable).parent.path;
    // `flutter run` puts the exe under build/; use the project folder's toolchains during dev.
    if (!Directory(p.join(base, 'toolchains')).existsSync() &&
        Directory(p.join(Directory.current.path, 'toolchains')).existsSync()) {
      base = Directory.current.path;
    }
    toolsDir = p.join(base, 'toolchains');
    workRoot = p.join(base, 'workspace');
  }

  static String get _ext => Platform.isWindows ? '.exe' : '';

  static String bundledPath(String tool) => p.join(toolsDir, tool + _ext);

  /// Bundled tool if present, otherwise the bare name so PATH can find it (dev machines).
  static String resolve(String tool, String workDir) {
    if (tool.startsWith('./')) return p.join(workDir, tool.substring(2) + _ext);
    final bundled = bundledPath(tool);
    return File(bundled).existsSync() ? bundled : p.basename(tool);
  }

  /// The steps for this platform (or [steps], e.g. an Arduino action), with `{tools}` and
  /// each `{name}` from [vars] filled in.
  static List<Step> stepsFor(Language lang, {List<Step>? steps, Map<String, String> vars = const {}}) {
    if (!lang.availableHere) return const [];
    String fill(String a) => vars.entries.fold(a.replaceAll('{tools}', toolsDir), (s, e) => s.replaceAll('{${e.key}}', e.value));
    return [
      for (final s in steps ?? (Platform.isAndroid ? lang.androidSteps ?? const <Step>[] : lang.steps))
        (tool: s.tool, args: [for (final a in s.args) fill(a)]),
    ];
  }

  /// Puts the tool's own folder first on PATH (MinGW DLLs, cc1/as/ld lookup).
  static Map<String, String> envFor(Language lang, String exe) {
    final env = <String, String>{
      ...?lang.env?.call(toolsDir),
      if (Platform.isAndroid) ...{
        'LD_LIBRARY_PATH': p.join(toolsDir, 'lib'), // Termux binaries look in Termux's lib dir otherwise
        'PYTHONHOME': toolsDir, // same for Python's standard library
        'TMPDIR': p.join(workRoot, '.tmp'),
        'HOME': workRoot,
        'ANDROID_DATA': p.join(workRoot, '.tmp'),
        'MONO_PATH': p.join(toolsDir, 'lib', 'mono', '4.5'), // the pack keeps no gac copies
      },
    };
    if (p.isAbsolute(exe)) {
      final sep = Platform.isWindows ? ';' : ':';
      env['PATH'] = '${p.dirname(exe)}$sep${Platform.environment['PATH'] ?? ''}';
    }
    return env;
  }
}

/// Makes printf show before scanf when stdout is a pipe (C fully buffers pipes).
const _unbufHeader = '''
#include <stdio.h>
__attribute__((constructor)) static void nexus_unbuf(void) { setvbuf(stdout, NULL, _IONBF, 0); }
''';

// Must match the bundled .NET SDK major: offline builds only have its own targeting pack.
const _csproj = '''
<Project Sdk="Microsoft.NET.Sdk">
  <PropertyGroup>
    <OutputType>Exe</OutputType>
    <TargetFramework>net10.0</TargetFramework>
    <ImplicitUsings>enable</ImplicitUsings>
    <Nullable>disable</Nullable>
  </PropertyGroup>
</Project>
''';

final languages = <Language>[
  Language(
    id: 'c',
    color: 0xFF3B6BFF,
    blurb: 'Programming fundamentals',
    label: 'C',
    fileName: 'main.c',
    mode: cpp,
    template: '#include <stdio.h>\n\nint main(void) {\n    printf("Hello, CTU Naga!\\n");\n    return 0;\n}\n',
    steps: [
      (tool: 'mingw/bin/gcc', args: ['-include', 'nexus_unbuf.h', 'main.c', '-o', 'main']),
      (tool: './main', args: []),
    ],
    // Termux's tcc has Termux paths baked in, so switch its defaults off and pass every path.
    androidSteps: [
      (tool: 'bin/tcc', args: [
        '-D__ANDROID_API__=24', '-D__ANDROID_MIN_SDK_VERSION__=24', // = app minSdk; NDK headers require it
        '-nostdinc', '-I{tools}/include/aarch64-linux-android', '-I{tools}/include', '-I{tools}/lib/tcc/include',
        '-nostdlib', '-L{tools}/lib', '{tools}/lib/tcc/crt/crtbegin_dynamic.o',
        '-include', 'nexus_unbuf.h', 'main.c',
        '{tools}/lib/tcc/libtcc1.a', '-lc', '-lm', '-ldl', '{tools}/lib/tcc/crt/crtend_android.o',
        '-o', 'main',
      ]),
      (tool: './main', args: []),
    ],
    extraFiles: {'nexus_unbuf.h': _unbufHeader},
    words: ['printf', 'scanf', 'puts', 'fgets', 'getchar', 'malloc', 'calloc', 'free', 'strlen', 'strcpy', 'strcmp', 'strcat', 'sizeof', 'NULL', 'EOF'],
  ),
  Language(
    id: 'arduino',
    color: 0xFF00979D,
    blurb: 'Sketch · Verify · Upload',
    label: 'Arduino',
    fileName: 'arduino.ino', // arduino-cli needs the sketch file named like its folder
    mode: cpp,
    template: '// Blink: the LED on pin 13 turns on and off every second.\n\n'
        'void setup() {\n    pinMode(LED_BUILTIN, OUTPUT);\n    Serial.begin(9600);\n}\n\n'
        'void loop() {\n    digitalWrite(LED_BUILTIN, HIGH);\n    Serial.println("LED on");\n    delay(1000);\n'
        '    digitalWrite(LED_BUILTIN, LOW);\n    Serial.println("LED off");\n    delay(1000);\n}\n',
    steps: verifySteps, // the editor's Arduino bar also offers Upload and Serial Monitor
    androidSteps: phoneBuildSteps, // Uno/Nano: bundled avr-gcc, upload over USB OTG (otg.dart)
    env: arduinoEnv,
    words: ['pinMode', 'digitalWrite', 'digitalRead', 'analogRead', 'analogWrite', 'delay', 'millis',
        'Serial', 'begin', 'println', 'print', 'available', 'read', 'HIGH', 'LOW', 'INPUT', 'OUTPUT',
        'INPUT_PULLUP', 'LED_BUILTIN', 'setup', 'loop', 'map', 'constrain', 'tone', 'noTone'],
  ),
  Language(
    id: 'python',
    color: 0xFFF2C230,
    blurb: 'Scripts and data',
    label: 'Python',
    fileName: 'main.py',
    mode: python,
    template: 'print("Hello, CTU Naga!")\n',
    steps: [
      (tool: 'python/python', args: ['-u', 'main.py']),
    ],
    androidSteps: [
      (tool: 'bin/python3', args: ['-u', 'main.py']),
    ],
    words: ['print', 'input', 'range', 'len', 'int', 'float', 'str', 'list', 'dict', 'enumerate'],
  ),
  Language(
    id: 'java',
    color: 0xFFE76F00,
    blurb: 'Object-oriented',
    label: 'Java',
    fileName: 'Main.java',
    mode: java,
    template: 'public class Main {\n    public static void main(String[] args) {\n        System.out.println("Hello, CTU Naga!");\n    }\n}\n',
    steps: [
      // JDK 11+ single-file launch: compiles in memory, no separate javac step.
      (tool: 'jdk/bin/java', args: ['Main.java']),
    ],
    // Phones: Termux's ecj compiler + dx, run on Android's own Java VM (no JDK to bundle).
    androidSteps: [
      (tool: _dalvikvm, args: ['-Xmx256m', '-cp', '{tools}/share/dex/ecj.jar', 'org.eclipse.jdt.internal.compiler.batch.Main',
          '-proc:none', '-8', '-nowarn', '-cp', '{tools}/share/java/android.jar', '-d', 'classes', 'Main.java']),
      // Android 14+ only loads read-only dex files, so main.dex is replaced, then locked.
      (tool: '/system/bin/rm', args: ['-f', 'main.dex']),
      (tool: _dalvikvm, args: ['-Xmx256m', '-cp', '{tools}/share/dex/dx.jar', 'dx.dx.command.Main',
          '--dex', '--min-sdk-version=26', '--output=main.dex', 'classes']),
      (tool: '/system/bin/chmod', args: ['444', 'main.dex']),
      (tool: _dalvikvm, args: ['-cp', 'main.dex', 'Main']),
    ],
    words: ['System', 'println', 'print', 'Scanner', 'nextInt', 'nextLine', 'String', 'ArrayList'],
  ),
  Language(
    id: 'csharp',
    color: 0xFF8E5BD8,
    blurb: '.NET console apps',
    label: 'C#',
    fileName: 'Program.cs',
    mode: cs,
    // Classic Main, not top-level statements: phones compile with Mono's mcs, which predates them.
    template: 'using System;\n\nclass Program {\n    static void Main() {\n        Console.WriteLine("Hello, CTU Naga!");\n    }\n}\n',
    steps: [
      (tool: 'dotnet/dotnet', args: ['run']),
    ],
    androidSteps: [
      (tool: 'bin/mono', args: ['{tools}/lib/mono/4.5/mcs.exe', '-nologo', 'Program.cs', '-out:main.exe']),
      (tool: 'bin/mono', args: ['main.exe']),
    ],
    extraFiles: {'nexus.csproj': _csproj},
    env: (tools) => {
      'DOTNET_CLI_HOME': p.join(tools, 'dotnet-home'), // keep lab PC profiles untouched
      'NUGET_PACKAGES': p.join(tools, 'nuget'),
      'DOTNET_NOLOGO': '1',
      'DOTNET_CLI_TELEMETRY_OPTOUT': '1',
      'DOTNET_SKIP_FIRST_TIME_EXPERIENCE': '1',
      // No lingering MSBuild/VBCSCompiler processes locking the USB drive.
      'MSBUILDDISABLENODEREUSE': '1',
      'DOTNET_CLI_USE_MSBUILD_SERVER': '0',
      'UseSharedCompilation': 'false',
    },
    words: ['Console', 'WriteLine', 'ReadLine', 'Write', 'string', 'int.Parse', 'List', 'Math'],
  ),
  Language(
    id: 'web',
    color: 0xFFE44D26,
    blurb: 'HTML · CSS · JS · Designer',
    label: 'Web',
    fileName: 'index.html',
    mode: xml,
    template: _webTemplate,
    steps: const [], // no compiler: the editor shows the page (web_preview.dart)
    androidSteps: const [],
    words: ['div', 'section', 'header', 'footer', 'button', 'input', 'class', 'style', 'display', 'flex', 'grid',
        'margin', 'padding', 'color', 'background', 'document', 'querySelector', 'addEventListener', 'console'],
  ),
  Language(
    id: 'php',
    color: 0xFF777BB4,
    blurb: 'Server pages · MySQL',
    label: 'PHP',
    fileName: 'index.php',
    mode: php,
    template: _phpTemplate,
    // Serves the folder at [phpUrl] until Stop. PC: portable PHP in toolchains/php (or PATH);
    // MySQL from XAMPP or a portable MariaDB.
    steps: [
      (tool: 'php/php', args: ['-S', '127.0.0.1:8080', '-t', '.']),
    ],
    // Phones: Termux PHP + MariaDB, started together by web/serve.sh.
    androidSteps: [
      (tool: '/system/bin/sh', args: ['{tools}/web/serve.sh']),
    ],
    words: ['echo', 'isset', 'mysqli', 'query', 'prepare', 'bind_param', 'execute', 'fetch_assoc', 'fetch_all',
        '\$_POST', '\$_GET', 'htmlspecialchars', 'foreach', 'array', 'count', 'strlen'],
  ),
];

/// Where the PHP tile's built-in server listens.
const phpUrl = 'http://127.0.0.1:8080/';

const _dalvikvm = '/system/bin/dalvikvm';

const _webTemplate = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>My Page</title>
  <style>
    body { font-family: sans-serif; margin: 0; padding: 16px; background: #f5f7ff; }
    .cards { display: flex; flex-wrap: wrap; gap: 12px; }
    .card { flex: 1 1 200px; background: white; border-radius: 12px; padding: 16px; }
    button { padding: 10px 16px; border: 0; border-radius: 8px; background: #3B6BFF; color: white; }
  </style>
</head>
<body>
  <h1>Hello, CTU Naga!</h1>
  <div class="cards">
    <div class="card">Cards wrap onto new rows on small screens.</div>
    <div class="card">Try the Design tab to drag in more.</div>
  </div>
  <p><button id="btn">Click me</button> <span id="out"></span></p>
  <script>
    let clicks = 0;
    document.getElementById('btn').addEventListener('click', () => {
      document.getElementById('out').textContent = 'Clicked ' + (++clicks) + ' times';
    });
  </script>
</body>
</html>
''';

const _phpTemplate = r'''<?php
// MySQL (MariaDB on phones): host 127.0.0.1, user root, no password, database nexus.
$error = '';
$guests = [];
try {
    $db = new mysqli('127.0.0.1', 'root', '', 'nexus');
    $db->query('CREATE TABLE IF NOT EXISTS guests (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100))');
    if (!empty($_POST['name'])) {
        $stmt = $db->prepare('INSERT INTO guests (name) VALUES (?)');
        $stmt->bind_param('s', $_POST['name']);
        $stmt->execute();
    }
    $guests = $db->query('SELECT name FROM guests ORDER BY id DESC')->fetch_all(MYSQLI_ASSOC);
} catch (mysqli_sql_exception $e) {
    $error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Guest Book</title>
</head>
<body style="font-family: sans-serif; padding: 16px">
  <h1>Guest Book</h1>
  <form method="post">
    <input name="name" placeholder="Your name" required>
    <button>Save</button>
  </form>
  <?php if ($error) echo '<p style="color:red">Database: ' . htmlspecialchars($error) . '</p>'; ?>
  <ul>
    <?php foreach ($guests as $g) echo '<li>' . htmlspecialchars($g['name']) . '</li>'; ?>
  </ul>
</body>
</html>
''';
