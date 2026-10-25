import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/main.dart';

Language lang(String id) => languages.firstWhere((l) => l.id == id);

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 10; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

void main() {
  setUp(() {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('starters').path;
    Settings.reset();
  });

  group('templates fit the file and the project', () {
    test('Student.java gets class Student and no main(); Main.java keeps the runnable template', () {
      final java = lang('java');
      expect(starterFor(java, 'Student.java'), 'public class Student {\n    \n}\n');
      expect(starterFor(java, 'model/Student.java'), startsWith('public class Student {'));
      expect(starterFor(java, 'Main.java'), contains('public static void main'));
      expect(starterFor(java, 'Student.java'), isNot(contains('main(')));
    });

    test('extra C and C# files never add a second entry point', () {
      expect(starterFor(lang('c'), 'main.c'), contains('int main'));
      expect(starterFor(lang('c'), 'util.c'), isNot(contains('main(')));
      expect(starterFor(lang('csharp'), 'Program.cs'), contains('static void Main()'));
      expect(starterFor(lang('csharp'), 'Student.cs'), allOf(contains('class Student'), isNot(contains('Main('))));
      expect(starterFor(lang('csharp'), 'my-list.cs'), contains('class my_list')); // a valid identifier
      expect(starterFor(lang('arduino'), 'helpers.ino'), allOf(isNot(contains('void setup()')), isNot(contains('void loop()'))));
      expect(starterFor(lang('arduino'), 'arduino.ino'), allOf(contains('void setup()'), contains('void loop()')));
    });

    test('headers get a guard from their name; a .c file includes its own header when there is one', () {
      expect(starterFor(lang('c'), 'my-utils.h'), allOf(startsWith('#ifndef MY_UTILS_H\n#define MY_UTILS_H'), endsWith('#endif /* MY_UTILS_H */\n')));
      final root = '${Toolchains.workRoot}/c';
      File('$root/util.h')
        ..createSync(recursive: true)
        ..writeAsStringSync('');
      expect(starterFor(lang('c'), 'util.c', root: root), contains('#include "util.h"'));
      expect(starterFor(lang('c'), 'other.c', root: root), isNot(contains('#include "other.h"')));
    });

    test('Python and Raspberry Pi get their own starters, without imports that do not exist', () {
      final py = starterFor(lang('python'), 'helpers.py')!;
      expect(py, allOf(contains('def main():'), contains('if __name__ == "__main__":'), isNot(contains('RPi'))));
      final pi = starterFor(lang('raspi'), 'led.py')!;
      expect(pi, contains('import RPi.GPIO as GPIO')); // the simulator ships this module
      expect(pi, isNot(contains('gpiozero'))); // only LED/Button exist in the stand-in; not needed here
      expect(startersFor(lang('raspi'), 'led.py').map((s) => s.id), ['raspi-module', 'py-script']);
    });

    test('HTML links only the stylesheets and scripts that exist, relative to the new page', () {
      final root = '${Toolchains.workRoot}/web';
      expect(starterFor(lang('web'), 'about.html', root: root), allOf(isNot(contains('<link')), isNot(contains('<script'))));
      for (final f in ['css/site.css', 'js/app.js']) {
        File('$root/$f')
          ..createSync(recursive: true)
          ..writeAsStringSync('');
      }
      final page = starterFor(lang('web'), 'pages/about.html', root: root)!;
      expect(page, contains('<link rel="stylesheet" href="../css/site.css">'));
      expect(page, contains('<script src="../js/app.js"></script>'));
      expect(page, contains('<title>about</title>'));
    });

    test('PHP picks the file role from its name; unknown types get no template', () {
      expect(startersFor(lang('php'), 'db.php').first.id, 'php-db');
      expect(starterFor(lang('php'), 'db.php'), contains('new mysqli("127.0.0.1", "root", "", "nexus")'));
      expect(startersFor(lang('php'), 'about.php').first.id, 'php-page');
      expect(starterFor(lang('web'), 'notes.txt'), isNull);
      expect(starterFor(lang('web'), 'logo.png'), isNull);
      expect(fileType('notes.txt'), isNull);
    });

    test('the cursor marker never reaches the file, and the cursor lands inside the body', () {
      final c = starterCode(lang('java'), 'Student.java')!;
      expect(c.text.contains('\u{E000}'), isFalse);
      expect(c.text.substring(0, c.cursor), 'public class Student {\n    ');
    });

    test('records follow renames, so Reset rebuilds the chosen template with the new name', () {
      final pi = lang('raspi');
      recordStarter(pi, 'lib/blink.py', 'py-script');
      moveStarterRecords(pi, 'lib', 'helpers');
      expect(starterId(pi, 'lib/blink.py'), isNull);
      expect(starterId(pi, 'helpers/blink.py'), 'py-script');
      expect(starterFor(pi, 'helpers/blink.py', id: starterId(pi, 'helpers/blink.py')), isNot(contains('RPi')));
      forgetStarterRecords(pi, 'helpers');
      expect(starterId(pi, 'helpers/blink.py'), isNull);
    });
  });

  group('Add File dialog', () {
    Future<void> openJava(WidgetTester t, Size size) async {
      t.view.physicalSize = size;
      t.view.devicePixelRatio = 1;
      addTearDown(t.view.reset);
      await t.pumpWidget(NexusApp(ready: Future.value()));
      await settle(t);
      await t.ensureVisible(find.text('Object-oriented'));
      await t.tap(find.text('Object-oriented'));
      await settle(t);
      if (find.byTooltip('New file').evaluate().isEmpty) {
        await t.tap(find.byTooltip('Files (explorer)')); // phones: explorer drawer
        await settle(t);
      }
      await t.tap(find.byTooltip('New file'));
      await settle(t);
    }

    for (final (label, size) in [('desktop', const Size(1400, 900)), ('phone', const Size(400, 860))]) {
      testWidgets('$label: Student becomes Student.java with class Student, opened at the cursor', (t) async {
        await openJava(t, size);
        await t.enterText(find.byKey(const Key('new-file-name')), 'Student');
        await t.pump();
        expect(find.text('Student.java'), findsOneWidget); // the full name, shown before creating
        expect(find.textContaining('.java (this workspace'), findsOneWidget);
        expect(find.text('Java'), findsWidgets);
        expect(find.text('Java class named like the file'), findsOneWidget);
        await t.tap(find.text('Preview'));
        await t.pump();
        expect(find.textContaining('public class Student {'), findsWidgets);

        await t.tap(find.byKey(const Key('new-file-create')));
        await settle(t);
        final f = File('${Toolchains.workRoot}/java/Student.java');
        expect(f.readAsStringSync(), 'public class Student {\n    \n}\n');
        expect(starterId(lang('java'), 'Student.java'), 'java-class');
        final code = t.widget<EditableText>(find.byType(EditableText).first).controller;
        expect(code.text, contains('public class Student'));
        expect(code.selection.baseOffset, 'public class Student {\n    '.length);
      });
    }

    testWidgets('invalid, duplicate and Windows-reserved names are refused inside the dialog; nothing is created', (t) async {
      await openJava(t, const Size(1400, 900));
      for (final (name, msg) in [
        ('my-class.java', 'valid class name'),
        ('Main.java', 'already exists'),
        ('con.java', 'Windows keeps'),
        ('../escape.java', 'Use letters'),
        ('bad.', 'end with a dot'),
      ]) {
        if (name == 'Main.java') {
          File('${Toolchains.workRoot}/java/Main.java')
            ..createSync(recursive: true)
            ..writeAsStringSync('mine');
        }
        await t.enterText(find.byKey(const Key('new-file-name')), name);
        await t.pump();
        await t.tap(find.byKey(const Key('new-file-create')));
        await settle(t);
        expect(find.textContaining(msg), findsOneWidget, reason: name);
      }
      expect(File('${Toolchains.workRoot}/java/Main.java').readAsStringSync(), 'mine'); // never overwritten
      expect(Directory('${Toolchains.workRoot}/java').listSync().whereType<File>().map((f) => f.uri.pathSegments.last), ['Main.java']);
    });

    testWidgets('unchecking Include starter code makes an empty file; unknown types are empty too', (t) async {
      await openJava(t, const Size(1400, 900));
      await t.enterText(find.byKey(const Key('new-file-name')), 'Empty.java');
      await t.pump();
      await t.tap(find.byKey(const Key('new-file-include')));
      await t.pump();
      await t.tap(find.byKey(const Key('new-file-create')));
      await settle(t);
      expect(File('${Toolchains.workRoot}/java/Empty.java').readAsStringSync(), '');

      await t.tap(find.byTooltip('New file'));
      await settle(t);
      await t.enterText(find.byKey(const Key('new-file-name')), 'docs/notes.txt');
      await t.pump();
      expect(find.text('Unknown type: the file will be empty'), findsOneWidget);
      await t.tap(find.byKey(const Key('new-file-create')));
      await settle(t);
      expect(File('${Toolchains.workRoot}/java/docs/notes.txt').readAsStringSync(), '');
    });

    testWidgets('a nested destination folder is used, and opening existing files never adds boilerplate', (t) async {
      final dir = Directory('${Toolchains.workRoot}/java/model')..createSync(recursive: true);
      File('${dir.parent.path}/Blank.java').writeAsStringSync(''); // intentionally empty: must stay empty
      await openJava(t, const Size(1400, 900));
      await t.tap(find.byKey(const Key('new-file-folder')));
      await settle(t);
      await t.tap(find.text('model/').last);
      await settle(t);
      await t.enterText(find.byKey(const Key('new-file-name')), 'Course.java');
      await t.pump();
      expect(find.text('model/Course.java'), findsOneWidget);
      await t.tap(find.byKey(const Key('new-file-create')));
      await settle(t);
      expect(File('${dir.path}/Course.java').readAsStringSync(), startsWith('public class Course {'));

      await t.tap(find.text('Blank.java'));
      await settle(t);
      await t.tap(find.text('Course.java').first);
      await settle(t);
      expect(File('${dir.parent.path}/Blank.java').readAsStringSync(), '');
    });
  });
}
