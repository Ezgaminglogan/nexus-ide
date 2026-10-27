import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path/path.dart' as p;

import 'console_buffer.dart';
import 'runner.dart';
import 'settings.dart';
import 'toolchains.dart';

/// PHP and Web projects the XAMPP way: every project is a folder in one `htdocs` folder
/// (`workspace/htdocs/<project>`), and one local server shows each at `http://localhost/<project>/`,
/// so what students learn here is what they do with XAMPP and real hosting.

String get htdocsDir => p.join(Toolchains.workRoot, 'htdocs');

Language _lang(String id) => languages.firstWhere((l) => l.id == id);

typedef HtProject = ({String name, bool php});

/// The project folders in htdocs, by name. A folder with an index.php is a PHP project.
List<HtProject> listProjects() {
  final d = Directory(htdocsDir);
  if (!d.existsSync()) return const [];
  return [
    for (final e in d.listSync().whereType<Directory>())
      if (!p.basename(e.path).startsWith('.')) (name: p.basename(e.path), php: File(p.join(e.path, 'index.php')).existsSync()),
  ]..sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
}

/// The editor language for a project: PHP when it has an index.php, otherwise Web (HTML).
Language projectLanguage(String name) => _lang(File(p.join(htdocsDir, name, 'index.php')).existsSync() ? 'php' : 'web').project(name);

/// Why [name] can't be a project folder (it becomes part of the URL), or null.
String? projectNameProblem(String name) {
  if (name.isEmpty) return 'Type a project name.';
  if (!RegExp(r'^[A-Za-z0-9][A-Za-z0-9_-]*$').hasMatch(name)) {
    return 'Use letters, numbers, "-" and "_" only (it becomes the address localhost/$name/), like guest-book.';
  }
  if (name.length > 60) return 'Keep it under 60 characters.';
  if (listProjects().any((pr) => pr.name.toLowerCase() == name.toLowerCase())) return '"$name" already exists in htdocs.';
  return null;
}

/// Makes `htdocs/<name>` with its index page (PHP or HTML template). Null on success.
String? createProject(String name, {required bool php}) {
  final problem = projectNameProblem(name);
  if (problem != null) return problem;
  final lang = _lang(php ? 'php' : 'web');
  try {
    final dir = Directory(p.join(htdocsDir, name))..createSync(recursive: true);
    File(p.join(dir.path, lang.fileName)).writeAsStringSync(lang.template);
  } on FileSystemException catch (e) {
    return 'Could not create $name: ${e.osError?.message ?? e.message}';
  }
  return null;
}

/// Before htdocs, the PHP and Web tiles each had one folder (workspace/php, workspace/web).
/// Their files are copied once into htdocs projects, so nothing a student made is lost.
/// The old folders stay where they were.
void migrateToHtdocs() {
  if (Settings.instance.get('htdocs.migrated', false)) return;
  for (final (old, name) in [('php', 'my-php-site'), ('web', 'my-website')]) {
    final from = Directory(p.join(Toolchains.workRoot, old));
    final to = Directory(p.join(htdocsDir, name));
    if (!from.existsSync() || to.existsSync()) continue;
    for (final f in from.listSync(recursive: true).whereType<File>()) {
      final rel = p.relative(f.path, from: from.path);
      f.copySync((File(p.join(to.path, rel))..parent.createSync(recursive: true)).path);
    }
  }
  Directory(htdocsDir).createSync(recursive: true);
  Settings.instance.set('htdocs.migrated', true);
}

/// The local web server, like XAMPP's Apache: one for all projects, started on demand and kept
/// running when you leave the editor, until Stop or the app closes.
/// PC: PHP's built-in server on port 80 (`http://localhost/<project>/`), or 8080 when another
/// server (XAMPP's Apache, IIS) already has 80. Phone: the bundled PHP + MariaDB on 8080.
class LocalServer extends ChangeNotifier {
  LocalServer._();
  static final instance = LocalServer._();

  final log = ConsoleBuffer(maxLines: 1000);
  RunHandle? _h;
  String? docroot; // the folder served at http://localhost/
  int port = 0;
  String error = '';
  bool starting = false;

  bool get running => _h != null;

  /// The address of the docroot, as students type it: http://localhost or http://localhost:8080.
  String get origin => port == 80 ? 'http://localhost' : 'http://localhost:$port';

  /// The address of [project] (a folder in the docroot) and optionally a file in it.
  Uri url(String project, [String file = '']) => Uri.parse('$origin/$project/${file == 'index.php' || file == 'index.html' ? '' : file}');

  /// Starts the server for [root] (restarting it if it served another folder). Returns false
  /// with [error] set when PHP can't start.
  Future<bool> ensure(String root) async {
    if (running && docroot == root) return true;
    if (starting) return false;
    starting = true;
    error = '';
    notifyListeners();
    try {
      await stop();
      log.clear();
      port = Platform.isAndroid ? 8080 : await _freePort();
      final php = _lang('php');
      final RunHandle h;
      try {
        if (Platform.isAndroid) {
          // web/serve.sh starts MariaDB once, then PHP on 8080 in the folder it runs in.
          h = await runTool('/system/bin/sh', [p.join(Toolchains.toolsDir, 'web', 'serve.sh')], cwd: root, env: Toolchains.envFor(php, '/system/bin/sh'));
        } else {
          final exe = Toolchains.resolve('php/php', root);
          h = await runTool(exe, ['-S', '127.0.0.1:$port', '-t', root], cwd: root, env: Toolchains.envFor(php, exe));
        }
      } on ProcessException {
        error = Platform.isAndroid
            ? 'PHP is missing from the NEXUS tool pack on this phone.'
            : 'PHP was not found. Install XAMPP (its PHP is used automatically when it is on PATH) or put PHP in toolchains/php.';
        return false;
      }
      _h = h;
      docroot = root;
      h.output.listen(log.add);
      h.exitCode.then((code) {
        if (_h != h) return;
        _h = null;
        error = 'The server stopped (exit code $code). ${log.lines.where((l) => l.trim().isNotEmpty).lastOrNull ?? ''}';
        notifyListeners();
      });
      // Ready when the port answers (the phone also starts MariaDB first: give it time).
      for (var i = 0; i < 80 && _h == h; i++) {
        try {
          (await Socket.connect('127.0.0.1', port, timeout: const Duration(milliseconds: 300))).destroy();
          return true;
        } on SocketException {
          await Future<void>.delayed(const Duration(milliseconds: 200));
        }
      }
      if (_h == h) {
        await stop();
        error = 'The server did not start on port $port.';
      }
      return false;
    } finally {
      starting = false;
      notifyListeners();
    }
  }

  Future<void> stop() async {
    final h = _h;
    _h = null;
    docroot = null;
    await h?.kill();
    notifyListeners();
  }

  /// 80 like XAMPP when nothing else serves it; else the first free of 8080-8090.
  /// Browsers try `localhost` over IPv6 (::1) first, so a port counts as taken when anything
  /// answers on either loopback address: otherwise the browser could show another server's page.
  static Future<int> _freePort() async {
    Future<bool> answers(String host, int port) async {
      try {
        (await Socket.connect(host, port, timeout: const Duration(milliseconds: 300))).destroy();
        return true;
      } on SocketException {
        return false;
      }
    }

    for (final port in [80, for (var p = 8080; p <= 8090; p++) p]) {
      if (await answers('127.0.0.1', port) || await answers('::1', port)) continue; // XAMPP's Apache, IIS...
      try {
        await (await ServerSocket.bind(InternetAddress.loopbackIPv4, port)).close();
        return port;
      } on SocketException {
        continue;
      }
    }
    return 8080;
  }
}
