import 'dart:convert';
import 'dart:io';

import 'package:path/path.dart' as p;

import 'toolchains.dart';

/// App settings in `workspace/.nexus/settings.json`: next to the student's files, never inside the
/// app folder an update replaces. Unknown or broken files fall back to defaults.
class Settings {
  Settings._(this._data);
  final Map<String, dynamic> _data;

  static Settings? _instance;
  static File get _file => File(p.join(Toolchains.workRoot, '.nexus', 'settings.json'));

  static Settings get instance {
    if (_instance != null) return _instance!;
    Map<String, dynamic> data = {};
    try {
      data = (jsonDecode(_file.readAsStringSync()) as Map).cast<String, dynamic>();
    } on Object {
      // first launch or a hand-broken file
    }
    return _instance = Settings._(data);
  }

  /// Tests point the workspace somewhere new; forget the cached copy.
  static void reset() => _instance = null;

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
