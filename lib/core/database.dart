import 'dart:io';

import 'settings.dart';
import 'toolchains.dart';

/// The Database workspace runs main.sql on one of two engines, chosen above the editor:
/// - SQLite: built in, no server. Python's sqlite3 module runs each statement on the file
///   nexus.db in the workspace and prints result tables (same on PCs and phones).
/// - MySQL: the real server, like phpMyAdmin's SQL tab. PCs use XAMPP's MySQL (client
///   C:\xampp\mysql\bin\mysql.exe); phones use the bundled MariaDB, started with the local server.
/// Both use host 127.0.0.1, user root, no password, database nexus.

enum SqlEngine { sqlite, mysql }

/// The MySQL database a workspace uses: the student's own work in `nexus`; every Learn practice
/// copy in its own (`nexus_lesson_db_join`...), so one lesson's tables (and foreign keys) never
/// block another lesson's DROP TABLE.
String mysqlDatabaseFor(Language lang) {
  final parts = lang.dir.split('/');
  return parts.first == 'practice' && parts.length > 1 ? 'nexus_${parts[1].replaceAll(RegExp(r'[^A-Za-z0-9]'), '_')}' : 'nexus';
}

SqlEngine get sqlEngine => Settings.instance.get('sql.engine', 'sqlite') == 'mysql' ? SqlEngine.mysql : SqlEngine.sqlite;
set sqlEngine(SqlEngine e) => Settings.instance.set('sql.engine', e.name);

/// MySQL: first make sure the nexus database exists (a build step, shown in Build details), then
/// run main.sql through the mysql client: `--table` prints SELECT results as tables and
/// `--abort-source-on-error` stops at the first error with a failing exit code. (The client won't
/// mix `source` with other statements in one -e, hence two steps.)
List<Step> mysqlSteps({String database = 'nexus'}) {
  final client = Platform.isAndroid ? 'bin/mariadb' : 'mysql/bin/mysql';
  const login = ['-h', '127.0.0.1', '-P', '3306', '-u', 'root', '--default-character-set=utf8mb4'];
  return [
    (tool: client, args: [...login, '-e', 'CREATE DATABASE IF NOT EXISTS $database']),
    (tool: client, args: [...login, '--table', '--abort-source-on-error', database, '-e', 'source main.sql']),
  ];
}

const sqlTemplate = '''-- A small school database. Run it, change it, run it again.
-- Pick the engine above the editor: SQLite (built in) or MySQL (XAMPP on PCs).
DROP TABLE IF EXISTS students;

CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    course VARCHAR(10),
    grade INTEGER
);

INSERT INTO students (id, name, course, grade) VALUES
    (1, 'Ana', 'BSIT', 91),
    (2, 'Ben', 'BSIT', 74),
    (3, 'Cara', 'BEEd', 85);

SELECT name, grade FROM students WHERE grade >= 75 ORDER BY grade DESC;
''';

/// Runs a .sql file on SQLite (nexus.db next to it), one statement at a time, printing a table
/// for each query and stopping at the first error with its line number.
const sqliteRunner = r'''
# NEXUS IDE: runs a .sql file on SQLite (nexus.db in this folder) and prints the results.
import sqlite3, sys

path = sys.argv[1] if len(sys.argv) > 1 else "main.sql"
sql = open(path, encoding="utf-8").read()
db = sqlite3.connect("nexus.db")
db.execute("PRAGMA foreign_keys = ON")

def statements(text):
    """Complete statements with the line each starts on."""
    buf, line, start = "", 1, 1
    for ch in text:
        if not buf.strip():
            start = line
        buf += ch
        if ch == "\n":
            line += 1
        if ch == ";" and sqlite3.complete_statement(buf):
            yield start, buf.strip()
            buf = ""
    if buf.strip() and any(not l.strip().startswith("--") for l in buf.strip().splitlines() if l.strip()):
        yield start, buf.strip()

def show(cur):
    names = [d[0] for d in cur.description]
    raw = cur.fetchall()
    rows = [["NULL" if v is None else str(v) for v in r] for r in raw]
    widths = [max([len(n)] + [len(r[i]) for r in rows]) for i, n in enumerate(names)]
    bar = "+" + "+".join("-" * (w + 2) for w in widths) + "+"
    # numbers right-aligned, like the mysql client
    fmt = lambda cells, nums: "| " + " | ".join(c.rjust(w) if n else c.ljust(w) for c, w, n in zip(cells, widths, nums)) + " |"
    body = [fmt(r, [isinstance(v, (int, float)) for v in vals]) for r, vals in zip(rows, raw)]
    print(bar, fmt(names, [False] * len(names)), bar, *body, bar, sep="\n")
    print(f"{len(rows)} row{'' if len(rows) == 1 else 's'} in set\n")

for line, st in statements(sql):
    try:
        cur = db.execute(st)
    except sqlite3.Error as e:
        db.commit()
        print(f"ERROR at line {line} in file: '{path}': {e}")
        sys.exit(1)
    if cur.description:
        show(cur)
    elif st.split(None, 1)[0].upper() in ("INSERT", "UPDATE", "DELETE", "REPLACE"):
        print(f"{cur.rowcount} row{'' if cur.rowcount == 1 else 's'} affected")
db.commit()
''';
