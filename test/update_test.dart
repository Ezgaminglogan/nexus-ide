import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/settings.dart';
import 'package:nexus_ide/core/toolchains.dart';
import 'package:nexus_ide/core/update.dart';

Release rel(String tag, {bool pre = false, List<String> assets = const ['nexus-ide-x-arm64.apk', 'nexus-ide-x-windows-x64.zip']}) => Release.fromJson({
      'tag_name': tag,
      'name': 'NEXUS IDE $tag',
      'prerelease': pre,
      'published_at': '2026-10-25T08:00:00Z',
      'assets': [for (final a in assets) {'name': a, 'browser_download_url': 'https://x/$a', 'size': 10, 'digest': 'sha256:abc'}],
    })!;

void main() {
  test('versions: numeric parts, pre-releases sort before the release, build metadata ignored', () {
    final v = Version.tryParse;
    expect(v('v1.10.0')! > v('1.9.9')!, isTrue);
    expect(v('1.2.0')! > v('1.2.0-beta.2')!, isTrue);
    expect(v('1.2.0-beta.10')! > v('1.2.0-beta.2')!, isTrue); // numeric, not text
    expect(v('1.2.0-rc.1')! > v('1.2.0-beta.9')!, isTrue);
    expect(v('1.2.0-beta')!.compareTo(v('1.2.0-beta.1')!), lessThan(0));
    expect(v('1.1.0+2')!.compareTo(v('1.1.0')!), 0);
    expect(v('nightly'), isNull);
  });

  test('pickUpdate: newest above current; pre-releases only on the beta channel', () {
    final current = Version.tryParse('1.1.0')!;
    final releases = [rel('v1.0.0'), rel('v1.1.0'), rel('v1.1.1'), rel('v1.2.0-beta.1', pre: true)];
    expect(pickUpdate(releases, current, beta: false)!.version.toString(), '1.1.1');
    expect(pickUpdate(releases, current, beta: true)!.version.toString(), '1.2.0-beta.1');
    expect(pickUpdate([rel('v1.1.0')], current, beta: false), isNull);
  });

  test('assetFor picks the APK on Android, the zip on Windows, nothing elsewhere', () {
    final r = rel('v1.2.0');
    expect(assetFor(r, os: 'android')!.name, endsWith('-arm64.apk'));
    expect(assetFor(r, os: 'windows')!.name, endsWith('-windows-x64.zip'));
    expect(assetFor(r, os: 'linux'), isNull);
    expect(assetFor(rel('v1.2.0', assets: ['nexus-ide-arm64.apk']), os: 'windows'), isNull); // incompatible
    expect(r.assets.first.sha256, 'abc');
  });

  test('parseNotes: summary plus the four sections, other headings go to Improvements', () {
    final n = parseNotes('Big update for the lab.\n\n## New Features\n- **Explorer:** folders\n'
        '### Bug fixes\n* PHP preview opens\n## Misc\n- Faster start\n## Breaking changes\n- Old settings reset');
    expect(n.summary, 'Big update for the lab.');
    expect(n.sections['New Features'], ['Explorer: folders']);
    expect(n.sections['Bug Fixes'], ['PHP preview opens']);
    expect(n.sections['Improvements'], ['Faster start']);
    expect(n.sections['Breaking Changes'], ['Old settings reset']);
    expect(parseNotes('').sections, isEmpty);
  });

  test('verify: size and SHA-256 must both match what GitHub published', () async {
    final f = File('${Directory.systemTemp.createTempSync('upd').path}/a.apk')..writeAsStringSync('hello');
    final good = sha256.convert(utf8.encode('hello')).toString();
    expect(await Updater.verify(f, (name: 'a', url: '', size: 5, sha256: good)), isNull);
    expect(await Updater.verify(f, (name: 'a', url: '', size: 6, sha256: good)), contains('incomplete'));
    expect(await Updater.verify(f, (name: 'a', url: '', size: 5, sha256: 'bad')), contains('damaged'));
    expect(await Updater.verify(f, (name: 'a', url: '', size: 5, sha256: null)), isNull); // older release: size only
  });

  test('one dialog per run, however many checks', () {
    final u = Updater.instance..latest = rel('v9.0.0');
    expect(u.claimModal(), isTrue);
    expect(u.claimModal(), isFalse);
    u.releaseModal();
    expect(u.claimModal(), isTrue);
  });

  test("what's new: once, only after the version went up; saved notes when the updater installed it", () {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('wn').path;
    Settings.reset();
    final u = Updater.instance..current = Version.tryParse('1.1.1');
    expect(u.takeWhatsNew(), isNull); // first launch ever: just remember 1.1.1
    expect(u.takeWhatsNew(), isNull); // same version again

    // The updater installs 1.1.2 and saves its notes; the new app starts.
    Settings.instance.set('update.installed', {'version': '1.1.2', 'title': 'NEXUS IDE v1.1.2', 'date': '2026-10-26T08:00:00Z', 'body': '## Bug Fixes\n- Tabs', 'page': 'https://p'});
    u.current = Version.tryParse('1.1.2');
    final r = u.takeWhatsNew()!;
    expect(r.version.toString(), '1.1.2');
    expect(parseNotes(r.body).sections['Bug Fixes'], ['Tabs']);
    expect(u.takeWhatsNew(), isNull); // only once

    // A manual install of 1.2.0 (no saved notes): still announced, with a link instead of notes.
    u.current = Version.tryParse('1.2.0');
    final m = u.takeWhatsNew()!;
    expect(m.body, '');
    expect(m.page, endsWith('/tag/v1.2.0'));
  });
  test('an update found earlier is still announced on launches that skip the online check', () async {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('upd').path;
    Settings.reset();
    Settings.instance
      ..set('update.lastCheck', DateTime.now().toIso8601String()) // checked an hour ago: no network now
      ..set('update.pending', {
        'tag_name': 'v9.1.0',
        'name': 'NEXUS IDE v9.1.0',
        'assets': [for (final a in ['nexus-ide-v9.1.0-arm64.apk', 'nexus-ide-v9.1.0-windows-x64.zip']) {'name': a, 'browser_download_url': 'https://x/$a', 'size': 10}],
      });
    final u = Updater.instance
      ..current = Version(1, 1, 4)
      ..latest = null
      ..status = UpdateStatus.idle;
    expect(await u.autoCheck(), isFalse); // no pop-up again today...
    expect(u.latest?.version.toString(), '9.1.0'); // ...but the home banner knows about it
    expect(u.status, Platform.isWindows || Platform.isAndroid ? UpdateStatus.available : UpdateStatus.incompatible);

    u
      ..current = Version(9, 1, 0) // installed it meanwhile: nothing to announce
      ..latest = null
      ..status = UpdateStatus.idle;
    await u.autoCheck();
    expect(u.latest, isNull);
  });
}
