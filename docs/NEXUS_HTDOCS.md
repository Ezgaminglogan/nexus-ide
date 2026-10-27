# NEXUS IDE: htdocs and localhost (the XAMPP way)

PHP and Web projects work like XAMPP, so what students practise in NEXUS is what they do on a lab PC with XAMPP and later on real hosting.

## What students see

- **The PHP and Web tiles open `htdocs`.** It lists the project folders (`guestbook`, `portfolio`…). It also shows where `htdocs` is on disk (with a copy button, and "Open in File Explorer" on Windows) and whether the local server is running.
- **New project** asks for a folder name and **PHP site** or **HTML site**. It shows the folder (`htdocs/<name>/`) and the address before creating, and starts the project with `index.php` or `index.html`.
- **Names** must work in a URL: letters, numbers, `-` and `_`, no spaces, and no duplicates (case-insensitive).
- **Each project opens at `http://localhost/<project>/`.**
  - **Windows:** **Open in browser** opens it in the student's own default browser (Chrome, Edge, Firefox…).
  - **Android:** **View** shows it inside NEXUS.
  - A PHP file that is open in the editor opens at its own address, such as `localhost/guestbook/about.php`.
- Projects can be renamed (the address changes with them) and deleted (after a confirmation).

## The server (`lib/core/htdocs.dart`, `LocalServer`)

**One server for all of `htdocs`**, like XAMPP's Apache:

- It starts by itself when a project is viewed, or with **Start** on the htdocs screen.
- It keeps running when you leave the editor, until **Stop** or until NEXUS closes.

**Windows:**

- **Server:** PHP's built-in server, `php -S 127.0.0.1:<port> -t <htdocs>`, using PHP from `toolchains/php`, or XAMPP's PHP when it is on PATH.
- **Port 80**, so the address is exactly `http://localhost/<project>/`, when nothing else answers there.
- **Port 8080** (then 8081–8090) when another server already holds port 80, usually **XAMPP's own Apache** or IIS. The htdocs screen says so: "Port 8080: port 80 is busy…".
- **Busy check:** a port counts as busy if anything answers on `127.0.0.1` **or** `[::1]`. Browsers try IPv6 first for `localhost`, so this keeps a browser from silently showing another server's page.

**Android:** the bundled `web/serve.sh`, started inside `htdocs`. It starts MariaDB once, then PHP on port 8080, so the address is `http://localhost:8080/<project>/`. Android apps can't use port 80.

**Web (HTML) projects:**

- On Windows they are served the same way. If PHP is missing, the file opens directly in the browser.
- On phones they open straight from the file, so no server is needed.

**MySQL:** host `127.0.0.1`, user `root`, no password, database `nexus`.

- **Lab PC:** start MySQL in the XAMPP Control Panel. phpMyAdmin still works through XAMPP's Apache (`http://localhost/phpmyadmin/`).
- **Phone:** MariaDB starts with the server.

**Closing NEXUS** stops the server (`AppLifecycleListener` in `main.dart`), so no `php.exe` keeps the port busy.

## Moving older projects

Before this change, the PHP and Web tiles each had one folder (`workspace/php`, `workspace/web`). The first time htdocs opens, their files are copied into `htdocs/my-php-site` and `htdocs/my-website`. This happens once, and never over newer edits. The old folders are left where they were.

## Differences from XAMPP (stated honestly)

- **No `.htaccess` or URL rewriting:** PHP's built-in server is not Apache.
- **One request at a time:** that's fine for class projects.
- **Address on phones:** `localhost:8080`, not `localhost`.
- **Address on a PC running XAMPP's Apache:** `localhost:8080`, because port 80 is Apache's.

## Tests

`test/htdocs_test.dart`:

- Projects, names, and moving the old folders.
- A **real PHP server**: it answers at `localhost:<port>/<project>/` with `REQUEST_URI` `/hello/`, and at `about.php`.
- Port 80 being taken: the server falls back to 8080.
- The htdocs screen: list, address, path, New project (a name with a space is refused), opening the editor with **Open in browser**.

On the PC used for testing, XAMPP's Apache already held port 80, so the 8080 path ran for real; the port-80 path was not exercised there. Nothing in this change was run on a phone.

Screenshots: `docs/screenshots/htdocs.png` and `phone_htdocs.png` (phone layout drawn by the test engine).
