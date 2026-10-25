import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/workspace.dart';

void main() {
  test('safeRel keeps paths inside the workspace', () {
    expect(safeRel('css/style.css'), 'css/style.css');
    expect(safeRel(r'img\\logo.png'), 'img/logo.png');
    for (final bad in ['../x.php', '/etc/passwd', 'a/../../b', '.env', '', 'a:b', 'C:/x']) {
      expect(safeRel(bad), isNull, reason: bad);
    }
  });

  test('nested create, list (folders first, generated files hidden), rename, delete', () {
    final root = Directory.systemTemp.createTempSync('ws').path;
    expect(createFolder(root, 'assets/img/icons'), isNull); // several levels at once
    expect(createFile(root, 'css/style.css'), isNull); // creates css/
    expect(createFile(root, 'index.html'), isNull);
    expect(createFile(root, 'index.html'), contains('already exists'));
    expect(createFile(root, '../escape.txt'), isNotNull);
    File('$root/main.exe').writeAsStringSync('x');

    expect(listDir(root).map((e) => e.name), ['assets', 'css', 'index.html']);
    expect(listDir(root, 'assets/img').single.rel, 'assets/img/icons');

    String? moved;
    expect(rename(root, 'css', 'styles', (r) => moved = r), isNull);
    expect(moved, 'styles');
    expect(File('$root/styles/style.css').existsSync(), isTrue);
    expect(rename(root, 'index.html', '../x.html', (_) {}), isNotNull);

    expect(fileCount(root, 'styles'), 1);
    delete(root, 'styles');
    expect(Directory('$root/styles').existsSync(), isFalse);
    delete(root, '../'); // refused, nothing happens
    expect(Directory(root).existsSync(), isTrue);
  });
}
