import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'toolchains.dart';

/// Small JSON stores in `workspace/.nexus/<name>.json`: next to the student's files, never inside the
/// app folder an update replaces. Unknown or broken files fall back to defaults.
/// [instance] holds app settings; [named] ('learn') keeps learning progress apart from them.
class Settings {
  Settings._(this._file, this._data);
  final File _file;
  final Map<String, dynamic> _data;

  static final _open = <String, Settings>{};

  static Settings get instance => named('settings');

  static Settings named(String name) => _open[name] ??= () {
        final file = File(p.join(Toolchains.workRoot, '.nexus', '$name.json'));
        Map<String, dynamic> data = {};
        try {
          data = (jsonDecode(file.readAsStringSync()) as Map).cast<String, dynamic>();
        } on Object {
          // first launch or a hand-broken file
        }
        return Settings._(file, data);
      }();

  /// Tests point the workspace somewhere new; forget the cached copies.
  static void reset() => _open.clear();

  Iterable<String> get keys => _data.keys.toList();

  T get<T>(String key, T fallback) {
    final v = _data[key];
    return v is T ? v : fallback;
  }

  void set(String key, Object? value) {
    value == null ? _data.remove(key) : _data[key] = value;
    try {
      (_file..parent.createSync(recursive: true)).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(_data));
    } on FileSystemException {
      // read-only drive: settings just don't persist
    }
  }
}
