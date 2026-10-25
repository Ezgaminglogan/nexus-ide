import 'dart:io';

import 'package:flutter/material.dart' hide Step;
import 'package:flutter/services.dart';
import 'package:flutter_highlight/flutter_highlight.dart';
import 'package:flutter_highlight/themes/vs2015.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../../learn/model.dart';
import '../../learn/practice.dart';
import '../../learn/tracks.dart';
import '../theme.dart';
import 'editor_screen.dart';

/// Learn & Practice: offline lessons, a quiz and checked exercises for every workspace.
/// Progress lives in workspace/.nexus/learn.json; practice code in workspace/practice/, never in
/// the student's own workspace files.
class LearnScreen extends StatefulWidget {
  const LearnScreen({super.key, this.langId});
  final String? langId; // open at this track's overview
  @override
  State<LearnScreen> createState() => _LearnScreenState();
}

enum _Kind { overview, lesson, quiz, exercise }

typedef _Page = ({int t, _Kind kind, int i});

const _mono = TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 13.5, height: 1.45, color: Color(0xFFD6DCEA));
const _ok = Color(0xFF3DDC84), _warn = Color(0xFFFFB224);

Settings get _progress => Settings.named('learn');
Language _base(Track t) => languages.firstWhere((l) => l.id == t.langId);

String _codeLang(String langId) => switch (langId) {
      'c' || 'arduino' => 'cpp',
      'python' || 'raspi' => 'python',
      'java' => 'java',
      'csharp' => 'cs',
      _ => 'xml', // web, php: HTML with <?php ?> and <script> blocks
    };

class _LearnScreenState extends State<LearnScreen> {
  late final List<_Page> _pages = [
    for (final (t, tr) in tracks.indexed) ...[
      (t: t, kind: _Kind.overview, i: 0),
      for (var i = 0; i < tr.lessons.length; i++) (t: t, kind: _Kind.lesson, i: i),
      (t: t, kind: _Kind.quiz, i: 0),
      for (var i = 0; i < tr.exercises.length; i++) (t: t, kind: _Kind.exercise, i: i),
    ],
  ];
  late _Page _page = (t: tracks.indexWhere((t) => t.langId == widget.langId).clamp(0, tracks.length - 1), kind: _Kind.overview, i: 0);
  late final Set<int> _open = {_page.t}; // expanded tracks in the sidebar
  bool _sidebar = true;
  String _query = '';
  final _scroll = ScrollController();
  final _status = <String, Future<(String, String)>>{};

  // Quiz and exercise state survives switching pages.
  final _answers = <int, Map<int, int>>{};
  final _submitted = <int>{};
  final _results = <String, CheckResult>{};
  final _showSolution = <String>{};
  String? _checking;
  PracticeRun? _run;

  Track get _track => tracks[_page.t];

  void _setQuery(String v) => setState(() => _query = v);

  void _go(_Page p) {
    setState(() {
      _page = p;
      _open.add(p.t);
    });
    if (p.kind == _Kind.lesson) _progress.set('read.${tracks[p.t].lessons[p.i].id}', true);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  String _pageTitle(_Page p) {
    final t = tracks[p.t];
    return switch (p.kind) {
      _Kind.overview => '${t.title}: overview',
      _Kind.lesson => t.lessons[p.i].title,
      _Kind.quiz => '${t.title} quiz',
      _Kind.exercise => t.exercises[p.i].title,
    };
  }

  void _say(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  @override
  void dispose() {
    _run?.stop();
    _scroll.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= 900;
    final sidebar = _Sidebar(state: this);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Learn & Practice'),
        actions: [
          if (wide)
            IconButton(
              tooltip: _sidebar ? 'Hide topics' : 'Show topics',
              onPressed: () => setState(() => _sidebar = !_sidebar),
              icon: Icon(_sidebar ? Icons.menu_open : Icons.menu),
            ),
        ],
      ),
      drawer: wide ? null : Drawer(width: 320, backgroundColor: Nx.bg, child: SafeArea(child: sidebar)),
      body: Row(children: [
        if (wide && _sidebar) ...[SizedBox(width: 320, child: sidebar), const VerticalDivider(width: 1, color: Nx.line)],
        Expanded(
          child: SelectionArea(
            child: ListView(
              controller: _scroll,
              padding: EdgeInsets.symmetric(horizontal: wide ? 32 : 16, vertical: 16),
              children: [
                Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 920),
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      _breadcrumbs(),
                      const SizedBox(height: 8),
                      ...switch (_page.kind) {
                        _Kind.overview => _overview(),
                        _Kind.lesson => _lesson(_track.lessons[_page.i]),
                        _Kind.quiz => _quiz(),
                        _Kind.exercise => _exercise(_track.exercises[_page.i]),
                      },
                      const SizedBox(height: 24),
                      _prevNext(),
                    ]),
                  ),
                ),
              ],
            ),
          ),
        ),
      ]),
    );
  }

  Widget _breadcrumbs() {
    final crumbs = <(String, _Page?)>[
      ('Learn', null),
      (_track.title, (t: _page.t, kind: _Kind.overview, i: 0)),
      if (_page.kind == _Kind.lesson) ('Lesson ${_page.i + 1} of ${_track.lessons.length}', null),
      if (_page.kind == _Kind.quiz) ('Quiz', null),
      if (_page.kind == _Kind.exercise) ('Exercise ${_page.i + 1} of ${_track.exercises.length}', null),
    ];
    return Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
      for (final (i, (label, target)) in crumbs.indexed) ...[
        if (i > 0) const Icon(Icons.chevron_right, size: 16, color: Nx.muted),
        target != null && _page.kind != _Kind.overview
            ? InkWell(onTap: () => _go(target), child: Text(label, style: const TextStyle(color: Color(0xFF8FB0FF), fontSize: 13)))
            : Text(label, style: const TextStyle(color: Nx.muted, fontSize: 13)),
      ],
    ]);
  }

  Widget _prevNext() {
    final at = _pages.indexOf(_page);
    final prev = at > 0 ? _pages[at - 1] : null, next = at < _pages.length - 1 ? _pages[at + 1] : null;
    Widget side(_Page? p, bool forward) => p == null
        ? const SizedBox()
        : OutlinedButton.icon(
            onPressed: () => _go(p),
            icon: Icon(forward ? Icons.arrow_forward : Icons.arrow_back),
            label: Text(_pageTitle(p), overflow: TextOverflow.ellipsis),
          );
    return Row(children: [
      Flexible(child: side(prev, false)),
      const Spacer(),
      Flexible(child: Directionality(textDirection: TextDirection.rtl, child: side(next, true))),
    ]);
  }

  // ---------- pieces ----------

  Widget _h1(String title, String sub) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(sub, style: const TextStyle(fontSize: 15, color: Nx.muted)),
        ]),
      );

  Widget _section(String title, List<Widget> body) => Padding(
        padding: const EdgeInsets.only(top: 18),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700, color: Color(0xFF8FB0FF))),
          const SizedBox(height: 8),
          ...body,
        ]),
      );

  Widget _p(String text) => Padding(padding: const EdgeInsets.only(bottom: 6), child: Text(text, style: const TextStyle(fontSize: 15, height: 1.5)));

  Widget _bullets(List<String> items, {bool numbered = false}) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final (i, s) in items.indexed)
            Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                SizedBox(width: 26, child: Text(numbered ? '${i + 1}.' : '•', style: const TextStyle(fontSize: 15, color: Nx.muted))),
                Expanded(child: Text(s, style: const TextStyle(fontSize: 15, height: 1.45))),
              ]),
            ),
        ],
      );

  Widget _box(String label, String text, {Color? color}) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: const Color(0xFF111827), borderRadius: BorderRadius.circular(10), border: Border.all(color: color ?? Nx.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Padding(padding: const EdgeInsets.fromLTRB(12, 8, 12, 0), child: Text(label, style: TextStyle(fontSize: 12, color: color ?? Nx.muted, fontWeight: FontWeight.w600))),
          Padding(padding: const EdgeInsets.all(12), child: Text(text, style: _mono)),
        ]),
      );

  Widget _code(String code, {String label = '', Color? border}) => CodeBlock(code, language: _codeLang(_track.langId), label: label, border: border);

  Widget _needs(String needs) => needs.isEmpty
      ? const SizedBox()
      : Container(
          margin: const EdgeInsets.only(top: 6),
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: _warn.withValues(alpha: 0.10), borderRadius: BorderRadius.circular(10), border: Border.all(color: _warn.withValues(alpha: 0.5))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            const Icon(Icons.memory, size: 18, color: _warn),
            const SizedBox(width: 8),
            Expanded(child: Text('Needs: $needs', style: const TextStyle(fontSize: 13.5, height: 1.4))),
          ]),
        );

  Widget _runtime(Track t) {
    final f = _status[t.langId] ??= runtimeStatus(_base(t));
    return FutureBuilder(
      future: f,
      builder: (context, snap) {
        final (state, detail) = snap.data ?? ('checking', 'Checking what runs this here...');
        final color = switch (state) { 'installed' || 'built-in' => _ok, 'simulated' => const Color(0xFF8FB0FF), 'checking' => Nx.muted, _ => Nx.stop };
        return Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.5))),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(6)),
              child: Text(state.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(detail, style: const TextStyle(fontSize: 13.5))),
          ]),
        );
      },
    );
  }

  String _outputLabel(Lesson l) => switch (_track.langId) {
        'raspi' => 'Simulated result (NEXUS board, not real hardware)',
        'arduino' => 'On a real board (NEXUS does not simulate Arduino)',
        'web' => 'What the preview shows',
        'php' when l.needs.isNotEmpty => 'What the page shows',
        _ => 'Expected output',
      };

  // ---------- pages ----------

  List<Widget> _overview() {
    final t = _track;
    final read = t.lessons.where((l) => _progress.get('read.${l.id}', false)).length;
    final best = _progress.get<num?>('quiz.${t.langId}.best', null);
    final passed = t.exercises.where((e) => _progress.get('ex.${e.id}.passed', false)).length;
    return [
      Row(children: [
        LanguageBadge(_base(t), size: 44),
        const SizedBox(width: 14),
        Expanded(child: _h1(t.title, '${t.lessons.length} lessons · ${t.quiz.length} quiz questions · ${t.exercises.length} exercises')),
      ]),
      _p(t.intro),
      _section('What runs your code', [Text(t.runtime, style: const TextStyle(fontSize: 14, height: 1.45)), const SizedBox(height: 8), _runtime(t)]),
      _section('How to run the examples', [_bullets(t.run, numbered: true)]),
      _section('Your progress', [
        _bullets([
          'Lessons opened: $read of ${t.lessons.length}',
          'Quiz: ${best == null ? 'not taken yet' : 'best score $best of ${t.quiz.length}'}',
          'Exercises passed by an automatic check: $passed of ${t.exercises.where((e) => e.kind == CheckKind.output || e.kind == CheckKind.gpio || e.kind == CheckKind.staticHtml).length}',
        ]),
      ]),
      _section('Lessons', [
        for (final (i, l) in t.lessons.indexed)
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(_progress.get('read.${l.id}', false) ? Icons.check_circle : Icons.circle_outlined, color: _progress.get('read.${l.id}', false) ? _ok : Nx.muted),
            title: Text('${i + 1}. ${l.title}'),
            subtitle: Text(l.summary),
            onTap: () => _go((t: _page.t, kind: _Kind.lesson, i: i)),
          ),
      ]),
    ];
  }

  List<Widget> _lesson(Lesson l) {
    final t = _track;
    return [
      _h1(l.title, l.summary),
      _needs(l.needs),
      _section('Objective', [_p(l.objective)]),
      _section('Explanation', [_p(l.explanation)]),
      _section('Syntax', [
        _code(l.syntax, label: 'Syntax'),
        for (final (part, meaning) in l.syntaxNotes)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Flexible(flex: 2, child: Text(part, style: _mono.copyWith(color: const Color(0xFFFFD580)))),
              const SizedBox(width: 12),
              Flexible(flex: 3, child: Text(meaning, style: const TextStyle(fontSize: 14.5, height: 1.4))),
            ]),
          ),
      ]),
      _section('Complete example', [
        _code(l.example, label: l.exampleFile.isEmpty ? _base(t).fileName : l.exampleFile),
        Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.icon(
            onPressed: _base(t).availableHere ? () => _tryInEditor(l) : null,
            icon: const Icon(Icons.play_arrow),
            label: const Text('Try in Editor'),
          ),
        ]),
        Padding(
          padding: const EdgeInsets.only(top: 6),
          child: Text(
            _base(t).availableHere
                ? 'Opens a separate practice copy (practice/lesson-${l.id}), so your own ${_base(t).label} files are not changed.'
                : '${_base(t).label} does not run on this device.',
            style: const TextStyle(fontSize: 12.5, color: Nx.muted),
          ),
        ),
      ]),
      _section('How to run it', [_bullets(l.run.isEmpty ? t.run : l.run, numbered: true)]),
      _section('Sample input and output', [
        if (l.input.isNotEmpty) _box('Sample input (type it in the terminal)', l.input),
        _box(_outputLabel(l), l.output, color: t.langId == 'raspi' ? const Color(0xFF8FB0FF) : null),
      ]),
      _section('Important lines explained', [_bullets(l.lines)]),
      _section('Common mistake', [
        _p(l.mistake),
        _code(l.mistakeCode, label: 'Wrong', border: Nx.stop),
        const SizedBox(height: 8),
        _code(l.fixCode, label: 'Fixed', border: _ok),
      ]),
      _section('Practice task', [_p(l.practice)]),
      _section('References', [
        for (final r in l.refs) _RefTile(r, onFail: () => _say('Could not open the page. View Source needs the internet; this lesson works offline.')),
        const Text('View Source opens the original page in your browser and needs the internet. The lesson above is written for NEXUS and works offline.',
            style: TextStyle(fontSize: 12.5, color: Nx.muted)),
      ]),
    ];
  }

  Future<void> _tryInEditor(Lesson l) async {
    final base = _base(_track);
    final lang = base.practice('lesson-${l.id}', '${base.label} · ${l.title}');
    final file = l.exampleFile.isEmpty ? lang.fileName : l.exampleFile;
    final f = File('${RunSession.workDir(lang).path}/$file');
    if (f.existsSync() && f.readAsStringSync() != l.example) {
      final choice = await showDialog<String>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Replace your practice copy?'),
          content: Text('You already changed the practice copy of "${l.title}". Open your copy as it is, or replace it with the lesson\'s example?'),
          actions: [
            TextButton(autofocus: true, onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            TextButton(onPressed: () => Navigator.pop(context, 'open'), child: const Text('Open my copy')),
            FilledButton(onPressed: () => Navigator.pop(context, 'replace'), child: const Text('Replace with example')),
          ],
        ),
      );
      if (choice == null) return;
      if (choice == 'replace') await RunSession.save(lang, l.example, file);
    } else {
      await RunSession.save(lang, l.example, file);
    }
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(language: lang)));
  }

  List<Widget> _quiz() {
    final t = _track, ti = _page.t;
    final answers = _answers[ti] ??= {};
    final done = _submitted.contains(ti);
    final score = [for (final (i, q) in t.quiz.indexed) if (answers[i] == q.answer) i].length;
    final best = _progress.get<num?>('quiz.${t.langId}.best', null);
    return [
      _h1('${t.title} quiz', '${t.quiz.length} questions. Pick one answer each, then press Check answers.${best == null ? '' : ' Best so far: $best of ${t.quiz.length}.'}'),
      for (final (i, q) in t.quiz.indexed)
        Card(
          color: Nx.surface,
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('${i + 1}. ${q.question}', style: const TextStyle(fontSize: 15.5, fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              RadioGroup<int>(
                groupValue: answers[i],
                onChanged: (v) => done ? null : setState(() => answers[i] = v!),
                child: Column(children: [
                  for (final (j, o) in q.options.indexed)
                    RadioListTile<int>(
                      dense: true,
                      contentPadding: EdgeInsets.zero,
                      value: j,
                      enabled: !done,
                      title: Text(o, style: TextStyle(
                        color: !done ? null : j == q.answer ? _ok : answers[i] == j ? Nx.stop : null,
                        fontWeight: done && j == q.answer ? FontWeight.w700 : null,
                      )),
                    ),
                ]),
              ),
              if (done)
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Icon(answers[i] == q.answer ? Icons.check_circle : Icons.cancel, size: 18, color: answers[i] == q.answer ? _ok : Nx.stop),
                  const SizedBox(width: 6),
                  Expanded(child: Text('${answers[i] == q.answer ? 'Correct. ' : answers[i] == null ? 'Not answered. ' : 'Not quite. '}${q.why}', style: const TextStyle(fontSize: 13.5, height: 1.4))),
                ]),
            ]),
          ),
        ),
      if (done)
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('Score: $score of ${t.quiz.length}', key: const Key('quiz-score'), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
        ),
      Wrap(spacing: 8, children: [
        if (!done)
          FilledButton(
            onPressed: answers.isEmpty
                ? null
                : () {
                    setState(() => _submitted.add(ti));
                    final s = [for (final (i, q) in t.quiz.indexed) if (answers[i] == q.answer) i].length;
                    if (best == null || s > best) _progress.set('quiz.${t.langId}.best', s);
                  },
            child: const Text('Check answers'),
          ),
        if (done)
          OutlinedButton.icon(
            onPressed: () => setState(() {
              _submitted.remove(ti);
              answers.clear();
            }),
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
      ]),
    ];
  }

  String _howChecked(Exercise e) => switch (e.kind) {
        CheckKind.output => 'Check runs your program with ${e.cases.length} test${e.cases.length == 1 ? '' : 's'} (10 seconds each) and compares what it prints.',
        CheckKind.gpio => 'Check runs your program in the Raspberry Pi simulator with ${e.cases.length} test${e.cases.length == 1 ? '' : 's'} and compares what it prints and '
            'the final pin states. This is a simulator check, not real hardware.',
        CheckKind.compileOnly => 'Check only compiles your sketch for an Arduino Uno. What it does on a board is up to you to check, with the checklist.',
        CheckKind.staticHtml => 'Check reads your files for the required parts; it does not run the page. How the page looks and behaves, you check with the checklist.',
        CheckKind.manual => 'Nothing is checked automatically for this exercise. Build it, try it, and tick the checklist.',
      };

  List<Widget> _exercise(Exercise e) {
    final base = _base(_track);
    final lang = exerciseLanguage(base, e);
    final attempts = _progress.get<num>('ex.${e.id}.attempts', 0);
    final passed = _progress.get('ex.${e.id}.passed', false);
    final r = _results[e.id];
    final ticked = _progress.get<List>('ex.${e.id}.checklist', const []).cast<num>().toSet();
    final running = _checking == e.id;
    return [
      Wrap(spacing: 8, crossAxisAlignment: WrapCrossAlignment.center, children: [
        Chip(label: Text(e.level), visualDensity: VisualDensity.compact),
        if (passed) const Chip(avatar: Icon(Icons.check, color: _ok, size: 16), label: Text('Passed before'), visualDensity: VisualDensity.compact),
      ]),
      _h1(e.title, 'Exercise ${_page.i + 1} of ${_track.exercises.length}'),
      _p(e.task),
      _section('Requirements', [_bullets(e.requirements)]),
      _section('How it is checked', [
        _p(_howChecked(e)),
        for (final (i, c) in e.cases.indexed)
          _box(
            'Test ${i + 1}${c.note.isEmpty ? '' : ': ${c.note}'}',
            [
              if (c.input.isNotEmpty) 'Input:\n${c.input}',
              if (c.pressed.isNotEmpty) 'Buttons held: ${c.pressed.map((p) => 'GPIO $p').join(', ')}',
              if (c.expect.isNotEmpty) 'Must print:\n${c.expect.join('\n')}',
              if (c.pins.isNotEmpty) 'Pins at the end: ${c.pins.entries.map((p) => 'GPIO ${p.key} ${p.value ? 'HIGH' : 'LOW'}').join(', ')}',
            ].join('\n\n'),
          ),
        _p('Done when: ${e.criteria}'),
      ]),
      _section('Starter code', [_code(e.starter, label: base.fileName)]),
      Padding(
        padding: const EdgeInsets.only(top: 12),
        child: Wrap(spacing: 8, runSpacing: 8, children: [
          FilledButton.tonalIcon(
            onPressed: base.availableHere && !running ? () => _openExercise(e, lang) : null,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Open in Editor'),
          ),
          if (!running)
            FilledButton.icon(
              key: const Key('check'),
              onPressed: base.availableHere && _checking == null ? () => _check(e, base) : null,
              icon: const Icon(Icons.fact_check_outlined),
              label: const Text('Check'),
            )
          else
            FilledButton.icon(
              style: FilledButton.styleFrom(backgroundColor: Nx.stop),
              onPressed: () => _run?.stop(),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            ),
          OutlinedButton.icon(
            onPressed: base.availableHere && !running ? () => _startOver(e, lang) : null,
            icon: const Icon(Icons.restart_alt),
            label: const Text('Start over'),
          ),
        ]),
      ),
      Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text('Your code for this exercise is kept in practice/${e.id}, apart from your own files.', style: const TextStyle(fontSize: 12.5, color: Nx.muted)),
      ),
      if (running) const Padding(padding: EdgeInsets.only(top: 12), child: LinearProgressIndicator()),
      if (r != null && !running) _resultView(r),
      if (e.checklist.isNotEmpty)
        _section('Checklist (you check these yourself)', [
          for (final (i, item) in e.checklist.indexed)
            CheckboxListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              controlAffinity: ListTileControlAffinity.leading,
              value: ticked.contains(i),
              title: Text(item, style: const TextStyle(fontSize: 14.5)),
              onChanged: (v) => setState(() => _progress.set('ex.${e.id}.checklist', [...ticked.where((x) => x != i), if (v!) i])),
            ),
          if (ticked.length == e.checklist.length)
            const Text('All ticked (self-checked). NEXUS did not verify these items.', style: TextStyle(fontSize: 13, color: _warn)),
        ]),
      _section('Hint', [
        ExpansionTile(
          tilePadding: EdgeInsets.zero,
          title: const Text('Show a hint'),
          children: [Align(alignment: Alignment.centerLeft, child: _p(e.hint))],
        ),
      ]),
      _section('Solution', [
        if (_showSolution.contains(e.id))
          _code(e.solution, label: 'One possible solution')
        else ...[
          OutlinedButton.icon(
            onPressed: attempts > 0 ? () => setState(() => _showSolution.add(e.id)) : null,
            icon: const Icon(Icons.lock_open_outlined),
            label: const Text('Show solution'),
          ),
          if (attempts == 0)
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Press Check at least once first: the solution unlocks after your first attempt.', style: TextStyle(fontSize: 12.5, color: Nx.muted)),
            ),
        ],
      ]),
    ];
  }

  Widget _resultView(CheckResult r) {
    final (icon, color, title) = r.passed
        ? (Icons.check_circle, _ok, 'Passed: ${r.cases.length} of ${r.cases.length} checks')
        : r.automatic
            ? (Icons.cancel, Nx.stop, 'Not passed yet: ${r.cases.where((c) => c.passed).length} of ${r.cases.length} checks')
            : (Icons.info_outline, _warn, 'Not checked automatically');
    return Container(
      key: const Key('result'),
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.08), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withValues(alpha: 0.6))),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Icon(icon, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color))),
        ]),
        if (r.message.isNotEmpty) Padding(padding: const EdgeInsets.only(top: 6), child: Text(r.message, style: const TextStyle(fontSize: 14))),
        for (final c in r.cases) ...[
          const SizedBox(height: 8),
          Row(children: [
            Icon(c.passed ? Icons.check : Icons.close, size: 18, color: c.passed ? _ok : Nx.stop),
            const SizedBox(width: 6),
            Expanded(child: Text(c.label, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600))),
          ]),
          if (c.detail.isNotEmpty) Padding(padding: const EdgeInsets.only(left: 24, top: 4), child: Text(c.detail, style: _mono.copyWith(fontSize: 12.5))),
        ],
      ]),
    );
  }

  Future<void> _ensureStarter(Exercise e, Language lang) async {
    if (!File('${RunSession.workDir(lang).path}/${lang.fileName}').existsSync()) await RunSession.save(lang, e.starter);
  }

  Future<void> _openExercise(Exercise e, Language lang) async {
    await _ensureStarter(e, lang);
    if (!mounted) return;
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(language: lang)));
    if (mounted) setState(() {});
  }

  Future<void> _check(Exercise e, Language base) async {
    await _ensureStarter(e, exerciseLanguage(base, e));
    final run = _run = PracticeRun();
    setState(() => _checking = e.id);
    try {
      final r = await checkExercise(base, e, run);
      _results[e.id] = r;
      if (!run.stopped) _progress.set('ex.${e.id}.attempts', _progress.get<num>('ex.${e.id}.attempts', 0) + 1);
      if (r.passed) _progress.set('ex.${e.id}.passed', true); // only a real, complete, automatic pass counts
    } finally {
      _run = null;
      if (mounted) setState(() => _checking = null);
    }
  }

  Future<void> _startOver(Exercise e, Language lang) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start this exercise over?'),
        content: Text('This replaces your code for "${e.title}" (practice/${e.id}) with the starter code. Your own workspace files are not touched.'),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, true), child: const Text('Start over')),
        ],
      ),
    );
    if (ok != true) return;
    await RunSession.save(lang, e.starter);
    setState(() {
      _results.remove(e.id);
      _showSolution.remove(e.id);
    });
    _say('Starter code restored for "${e.title}".');
  }

  /// Search across every track: titles, summaries, keywords (functions, symbols), explanations.
  List<(_Page, String, String)> _search(String q) {
    final words = q.toLowerCase().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    bool hit(Track t, List<String> fields) {
      final text = [t.title, t.langId, ...fields].join(' ').toLowerCase();
      return words.every(text.contains);
    }

    return [
      for (final (ti, t) in tracks.indexed) ...[
        for (final (i, l) in t.lessons.indexed)
          if (hit(t, [l.title, l.summary, ...l.keywords, l.explanation, l.syntax])) ((t: ti, kind: _Kind.lesson, i: i), l.title, '${t.title} · ${l.summary}'),
        for (final (i, e) in t.exercises.indexed)
          if (hit(t, [e.title, e.task, e.level, 'exercise', 'practice'])) ((t: ti, kind: _Kind.exercise, i: i), e.title, '${t.title} · ${e.level} exercise'),
        if (hit(t, ['quiz', 'questions', 'test'])) ((t: ti, kind: _Kind.quiz, i: 0), '${t.title} quiz', '${t.quiz.length} questions'),
      ],
    ];
  }
}

class _Sidebar extends StatelessWidget {
  const _Sidebar({required this.state});
  final _LearnScreenState state;

  @override
  Widget build(BuildContext context) {
    final s = state;
    final inDrawer = Scaffold.maybeOf(context)?.isDrawerOpen ?? false;
    void go(_Page p) {
      s._go(p);
      if (inDrawer) Navigator.pop(context);
    }

    Widget item(_Page p, String label, {IconData? icon, bool done = false}) {
      final selected = p == s._page;
      return ListTile(
        dense: true,
        selected: selected,
        selectedTileColor: Nx.surface,
        contentPadding: const EdgeInsets.only(left: 24, right: 8),
        leading: Icon(done ? Icons.check_circle : icon ?? Icons.article_outlined, size: 18, color: done ? _ok : Nx.muted),
        title: Text(label, maxLines: 2, overflow: TextOverflow.ellipsis),
        onTap: () => go(p),
      );
    }

    final results = s._query.trim().isEmpty ? null : s._search(s._query);
    return Column(children: [
      Padding(
        padding: const EdgeInsets.all(12),
        child: TextField(
          key: const Key('learn-search'),
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search: language, topic, function...',
            isDense: true,
            border: OutlineInputBorder(),
          ),
          onChanged: s._setQuery,
        ),
      ),
      Expanded(
        child: results != null
            ? (results.isEmpty
                ? const Padding(padding: EdgeInsets.all(16), child: Text('No lessons match. Try a shorter word, like "loop" or "printf".', style: TextStyle(color: Nx.muted)))
                : ListView(children: [
                    for (final (p, title, sub) in results)
                      ListTile(dense: true, title: Text(title), subtitle: Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis), onTap: () => go(p)),
                  ]))
            : ListView(children: [
                for (final (ti, t) in tracks.indexed)
                  ExpansionTile(
                    key: PageStorageKey('track-${t.langId}'),
                    initiallyExpanded: s._open.contains(ti),
                    onExpansionChanged: (o) => o ? s._open.add(ti) : s._open.remove(ti),
                    leading: LanguageBadge(_base(t), size: 26),
                    title: Text(t.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                    children: [
                      item((t: ti, kind: _Kind.overview, i: 0), 'Overview', icon: Icons.info_outline),
                      for (final (i, l) in t.lessons.indexed)
                        item((t: ti, kind: _Kind.lesson, i: i), '${i + 1}. ${l.title}', done: _progress.get('read.${l.id}', false)),
                      item((t: ti, kind: _Kind.quiz, i: 0), 'Quiz', icon: Icons.quiz_outlined),
                      for (final (i, e) in t.exercises.indexed)
                        item((t: ti, kind: _Kind.exercise, i: i), '${e.level}: ${e.title}',
                            icon: Icons.fitness_center_outlined, done: _progress.get('ex.${e.id}.passed', false)),
                    ],
                  ),
              ]),
      ),
    ]);
  }
}

class _RefTile extends StatelessWidget {
  const _RefTile(this.r, {required this.onFail});
  final Ref r;
  final VoidCallback onFail;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Icon(Icons.menu_book_outlined, size: 18, color: Nx.muted),
          const SizedBox(width: 8),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(r.title, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w600)),
              Text([r.publisher, if (r.version.isNotEmpty) r.version, 'checked ${r.verified}'].join(' · '), style: const TextStyle(fontSize: 12.5, color: Nx.muted)),
              Text(r.url, style: const TextStyle(fontSize: 12, color: Color(0xFF8FB0FF))),
            ]),
          ),
          TextButton.icon(
            onPressed: () async {
              final ok = await launchUrl(Uri.parse(r.url), mode: LaunchMode.externalApplication).catchError((_) => false);
              if (!ok) onFail();
            },
            icon: const Icon(Icons.open_in_new, size: 16),
            label: const Text('View Source'),
          ),
        ]),
      );
}

/// Read-only highlighted code with a Copy button (lessons, starters, solutions).
class CodeBlock extends StatelessWidget {
  const CodeBlock(this.code, {super.key, this.language, this.label = '', this.border});
  final String code;
  final String? language, label;
  final Color? border;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        margin: const EdgeInsets.only(bottom: 8),
        decoration: BoxDecoration(color: const Color(0xFF1E1E1E), borderRadius: BorderRadius.circular(10), border: Border.all(color: border ?? Nx.line)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const SizedBox(width: 12),
            Expanded(child: Text(label ?? '', style: TextStyle(fontSize: 12, color: border ?? Nx.muted, fontWeight: FontWeight.w600))),
            IconButton(
              tooltip: 'Copy code',
              visualDensity: VisualDensity.compact,
              icon: const Icon(Icons.copy, size: 16),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: code));
                ScaffoldMessenger.of(context)
                  ..hideCurrentSnackBar()
                  ..showSnackBar(const SnackBar(content: Text('Code copied'), duration: Duration(seconds: 2)));
              },
            ),
          ]),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: HighlightView(
              code.trimRight(),
              language: language,
              theme: {...vs2015Theme, 'root': vs2015Theme['root']!.copyWith(backgroundColor: Colors.transparent)},
              padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
              textStyle: _mono,
            ),
          ),
        ]),
      );
}
