/// Tech stacks for new htdocs projects: what the project is built with, ready to run offline.
/// Bootstrap ships inside NEXUS (assets/stacks/bootstrap, v5.3.8, MIT) and is copied into the
/// project's assets/bootstrap folder, so pages look right without the internet.
library;

typedef TechStack = ({String id, String label, String about, bool php, bool bootstrap});

const techStacks = <TechStack>[
  (id: 'html', label: 'HTML + CSS + JS', about: 'A plain web page you build from scratch: index.html.', php: false, bootstrap: false),
  (
    id: 'html-bootstrap',
    label: 'HTML + Bootstrap 5',
    about: 'A responsive page with Bootstrap\'s grid, navbar, cards and buttons (Bootstrap included, works offline).',
    php: false,
    bootstrap: true,
  ),
  (id: 'php-mysql', label: 'PHP + MySQL', about: 'A guest book saved in MySQL with mysqli (XAMPP MySQL on PCs, MariaDB on phones).', php: true, bootstrap: false),
  (
    id: 'php-sqlite',
    label: 'PHP + SQLite',
    about: 'A guest book saved in a SQLite file with PDO. No database server to start.',
    php: true,
    bootstrap: false,
  ),
  (
    id: 'php-bootstrap-mysql',
    label: 'PHP + Bootstrap + MySQL',
    about: 'A student list you can add to and delete from (CRUD), styled with Bootstrap, saved in MySQL.',
    php: true,
    bootstrap: true,
  ),
];

TechStack stackById(String? id) => techStacks.firstWhere((s) => s.id == id, orElse: () => techStacks.first);

/// The index page each stack starts with ('php-mysql' and 'html' use the PHP and Web templates).
const stackPages = {
  'html-bootstrap': _bootstrapPage,
  'php-sqlite': _phpSqlitePage,
  'php-bootstrap-mysql': _phpBootstrapCrud,
};

const _bootstrapPage = '''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>My Bootstrap Page</title>
  <link rel="stylesheet" href="assets/bootstrap/css/bootstrap.min.css">
</head>
<body>
  <nav class="navbar navbar-expand-md navbar-dark bg-primary">
    <div class="container">
      <a class="navbar-brand" href="#">CTU Naga</a>
      <button class="navbar-toggler" type="button" data-bs-toggle="collapse" data-bs-target="#menu" aria-controls="menu" aria-expanded="false" aria-label="Menu">
        <span class="navbar-toggler-icon"></span>
      </button>
      <div class="collapse navbar-collapse" id="menu">
        <ul class="navbar-nav ms-auto">
          <li class="nav-item"><a class="nav-link active" href="#">Home</a></li>
          <li class="nav-item"><a class="nav-link" href="#courses">Courses</a></li>
        </ul>
      </div>
    </div>
  </nav>

  <main class="container py-4">
    <h1 class="mb-3">Hello, CTU Naga!</h1>
    <p class="lead">This page uses Bootstrap: resize the window and the cards rearrange.</p>
    <div class="row g-3" id="courses">
      <div class="col-12 col-md-4">
        <div class="card h-100"><div class="card-body"><h5 class="card-title">BSIT</h5><p class="card-text">Information Technology</p></div></div>
      </div>
      <div class="col-12 col-md-4">
        <div class="card h-100"><div class="card-body"><h5 class="card-title">BEEd</h5><p class="card-text">Elementary Education</p></div></div>
      </div>
      <div class="col-12 col-md-4">
        <div class="card h-100"><div class="card-body"><h5 class="card-title">BSIE</h5><p class="card-text">Industrial Engineering</p></div></div>
      </div>
    </div>
    <button class="btn btn-success mt-4">Enroll now</button>
  </main>

  <script src="assets/bootstrap/js/bootstrap.bundle.min.js"></script>
</body>
</html>
''';

const _phpSqlitePage = r'''<?php
// PHP + SQLite: the database is the file guestbook.db next to this page (created on first visit).
$error = '';
$guests = [];
try {
    $db = new PDO('sqlite:' . __DIR__ . '/guestbook.db');
    $db->setAttribute(PDO::ATTR_ERRMODE, PDO::ERRMODE_EXCEPTION);
    $db->exec('CREATE TABLE IF NOT EXISTS guests (id INTEGER PRIMARY KEY, name TEXT NOT NULL, signed_at TEXT DEFAULT CURRENT_TIMESTAMP)');
    if (!empty($_POST['name'])) {
        $stmt = $db->prepare('INSERT INTO guests (name) VALUES (?)');
        $stmt->execute([trim($_POST['name'])]);
    }
    $guests = $db->query('SELECT name, signed_at FROM guests ORDER BY id DESC')->fetchAll(PDO::FETCH_ASSOC);
} catch (PDOException $e) {
    $error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Guest Book (SQLite)</title>
</head>
<body style="font-family: sans-serif; padding: 16px">
  <h1>Guest Book</h1>
  <p>Saved in a SQLite file with PDO: no database server needed.</p>
  <form method="post">
    <input name="name" placeholder="Your name" required>
    <button>Sign</button>
  </form>
  <?php if ($error) echo '<p style="color:red">Database: ' . htmlspecialchars($error) . '</p>'; ?>
  <ul>
    <?php foreach ($guests as $g) echo '<li>' . htmlspecialchars($g['name']) . ' <small>' . htmlspecialchars($g['signed_at']) . '</small></li>'; ?>
  </ul>
</body>
</html>
''';

const _phpBootstrapCrud = r'''<?php
// PHP + Bootstrap + MySQL: add and delete students (CRUD) with prepared statements.
// MySQL: host 127.0.0.1, user root, no password, database nexus (start MySQL in XAMPP on a PC).
mysqli_report(MYSQLI_REPORT_ERROR | MYSQLI_REPORT_STRICT);
$error = '';
$students = [];
try {
    $db = new mysqli('127.0.0.1', 'root', '', 'nexus');
    $db->set_charset('utf8mb4');
    $db->query('CREATE TABLE IF NOT EXISTS crud_students (
        id INT AUTO_INCREMENT PRIMARY KEY,
        name VARCHAR(100) NOT NULL,
        course VARCHAR(20) NOT NULL
    )');
    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        if (isset($_POST['delete'])) {
            $stmt = $db->prepare('DELETE FROM crud_students WHERE id = ?');
            $id = (int) $_POST['delete'];
            $stmt->bind_param('i', $id);
            $stmt->execute();
        } elseif (trim($_POST['name'] ?? '') !== '') {
            $stmt = $db->prepare('INSERT INTO crud_students (name, course) VALUES (?, ?)');
            $name = trim($_POST['name']);
            $course = $_POST['course'] ?? 'BSIT';
            $stmt->bind_param('ss', $name, $course);
            $stmt->execute();
        }
        header('Location: ' . $_SERVER['PHP_SELF']); // reloading won't post the form again
        exit;
    }
    $students = $db->query('SELECT id, name, course FROM crud_students ORDER BY name')->fetch_all(MYSQLI_ASSOC);
} catch (mysqli_sql_exception $e) {
    $error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Students</title>
  <link rel="stylesheet" href="assets/bootstrap/css/bootstrap.min.css">
</head>
<body class="bg-light">
  <main class="container py-4">
    <h1 class="mb-4">Students</h1>
    <?php if ($error): ?>
      <div class="alert alert-danger">Database: <?= htmlspecialchars($error) ?></div>
    <?php endif; ?>
    <form method="post" class="row g-2 mb-4">
      <div class="col-12 col-md-6"><input class="form-control" name="name" placeholder="Student name" required></div>
      <div class="col-8 col-md-3">
        <select class="form-select" name="course">
          <option>BSIT</option><option>BEEd</option><option>BSIE</option>
        </select>
      </div>
      <div class="col-4 col-md-3"><button class="btn btn-primary w-100">Add</button></div>
    </form>
    <table class="table table-striped bg-white">
      <thead><tr><th>Name</th><th>Course</th><th></th></tr></thead>
      <tbody>
        <?php foreach ($students as $s): ?>
          <tr>
            <td><?= htmlspecialchars($s['name']) ?></td>
            <td><?= htmlspecialchars($s['course']) ?></td>
            <td class="text-end">
              <form method="post" class="d-inline"><button class="btn btn-sm btn-outline-danger" name="delete" value="<?= $s['id'] ?>">Delete</button></form>
            </td>
          </tr>
        <?php endforeach; ?>
      </tbody>
    </table>
  </main>
  <script src="assets/bootstrap/js/bootstrap.bundle.min.js"></script>
</body>
</html>
''';
