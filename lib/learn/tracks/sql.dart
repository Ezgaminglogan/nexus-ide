import '../model.dart';

const _sqlite = 'SQLite (sqlite.org)';
const _sqliteV = 'SQLite 3 (3.50 on the lab PCs, 3.54 on phones)';
const _mysql = 'Oracle (MySQL 8.4 Reference Manual)';
const _mysqlV = 'MySQL 8.4 manual; XAMPP ships MariaDB 10.4, which runs the same SQL here';
const _lite = 'https://www.sqlite.org';
const _man = 'https://dev.mysql.com/doc/refman/8.4/en';

const _w3 = Ref('SQL Tutorial', 'W3Schools', 'https://www.w3schools.com/sql/', version: 'Free tutorial with "Try it" examples');
const _liteTut = Ref('SQLite Tutorial', 'sqlitetutorial.net', 'https://www.sqlitetutorial.net/', version: 'Free tutorial');
const _myTut = Ref('MySQL Tutorial', 'mysqltutorial.org', 'https://www.mysqltutorial.org/', version: 'Free tutorial');

/// The Database track: standard SQL that runs the same on SQLite and MySQL (every example is
/// checked on both), with what differs between them shown for the engine the student picked.
const sqlTrack = Track(
  langId: 'sql',
  title: 'Databases: SQLite & MySQL',
  intro: 'A database keeps data in tables and answers questions about it with SQL. You will learn two of the most used ones: '
      'SQLite, a database that is just a file (no server), and MySQL, a database server like the one in XAMPP. '
      'Choose the one you are learning on the overview: lessons show what is different on it. The SQL itself is the same on both, '
      'and every example here was run on both.',
  runtime: 'SQLite: built into NEXUS (Python\'s sqlite3 runs your file on nexus.db). MySQL: XAMPP\'s MySQL on lab PCs (start it in the XAMPP '
      'Control Panel), the bundled MariaDB on phones. Practice checks run on SQLite in their own folder.',
  run: [
    'Open the Database tile (or press Try in Editor to open a practice copy).',
    'Pick SQLite or MySQL above the editor.',
    'Press Run. Each SELECT prints a table; errors show the line they are on.',
  ],
  lessons: [
    Lesson(
      id: 'db-intro',
      title: 'What a database is, and its types',
      summary: 'Tables, rows and columns; server databases versus file databases.',
      objective: 'Tell a server database (MySQL) from a file database (SQLite), and run your first SQL.',
      explanation: 'A relational database keeps data in tables: each row is one thing (a subject, a student) and each column is one fact about it. '
          'You talk to it in SQL. There are two big families you will meet: server databases such as MySQL, MariaDB and PostgreSQL run as a '
          'separate program that many users and websites connect to at once (XAMPP starts MySQL for you); embedded databases such as SQLite '
          'are a single file read directly by your program: no server, no accounts, perfect for apps and phones. '
          'There are also non-relational (NoSQL) databases such as MongoDB that store documents instead of tables; this track sticks to SQL.',
      syntax: r'''CREATE TABLE table_name (column TYPE, ...);
INSERT INTO table_name (columns) VALUES (values);
SELECT columns FROM table_name;''',
      syntaxNotes: [
        ('table', 'Like a spreadsheet sheet with fixed columns.'),
        ('row', 'One record (one subject).'),
        ('column', 'One fact, with a type (text, number, date).'),
        (';', 'Ends each SQL statement.'),
      ],
      example: r'''DROP TABLE IF EXISTS subjects;
CREATE TABLE subjects (
    code VARCHAR(10) PRIMARY KEY,
    title VARCHAR(60) NOT NULL
);
INSERT INTO subjects (code, title) VALUES
    ('IT101', 'Introduction to Computing'),
    ('IT102', 'Computer Programming 1');
SELECT code, title FROM subjects;
''',
      output: '+-------+---------------------------+\n| code  | title                     |\n+-------+---------------------------+\n'
          '| IT101 | Introduction to Computing |\n| IT102 | Computer Programming 1    |\n+-------+---------------------------+',
      checks: ['| IT101 | Introduction to Computing |', '| IT102 | Computer Programming 1 |'],
      lines: [
        'DROP TABLE IF EXISTS lets you run the file again and again from a clean start.',
        'One INSERT can add several rows, separated by commas.',
        'SELECT asks for the columns you name, from one table.',
      ],
      mistake: 'Writing text values without quotes: SQL then reads them as column names.',
      mistakeCode: r'''INSERT INTO subjects (code, title) VALUES (IT103, Data Structures);''',
      fixCode: r'''INSERT INTO subjects (code, title) VALUES ('IT103', 'Data Structures');''',
      practice: 'Add a units column and two more subjects, then select only the codes and units.',
      refs: [
        Ref('Appropriate Uses For SQLite', _sqlite, '$_lite/whentouse.html', version: _sqliteV),
        Ref('SQLite Is Serverless', _sqlite, '$_lite/serverless.html', version: _sqliteV),
        Ref('Creating and Using a Database', _mysql, '$_man/database-use.html', version: _mysqlV),
        _w3,
      ],
      keywords: ['database', 'table', 'row', 'column', 'mysql', 'sqlite', 'mariadb', 'server', 'nosql', 'relational', 'types'],
      engines: {
        'sqlite': 'SQLite: the whole database is one file (here nexus.db in your project). Nothing to start, no user or password. '
            'Great for phone apps, small tools and learning; one writer at a time.',
        'mysql': 'MySQL: a server program. On a lab PC, start MySQL in the XAMPP Control Panel; NEXUS connects to 127.0.0.1 as root and uses '
            'the database nexus. Many users and websites can use it at the same time. phpMyAdmin (localhost/phpmyadmin) shows its tables.',
      },
    ),
    Lesson(
      id: 'db-tables',
      title: 'Creating tables and data types',
      summary: 'CREATE TABLE, column types, NOT NULL and the primary key.',
      objective: 'Create a students table with the right type for each column and a primary key.',
      explanation: 'Every column has a type: whole numbers (INTEGER/INT), text (VARCHAR(n) or TEXT), dates (DATE), exact decimals (DECIMAL(p,s)). '
          'NOT NULL means the column must have a value. The PRIMARY KEY is the column that identifies each row: no two rows can share it. '
          'Choose the smallest type that fits: VARCHAR(50) for names, DECIMAL for money and grades, never FLOAT for money.',
      syntax: r'''CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    birthday DATE,
    gpa DECIMAL(3,2)
);''',
      syntaxNotes: [
        ('INTEGER PRIMARY KEY', 'The id: unique for every row.'),
        ('VARCHAR(50)', 'Text up to 50 characters.'),
        ('DATE', 'A date written as \'YYYY-MM-DD\'.'),
        ('DECIMAL(3,2)', '3 digits in all, 2 after the point: 1.75.'),
        ('NOT NULL', 'This column may not be left empty.'),
      ],
      example: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    birthday DATE,
    gpa DECIMAL(3,2)
);
INSERT INTO students (id, name, birthday, gpa) VALUES (1, 'Ana Santos', '2007-03-14', 1.75);
SELECT id, name, birthday, gpa FROM students;
''',
      output: '+----+------------+------------+------+\n| id | name       | birthday   | gpa  |\n+----+------------+------------+------+\n'
          '|  1 | Ana Santos | 2007-03-14 | 1.75 |\n+----+------------+------------+------+',
      checks: ['| 1 | Ana Santos | 2007-03-14 | 1.75 |'],
      lines: ['Dates are written as text in the form \'YYYY-MM-DD\'.', 'The table definition is the "shape"; INSERT fills it.'],
      mistake: 'Two rows with the same primary key: the second INSERT fails.',
      mistakeCode: r'''INSERT INTO students (id, name) VALUES (1, 'Ana');
INSERT INTO students (id, name) VALUES (1, 'Ben');  -- error: duplicate id''',
      fixCode: r'''INSERT INTO students (id, name) VALUES (1, 'Ana');
INSERT INTO students (id, name) VALUES (2, 'Ben');''',
      practice: 'Create a teachers table with id, name, department and hired (a date), then add two teachers.',
      refs: [
        Ref('CREATE TABLE', _sqlite, '$_lite/lang_createtable.html', version: _sqliteV),
        Ref('Datatypes In SQLite', _sqlite, '$_lite/datatype3.html', version: _sqliteV),
        Ref('Creating a Table', _mysql, '$_man/creating-tables.html', version: _mysqlV),
        Ref('Data Types', _mysql, '$_man/data-types.html', version: _mysqlV),
      ],
      keywords: ['create table', 'data type', 'integer', 'int', 'varchar', 'text', 'date', 'decimal', 'primary key', 'not null', 'auto_increment', 'autoincrement'],
      engines: {
        'sqlite': 'SQLite: types are flexible ("type affinity"): VARCHAR(50) is accepted but the 50 is not enforced, and a DATE is stored as text. '
            'An id INTEGER PRIMARY KEY numbers itself when you leave it out of INSERT (add AUTOINCREMENT only if ids must never be reused).',
        'mysql': 'MySQL: types are strict: VARCHAR(50) holds at most 50 characters and DATE is a real date. For ids that number themselves, write '
            'id INT AUTO_INCREMENT PRIMARY KEY.',
      },
    ),
    Lesson(
      id: 'db-insert',
      title: 'Adding rows: INSERT',
      summary: 'One row or several at once, naming the columns.',
      objective: 'Insert one row, then several rows in one statement, and count them.',
      explanation: 'INSERT INTO adds rows. Always name the columns you fill: the statement keeps working if a column is added later. '
          'Text goes in single quotes; numbers do not. COUNT(*) counts the rows of a table.',
      syntax: r'''INSERT INTO students (id, name, course) VALUES (1, 'Ana', 'BSIT');
INSERT INTO students (id, name, course) VALUES (2, 'Ben', 'BSIT'), (3, 'Cara', 'BEEd');''',
      syntaxNotes: [
        ('(id, name, course)', 'The columns being filled, in order.'),
        ('VALUES (...), (...)', 'One pair of brackets per row.'),
        ("'Ana'", 'Text in single quotes; double a quote inside: \'O\'\'Neil\'.'),
      ],
      example: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (
    id INTEGER PRIMARY KEY,
    name VARCHAR(50) NOT NULL,
    course VARCHAR(10)
);
INSERT INTO students (id, name, course) VALUES (1, 'Ana', 'BSIT');
INSERT INTO students (id, name, course) VALUES
    (2, 'Ben', 'BSIT'),
    (3, 'Cara', 'BEEd');
SELECT COUNT(*) AS total FROM students;
''',
      output: '+-------+\n| total |\n+-------+\n|     3 |\n+-------+',
      checks: ['| total |', '| 3 |'],
      lines: ['AS total names the result column.', 'SQLite also prints "1 row affected" for each INSERT; the MySQL client prints nothing.'],
      mistake: 'Leaving out a NOT NULL column: the INSERT is refused.',
      mistakeCode: r'''INSERT INTO students (id, course) VALUES (4, 'BSIT');''',
      fixCode: r'''INSERT INTO students (id, name, course) VALUES (4, 'Dan', 'BSIT');''',
      practice: 'Insert five students in one INSERT, then count only the BSIT ones with WHERE course = \'BSIT\'.',
      refs: [
        Ref('INSERT', _sqlite, '$_lite/lang_insert.html', version: _sqliteV),
        Ref('INSERT Statement', _mysql, '$_man/insert.html', version: _mysqlV),
        _w3,
      ],
      keywords: ['insert', 'into', 'values', 'count', 'rows'],
      engines: {
        'sqlite': 'SQLite: leave the id out (or insert NULL) and an INTEGER PRIMARY KEY gets the next number.',
        'mysql': 'MySQL: with id INT AUTO_INCREMENT, leave the id out and MySQL numbers it; LAST_INSERT_ID() tells you which number it used.',
      },
    ),
    Lesson(
      id: 'db-select',
      title: 'Asking questions: SELECT',
      summary: 'WHERE filters, ORDER BY sorts, LIMIT keeps the first rows.',
      objective: 'Find the top BSIT students who passed, highest grade first.',
      explanation: 'SELECT is how you read data. WHERE keeps the rows you want (join conditions with AND / OR), ORDER BY sorts '
          '(ASC is A to Z or small to big, DESC the other way), and LIMIT keeps only the first rows. The clauses always come in this order: '
          'SELECT, FROM, WHERE, ORDER BY, LIMIT.',
      syntax: r'''SELECT name, grade
FROM students
WHERE course = 'BSIT' AND grade >= 75
ORDER BY grade DESC
LIMIT 2;''',
      syntaxNotes: [
        ('WHERE ... AND ...', 'Both conditions must be true.'),
        ('=  <>  <  >  <=  >=', 'Comparisons (<> means not equal).'),
        ("LIKE 'A%'", 'Text that starts with A (% is any characters).'),
        ('ORDER BY grade DESC', 'Biggest grade first.'),
      ],
      example: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50), course VARCHAR(10), grade INTEGER);
INSERT INTO students (id, name, course, grade) VALUES
    (1, 'Ana', 'BSIT', 91), (2, 'Ben', 'BSIT', 74), (3, 'Cara', 'BEEd', 85), (4, 'Dan', 'BSIT', 88);

SELECT name, grade
FROM students
WHERE course = 'BSIT' AND grade >= 75
ORDER BY grade DESC
LIMIT 2;
''',
      output: '+------+-------+\n| name | grade |\n+------+-------+\n| Ana  |    91 |\n| Dan  |    88 |\n+------+-------+',
      checks: ['| Ana | 91 |', '| Dan | 88 |'],
      lines: ['Ben (74) fails grade >= 75; Cara is BEEd.', 'ORDER BY ... DESC puts 91 before 88; LIMIT 2 stops there.'],
      mistake: 'Putting ORDER BY before WHERE: the clauses have a fixed order.',
      mistakeCode: r'''SELECT name FROM students ORDER BY name WHERE grade >= 75;''',
      fixCode: r'''SELECT name FROM students WHERE grade >= 75 ORDER BY name;''',
      practice: 'List the students whose names start with C or D, sorted A to Z.',
      refs: [
        Ref('SELECT', _sqlite, '$_lite/lang_select.html', version: _sqliteV),
        Ref('SELECT Statement', _mysql, '$_man/select.html', version: _mysqlV),
        _liteTut,
      ],
      keywords: ['select', 'from', 'where', 'and', 'or', 'order by', 'asc', 'desc', 'limit', 'like'],
      engines: {
        'sqlite': "SQLite: LIKE ignores upper/lower case for A–Z ('a%' finds Ana). Text = text is case-sensitive.",
        'mysql': "MySQL: with XAMPP's default collation both = and LIKE ignore upper/lower case ('ana' = 'Ana' is true).",
      },
    ),
    Lesson(
      id: 'db-update',
      title: 'Changing data: UPDATE and DELETE',
      summary: 'Change or remove rows, always with a WHERE.',
      objective: 'Correct one grade and remove the rows of one course.',
      explanation: 'UPDATE changes columns of the rows that match WHERE; DELETE removes the rows that match. Without WHERE they change or remove '
          'EVERY row, so write the WHERE first, and try it as a SELECT before running the UPDATE or DELETE.',
      syntax: r'''UPDATE students SET grade = 76 WHERE id = 2;
DELETE FROM students WHERE course = 'BEEd';''',
      syntaxNotes: [
        ('SET grade = 76', 'The new value (several: SET a = 1, b = 2).'),
        ('WHERE id = 2', 'Which rows; by primary key is safest.'),
      ],
      example: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50), course VARCHAR(10), grade INTEGER);
INSERT INTO students (id, name, course, grade) VALUES
    (1, 'Ana', 'BSIT', 91), (2, 'Ben', 'BSIT', 74), (3, 'Cara', 'BEEd', 85);

UPDATE students SET grade = 76 WHERE id = 2;
DELETE FROM students WHERE course = 'BEEd';
SELECT id, name, grade FROM students ORDER BY id;
''',
      output: '+----+------+-------+\n| id | name | grade |\n+----+------+-------+\n|  1 | Ana  |    91 |\n|  2 | Ben  |    76 |\n+----+------+-------+',
      checks: ['| 1 | Ana | 91 |', '| 2 | Ben | 76 |'],
      lines: ['Only Ben\'s grade changes.', 'Cara is removed; the other rows stay.'],
      mistake: 'Forgetting WHERE: every student gets the same grade.',
      mistakeCode: r'''UPDATE students SET grade = 76;''',
      fixCode: r'''UPDATE students SET grade = 76 WHERE id = 2;''',
      practice: 'Add 5 points to every BSIT grade below 75, then delete the students with no course.',
      refs: [
        Ref('UPDATE', _sqlite, '$_lite/lang_update.html', version: _sqliteV),
        Ref('DELETE', _sqlite, '$_lite/lang_delete.html', version: _sqliteV),
        Ref('UPDATE Statement', _mysql, '$_man/update.html', version: _mysqlV),
        Ref('DELETE Statement', _mysql, '$_man/delete.html', version: _mysqlV),
      ],
      keywords: ['update', 'set', 'delete', 'where', 'safe'],
      engines: {
        'sqlite': 'SQLite: the change is saved in nexus.db when the run ends; there is no undo, so keep a CREATE + INSERT script to start over.',
        'mysql': 'MySQL: phpMyAdmin and MySQL Workbench often use "safe updates", which refuse an UPDATE or DELETE without a WHERE on a key.',
      },
    ),
    Lesson(
      id: 'db-join',
      title: 'Related tables: keys and JOIN',
      summary: 'Foreign keys connect tables; JOIN puts them back together.',
      objective: 'List which student takes which course from three related tables.',
      explanation: 'Instead of repeating a course title on every row, keep courses in their own table and store only its code. A FOREIGN KEY says '
          'that a column must hold a value that exists in another table. JOIN ... ON matches rows of two tables, like looking up the code in '
          'the courses table. Short names (s, c, e) for tables keep the query readable.',
      syntax: r'''FOREIGN KEY (student_id) REFERENCES students(id)

SELECT s.name, c.title
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN courses c ON c.code = e.course_code;''',
      syntaxNotes: [
        ('FOREIGN KEY ... REFERENCES', 'Values must exist in the other table.'),
        ('JOIN ... ON', 'How the rows of two tables match.'),
        ('enrollments e', 'e is a short name (alias) for the table.'),
        ('LEFT JOIN', 'Keeps rows even when there is no match (with NULLs).'),
      ],
      example: r'''DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50) NOT NULL);
CREATE TABLE courses (code VARCHAR(10) PRIMARY KEY, title VARCHAR(60) NOT NULL);
CREATE TABLE enrollments (
    student_id INTEGER NOT NULL,
    course_code VARCHAR(10) NOT NULL,
    FOREIGN KEY (student_id) REFERENCES students(id),
    FOREIGN KEY (course_code) REFERENCES courses(code)
);
INSERT INTO students (id, name) VALUES (1, 'Ana'), (2, 'Ben');
INSERT INTO courses (code, title) VALUES ('IT101', 'Computing'), ('MATH1', 'Algebra');
INSERT INTO enrollments (student_id, course_code) VALUES (1, 'IT101'), (1, 'MATH1'), (2, 'IT101');

SELECT s.name, c.title
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN courses c ON c.code = e.course_code
ORDER BY s.name, c.title;
''',
      output: '+------+-----------+\n| name | title     |\n+------+-----------+\n| Ana  | Algebra   |\n| Ana  | Computing |\n| Ben  | Computing |\n+------+-----------+',
      checks: ['| Ana | Algebra |', '| Ana | Computing |', '| Ben | Computing |'],
      lines: [
        'The tables are dropped child-first (enrollments), because it points at the other two.',
        'Each enrollment row becomes one result row, with the name and title looked up.',
      ],
      mistake: 'Joining without ON pairs every row with every row (a "cross join").',
      mistakeCode: r'''SELECT s.name, c.title FROM students s JOIN courses c;''',
      fixCode: r'''SELECT s.name, c.title
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN courses c ON c.code = e.course_code;''',
      practice: 'Use LEFT JOIN to also list students who are not enrolled in anything.',
      refs: [
        Ref('SQLite Foreign Key Support', _sqlite, '$_lite/foreignkeys.html', version: _sqliteV),
        Ref('FOREIGN KEY Constraints', _mysql, '$_man/create-table-foreign-keys.html', version: _mysqlV),
        Ref('JOIN Clause', _mysql, '$_man/join.html', version: _mysqlV),
        Ref('SQL Joins', 'W3Schools', 'https://www.w3schools.com/sql/sql_join.asp', version: 'Free tutorial'),
      ],
      keywords: ['join', 'inner join', 'left join', 'foreign key', 'references', 'relationship', 'alias'],
      engines: {
        'sqlite': 'SQLite: foreign keys are only checked after PRAGMA foreign_keys = ON; NEXUS turns it on for you. Your own apps must do it on every connection.',
        'mysql': 'MySQL: foreign keys are checked by the InnoDB engine (XAMPP\'s default). The referenced column must be a key with the same type.',
      },
    ),
    Lesson(
      id: 'db-group',
      title: 'Summaries: GROUP BY',
      summary: 'COUNT, MIN, MAX, SUM and AVG per group; HAVING filters groups.',
      objective: 'Count the students in each subject and find their lowest and highest grade.',
      explanation: 'Aggregate functions turn many rows into one value: COUNT(*) counts, SUM adds, AVG averages, MIN and MAX find the smallest and '
          'biggest. GROUP BY makes one result row per group (per subject). WHERE filters rows before grouping; HAVING filters the groups after.',
      syntax: r'''SELECT subject, COUNT(*) AS students, MIN(grade) AS lowest, MAX(grade) AS highest
FROM grades
GROUP BY subject
HAVING COUNT(*) >= 2;''',
      syntaxNotes: [
        ('COUNT(*)', 'Rows in the group.'),
        ('AVG(grade)', 'Average of the group.'),
        ('GROUP BY subject', 'One result row per subject.'),
        ('HAVING', 'Like WHERE, but for groups (can use COUNT, AVG...).'),
      ],
      example: r'''DROP TABLE IF EXISTS grades;
CREATE TABLE grades (student VARCHAR(50), subject VARCHAR(10), grade INTEGER);
INSERT INTO grades (student, subject, grade) VALUES
    ('Ana', 'IT101', 91), ('Ben', 'IT101', 74), ('Cara', 'IT101', 85),
    ('Ana', 'MATH1', 88), ('Ben', 'MATH1', 70);

SELECT subject, COUNT(*) AS students, MIN(grade) AS lowest, MAX(grade) AS highest
FROM grades
GROUP BY subject
HAVING COUNT(*) >= 2
ORDER BY subject;
''',
      output: '+---------+----------+--------+---------+\n| subject | students | lowest | highest |\n+---------+----------+--------+---------+\n'
          '| IT101   |        3 |     74 |      91 |\n| MATH1   |        2 |     70 |      88 |\n+---------+----------+--------+---------+',
      checks: ['| IT101 | 3 | 74 | 91 |', '| MATH1 | 2 | 70 | 88 |'],
      lines: ['Five rows become two: one per subject.', 'Every selected column is either grouped (subject) or aggregated.'],
      mistake: 'Using an aggregate in WHERE: WHERE runs before the groups exist.',
      mistakeCode: r'''SELECT subject FROM grades WHERE COUNT(*) >= 2 GROUP BY subject;''',
      fixCode: r'''SELECT subject FROM grades GROUP BY subject HAVING COUNT(*) >= 2;''',
      practice: 'Show each student with their average grade, best first.',
      refs: [
        Ref('Built-in Aggregate Functions', _sqlite, '$_lite/lang_aggfunc.html', version: _sqliteV),
        Ref('Aggregate Function Descriptions', _mysql, '$_man/aggregate-functions.html', version: _mysqlV),
        Ref('SQL GROUP BY Statement', 'W3Schools', 'https://www.w3schools.com/sql/sql_groupby.asp', version: 'Free tutorial'),
      ],
      keywords: ['group by', 'having', 'count', 'sum', 'avg', 'min', 'max', 'aggregate'],
      engines: {
        'sqlite': 'SQLite: AVG of whole numbers gives a decimal like 83.333333333333; use ROUND(AVG(grade), 2) for 83.33.',
        'mysql': 'MySQL: AVG of whole numbers gives 4 decimals (83.3333); ROUND(AVG(grade), 2) gives 83.33.',
      },
    ),
    Lesson(
      id: 'db-php',
      title: 'Using the database from PHP',
      summary: 'PDO talks to SQLite and MySQL with the same code; only the connection line changes.',
      objective: 'Connect a PHP page to SQLite or MySQL with PDO and run a prepared statement.',
      explanation: 'PHP\'s PDO works with many databases through the same functions. The connection string (DSN) picks the database: '
          '"sqlite:school.db" opens a file, "mysql:host=127.0.0.1;dbname=nexus" connects to the server. Always use prepared statements '
          '(? placeholders and execute([...])) for values that come from users: they cannot change your SQL.',
      syntax: r'''$db = new PDO('sqlite:' . __DIR__ . '/school.db');
// or: $db = new PDO('mysql:host=127.0.0.1;dbname=nexus;charset=utf8mb4', 'root', '');
$stmt = $db->prepare('SELECT name FROM students WHERE grade >= ?');
$stmt->execute([75]);''',
      syntaxNotes: [
        ("'sqlite:' . __DIR__ . '/school.db'", 'A SQLite file next to the page.'),
        ("'mysql:host=127.0.0.1;dbname=nexus'", 'The XAMPP / NEXUS MySQL settings.'),
        ('?', 'A placeholder, filled by execute([...]).'),
        ('PDO::ERRMODE_EXCEPTION', 'Errors become exceptions you can catch.'),
      ],
      example: r'''<?php
// Put this in an htdocs project (PHP site) and press Open in browser.
$useMysql = false; // true: XAMPP MySQL (start it first); false: a SQLite file
$db = $useMysql
    ? new PDO('mysql:host=127.0.0.1;dbname=nexus;charset=utf8mb4', 'root', '')
    : new PDO('sqlite:' . __DIR__ . '/school.db');
$db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);

$db->exec('CREATE TABLE IF NOT EXISTS learn_students (id INTEGER PRIMARY KEY, name VARCHAR(50), grade INTEGER)');
$db->exec('DELETE FROM learn_students');
$add = $db->prepare('INSERT INTO learn_students (id, name, grade) VALUES (?, ?, ?)');
foreach ([[1, 'Ana', 91], [2, "O'Neil", 74], [3, 'Cara', 85]] as $row) {
    $add->execute($row);
}

$q = $db->prepare('SELECT name, grade FROM learn_students WHERE grade >= ? ORDER BY grade DESC');
$q->execute([75]);
foreach ($q as $row) {
    echo htmlspecialchars($row['name']) . ': ' . $row['grade'] . "<br>\n";
}
''',
      run: [
        'Make an htdocs project (PHP site) and put the example in index.php.',
        'For MySQL: start MySQL in XAMPP and set \$useMysql = true. For SQLite nothing else is needed.',
        'Press Open in browser (View on a phone).',
      ],
      output: 'The page shows:\nAna: 91\nCara: 85',
      lines: [
        'Only the connection line differs between SQLite and MySQL; the queries are the same.',
        "O'Neil is stored safely by the prepared statement, quote and all.",
      ],
      mistake: 'Pasting a form value into the SQL text lets users change the query (SQL injection).',
      mistakeCode: r'''$db->query("SELECT * FROM learn_students WHERE name = '$_GET[name]'");''',
      fixCode: r'''$q = $db->prepare('SELECT * FROM learn_students WHERE name = ?');
$q->execute([$_GET['name'] ?? '']);''',
      practice: 'Add a form that inserts a student with a prepared statement, then switch \$useMysql and check it works on both.',
      refs: [
        Ref('PHP Data Objects (PDO)', 'The PHP Group (php.net)', 'https://www.php.net/manual/en/book.pdo.php', version: 'PHP 8'),
        Ref('Prepared statements and stored procedures', 'The PHP Group (php.net)', 'https://www.php.net/manual/en/pdo.prepared-statements.php', version: 'PHP 8'),
        Ref('SQLite PDO driver', 'The PHP Group (php.net)', 'https://www.php.net/manual/en/ref.pdo-sqlite.php', version: 'PHP 8'),
        _myTut,
      ],
      keywords: ['php', 'pdo', 'mysqli', 'dsn', 'prepared statement', 'sql injection', 'connect'],
      needs: 'The local server: an htdocs PHP project, Open in browser (MySQL: XAMPP MySQL running)',
      engines: {
        'sqlite': "SQLite from PHP: new PDO('sqlite:' . __DIR__ . '/school.db'). The file is created on first use; keep it out of public folders on a real host.",
        'mysql': "MySQL from PHP: new PDO('mysql:host=127.0.0.1;dbname=nexus;charset=utf8mb4', 'root', ''), or mysqli as in the PHP track.",
      },
    ),
  ],
  quiz: [
    Question('Which one is a database that is just a file, with no server?', ['MySQL', 'SQLite', 'MariaDB', 'PostgreSQL'], 1, 'SQLite reads and writes one file directly.'),
    Question('What does XAMPP start for its database?', ['SQLite', 'A MySQL (MariaDB) server', 'MongoDB', 'Nothing'], 1, 'The XAMPP Control Panel starts MySQL (MariaDB).'),
    Question('Which kind fits a website where many users log in at the same time?', ['A text file', 'A server database like MySQL', 'An Excel sheet', 'Variables in PHP'], 1,
        'Server databases handle many connections at once.'),
    Question('What does PRIMARY KEY guarantee?', ['The column is text', 'Each row has a unique value there', 'The table is sorted', 'Nothing'], 1, 'No two rows can share it.'),
    Question('How does MySQL make ids number themselves?', ['AUTOINCREMENT', 'AUTO_INCREMENT', 'SERIAL ONLY', 'COUNT(*)'], 1,
        'MySQL: INT AUTO_INCREMENT PRIMARY KEY. SQLite: INTEGER PRIMARY KEY (optionally AUTOINCREMENT).'),
    Question('What happens with UPDATE students SET grade = 0; (no WHERE)?', ['Nothing', 'Only the first row changes', 'Every row changes', 'An error'], 2,
        'Without WHERE, UPDATE and DELETE affect every row.'),
    Question('Which clause filters groups after GROUP BY?', ['WHERE', 'HAVING', 'ORDER BY', 'LIMIT'], 1, 'WHERE filters rows before grouping; HAVING filters groups.'),
    Question('What is a FOREIGN KEY for?', ['Encrypting data', 'Making a column hold values that exist in another table', 'Sorting', 'Indexing text'], 1,
        'It links tables and keeps them consistent.'),
    Question('In SQLite, what must be on for foreign keys to be checked?', ['STRICT', 'PRAGMA foreign_keys = ON', 'InnoDB', 'Nothing'], 1, 'SQLite checks them only when the pragma is on.'),
    Question('Why use prepared statements (?) from PHP?', ['They are shorter', 'User input can\'t change the SQL', 'They skip errors', 'They work offline'], 1, 'They prevent SQL injection.'),
  ],
  exercises: [
    Exercise(
      id: 'db-ex-bsit',
      level: 'Beginner',
      title: 'BSIT class list',
      task: 'Write a query that lists the names (column name) of the BSIT students in alphabetical order.',
      starter: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50), course VARCHAR(10), grade INTEGER);
INSERT INTO students (id, name, course, grade) VALUES
    (1, 'Dan', 'BSIT', 88), (2, 'Ana', 'BSIT', 91), (3, 'Cara', 'BEEd', 85), (4, 'Ben', 'BSIT', 74);

-- Write your query below.
''',
      requirements: ['Only the name column.', 'Only BSIT students.', 'Sorted A to Z.'],
      cases: [TestCase(expect: ['| name |', '| Ana |', '| Ben |', '| Dan |'], note: 'Ana, Ben, Dan in that order')],
      criteria: 'The test passes (checked by running your SQL on SQLite).',
      hint: "SELECT name FROM students WHERE course = 'BSIT' ORDER BY ...",
      solution: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50), course VARCHAR(10), grade INTEGER);
INSERT INTO students (id, name, course, grade) VALUES
    (1, 'Dan', 'BSIT', 88), (2, 'Ana', 'BSIT', 91), (3, 'Cara', 'BEEd', 85), (4, 'Ben', 'BSIT', 74);

SELECT name FROM students WHERE course = 'BSIT' ORDER BY name;
''',
    ),
    Exercise(
      id: 'db-ex-count',
      level: 'Intermediate',
      title: 'Students per course',
      task: 'Show each course with how many students it has: columns course and total, courses in alphabetical order.',
      starter: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50), course VARCHAR(10), grade INTEGER);
INSERT INTO students (id, name, course, grade) VALUES
    (1, 'Dan', 'BSIT', 88), (2, 'Ana', 'BSIT', 91), (3, 'Cara', 'BEEd', 85), (4, 'Ben', 'BSIT', 74), (5, 'Eva', 'BSHM', 80);

-- Write your query below.
''',
      requirements: ['GROUP BY course.', 'Name the count column total (AS total).', 'Sorted by course.'],
      cases: [TestCase(expect: ['| course | total |', '| BEEd | 1 |', '| BSHM | 1 |', '| BSIT | 3 |'], note: 'three courses')],
      criteria: 'The test passes (checked by running your SQL on SQLite).',
      hint: 'SELECT course, COUNT(*) AS total FROM students GROUP BY course ORDER BY course;',
      solution: r'''DROP TABLE IF EXISTS students;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50), course VARCHAR(10), grade INTEGER);
INSERT INTO students (id, name, course, grade) VALUES
    (1, 'Dan', 'BSIT', 88), (2, 'Ana', 'BSIT', 91), (3, 'Cara', 'BEEd', 85), (4, 'Ben', 'BSIT', 74), (5, 'Eva', 'BSHM', 80);

SELECT course, COUNT(*) AS total
FROM students
GROUP BY course
ORDER BY course;
''',
    ),
    Exercise(
      id: 'db-ex-failed',
      level: 'Challenge',
      title: 'Who failed what',
      task: 'Using the three tables, list every failing grade (below 75): columns name, title and grade, sorted by name and then title.',
      starter: r'''DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50) NOT NULL);
CREATE TABLE courses (code VARCHAR(10) PRIMARY KEY, title VARCHAR(60) NOT NULL);
CREATE TABLE enrollments (
    student_id INTEGER NOT NULL REFERENCES students(id),
    course_code VARCHAR(10) NOT NULL REFERENCES courses(code),
    grade INTEGER
);
INSERT INTO students (id, name) VALUES (1, 'Ana'), (2, 'Ben'), (3, 'Cara');
INSERT INTO courses (code, title) VALUES ('IT101', 'Computing'), ('MATH1', 'Algebra');
INSERT INTO enrollments (student_id, course_code, grade) VALUES
    (1, 'IT101', 91), (1, 'MATH1', 88), (2, 'IT101', 74), (2, 'MATH1', 70), (3, 'IT101', 85);

-- Write your query below.
''',
      requirements: ['Two JOINs (students and courses).', 'WHERE grade < 75.', 'ORDER BY name, title.'],
      cases: [TestCase(expect: ['| name | title | grade |', '| Ben | Algebra | 70 |', '| Ben | Computing | 74 |'], note: "Ben's two failing grades")],
      criteria: 'The test passes (checked by running your SQL on SQLite).',
      hint: 'FROM enrollments e JOIN students s ON s.id = e.student_id JOIN courses c ON c.code = e.course_code WHERE e.grade < 75',
      solution: r'''DROP TABLE IF EXISTS enrollments;
DROP TABLE IF EXISTS students;
DROP TABLE IF EXISTS courses;
CREATE TABLE students (id INTEGER PRIMARY KEY, name VARCHAR(50) NOT NULL);
CREATE TABLE courses (code VARCHAR(10) PRIMARY KEY, title VARCHAR(60) NOT NULL);
CREATE TABLE enrollments (
    student_id INTEGER NOT NULL REFERENCES students(id),
    course_code VARCHAR(10) NOT NULL REFERENCES courses(code),
    grade INTEGER
);
INSERT INTO students (id, name) VALUES (1, 'Ana'), (2, 'Ben'), (3, 'Cara');
INSERT INTO courses (code, title) VALUES ('IT101', 'Computing'), ('MATH1', 'Algebra');
INSERT INTO enrollments (student_id, course_code, grade) VALUES
    (1, 'IT101', 91), (1, 'MATH1', 88), (2, 'IT101', 74), (2, 'MATH1', 70), (3, 'IT101', 85);

SELECT s.name, c.title, e.grade
FROM enrollments e
JOIN students s ON s.id = e.student_id
JOIN courses c ON c.code = e.course_code
WHERE e.grade < 75
ORDER BY s.name, c.title;
''',
    ),
  ],
);
