// Runs every Learn example and exercise through the real practice runner and this PC's toolchains:
//   flutter test tool/verify_learn_test.dart
// - each lesson example (that has a console/simulator result) must print its expected lines;
// - each exercise's solution must pass all its tests, and its starter must NOT pass them all
//   (otherwise the tests check nothing).
// A missing runtime makes that track's tests fail with "could not start", never pass.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/learn/model.dart';
import 'package:nexus_ide/learn/practice.dart';
import 'package:nexus_ide/learn/tracks.dart';

Language lang(String id) => languages.firstWhere((l) => l.id == id);

/// Lessons whose result is visible behaviour (a page, a board) rather than printed lines.
bool printable(Track t, Lesson l) => !{'web', 'arduino'}.contains(t.langId) && !(t.langId == 'php' && l.needs.isNotEmpty);

void main() {
  setUpAll(() {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('verify_learn').path;
    Toolchains.toolsDir = '${Directory.current.path}/toolchains';
  });

  final only = Platform.environment['TRACK']; // e.g. TRACK=c to check one track
  for (final t in tracks.where((t) => only == null || t.langId == only)) {
    group(t.title, () {
      for (final l in t.lessons.where((l) => printable(t, l))) {
        test('lesson ${l.id} runs and prints its expected output', () async {
          final expect0 = l.checks.isNotEmpty ? l.checks : l.output.split('\n').where((s) => s.trim().isNotEmpty).toList();
          final ex = Exercise(
            id: 'verify-${l.id}',
            level: '',
            title: l.title,
            task: '',
            starter: '',
            requirements: const [],
            criteria: '',
            hint: '',
            solution: '',
            kind: t.langId == 'raspi' ? CheckKind.gpio : CheckKind.output,
            cases: [TestCase(input: l.input, expect: expect0)],
          );
          final r = await checkExercise(lang(t.langId), ex, PracticeRun(), code: l.example);
          expect(r.passed, isTrue, reason: '${r.message}\n${r.cases.map((c) => c.detail).join('\n')}');
        }, timeout: const Timeout(Duration(minutes: 5)));
      }
      // Sketches can't run here; at least each one must compile for an Uno.
      for (final l in t.lessons.where((l) => t.langId == 'arduino')) {
        test('lesson ${l.id} compiles', () async {
          final ex = Exercise(id: 'verify-${l.id}', level: '', title: l.title, task: '', starter: '', requirements: const [],
              criteria: '', hint: '', solution: '', kind: CheckKind.compileOnly);
          final r = await checkExercise(lang(t.langId), ex, PracticeRun(), code: l.example);
          expect(r.cases.single.passed, isTrue, reason: r.cases.single.detail);
        }, timeout: const Timeout(Duration(minutes: 5)));
      }
      for (final e in t.exercises) {
        test('exercise ${e.id}: solution passes, starter does not', () async {
          final good = await checkExercise(lang(t.langId), e, PracticeRun(), code: e.solution);
          switch (e.kind) {
            case CheckKind.output || CheckKind.gpio || CheckKind.staticHtml:
              expect(good.passed, isTrue, reason: '${good.message}\n${good.cases.map((c) => '${c.label}: ${c.detail}').join('\n')}');
              final bad = await checkExercise(lang(t.langId), e, PracticeRun(), code: e.starter);
              expect(bad.passed, isFalse, reason: 'the starter already passes: the tests check nothing');
            case CheckKind.compileOnly:
              expect(good.cases.single.passed, isTrue, reason: good.cases.single.detail);
              expect(good.passed, isFalse); // compiling is never reported as "passed"
            case CheckKind.manual:
              expect(good.passed, isFalse); // nothing automatic: never "passed"
              expect(e.checklist, isNotEmpty);
          }
        }, timeout: const Timeout(Duration(minutes: 5)));
      }
    });
  }
}
