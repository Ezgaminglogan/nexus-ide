/// Learn & Practice content: plain Dart data compiled into the app, so every lesson, quiz and
/// exercise works offline. Only "View Source" needs the internet.
library;

/// A page the lesson was written from. [verified] is the date the page was opened and checked.
class Ref {
  const Ref(this.title, this.publisher, this.url, {this.version = '', this.verified = '2026-10-25'});
  final String title, publisher, url, version, verified;
}

class Lesson {
  const Lesson({
    required this.id,
    required this.title,
    required this.summary,
    required this.objective,
    required this.explanation,
    required this.syntax,
    required this.syntaxNotes,
    required this.example,
    this.run = const [],
    this.input = '',
    required this.output,
    required this.lines,
    required this.mistake,
    required this.mistakeCode,
    required this.fixCode,
    required this.practice,
    required this.refs,
    this.keywords = const [],
    this.needs = '',
    this.exampleFile = '',
    this.checks = const [],
  });

  final String id, title, summary, objective, explanation;
  final String syntax; // the pattern, in the language
  final List<(String, String)> syntaxNotes; // part → what it means
  final String example; // complete program/page that runs in NEXUS
  final List<String> run; // steps; empty = the track's default steps
  final String input; // sample input typed in the terminal ('' = none)
  final String output; // expected output or visible behaviour
  final List<String> lines; // the important lines, explained
  final String mistake; // the mistake, in words
  final String mistakeCode, fixCode;
  final String practice;
  final List<Ref> refs;
  final List<String> keywords; // extra search words (functions, symbols)
  final String needs; // extra hardware/software, '' = nothing extra
  final String exampleFile; // file the example goes in ('' = the track's main file)
  final List<String> checks; // lines the verification run must see ('' input: defaults to [output]'s lines)
}

class Question {
  const Question(this.question, this.options, this.answer, this.why);
  final String question;
  final List<String> options;
  final int answer; // index into [options]
  final String why;
}

/// How an exercise is checked. Only [output] and [gpio] run the student's program against
/// test cases; the others say exactly what they did and did not check.
enum CheckKind {
  output, // run with each case's input, compare the printed lines
  gpio, // Raspberry Pi: run in the simulator, compare the final pin states (and output)
  compileOnly, // Arduino: compile it; behaviour needs a board (manual checklist)
  staticHtml, // Web: read the code for required parts; looks are a manual checklist
  manual, // nothing automatic (e.g. needs MySQL running): checklist only
}

class TestCase {
  const TestCase({this.input = '', this.expect = const [], this.pressed = const {}, this.pins = const {}, this.note = ''});
  final String input; // lines typed into the program
  final List<String> expect; // lines that must appear in the output, in this order
  final Set<int> pressed; // Raspberry Pi: BCM pins held down while it runs
  final Map<int, bool> pins; // Raspberry Pi: BCM output pin → expected HIGH (true) / LOW at the end
  final String note; // what this case is about ("empty list", "exactly 75"...)
}

class Exercise {
  const Exercise({
    required this.id,
    required this.level,
    required this.title,
    required this.task,
    required this.starter,
    required this.requirements,
    required this.criteria,
    required this.hint,
    required this.solution,
    this.kind = CheckKind.output,
    this.cases = const [],
    this.checks = const [],
    this.checklist = const [],
  });

  final String id, level, title, task, starter, criteria, hint, solution;
  final List<String> requirements;
  final CheckKind kind;
  final List<TestCase> cases;
  final List<(String, String)> checks; // staticHtml: (what is checked, regular expression)
  final List<String> checklist; // things the student checks by looking/hardware
}

class Track {
  const Track({
    required this.langId,
    required this.title,
    required this.intro,
    required this.runtime,
    required this.run,
    required this.lessons,
    required this.quiz,
    required this.exercises,
  });

  final String langId; // matches Language.id
  final String title, intro;
  final String runtime; // what actually runs this code in NEXUS (PC / phone)
  final List<String> run; // default "how to run it" steps for lessons
  final List<Lesson> lessons;
  final List<Question> quiz;
  final List<Exercise> exercises;
}
