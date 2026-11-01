import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/main.dart';

/// flutter_test swaps in a fake HttpClient that answers 400 to everything; these talk to a real server.
Future<String> get(Uri url) => HttpOverrides.runWithHttpOverrides(() => _get(url), _Real());

class _Real extends HttpOverrides {}

/// POSTs a form, then GETs the page again (as the browser does after a redirect).
Future<String> post(Uri url, String form) => HttpOverrides.runWithHttpOverrides(() async {
      final c = HttpClient();
      try {
        final req = await c.postUrl(url)
          ..headers.contentType = ContentType('application', 'x-www-form-urlencoded')
          ..write(form);
        await (await req.close()).drain<void>();
        return await _get(url);
      } finally {
        c.close();
      }
    }, _Real());

const _mysqlExe = r'C:\xampp\mysql\bin\mysql.exe';

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

  test('projects are folders in htdocs; index.php makes a PHP project; names must work in a URL', () async {
    expect(await createProject('guestbook', stack: 'php-mysql'), isNull);
    expect(await createProject('portfolio', stack: 'html'), isNull);
    expect(File('$htdocsDir/guestbook/index.php').existsSync(), isTrue);
    expect(File('$htdocsDir/portfolio/index.html').existsSync(), isTrue);
    expect([for (final p in listProjects()) (p.name, p.php, p.stack.label)], [('guestbook', true, 'PHP + MySQL'), ('portfolio', false, 'HTML + CSS + JS')]);
    expect(projectLanguage('guestbook').id, 'php');
    expect(projectLanguage('portfolio').id, 'web');
    expect(RunSession.workDir(projectLanguage('guestbook')).path, endsWith('htdocs${Platform.pathSeparator}guestbook'));
    expect(await createProject('Guestbook', stack: 'php-mysql'), contains('already exists'));
    expect(await createProject('my site', stack: 'php-mysql'), contains('letters, numbers'));
    expect(await createProject('../out', stack: 'php-mysql'), contains('letters, numbers'));
    expect(Directory(htdocsDir).listSync().length, 2); // nothing half-made by the refused names
  });

  test('stacks: SQLite guest book saves a name; Bootstrap ships offline; Bootstrap + MySQL adds a student', () async {
    expect(await createProject('book', stack: 'php-sqlite'), isNull);
    expect(await createProject('styled', stack: 'html-bootstrap'), isNull);
    expect(await createProject('crud', stack: 'php-bootstrap-mysql'), isNull);
    expect([for (final p in listProjects()) p.stack.label], ['PHP + SQLite', 'PHP + Bootstrap + MySQL', 'HTML + Bootstrap 5']);
    expect(File('$htdocsDir/styled/assets/bootstrap/css/bootstrap.min.css').readAsStringSync(), contains('Bootstrap  v5.3.8'));
    expect(File('$htdocsDir/crud/assets/bootstrap/js/bootstrap.bundle.min.js').existsSync(), isTrue);
    expect(Directory('$htdocsDir/book/assets').existsSync(), isFalse);

    final s = LocalServer.instance;
    expect(await s.ensure(htdocsDir), isTrue, reason: s.error);
    expect(await post(s.url('book'), 'name=Ana+%3Cb%3E'), allOf(startsWith('200 '), contains('Ana &lt;b&gt;'), isNot(contains('Database:'))));
    expect(File('$htdocsDir/book/guestbook.db').existsSync(), isTrue);
    expect(await get(Uri.parse('${s.origin}/styled/assets/bootstrap/css/bootstrap.min.css')), startsWith('200 @charset'));
    expect(await get(s.url('styled')), contains('<nav class="navbar'));

    if (Process.runSync(_mysqlExe, ['-h', '127.0.0.1', '-u', 'root', '-e', 'SELECT 1']).exitCode == 0) {
      final name = 'Test${DateTime.now().millisecondsSinceEpoch}';
      expect(await post(s.url('crud'), 'name=$name&course=BEEd'), allOf(contains(name), contains('BEEd'), isNot(contains('alert-danger'))));
      Process.runSync(_mysqlExe, ['-h', '127.0.0.1', '-u', 'root', 'nexus', '-e', "DELETE FROM crud_students WHERE name = '$name'"]);
    }
  }, skip: Platform.isWindows ? false : 'needs PHP on PATH (this PC: XAMPP)');

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
    await createProject('hello', stack: 'php-mysql');
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
    await createProject('site', stack: 'html');
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
    await createProject('portfolio', stack: 'html');
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
