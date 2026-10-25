import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Kills [pid] and every child it started (a student's program, MSBuild nodes...).
Future<void> killTree(int pid) async {
  if (Platform.isWindows) {
    await Process.run('taskkill', ['/PID', '$pid', '/T', '/F']);
  } else {
    Process.killPid(pid, ProcessSignal.sigkill);
  }
}

class RunHandle {
  RunHandle(this._p, this.output);
  final Process _p;

  /// Set when NEXUS ended the program itself (time or output limit). Kept out of [output], which
  /// is only what the program printed.
  String? endedBy;

  /// stdout + stderr, decoded, live. Closes when both pipes close.
  final Stream<String> output;
  Future<int> get exitCode => _p.exitCode;

  /// Feeds one line to the program (scanf, input(), Scanner...).
  void send(String line) {
    try {
      _p.stdin.writeln(line);
    } on StateError {
      // stdin already closed: program exited.
    }
  }

  /// End of input (like Ctrl+D): practice checks send every line, then close.
  void closeInput() {
    try {
      _p.stdin.close();
    } on Object {
      // already closed
    }
  }

  Future<void> kill() => killTree(_p.pid);
}

/// Starts [exe] without a shell: args stay a list (paths with spaces are safe)
/// and [RunHandle.kill] hits the real program, not a cmd.exe wrapper.
Future<RunHandle> runTool(
  String exe,
  List<String> args, {
  required String cwd,
  Map<String, String>? env,
  Duration? timeout, // compile steps only; interactive runs rely on the Stop button
  int maxChars = 1 << 20, // ponytail: 1M-char cap per run, raise if real programs need more
}) async {
  final p = await Process.start(exe, args, workingDirectory: cwd, environment: env);
  final out = StreamController<String>();
  late final RunHandle h;
  var chars = 0, open = 2;
  var capped = false;

  void pipe(Stream<List<int>> s) {
    s.transform(const Utf8Decoder(allowMalformed: true)).listen((text) {
      if (capped) return;
      chars += text.length;
      if (chars > maxChars) {
        capped = true;
        h.endedBy = 'Stopped by NEXUS: the program printed more than ${maxChars ~/ 1000}k characters (an endless loop?).';
        killTree(p.pid);
        return;
      }
      out.add(text);
    }, onDone: () {
      if (--open == 0) out.close();
    });
  }

  h = RunHandle(p, out.stream);
  pipe(p.stdout);
  pipe(p.stderr);
  if (timeout != null) {
    final t = Timer(timeout, () {
      h.endedBy = 'Timed out after ${timeout.inSeconds} s.';
      killTree(p.pid);
    });
    p.exitCode.whenComplete(t.cancel);
  }
  return h;
}
