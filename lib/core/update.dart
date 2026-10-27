import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:path/path.dart' as p;

import 'settings.dart';
import 'toolchains.dart';

/// Updates come from the project's GitHub Releases. The version that counts is pubspec.yaml's,
/// which Flutter writes into the APK and the exe (read back with package_info_plus).
const releasesApi = 'https://api.github.com/repos/Ezgaminglogan/nexus-ide/releases';
const releasesPage = 'https://github.com/Ezgaminglogan/nexus-ide/releases';

/// Semantic version: 1.2.3, 1.2.3-beta.2 (a pre-release sorts before 1.2.3). Build (+5) is ignored.
class Version implements Comparable<Version> {
  Version(this.major, this.minor, this.patch, [this.pre = const []]);
  final int major, minor, patch;
  final List<String> pre;

  static Version? tryParse(String s) {
    final m = RegExp(r'^v?(\d+)\.(\d+)\.(\d+)(?:-([0-9A-Za-z.-]+))?(?:\+.*)?$').firstMatch(s.trim());
    if (m == null) return null;
    return Version(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!), m[4]?.split('.') ?? const []);
  }

  bool get isPre => pre.isNotEmpty;

  @override
  int compareTo(Version o) {
    for (final (a, b) in [(major, o.major), (minor, o.minor), (patch, o.patch)]) {
      if (a != b) return a.compareTo(b);
    }
    if (pre.isEmpty || o.pre.isEmpty) return pre.isEmpty == o.pre.isEmpty ? 0 : (pre.isEmpty ? 1 : -1);
    for (var i = 0; i < pre.length && i < o.pre.length; i++) {
      final x = int.tryParse(pre[i]), y = int.tryParse(o.pre[i]);
      final c = x != null && y != null ? x.compareTo(y) : x != null ? -1 : y != null ? 1 : pre[i].compareTo(o.pre[i]);
      if (c != 0) return c;
    }
    return pre.length.compareTo(o.pre.length);
  }

  bool operator >(Version o) => compareTo(o) > 0;

  @override
  String toString() => '$major.$minor.$patch${pre.isEmpty ? '' : '-${pre.join('.')}'}';
}

typedef Asset = ({String name, String url, int size, String? sha256});

class Release {
  Release({required this.version, required this.title, required this.published, required this.body, required this.prerelease, required this.assets, required this.page});
  final Version version;
  final String title, body, page;
  final DateTime? published;
  final bool prerelease;
  final List<Asset> assets;

  static Release? fromJson(Map<String, dynamic> j) {
    final v = Version.tryParse(j['tag_name'] as String? ?? '');
    if (v == null || j['draft'] == true) return null;
    return Release(
      version: v,
      title: (j['name'] as String?)?.trim().isNotEmpty == true ? j['name'] as String : 'NEXUS IDE ${j['tag_name']}',
      published: DateTime.tryParse(j['published_at'] as String? ?? ''),
      body: j['body'] as String? ?? '',
      prerelease: j['prerelease'] == true || v.isPre,
      page: j['html_url'] as String? ?? releasesPage,
      assets: [
        for (final a in (j['assets'] as List? ?? const []).cast<Map<String, dynamic>>())
          (
            name: a['name'] as String,
            url: a['browser_download_url'] as String,
            size: a['size'] as int? ?? 0,
            sha256: (a['digest'] as String?)?.startsWith('sha256:') == true ? (a['digest'] as String).substring(7) : null,
          ),
      ],
    );
  }
}

/// The asset this device can install: the arm64 APK on Android, the x64 zip on Windows.
Asset? assetFor(Release r, {String? os}) {
  final suffix = switch (os ?? Platform.operatingSystem) {
    'android' => '-arm64.apk',
    'windows' => '-windows-x64.zip',
    _ => null,
  };
  return suffix == null ? null : r.assets.where((a) => a.name.endsWith(suffix)).firstOrNull;
}

/// Newest release above [current]; pre-releases only on the beta channel.
Release? pickUpdate(Iterable<Release> releases, Version current, {required bool beta}) {
  Release? best;
  for (final r in releases) {
    if ((r.prerelease && !beta) || !(r.version > current)) continue;
    if (best == null || r.version > best.version) best = r;
  }
  return best;
}

const noteSections = ['New Features', 'Improvements', 'Bug Fixes', 'Breaking Changes'];

/// Release notes split into [noteSections] (from `## Heading` / `**Heading**` lines) plus the text
/// before them as the summary. Bullets under any other heading land in Improvements.
({String summary, Map<String, List<String>> sections}) parseNotes(String body) {
  final sections = <String, List<String>>{};
  final summary = <String>[];
  String? current;
  for (var line in body.replaceAll('\r', '').split('\n')) {
    line = line.trim();
    final heading = RegExp(r'^(?:#{1,4}\s*(.+?)|\*\*(.+?)\*\*:?)$').firstMatch(line);
    if (heading != null) {
      final h = (heading[1] ?? heading[2]!).toLowerCase();
      current = h.contains('break')
          ? 'Breaking Changes'
          : h.contains('fix')
              ? 'Bug Fixes'
              : h.contains('new') || h.contains('feature')
                  ? 'New Features'
                  : 'Improvements';
      continue;
    }
    final bullet = RegExp(r'^[-*]\s+(.*)$').firstMatch(line);
    if (bullet != null && current != null) {
      (sections[current] ??= []).add(bullet[1]!.replaceAll('**', ''));
    } else if (current == null && line.isNotEmpty) {
      summary.add((bullet?[1] ?? line).replaceAll('**', ''));
    }
  }
  return (summary: summary.join(' '), sections: sections);
}

enum UpdateStatus { idle, checking, upToDate, available, incompatible, downloading, verifying, ready, installing, offline, failed }

/// Before a restart: every open editor saves here (see EditorScreen), so updates never lose work.
final beforeRestart = <Future<void> Function()>{};

class Updater extends ChangeNotifier {
  Updater._();
  static final instance = Updater._();

  UpdateStatus status = UpdateStatus.idle;
  Version? current;
  Release? latest; // newest release seen (an update when status says so)
  double progress = 0; // download, 0..1
  String error = '';
  File? _file;
  bool _modalShown = false; // one update dialog per app run, however many checks

  DateTime? get lastCheck => DateTime.tryParse(Settings.instance.get('update.lastCheck', ''));
  bool get beta => Settings.instance.get('update.channel', 'stable') == 'beta';
  set beta(bool b) => Settings.instance.set('update.channel', b ? 'beta' : 'stable');

  void _set(UpdateStatus s, [String e = '']) {
    status = s;
    error = e;
    notifyListeners();
  }

  /// Startup check: at most once a day and quietly (offline is normal for a lab).
  /// Returns true when the update dialog should open now.
  Future<bool> autoCheck() async {
    final last = lastCheck;
    final snooze = DateTime.tryParse(Settings.instance.get('update.snoozeUntil', ''));
    if (last != null && DateTime.now().difference(last) < const Duration(hours: 20)) {
      await _restorePending(); // offline-friendly: the update found earlier stays announced
      return false;
    }
    if (snooze != null && DateTime.now().isBefore(snooze)) return false;
    await check();
    return status == UpdateStatus.available && claimModal();
  }

  /// The update found by the last online check, if it is still newer than what is installed.
  Future<void> _restorePending() async {
    final j = Settings.instance.get<Map?>('update.pending', null);
    final r = j == null ? null : Release.fromJson(j.cast<String, dynamic>());
    await loadCurrent();
    if (r == null || current == null || !(r.version > current!) || (r.prerelease && !beta)) return;
    latest = r;
    _set(assetFor(r) == null ? UpdateStatus.incompatible : UpdateStatus.available);
  }

  /// True when no update dialog is open, so repeated checks never stack dialogs.
  bool claimModal() {
    if (latest == null || _modalShown) return false;
    return _modalShown = true;
  }

  void releaseModal() => _modalShown = false;

  void remindLater() => Settings.instance.set('update.snoozeUntil', DateTime.now().add(const Duration(days: 1)).toIso8601String());

  /// The installed version (from the APK / exe, which take it from pubspec.yaml).
  Future<void> loadCurrent() async {
    try {
      current ??= Version.tryParse((await PackageInfo.fromPlatform()).version);
      notifyListeners();
    } on Object {
      // no platform plugin (widget tests): stays unknown
    }
  }

  /// Once, on the first launch after the version went up: the release now installed (with the
  /// notes saved by [install], or just the version after a manual install). Null otherwise.
  Release? takeWhatsNew() {
    final s = Settings.instance, cur = current;
    if (cur == null) return null;
    final last = Version.tryParse(s.get('update.lastRun', ''));
    final saved = s.get<Map>('update.installed', const {});
    s.set('update.lastRun', cur.toString());
    s.set('update.installed', null);
    if (last == null || !(cur > last)) return null; // first launch ever, or same version
    final mine = Version.tryParse(saved['version'] as String? ?? '')?.compareTo(cur) == 0;
    return Release(
      version: cur,
      title: mine ? saved['title'] as String : 'NEXUS IDE v$cur',
      published: mine ? DateTime.tryParse(saved['date'] as String? ?? '') : null,
      body: mine ? saved['body'] as String : '',
      prerelease: cur.isPre,
      assets: const [],
      page: mine ? saved['page'] as String : '$releasesPage/tag/v$cur',
    );
  }

  Future<void> check() async {
    if (status == UpdateStatus.checking || status == UpdateStatus.downloading || status == UpdateStatus.verifying) return;
    _set(UpdateStatus.checking);
    try {
      await loadCurrent();
      final list = jsonDecode(await _get(releasesApi)) as List;
      final releases = [for (final j in list.cast<Map<String, dynamic>>()) ?Release.fromJson(j)];
      Settings.instance.set('update.lastCheck', DateTime.now().toIso8601String());
      latest = pickUpdate(releases, current ?? Version(0, 0, 0), beta: beta);
      // Remembered, so the home banner still shows on launches that skip the online check.
      Settings.instance.set('update.pending', latest == null ? null : list.firstWhere((j) => j['tag_name'] == 'v${latest!.version}' || j['tag_name'] == '${latest!.version}', orElse: () => null));
      if (latest == null) return _set(UpdateStatus.upToDate);
      _set(assetFor(latest!) == null ? UpdateStatus.incompatible : UpdateStatus.available);
    } on SocketException {
      _set(UpdateStatus.offline, 'No internet connection. NEXUS works offline; check again when you are online.');
    } on TimeoutException {
      _set(UpdateStatus.offline, 'GitHub did not answer in time. Check your connection and try again.');
    } on Object catch (e) {
      _set(UpdateStatus.failed, 'Could not read the release list: $e');
    }
  }

  Future<String> _get(String url) async {
    final client = HttpClient()..connectionTimeout = const Duration(seconds: 10);
    try {
      final req = await client.getUrl(Uri.parse(url));
      req.headers
        ..set('User-Agent', 'NEXUS-IDE')
        ..set('Accept', 'application/vnd.github+json');
      final res = await req.close().timeout(const Duration(seconds: 20));
      if (res.statusCode != 200) throw HttpException('GitHub answered ${res.statusCode}');
      return await res.transform(utf8.decoder).join();
    } finally {
      client.close();
    }
  }

  /// Downloads the platform asset with live progress, then checks its size and SHA-256
  /// against what GitHub published for it.
  Future<void> download() async {
    final asset = latest == null ? null : assetFor(latest!);
    if (asset == null) return _set(UpdateStatus.incompatible);
    final dir = Directory(p.join(Toolchains.workRoot, '.nexus', 'updates'))..createSync(recursive: true);
    final file = File(p.join(dir.path, asset.name));
    final client = HttpClient();
    _set(UpdateStatus.downloading);
    progress = 0;
    try {
      final res = await (await client.getUrl(Uri.parse(asset.url))).close();
      if (res.statusCode != 200) throw HttpException('download answered ${res.statusCode}');
      final total = asset.size > 0 ? asset.size : res.contentLength;
      final sink = file.openWrite();
      var got = 0;
      await for (final chunk in res) {
        sink.add(chunk);
        got += chunk.length;
        if (total > 0) {
          progress = got / total;
          notifyListeners();
        }
      }
      await sink.close();
      _set(UpdateStatus.verifying);
      final problem = await verify(file, asset);
      if (problem != null) {
        file.deleteSync();
        return _set(UpdateStatus.failed, problem);
      }
      _file = file;
      _set(UpdateStatus.ready);
    } on SocketException {
      _set(UpdateStatus.offline, 'The connection dropped during the download. Try again.');
    } on Object catch (e) {
      _set(UpdateStatus.failed, 'Download failed: $e');
    } finally {
      client.close();
    }
  }

  /// Null when [file] matches [asset]; otherwise what is wrong with it.
  static Future<String?> verify(File file, Asset asset) async {
    final size = file.lengthSync();
    if (asset.size > 0 && size != asset.size) return 'The download is incomplete ($size of ${asset.size} bytes).';
    if (asset.sha256 == null) return null; // older releases have no digest: size check only
    final hash = (await sha256.bind(file.openRead()).first).toString();
    return hash == asset.sha256 ? null : 'The download is damaged (checksum mismatch). It was deleted; try again.';
  }

  /// Saves every open editor, then hands the package to the system installer (Android) or to a
  /// small script that waits for NEXUS to close, unpacks the zip over the app folder and restarts
  /// it (Windows). Student files and settings live in workspace/, which the zip never contains.
  Future<void> install() async {
    final file = _file;
    if (file == null) return;
    _set(UpdateStatus.installing);
    // Remember the notes so the updated app can say what's new, even offline.
    final r = latest!;
    Settings.instance.set('update.installed', {
      'version': r.version.toString(),
      'title': r.title,
      'date': r.published?.toIso8601String(),
      'body': r.body,
      'page': r.page,
    });
    for (final save in beforeRestart.toList()) {
      await save();
    }
    try {
      if (Platform.isAndroid) {
        await const MethodChannel('nexus/toolchains').invokeMethod('installApk', {'path': file.path});
        _set(UpdateStatus.ready); // Android's installer takes over; NEXUS restarts when it finishes
      } else if (Platform.isWindows) {
        final appDir = File(Platform.resolvedExecutable).parent.path;
        final script = File(p.join(file.parent.path, 'apply-update.cmd'))
          ..writeAsStringSync([
            '@echo off',
            ':wait',
            'tasklist /FI "PID eq $pid" | find "$pid" >nul && (timeout /t 1 /nobreak >nul & goto wait)',
            'powershell -NoProfile -Command "Expand-Archive -Force -LiteralPath \'${file.path}\' -DestinationPath \'$appDir\'"',
            'start "" "${Platform.resolvedExecutable}"',
          ].join('\r\n'));
        await Process.start('cmd', ['/c', script.path], mode: ProcessStartMode.detached);
        exit(0);
      } else {
        _set(UpdateStatus.incompatible);
      }
    } on Object catch (e) {
      _set(UpdateStatus.failed, 'Could not start the installer: $e');
    }
  }
}
