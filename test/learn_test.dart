import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/core.dart';
import 'package:nexus_ide/learn/model.dart';
import 'package:nexus_ide/learn/practice.dart';
import 'package:nexus_ide/learn/tracks.dart';
import 'package:nexus_ide/ui/screens/learn_screen.dart';
import 'package:nexus_ide/ui/theme.dart';

Future<void> settle(WidgetTester t) async {
  for (var i = 0; i < 8; i++) {
    await t.runAsync(() => Future<void>.delayed(const Duration(milliseconds: 30)));
    await t.pump(const Duration(milliseconds: 50));
  }
}

Future<void> open(WidgetTester t, {String? langId, Size size = const Size(1400, 1000)}) async {
  t.view.physicalSize = size;
  t.view.devicePixelRatio = 1;
  addTearDown(t.view.reset);
  await t.pumpWidget(MaterialApp(theme: Nx.theme(), home: LearnScreen(langId: langId)));
  await settle(t);
}

void main() {
  setUp(() {
    Toolchains.workRoot = Directory.systemTemp.createTempSync('learn').path;
    Settings.reset();
  });

  test('every workspace has a complete track', () {
    expect({for (final t in tracks) t.langId}, {for (final l in languages) l.id});
    for (final t in tracks) {
      expect(t.quiz, hasLength(10), reason: t.langId);
      expect(t.exercises.map((e) => e.level), ['Beginner', 'Intermediate', 'Challenge'], reason: t.langId);
      expect(t.lessons.length, greaterThanOrEqualTo(6), reason: t.langId);
      for (final q in t.quiz) {
        expect(q.answer, inInclusiveRange(0, q.options.length - 1), reason: q.question);
      }
      for (final l in t.lessons) {
        for (final part in [l.objective, l.explanation, l.syntax, l.example, l.output, l.mistake, l.mistakeCode, l.fixCode, l.practice]) {
          expect(part.trim(), isNotEmpty, reason: '${l.id} has an empty part');
        }
        expect(l.syntaxNotes, isNotEmpty, reason: l.id);
        expect(l.lines, isNotEmpty, reason: l.id);
        expect(l.refs, isNotEmpty, reason: l.id);
        for (final r in l.refs) {
          expect(r.url, startsWith('https://'), reason: l.id);
          expect([r.title, r.publisher, r.verified].every((s) => s.isNotEmpty), isTrue, reason: l.id);
        }
      }
      for (final e in t.exercises) {
        // Anything a person has to look at comes with a checklist.
        if (e.kind != CheckKind.output && e.kind != CheckKind.gpio) expect(e.checklist, isNotEmpty, reason: e.id);
        if (e.kind == CheckKind.output || e.kind == CheckKind.gpio) expect(e.cases, isNotEmpty, reason: e.id);
      }
    }
    final ids = [for (final t in tracks) ...t.lessons.map((l) => l.id), for (final t in tracks) ...t.exercises.map((e) => e.id)];
    expect(ids.toSet(), hasLength(ids.length), reason: 'ids must be unique (they name practice folders and progress keys)');
  });

  test('a result is "passed" only when an automatic check ran every case and all passed', () {
    expect(CheckResult(automatic: false, cases: [CaseResult('Compiles', true)]).passed, isFalse);
    expect(CheckResult(automatic: true).passed, isFalse); // nothing ran
    expect(CheckResult(automatic: true, cases: [CaseResult('a', true), CaseResult('b', false)]).passed, isFalse);
    expect(CheckResult(automatic: true, cases: [CaseResult('a', true)]).passed, isTrue);
    expect(outputMatches('Enter a score: Average: 85.50\n', ['average: 85.50']), isTrue);
    expect(outputMatches('B\nA\n', ['A', 'B']), isFalse); // order matters
  });

  testWidgets('search finds lessons by function name and opens them; breadcrumbs and next work', (t) async {
    await open(t);
    expect(find.text('Learn & Practice'), findsOneWidget);
    await t.enterText(find.byKey(const Key('learn-search')), 'printf');
    await t.pump();
    expect(find.text('Input and output'), findsWidgets);
    await t.tap(find.text('Input and output').first);
    await settle(t);
    expect(find.text('Lesson 3 of 9'), findsOneWidget);
    expect(find.text('Objective'), findsOneWidget);
    expect(find.text('Common mistake'), findsOneWidget);
    expect(find.text('Try in Editor'), findsOneWidget);
    expect(find.text('View Source'), findsWidgets);
    expect(Settings.named('learn').get('read.c-io', false), isTrue);

    await t.enterText(find.byKey(const Key('learn-search')), 'zzqx nothing');
    await t.pump();
    expect(find.textContaining('No lessons match'), findsOneWidget);
  });

  testWidgets('quiz: scores answers, keeps the best score, and can be retried', (t) async {
    await open(t, langId: 'python');
    final python = tracks.firstWhere((t) => t.langId == 'python');
    await t.tap(find.text('Quiz').last);
    await settle(t);
    // Answer the first two questions: one right, one wrong.
    final q0 = python.quiz[0], q1 = python.quiz[1];
    for (final o in [q0.options[q0.answer], q1.options[(q1.answer + 1) % q1.options.length]]) {
      await t.ensureVisible(find.text(o).first);
      await t.pump();
      await t.tap(find.text(o).first);
      await t.pump();
    }
    await t.pump();
    await t.ensureVisible(find.text('Check answers'));
    await t.pump();
    await t.tap(find.text('Check answers'));
    await t.pump();
    expect(find.text('Score: 1 of 10'), findsOneWidget);
    expect(Settings.named('learn').get<num?>('quiz.python.best', null), 1);
    await t.ensureVisible(find.text('Try again'));
    await t.pump();
    await t.tap(find.text('Try again'));
    await t.pump();
    expect(find.text('Check answers'), findsOneWidget);
  });

  testWidgets('a manual exercise never shows Passed; the solution unlocks only after an attempt', (t) async {
    await open(t, langId: 'php');
    await t.enterText(find.byKey(const Key('learn-search')), 'guest book');
    await t.pump();
    await t.tap(find.text('Guest book with MySQL'));
    await settle(t);
    final php = tracks.firstWhere((t) => t.langId == 'php').exercises.last;

    await t.ensureVisible(find.text('Show solution'));
    await t.pump();
    final locked = t.widget<OutlinedButton>(find.ancestor(of: find.text('Show solution'), matching: find.byType(OutlinedButton)));
    expect(locked.onPressed, isNull);

    await t.ensureVisible(find.byKey(const Key('check')));
    await t.pump();
    await t.tap(find.byKey(const Key('check')));
    await settle(t);
    expect(find.text('Not checked automatically'), findsOneWidget);
    expect(find.textContaining('Passed'), findsNothing);
    expect(Settings.named('learn').get('ex.${php.id}.passed', false), isFalse);
    expect(File('${Toolchains.workRoot}/practice/${php.id}/php/index.php').readAsStringSync(), php.starter); // practice folder, not the workspace

    await t.ensureVisible(find.text('Show solution'));
    await t.pump();
    await t.tap(find.text('Show solution'));
    await t.pump();
    expect(find.text('One possible solution'), findsOneWidget);
  });

  testWidgets('phones get the topics in a drawer', (t) async {
    await open(t, size: const Size(400, 800));
    expect(find.byKey(const Key('learn-search')), findsNothing);
    await t.tap(find.byTooltip('Open navigation menu'));
    await settle(t);
    expect(find.byKey(const Key('learn-search')), findsOneWidget);
    await t.enterText(find.byKey(const Key('learn-search')), 'class main');
    await t.pump();
    await t.tap(find.text('Class and main method'));
    await settle(t);
    expect(find.byKey(const Key('learn-search')), findsNothing); // drawer closed
    expect(find.text('Lesson 1 of 9'), findsOneWidget);
  });
}
