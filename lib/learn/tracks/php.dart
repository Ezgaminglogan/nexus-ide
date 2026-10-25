import '../model.dart';

const _php = 'The PHP Group (php.net)';
const _v = 'PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones)';
const _man = 'https://www.php.net/manual/en';
const _server = 'The PHP server: press Run, then open the preview';
const _mysql = 'MySQL or MariaDB running (XAMPP MySQL on lab PCs, bundled MariaDB on phones)';

const phpTrack = Track(
  langId: 'php',
  title: 'PHP + MySQL',
  intro: 'PHP runs on the server: it builds the HTML page before the browser sees it, and can read forms and talk to a MySQL database. '
      'In NEXUS, Run starts a small PHP server for the project folder and the preview shows the page. Most lessons print plain text so the '
      'output is easy to compare; the form and database lessons need the server and MySQL.',
  runtime: 'Lab PC: PHP from toolchains/php, XAMPP (C:\\xampp\\php) or PATH; MySQL from XAMPP. Phone: bundled PHP + MariaDB, started together by Run. '
      'Database settings: host 127.0.0.1, user root, no password, database nexus.',
  run: [
    'Open the PHP tile (or press Try in Editor to open a practice copy).',
    'Press Run: NEXUS starts the PHP server and opens the preview.',
    'Edit, save, and reload the preview to see changes. Practice checks run index.php once as a script and read what it prints.',
  ],
  lessons: [
    Lesson(
      id: 'php-syntax',
      title: 'PHP tags and echo',
      summary: 'Where PHP code goes and how it adds text to the page.',
      objective: 'Mix HTML and PHP in index.php and print with echo.',
      explanation: 'PHP code sits between <?php and ?>. Everything outside those tags is sent to the browser as it is. echo adds text '
          '(often HTML) to the page. Statements end with a semicolon.',
      syntax: r'''<h1>Static HTML</h1>
<?php
echo "<p>Made by PHP</p>";
?>''',
      syntaxNotes: [
        ('<?php ... ?>', 'PHP code. The closing ?> can be left out at the very end of a file.'),
        ('echo', 'Sends text to the page.'),
        ('// comment', 'Ignored by PHP.'),
      ],
      example: r'''<h1>Welcome</h1>
<?php
echo "<p>Today is a good day to code.</p>\n";
echo "<p>1 + 2 = " . (1 + 2) . "</p>\n";
?>
<p>Back to plain HTML.</p>
''',
      output: '<h1>Welcome</h1>\n<p>Today is a good day to code.</p>\n<p>1 + 2 = 3</p>\n<p>Back to plain HTML.</p>',
      lines: ['The first and last lines are not PHP: they are sent unchanged.', 'The dot (.) joins strings; (1 + 2) is worked out first.'],
      mistake: 'Forgetting the semicolon gives "syntax error, unexpected ...".',
      mistakeCode: r'''echo "Hello"
echo "World";''',
      fixCode: r'''echo "Hello";
echo "World";''',
      practice: 'Print a small HTML list (<ul>) of three subjects with echo.',
      refs: [
        Ref('Basic syntax: PHP tags', _php, '$_man/language.basic-syntax.php', version: _v),
        Ref('echo', _php, '$_man/function.echo.php', version: _v),
      ],
      keywords: ['<?php', 'echo', 'tags', 'html'],
    ),
    Lesson(
      id: 'php-variables',
      title: 'Variables and strings',
      summary: r'Variables start with $; join strings with . or put variables inside "double quotes".',
      objective: 'Store values in variables and print them in sentences.',
      explanation: r'A PHP variable starts with $ and needs no type: $age = 18; $name = "Ana";. Inside double quotes, variables are replaced '
          r'by their value ("Hi $name"); single quotes keep the text exactly. number_format($x, 2) shows two decimals.',
      syntax: r'''$name = "Ana";
$age = 18;
echo "Hi $name";
echo 'Age: ' . $age;''',
      syntaxNotes: [
        (r'$name', r'A variable; the $ is part of the name.'),
        (r'"Hi $name"', 'Double quotes put the value in.'),
        ('number_format(\$x, 2)', 'The number with 2 decimals, as text.'),
      ],
      example: r'''<?php
$name = "Ana";
$age = 18;
$gpa = 1.754;

echo "Name: $name\n";
echo 'Age next year: ' . ($age + 1) . "\n";
echo "GPA: " . number_format($gpa, 2) . "\n";
echo 'Single quotes print $name as it is.' . "\n";
''',
      output: 'Name: Ana\nAge next year: 19\nGPA: 1.75\nSingle quotes print \$name as it is.',
      lines: [r'"\n" is a new line (only inside double quotes).', r'Single quotes leave $name untouched.'],
      mistake: 'Using + to join strings: PHP tries to add them as numbers.',
      mistakeCode: r'''echo "Total: " + 5;  // TypeError''',
      fixCode: r'''echo "Total: " . 5;''',
      practice: 'Store a product name, price and quantity, and print the total with number_format.',
      refs: [Ref('Variables: basics', _php, '$_man/language.variables.basics.php', version: _v)],
      keywords: [r'$', 'variable', 'string', 'concatenation', '.', 'number_format'],
    ),
    Lesson(
      id: 'php-conditions',
      title: 'Conditions: if, elseif, else',
      summary: 'Choose what to show depending on a value.',
      objective: 'Print a remark for a score.',
      explanation: 'if runs code when its condition is true; elseif and else handle the other cases. Compare with === (same value and type), '
          '!==, <, >, <=, >=, and join conditions with && and ||.',
      syntax: r'''if ($score >= 90) {
    ...
} elseif ($score >= 75) {
    ...
} else {
    ...
}''',
      syntaxNotes: [
        ('===', 'Equal and the same type ("5" === 5 is false).'),
        ('elseif', 'One word in PHP.'),
        ('&& / ||', 'And / or.'),
      ],
      example: r'''<?php
$scores = [95, 80, 60];
foreach ($scores as $score) {
    if ($score >= 90) {
        $remark = "Excellent";
    } elseif ($score >= 75) {
        $remark = "Passed";
    } else {
        $remark = "Needs improvement";
    }
    echo "$score: $remark\n";
}
''',
      output: '95: Excellent\n80: Passed\n60: Needs improvement',
      lines: ['The loop gives each score in turn to the if chain.', 'Only the first true branch sets the remark.'],
      mistake: 'Using = (assignment) instead of === in a condition makes it always true.',
      mistakeCode: r'''if ($role = "admin") {''',
      fixCode: r'''if ($role === "admin") {''',
      practice: r'Given $age, print "Minor", "Adult" or "Senior" (60 and up).',
      refs: [Ref('if', _php, '$_man/control-structures.if.php', version: _v)],
      keywords: ['if', 'elseif', 'else', '===', 'condition'],
    ),
    Lesson(
      id: 'php-loops',
      title: 'Loops: for, while, foreach',
      summary: 'Repeat code, or go through every item of an array.',
      objective: 'Build table rows with for and a list with foreach.',
      explanation: r'for ($i = 1; $i <= 5; $i++) counts. foreach ($items as $item) visits each item of an array; foreach ($items as $key => $value) '
          'also gives the key. Loops are how PHP turns data into many rows of HTML.',
      syntax: r'''for ($i = 1; $i <= 3; $i++) { ... }
foreach ($names as $name) { ... }
foreach ($prices as $item => $price) { ... }''',
      syntaxNotes: [
        (r'$i++', r'Adds 1 to $i.'),
        (r'as $key => $value', 'Gives both the key and the value.'),
      ],
      example: r'''<?php
for ($i = 1; $i <= 3; $i++) {
    echo "<tr><td>Row $i</td></tr>\n";
}

$subjects = ["Math", "Science", "English"];
foreach ($subjects as $s) {
    echo "<li>$s</li>\n";
}
''',
      output: '<tr><td>Row 1</td></tr>\n<tr><td>Row 2</td></tr>\n<tr><td>Row 3</td></tr>\n<li>Math</li>\n<li>Science</li>\n<li>English</li>',
      lines: ['The for loop prints three table rows.', 'foreach prints one <li> per subject.'],
      mistake: r'Forgetting $i++ makes the for loop run forever.',
      mistakeCode: r'''for ($i = 1; $i <= 3; ) {''',
      fixCode: r'''for ($i = 1; $i <= 3; $i++) {''',
      practice: 'Print an HTML <select> with <option>s for the years 2020 to 2026.',
      refs: [
        Ref('for', _php, '$_man/control-structures.for.php', version: _v),
        Ref('foreach', _php, '$_man/control-structures.foreach.php', version: _v),
      ],
      keywords: ['for', 'while', 'foreach', 'loop', '=>'],
    ),
    Lesson(
      id: 'php-arrays',
      title: 'Arrays',
      summary: 'Lists and key => value maps in one type.',
      objective: 'Use an indexed array and an associative array, and count them.',
      explanation: r'[1, 2, 3] is an indexed array (keys 0, 1, 2). ["Ana" => 91] is an associative array: you choose the keys. '
          r'count($a) gives the size, $a[] = x adds to the end, and array_sum adds the values.',
      syntax: r'''$nums = [90, 72, 85];
$grades = ["Ana" => 91, "Ben" => 78];
$nums[] = 60;          // add to the end
echo $grades["Ana"];   // 91''',
      syntaxNotes: [
        (r'$nums[0]', 'The first item.'),
        (r'$grades["Ana"]', 'The value stored under the key "Ana".'),
        (r'count($a)', 'Number of items.'),
      ],
      example: r'''<?php
$grades = ["Ana" => 91, "Ben" => 78, "Cara" => 85];
$grades["Dan"] = 70;

foreach ($grades as $name => $grade) {
    echo "$name: $grade\n";
}
echo "Students: " . count($grades) . "\n";
echo "Average: " . number_format(array_sum($grades) / count($grades), 2) . "\n";
''',
      output: 'Ana: 91\nBen: 78\nCara: 85\nDan: 70\nStudents: 4\nAverage: 81.00',
      lines: [r'$grades["Dan"] = 70 adds a new key.', 'array_sum adds all the values; dividing by count gives the average.'],
      mistake: 'Reading a key that does not exist gives a warning ("Undefined array key").',
      mistakeCode: r'''echo $grades["Eve"];''',
      fixCode: r'''echo $grades["Eve"] ?? "no grade";''',
      practice: 'Store prices of three items in an associative array and print the most expensive one.',
      refs: [Ref('foreach', _php, '$_man/control-structures.foreach.php', version: _v)],
      keywords: ['array', 'associative', 'count', 'array_sum', '??', 'key'],
    ),
    Lesson(
      id: 'php-functions',
      title: 'Functions',
      summary: 'Reusable code with parameters and a return value.',
      objective: 'Write a function that turns a score into a letter grade.',
      explanation: r'function name($param) { ... return $value; } defines a function. Type declarations (int $score): string are optional '
          'but catch mistakes early.',
      syntax: r'''function letter(int $score): string {
    return $score >= 90 ? "A" : "B";
}
echo letter(95);''',
      syntaxNotes: [
        (r'int $score', 'The parameter must be an int.'),
        (': string', 'The function returns a string.'),
        ('return', 'Sends the result back.'),
      ],
      example: r'''<?php
function letter(int $score): string {
    if ($score >= 90) return "A";
    if ($score >= 80) return "B";
    if ($score >= 75) return "C";
    return "F";
}

function average(array $nums): float {
    return count($nums) ? array_sum($nums) / count($nums) : 0;
}

$scores = [92, 81, 74];
foreach ($scores as $s) {
    echo "$s -> " . letter($s) . "\n";
}
echo "Average: " . number_format(average($scores), 2) . "\n";
''',
      output: '92 -> A\n81 -> B\n74 -> F\nAverage: 82.33',
      lines: ['letter() returns as soon as a condition is true.', 'average() returns 0 for an empty array instead of dividing by zero.'],
      mistake: r'Using a variable from outside the function: functions cannot see outside variables.',
      mistakeCode: r'''$rate = 0.12;
function tax($x) { return $x * $rate; }''',
      fixCode: r'''function tax($x, $rate) { return $x * $rate; }
echo tax(100, 0.12);''',
      practice: r'Write a function isPassing(int $score): bool and use it to count passing scores.',
      refs: [Ref('User-defined functions', _php, '$_man/functions.user-defined.php', version: _v)],
      keywords: ['function', 'return', 'parameter', 'type', 'scope'],
    ),
    Lesson(
      id: 'php-forms',
      title: 'Forms with \$_POST',
      summary: 'Read what the user typed into an HTML form.',
      objective: 'Make a form that greets the user by name.',
      explanation: r'A <form method="post"> sends its fields to the page named in action (the same page when action is left out). PHP '
          r"finds them in $_POST, using each input's name. Check with isset() or ?? before using a field, and escape it before printing.",
      syntax: r'''<form method="post">
  <input name="name">
  <button>Send</button>
</form>
<?php $name = $_POST["name"] ?? ""; ?>''',
      syntaxNotes: [
        ('method="post"', r'Fields arrive in $_POST.'),
        ('name="name"', r'The key used in $_POST["name"].'),
        (r'?? ""', 'Use "" when the field was not sent (first visit).'),
      ],
      example: r'''<?php
$name = trim($_POST["name"] ?? "");
?>
<!DOCTYPE html>
<html>
<body style="font-family: sans-serif">
  <form method="post">
    <label>Your name <input name="name" required></label>
    <button>Greet me</button>
  </form>
  <?php if ($name !== ""): ?>
    <p>Hello, <?= htmlspecialchars($name) ?>!</p>
  <?php endif; ?>
</body>
</html>
''',
      run: ['Put the example in index.php.', 'Press Run and open the preview.', 'Type a name and press Greet me.'],
      input: 'Ana (typed into the form)',
      output: 'The page shows: Hello, Ana!',
      lines: [
        'On the first visit there is no POST, so \$name is "" and no greeting is shown.',
        '<?= ... ?> is short for <?php echo ... ?>.',
        'htmlspecialchars keeps a name like <b>Ana</b> from turning into HTML.',
      ],
      mistake: r'Reading $_POST["name"] directly shows a warning on the first visit, before the form is sent.',
      mistakeCode: r'''$name = $_POST["name"];''',
      fixCode: r'''$name = $_POST["name"] ?? "";''',
      practice: 'Add an age field and print the age next year, refusing ages that are not numbers.',
      refs: [Ref('Dealing with Forms', _php, '$_man/tutorial.forms.php', version: _v)],
      keywords: [r'$_POST', r'$_GET', 'form', 'isset', 'post', 'input'],
      needs: _server,
      exampleFile: 'index.php',
    ),
    Lesson(
      id: 'php-escaping',
      title: 'Escaping output',
      summary: 'Never print user input as raw HTML.',
      objective: 'Use htmlspecialchars to print user text safely.',
      explanation: 'If a user types <script> into a form and you echo it, the browser runs it (cross-site scripting). '
          'htmlspecialchars turns < > & " \' into harmless text, so the text is shown exactly as typed.',
      syntax: r'''echo htmlspecialchars($text);''',
      syntaxNotes: [
        ('htmlspecialchars(\$s)', '< becomes &lt;, > becomes &gt;, & becomes &amp;, quotes become &quot; / &#039;.'),
      ],
      example: r'''<?php
$comment = '<script>alert("hi")</script> & welcome';
echo "Unsafe: $comment\n";
echo "Safe: " . htmlspecialchars($comment) . "\n";
''',
      output: 'Unsafe: <script>alert("hi")</script> & welcome\nSafe: &lt;script&gt;alert(&quot;hi&quot;)&lt;/script&gt; &amp; welcome',
      lines: ['In a browser the unsafe line would run the script.', 'The safe line shows the text instead of running it.'],
      mistake: 'Escaping the text before saving it to the database: escape when printing, not when storing.',
      mistakeCode: r'''$stmt->bind_param("s", htmlspecialchars($name));''',
      fixCode: r'''$stmt->bind_param("s", $name);       // store as typed
echo htmlspecialchars($row["name"]);   // escape when printing''',
      practice: 'Print a list of three comments, one of them containing <b>, safely.',
      refs: [Ref('htmlspecialchars', _php, '$_man/function.htmlspecialchars.php', version: _v)],
      keywords: ['htmlspecialchars', 'xss', 'escape', 'security'],
    ),
    Lesson(
      id: 'php-mysql',
      title: 'MySQL with prepared statements',
      summary: 'Save and read rows safely with mysqli.',
      objective: 'Create a practice table, insert rows with a prepared statement and list them.',
      explanation: 'mysqli connects PHP to MySQL. For any value that comes from a user, use a prepared statement: the SQL has ? placeholders and '
          'bind_param sends the values separately, so they can never change the SQL (SQL injection). This lesson uses its own disposable table, '
          'learn_students, in the nexus database: it is dropped and created again each run, so your other tables are not touched.',
      syntax: r'''$db = new mysqli("127.0.0.1", "root", "", "nexus");
$stmt = $db->prepare("INSERT INTO t (name, score) VALUES (?, ?)");
$stmt->bind_param("si", $name, $score);
$stmt->execute();''',
      syntaxNotes: [
        ('127.0.0.1, root, "", nexus', 'The NEXUS settings: host, user, password (none), database.'),
        ('?', 'A placeholder for a value.'),
        ('"si"', 'Types of the values: s = string, i = integer, d = double.'),
        ('mysqli_report(...)', 'Makes errors throw exceptions you can catch.'),
      ],
      example: r'''<?php
// Practice table only: dropped and recreated every run.
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
try {
    $db = new mysqli("127.0.0.1", "root", "", "nexus");
    $db->query("DROP TABLE IF EXISTS learn_students");
    $db->query("CREATE TABLE learn_students (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(100), score INT)");

    $stmt = $db->prepare("INSERT INTO learn_students (name, score) VALUES (?, ?)");
    foreach (["Ana" => 91, "Ben" => 78, "O'Neil" => 85] as $name => $score) {
        $stmt->bind_param("si", $name, $score);
        $stmt->execute();
    }

    $min = 80;
    $q = $db->prepare("SELECT name, score FROM learn_students WHERE score >= ? ORDER BY score DESC");
    $q->bind_param("i", $min);
    $q->execute();
    foreach ($q->get_result() as $row) {
        echo htmlspecialchars($row["name"]) . ": " . $row["score"] . "\n";
    }
} catch (mysqli_sql_exception $e) {
    echo "Database error: " . $e->getMessage() . "\n";
}
''',
      run: [
        'Start MySQL: on a lab PC open the XAMPP Control Panel and Start MySQL; on a phone Run starts MariaDB.',
        'Make sure the nexus database exists (in phpMyAdmin or the MySQL console: CREATE DATABASE IF NOT EXISTS nexus;).',
        'Put the example in index.php, press Run and open the preview.',
      ],
      output: 'Ana: 91\nO&#039;Neil: 85',
      lines: [
        "O'Neil has a quote that would break hand-built SQL; with a placeholder it is stored as it is.",
        'get_result() returns the rows; each \$row is an associative array.',
        'If MySQL is not running, the catch block prints "Database error: ..." instead of crashing.',
      ],
      mistake: 'Putting user input straight into SQL lets the user change the query (SQL injection).',
      mistakeCode: r'''$db->query("SELECT * FROM users WHERE name = '$_POST[name]'");''',
      fixCode: r'''$stmt = $db->prepare("SELECT * FROM users WHERE name = ?");
$stmt->bind_param("s", $_POST["name"]);
$stmt->execute();''',
      practice: 'Add a form to the example that inserts a new student with a prepared statement.',
      refs: [
        Ref('mysqli: prepared statements', _php, '$_man/mysqli.quickstart.prepared-statements.php', version: _v),
        Ref('Creating a Table', 'Oracle (MySQL 8.4 Reference Manual)', 'https://dev.mysql.com/doc/refman/8.4/en/creating-tables.html', version: 'MySQL 8.4'),
        Ref('CREATE TABLE', 'MariaDB Documentation', 'https://mariadb.com/docs/server/server-usage/tables/create-table', version: 'MariaDB Server (bundled on phones)'),
      ],
      keywords: ['mysql', 'mariadb', 'mysqli', 'prepare', 'bind_param', 'execute', 'sql', 'injection', 'database'],
      needs: '$_mysql; $_server',
      exampleFile: 'index.php',
    ),
  ],
  quiz: [
    Question('What does PHP do with text outside <?php ?> tags?', ['Ignores it', 'Sends it to the browser unchanged', 'Runs it', 'Shows an error'], 1,
        'Only the code inside the tags runs.'),
    Question('How do you join two strings in PHP?', ['+', '.', '&', ','], 1, 'The dot operator joins strings.'),
    Question(r'With $name = "Ana", what does echo ' "'Hi \$name'" r'; print?', ['Hi Ana', r'Hi $name', 'Hi', 'An error'], 1,
        'Single quotes do not replace variables.'),
    Question('Which comparison is true only for the same value and type?', ['=', '==', '===', '=>'], 2, '=== also compares types.'),
    Question(r'How do you read a posted form field called email?', [r'$_GET["email"]', r'$_POST["email"]', r'$email', r'POST.email'], 1,
        'method="post" fields arrive in \$_POST.'),
    Question('What does count(["a" => 1, "b" => 2]) return?', ['1', '2', '3', '0'], 1, 'Two key => value pairs.'),
    Question('Why use htmlspecialchars when printing user text?', ['It is faster', 'So HTML/scripts in it are shown, not run', 'To save space', 'To translate it'], 1,
        'It prevents cross-site scripting.'),
    Question('What protects a SQL query from injection?', ['addslashes', 'Prepared statements with bind_param', 'htmlspecialchars', 'Uppercase SQL'], 1,
        'Values are sent separately from the SQL.'),
    Question('In bind_param("si", \$a, \$b), what is i?', ['An index', 'An integer value', 'Insert', 'Ignore'], 1, 's = string, i = integer, d = double.'),
    Question('What are the NEXUS MySQL settings?', ['localhost / admin / admin', '127.0.0.1 / root / no password / nexus', '0.0.0.0 / user / 1234', 'They are random'], 1,
        'The same settings work with XAMPP and the phone\'s MariaDB.'),
  ],
  exercises: [
    Exercise(
      id: 'php-ex-table',
      level: 'Beginner',
      title: 'Multiplication table',
      task: 'Print the multiplication table of 7 from 1 to 10, one line each, like "7 x 3 = 21".',
      starter: r'''<?php
$n = 7;
// print 7 x 1 = 7 ... 7 x 10 = 70
''',
      requirements: ['Use a for loop.', r'Use $n so the table changes when $n changes.', 'Print each line followed by a new line.'],
      cases: [TestCase(expect: ['7 x 1 = 7', '7 x 5 = 35', '7 x 10 = 70'], note: 'first, middle and last lines')],
      criteria: 'The test passes.',
      hint: r'for ($i = 1; $i <= 10; $i++) { echo "$n x $i = " . ($n * $i) . "\n"; }',
      solution: r'''<?php
$n = 7;
for ($i = 1; $i <= 10; $i++) {
    echo "$n x $i = " . ($n * $i) . "\n";
}
''',
    ),
    Exercise(
      id: 'php-ex-report',
      level: 'Intermediate',
      title: 'Grade report',
      task: r'Write function letter(int $score): string (A for 90+, B for 80-89, C for 75-79, F below 75). Use it to print "Name: score (letter)" for each '
          'student in the array, then "Class average: " with two decimals.',
      starter: r'''<?php
$students = ["Ana" => 91, "Ben" => 78, "Cara" => 85, "Dan" => 70];

function letter(int $score): string {
    // return A, B, C or F
    return "";
}

// print each student, then the class average
''',
      requirements: ['letter() returns the right grade at the edges (90, 80, 75).', 'foreach over the associative array.', 'number_format for the average.'],
      cases: [TestCase(expect: ['Ana: 91 (A)', 'Ben: 78 (C)', 'Cara: 85 (B)', 'Dan: 70 (F)', 'Class average: 81.00'], note: 'the given students')],
      criteria: 'The test passes.',
      hint: r'foreach ($students as $name => $score) { echo "$name: $score (" . letter($score) . ")\n"; }',
      solution: r'''<?php
$students = ["Ana" => 91, "Ben" => 78, "Cara" => 85, "Dan" => 70];

function letter(int $score): string {
    if ($score >= 90) return "A";
    if ($score >= 80) return "B";
    if ($score >= 75) return "C";
    return "F";
}

foreach ($students as $name => $score) {
    echo "$name: $score (" . letter($score) . ")\n";
}
echo "Class average: " . number_format(array_sum($students) / count($students), 2) . "\n";
''',
    ),
    Exercise(
      id: 'php-ex-guestbook',
      level: 'Challenge',
      title: 'Guest book with MySQL',
      task: 'Build a guest book page: a form with name and message, saved to a practice table learn_guestbook in the nexus database with a '
          'prepared statement, and the 10 newest entries listed below the form (escaped with htmlspecialchars).',
      kind: CheckKind.manual,
      starter: r'''<?php
// MySQL settings: host 127.0.0.1, user root, no password, database nexus.
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$db = new mysqli("127.0.0.1", "root", "", "nexus");
$db->query("CREATE TABLE IF NOT EXISTS learn_guestbook (
    id INT AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    message TEXT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
)");
// 1. if the form was posted, INSERT it with a prepared statement
// 2. SELECT the 10 newest rows
?>
<!DOCTYPE html>
<html>
<body>
  <!-- the form, then the list -->
</body>
</html>
''',
      requirements: [
        'The INSERT uses ? placeholders and bind_param (no values pasted into the SQL).',
        'Empty names or messages are refused with a message.',
        'Every name and message is printed with htmlspecialchars.',
        'Only learn_guestbook is used.',
      ],
      checklist: [
        'MySQL is running (XAMPP on a PC, Run on a phone) and the page opens without a database error.',
        'Submitting the form adds the entry at the top of the list.',
        'An empty name or message shows a message and saves nothing.',
        "A name like O'Neil saves and shows correctly.",
        'A message like <b>hi</b> is shown as text, not bold.',
        'Reloading the page after posting does not break anything.',
      ],
      criteria: 'Every checklist item is true when you try it in the preview. NEXUS cannot check a database page automatically, so you tick the list yourself.',
      hint: r'Check $_SERVER["REQUEST_METHOD"] === "POST", trim both fields, then prepare("INSERT INTO learn_guestbook (name, message) VALUES (?, ?)") and bind_param("ss", ...).',
      solution: r'''<?php
// MySQL settings: host 127.0.0.1, user root, no password, database nexus.
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$error = "";
$rows = [];
try {
    $db = new mysqli("127.0.0.1", "root", "", "nexus");
    $db->query("CREATE TABLE IF NOT EXISTS learn_guestbook (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        message TEXT NOT NULL,
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
    )");
    if ($_SERVER["REQUEST_METHOD"] === "POST") {
        $name = trim($_POST["name"] ?? "");
        $message = trim($_POST["message"] ?? "");
        if ($name === "" || $message === "") {
            $error = "Please fill in both your name and a message.";
        } else {
            $stmt = $db->prepare("INSERT INTO learn_guestbook (name, message) VALUES (?, ?)");
            $stmt->bind_param("ss", $name, $message);
            $stmt->execute();
        }
    }
    $rows = $db->query("SELECT name, message, created_at FROM learn_guestbook ORDER BY id DESC LIMIT 10")->fetch_all(MYSQLI_ASSOC);
} catch (mysqli_sql_exception $e) {
    $error = "Database: " . $e->getMessage();
}
?>
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Guest Book</title>
</head>
<body style="font-family: sans-serif; padding: 16px">
  <h1>Guest Book</h1>
  <form method="post">
    <p><input name="name" placeholder="Your name" maxlength="100"></p>
    <p><textarea name="message" placeholder="Your message"></textarea></p>
    <button>Sign</button>
  </form>
  <?php if ($error): ?><p style="color: red"><?= htmlspecialchars($error) ?></p><?php endif; ?>
  <?php foreach ($rows as $r): ?>
    <p><b><?= htmlspecialchars($r["name"]) ?></b> (<?= $r["created_at"] ?>)<br><?= htmlspecialchars($r["message"]) ?></p>
  <?php endforeach; ?>
</body>
</html>
''',
    ),
  ],
);
