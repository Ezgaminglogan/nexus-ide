import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/main.dart';

/// flutter_test swaps in a fake HttpClient that answers 400 to everything; these talk to a real server.
Future<String> get(Uri url) => HttpOverrides.runWithHttpOverrides(() => _get(url), _Real());

class _Real extends HttpOverrides {}

Future<String> _get(Uri url) async {
  final c = HttpClient();
  try {
    final res = await (await c.getUrl(url)).close();
    return '${res.statusCode} ${await res.transform(utf8.decoder).join()}';
  } finally {
    c.close();
  }
}

void main() {
  setUp(() {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('htdocs').path;
    Settings.reset();
  });
  tearDown(() => LocalServer.instance.stop());

  test('projects are folders in htdocs; index.php makes a PHP project; names must work in a URL', () {
    expect(createProject('guestbook', php: true), isNull);
    expect(createProject('portfolio', php: false), isNull);
    expect(File('$htdocsDir/guestbook/index.php').existsSync(), isTrue);
    expect(File('$htdocsDir/portfolio/index.html').existsSync(), isTrue);
    expect(listProjects(), [(name: 'guestbook', php: true), (name: 'portfolio', php: false)]);
    expect(projectLanguage('guestbook').id, 'php');
    expect(projectLanguage('portfolio').id, 'web');
    expect(RunSession.workDir(projectLanguage('guestbook')).path, endsWith('htdocs${Platform.pathSeparator}guestbook'));
    expect(createProject('Guestbook', php: true), contains('already exists'));
    expect(createProject('my site', php: true), contains('letters, numbers'));
    expect(createProject('../out', php: true), contains('letters, numbers'));
    expect(Directory(htdocsDir).listSync().length, 2);
  });

  test('the old PHP and Web folders are copied into htdocs once, and stay where they were', () {
    File('${Toolchains.workRoot}/php/pages/about.php')
      ..createSync(recursive: true)
      ..writeAsStringSync('<?php echo 1;');
    File('${Toolchains.workRoot}/web/index.html')
      ..createSync(recursive: true)
      ..writeAsStringSync('<h1>mine</h1>');
    migrateToHtdocs();
    expect(File('$htdocsDir/my-php-site/pages/about.php').readAsStringSync(), '<?php echo 1;');
    expect(File('$htdocsDir/my-website/index.html').readAsStringSync(), '<h1>mine</h1>');
    expect(File('${Toolchains.workRoot}/php/pages/about.php').existsSync(), isTrue);
    File('$htdocsDir/my-website/index.html').writeAsStringSync('<h1>edited</h1>');
    migrateToHtdocs(); // second launch: nothing is copied over the student's edits
    expect(File('$htdocsDir/my-website/index.html').readAsStringSync(), '<h1>edited</h1>');
  });

  test('one server for htdocs answers at localhost/<project>/, on port 80 when free', () async {
    createProject('hello', php: true);
    File('$htdocsDir/hello/index.php').writeAsStringSync('<?php echo "hi from " . basename(__DIR__) . " at " . \$_SERVER["REQUEST_URI"];');
    File('$htdocsDir/hello/about.php').writeAsStringSync('<?php echo "about";');
    final s = LocalServer.instance;
    expect(await s.ensure(htdocsDir), isTrue, reason: s.error);
    expect(s.origin, s.port == 80 ? 'http://localhost' : 'http://localhost:${s.port}');
    expect(s.url('hello', 'index.php').toString(), '${s.origin}/hello/');
    expect(await get(s.url('hello')), '200 hi from hello at /hello/');
    expect(await get(s.url('hello', 'about.php')), '200 about');
    await s.stop();
    expect(s.running, isFalse);
  }, skip: Platform.isWindows ? false : 'needs PHP on PATH (this PC: XAMPP)');

  test('when port 80 is taken (XAMPP Apache), it uses 8080 instead', () async {
    ServerSocket? apache;
    try {
      apache = await ServerSocket.bind(InternetAddress.loopbackIPv4, 80);
      apache.listen((c) => c.destroy());
    } on SocketException {
      // something already serves port 80 on this PC: the same situation
    }
    createProject('site', php: false);
    final s = LocalServer.instance;
    expect(await s.ensure(htdocsDir), isTrue, reason: s.error);
    expect(s.port, isNot(80));
    expect(s.origin, 'http://localhost:${s.port}');
    expect(await get(s.url('site')), startsWith('200 '));
    await apache?.close();
  }, skip: Platform.isWindows ? false : 'needs PHP on PATH (this PC: XAMPP)');

  testWidgets('the PHP tile opens htdocs; New project makes the folder and opens it in the editor', (t) async {
    t.view.physicalSize = const Size(1280, 900);
    t.view.devicePixelRatio = 1;
    addTearDown(t.view.reset);
    createProject('portfolio', php: false);
    await t.pumpWidget(NexusApp(ready: Future.value()));
    await t.pumpAndSettle();
    await t.tap(find.text('Server pages · MySQL'));
    await t.pumpAndSettle();
    expect(find.text('htdocs'), findsOneWidget);
    expect(find.text('portfolio'), findsOneWidget);
    expect(find.text('http://localhost/portfolio/'), findsOneWidget);
    expect(find.textContaining(htdocsDir), findsOneWidget); // where it is on disk

    await t.tap(find.byKey(const Key('new-project')));
    await t.pumpAndSettle();
    await t.enterText(find.byKey(const Key('project-name')), 'my shop');
    await t.pump();
    await t.tap(find.byKey(const Key('project-create')));
    await t.pumpAndSettle();
    expect(find.textContaining('letters, numbers'), findsOneWidget); // no spaces in a URL
    await t.enterText(find.byKey(const Key('project-name')), 'shop');
    await t.pump();
    expect(find.text('Address: http://localhost/shop/'), findsOneWidget);
    await t.tap(find.byKey(const Key('project-create')));
    for (var i = 0; i < 5; i++) {
      await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 50)));
      await t.pump();
    }
    await t.pumpAndSettle();
    expect(File('$htdocsDir/shop/index.php').existsSync(), isTrue);
    expect(find.text('SHOP PROJECT'), findsOneWidget); // the editor, on the new project
    expect(find.text('Open in browser'), findsOneWidget);
  });
}
