import 'dart:io';

import 'package:path/path.dart' as p;

/// File operations for the explorer, always inside one language's workspace folder ([root]).
/// Paths are relative with forward slashes ("css/style.css"); anything that would leave [root]
/// (absolute paths, "..", odd characters) is refused.

/// [rel] cleaned up, or null when it isn't a safe path inside the workspace.
String? safeRel(String rel) {
  if (rel.startsWith('/') || rel.startsWith(r'\')) return null; // absolute
  final parts = rel.replaceAll(r'\', '/').split('/').where((s) => s.isNotEmpty).toList();
  if (parts.isEmpty || parts.any((s) => s == '.' || s == '..' || !RegExp(r'^[\w][\w .-]*$').hasMatch(s))) return null;
  return parts.join('/');
}

String _abs(String root, String rel) => p.joinAll([root, ...rel.split('/')]);

/// Hidden from the explorer: dot-files and what compilers/NEXUS generate.
const _generated = {'build', 'classes', 'bin', 'obj', 'RPi', '__pycache__', 'design.json', 'nexus_unbuf.h', 'nexus.csproj', 'main.exe', 'main.dex', 'main', 'gpio_state.txt', 'gpio_in.txt'};

bool shown(String name) => !name.startsWith('.') && !_generated.contains(name);

/// Children of folder [rel] ('' = workspace root): folders first, then files, by name.
List<({String rel, String name, bool folder})> listDir(String root, [String rel = '']) {
  final dir = Directory(rel.isEmpty ? root : _abs(root, rel));
  if (!dir.existsSync()) return const [];
  final items = [
    for (final e in dir.listSync())
      if (shown(p.basename(e.path)))
        (rel: rel.isEmpty ? p.basename(e.path) : '$rel/${p.basename(e.path)}', name: p.basename(e.path), folder: e is Directory),
  ]..sort((a, b) => a.folder != b.folder ? (a.folder ? -1 : 1) : a.name.toLowerCase().compareTo(b.name.toLowerCase()));
  return items;
}

/// Each returns null on success or a sentence to show the student.
String? createFile(String root, String rel) {
  final r = safeRel(rel);
  if (r == null) return 'Use letters, numbers, "-", "_" and "." (folders with "/"), like css/style.css.';
  final f = File(_abs(root, r));
  if (f.existsSync() || Directory(f.path).existsSync()) return '$r already exists.';
  f
    ..createSync(recursive: true)
    ..writeAsStringSync('');
  return null;
}

String? createFolder(String root, String rel) {
  final r = safeRel(rel);
  if (r == null) return 'Use letters, numbers, "-", "_" and "." (subfolders with "/"), like assets/img.';
  final d = Directory(_abs(root, r));
  if (d.existsSync() || File(d.path).existsSync()) return '$r already exists.';
  d.createSync(recursive: true);
  return null;
}

/// Renames in place (same folder); returns the new relative path via [onDone].
String? rename(String root, String rel, String newName, void Function(String newRel) onDone) {
  final name = safeRel(newName);
  if (name == null || name.contains('/')) return 'A name can\'t contain "/" or start with "." or "..".';
  final parent = rel.contains('/') ? rel.substring(0, rel.lastIndexOf('/')) : '';
  final to = parent.isEmpty ? name : '$parent/$name';
  if (FileSystemEntity.typeSync(_abs(root, to)) != FileSystemEntityType.notFound) return '$to already exists.';
  final type = FileSystemEntity.typeSync(_abs(root, rel));
  if (type == FileSystemEntityType.directory) {
    Directory(_abs(root, rel)).renameSync(_abs(root, to));
  } else {
    File(_abs(root, rel)).renameSync(_abs(root, to));
  }
  onDone(to);
  return null;
}

/// Number of files a delete would remove (the confirm dialog says it).
int fileCount(String root, String rel) {
  final d = Directory(_abs(root, rel));
  return d.existsSync() ? d.listSync(recursive: true).whereType<File>().length : 1;
}

void delete(String root, String rel) {
  final r = safeRel(rel);
  if (r == null) return;
  final path = _abs(root, r);
  if (FileSystemEntity.isDirectorySync(path)) {
    Directory(path).deleteSync(recursive: true);
  } else if (File(path).existsSync()) {
    File(path).deleteSync();
  }
}
