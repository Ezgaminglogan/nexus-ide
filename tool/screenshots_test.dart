// Renders documentation screenshots with Flutter's test engine (real fonts, no device needed):
//   flutter test tool/screenshots_test.dart
// Writes docs/screenshots/*.png. These are the real widgets, drawn off-screen, not a captured app.
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/main.dart';
import 'package:nexus_ide/ui/screens/settings_screen.dart';
import 'package:nexus_ide/ui/widgets/update_dialog.dart';

Future<void> font(String family, List<String> files) async {
  final loader = FontLoader(family);
  for (final f in files) {
    if (File(f).existsSync()) loader.addFont(Future.value(ByteData.sublistView(File(f).readAsBytesSync())));
  }
  await loader.load();
}

Future<void> shot(WidgetTester t, String name) async {
  await t.runAsync(() async {
    final boundary = t.binding.rootElement!.findRenderObject()!;
    final layer = (boundary as RenderView).debugLayer! as OffsetLayer;
    final img = await layer.toImage(Offset.zero & t.view.physicalSize); // the root layer is already in device pixels
    final png = await img.toByteData(format: ui.ImageByteFormat.png);
    File('docs/screenshots/$name.png').writeAsBytesSync(png!.buffer.asUint8List());
  });
}

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 6; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 40)));
    await t.pump(const Duration(milliseconds: 120));
  }
}

void main() {
  setUpAll(() async {
    await font('Roboto', ['C:/Windows/Fonts/segoeui.ttf', 'C:/Windows/Fonts/segoeuib.ttf']);
    await font('Consolas', ['C:/Windows/Fonts/consola.ttf']);
    // flutter_tester lives in flutter/bin/cache/artifacts/engine/<platform>/
    final cache = File(Platform.resolvedExecutable).parent.parent.parent.parent.path;
    await font('MaterialIcons', ['$cache/artifacts/material_fonts/materialicons-regular.otf']);
    registerHighlighting(); // main() does this in the app
  });

  setUp(() {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('shots').path;
    Settings.reset();
    final php = Directory('${Toolchains.workRoot}/php')..createSync(recursive: true);
    File('${php.path}/index.php').writeAsStringSync(languages.firstWhere((l) => l.id == 'php').template);
    File('${php.path}/pages/admin/about.php')
      ..createSync(recursive: true)
      ..writeAsStringSync('<?php\n\$title = "About";\n?>\n<h1><?= \$title ?></h1>\n');
    File('${php.path}/css/style.css')
      ..createSync(recursive: true)
      ..writeAsStringSync('body { margin: 0; }\n');
    Settings.instance.set('explorer.expanded.php', ['pages', 'pages/admin', 'css']);
  });

  Future<void> openPhp(WidgetTester t) async {
    await t.pumpWidget(NexusApp(ready: Future.value()));
    await settle(t);
    await t.ensureVisible(find.text('Server pages · MySQL'));
    await settle(t);
    await t.tap(find.text('Server pages · MySQL'));
    await settle(t);
  }

  testWidgets('desktop editor with explorer', (t) async {
    t.view.physicalSize = const Size(1600, 900);
    t.view.devicePixelRatio = 1;
    await openPhp(t);
    await t.tap(find.text('about.php'));
    await settle(t);
    await t.tap(find.textContaining('About', findRichText: true).first);
    await t.enterText(find.byType(EditableText).first, '<?php\n\$title = "About us";\n?>\n<h1><?= \$title ?></h1>\n');
    await settle(t);
    await shot(t, 'desktop_editor');
  });

  testWidgets('update dialog', (t) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    Updater.instance
      ..current = Version.tryParse('1.1.0')
      ..status = UpdateStatus.available
      ..latest = Release.fromJson({
        'tag_name': 'v1.1.1',
        'name': 'NEXUS IDE v1.1.1',
        'published_at': '2026-10-25T08:00:00Z',
        'body': 'Files, folders and a clearer editor.\n\n## New Features\n- **Explorer:** create, rename and delete files and folders in a sidebar.\n'
            '## Improvements\n- **Editor:** the line you are on and matching brackets are highlighted.\n## Bug Fixes\n- **PHP:** HTML inside .php files is colored again.',
        'assets': [
          {'name': 'nexus-ide-v1.1.1-windows-x64.zip', 'browser_download_url': 'https://x', 'size': 26000000, 'digest': 'sha256:ab'},
          {'name': 'nexus-ide-v1.1.1-arm64.apk', 'browser_download_url': 'https://x', 'size': 134000000, 'digest': 'sha256:ab'},
        ],
      });
    await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const SettingsScreen()));
    await settle(t);
    showUpdateDialog(t.element(find.byType(SettingsScreen)));
    await settle(t);
    await shot(t, 'update_dialog');
  });

  testWidgets('phone: explorer drawer', (t) async {
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    t.view.devicePixelRatio = 2.6;
    await openPhp(t);
    await t.tap(find.byTooltip('Files (explorer)'));
    await settle(t);
    await shot(t, 'phone_drawer');
  });

  testWidgets('phone: Raspberry Pi board', (t) async {
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    t.view.devicePixelRatio = 2.6;
    final dir = Directory('${Toolchains.workRoot}/raspi')..createSync(recursive: true);
    File('${dir.path}/$stateFile').writeAsStringSync('18 out 1\n17 in 0 up');
    await t.pumpWidget(NexusApp(ready: Future.value()));
    await settle(t);
    await t.ensureVisible(find.text('GPIO simulator · Python'));
    await settle(t);
    await t.tap(find.text('GPIO simulator · Python'));
    await settle(t);
    await shot(t, 'phone_raspi');
  });

  testWidgets('home (desktop and phone)', (t) async {
    t.view.physicalSize = const Size(1280, 975);
    t.view.devicePixelRatio = 1;
    await t.pumpWidget(NexusApp(ready: Future.value()));
    await settle(t);
    await shot(t, 'desktop_home');
    t.view.physicalSize = const Size(412 * 2.6, 915 * 2.6);
    t.view.devicePixelRatio = 2.6;
    await settle(t);
    await shot(t, 'phone_home');
  });

  testWidgets("what's new after an update", (t) async {
    t.view.physicalSize = const Size(1280, 800);
    t.view.devicePixelRatio = 1;
    await t.pumpWidget(MaterialApp(debugShowCheckedModeBanner: false, theme: ThemeData.dark(), home: const Scaffold()));
    showWhatsNewDialog(
      t.element(find.byType(Scaffold)),
      Release.fromJson({
        'tag_name': 'v1.1.2',
        'name': 'NEXUS IDE v1.1.2',
        'published_at': '2026-10-26T08:00:00Z',
        'body': 'Clearer home screen.\n\n## Improvements\n- **Home:** every tile says what you can do with that language.\n## New Features\n- **What\'s new:** after an update, NEXUS shows this message once.',
      })!,
    );
    await settle(t);
    await shot(t, 'whats_new');
  });
}
