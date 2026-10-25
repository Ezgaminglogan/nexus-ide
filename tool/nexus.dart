// NEXUS IDE project commands. Run from the project folder:  dart run tool/nexus.dart <command>
//
//   dev            Run the app on a connected phone (or the first device): flutter run
//   desktop        Run the Windows app in debug mode: flutter run -d windows
//   build:apk      Release APK -> dist/nexus-ide-v<version>-arm64.apk (builds the phone compiler pack first if missing)
//   build:win      Release Windows app -> dist/nexus-ide-v<version>-windows-x64.zip
//   version:patch  1.1.0+2 -> 1.1.1+3 in pubspec.yaml (the one place the version lives)
//   release:prepare  build:apk + build:win + dist/RELEASE_NOTES.md draft (with SHA-256s), same version
//   release:patch  version:patch, then release:prepare
//
// Nothing here commits, tags or publishes. Publishing is a separate, deliberate step (see
// docs/NEXUS_IDE_IMPROVEMENTS.md). The in-app updater finds releases by these asset names.
import 'dart:convert';
import 'dart:io';

final pubspec = File('pubspec.yaml');

String get version => RegExp(r'^version:\s*(\S+)', multiLine: true).firstMatch(pubspec.readAsStringSync())![1]!;
String get semver => version.split('+').first;

Future<void> run(String exe, List<String> args) async {
  stdout.writeln('> $exe ${args.join(' ')}');
  final p = await Process.start(exe, args, mode: ProcessStartMode.inheritStdio, runInShell: Platform.isWindows);
  final code = await p.exitCode;
  if (code != 0) {
    stderr.writeln('"$exe ${args.first}" failed (exit code $code).');
    exit(code);
  }
}

Future<String> buildApk() async {
  if (!File('android/app/src/main/assets/toolchains.zip').existsSync()) {
    await run('python', ['tool/build_android_toolchains.py']);
  }
  await run('flutter', ['build', 'apk', '--release', '--target-platform', 'android-arm64']);
  final out = 'dist/nexus-ide-v$semver-arm64.apk';
  Directory('dist').createSync();
  File('build/app/outputs/flutter-apk/app-release.apk').copySync(out);
  stdout.writeln('APK: $out');
  return out;
}

Future<String> buildWin() async {
  if (!Platform.isWindows) {
    stderr.writeln('build:win needs Windows (Flutter builds Windows apps only on Windows).');
    exit(1);
  }
  await run('flutter', ['build', 'windows', '--release']);
  final out = 'dist/nexus-ide-v$semver-windows-x64.zip';
  Directory('dist').createSync();
  if (File(out).existsSync()) File(out).deleteSync();
  // The zip holds the app folder's contents at its root: the updater unpacks it over the app.
  await run('powershell', ['-NoProfile', '-Command', "Compress-Archive -Path 'build\\windows\\x64\\runner\\Release\\*' -DestinationPath '$out'"]);
  stdout.writeln('Windows zip: $out (portable toolchains/ are not included; see the README)');
  return out;
}

void bumpPatch() {
  final m = RegExp(r'^(\d+)\.(\d+)\.(\d+)(?:\+(\d+))?$').firstMatch(version);
  if (m == null) {
    stderr.writeln('Can\'t bump "$version": expected x.y.z+n in pubspec.yaml.');
    exit(1);
  }
  final next = '${m[1]}.${m[2]}.${int.parse(m[3]!) + 1}+${int.parse(m[4] ?? '0') + 1}';
  pubspec.writeAsStringSync(pubspec.readAsStringSync().replaceFirst(RegExp(r'^version:\s*\S+', multiLine: true), 'version: $next'));
  stdout.writeln('Version $version -> $next (pubspec.yaml)');
}

Future<String> sha256Of(String path) async {
  final r = await Process.run('certutil', ['-hashfile', path, 'SHA256']);
  return const LineSplitter().convert(r.stdout as String).elementAt(1).replaceAll(' ', '').trim();
}

Future<void> releaseNotes(List<String> assets) async {
  final last = await Process.run('git', ['describe', '--tags', '--abbrev=0']);
  final range = last.exitCode == 0 ? '${(last.stdout as String).trim()}..HEAD' : 'HEAD';
  final log = await Process.run('git', ['log', range, '--pretty=format:- %s']);
  final notes = StringBuffer()
    ..writeln('One or two sentences on what this version is about.')
    ..writeln()
    ..writeln('## New Features')
    ..writeln('- **Name:** what you can do now.')
    ..writeln()
    ..writeln('## Improvements')
    ..writeln('- **Name:** what works better.')
    ..writeln()
    ..writeln('## Bug Fixes')
    ..writeln('- **Name:** what was wrong and is now fixed.')
    ..writeln()
    ..writeln('## Breaking Changes')
    ..writeln('- Remove this section if nothing breaks.')
    ..writeln()
    ..writeln('<!-- Commits since the last tag, to write the notes from (delete before publishing):')
    ..writeln(log.stdout)
    ..writeln('-->')
    ..writeln()
    ..writeln('<!-- Files to attach (SHA-256, for checking; GitHub also records it):');
  for (final a in assets) {
    notes.writeln('$a  ${await sha256Of(a)}');
  }
  notes.writeln('-->');
  File('dist/RELEASE_NOTES.md').writeAsStringSync(notes.toString());
  stdout.writeln('Release notes draft: dist/RELEASE_NOTES.md (the updater reads these four ## sections)');
}

Future<void> main(List<String> args) async {
  switch (args.firstOrNull) {
    case 'dev':
      await run('flutter', ['run']);
    case 'desktop':
      await run('flutter', ['run', '-d', 'windows']);
    case 'build:apk':
      await buildApk();
    case 'build:win':
      await buildWin();
    case 'version:patch':
      bumpPatch();
    case 'release:prepare' || 'release:patch':
      if (args.first == 'release:patch') bumpPatch();
      final assets = [await buildApk(), await buildWin()];
      await releaseNotes(assets);
      stdout.writeln('\nPrepared v$semver locally. Nothing was committed, tagged or published.');
    default:
      stdout.writeln(File(Platform.script.toFilePath()).readAsLinesSync().takeWhile((l) => l.startsWith('//')).join('\n'));
      exit(args.isEmpty ? 0 : 64);
  }
}
