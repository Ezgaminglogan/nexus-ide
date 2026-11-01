# NEXUS IDE: Databases (SQLite & MySQL) and tech stacks

## 1. The Database workspace

A ninth home tile, **Database** ("SQL · SQLite or MySQL"), edits and runs `main.sql`. You choose the engine above the editor, and NEXUS remembers the choice.

| Engine | How NEXUS runs `main.sql` | Needs |
|---|---|---|
| **SQLite** | `run_sql.py` (bundled Python's `sqlite3`) runs each statement on the file `nexus.db` in the project. It prints a table for each query (numbers right-aligned, like MySQL), "N rows affected" for each change, and stops at the first error with `ERROR at line N in file: 'main.sql'` | Nothing: works offline on PCs and phones (Python 3.14 + SQLite 3.50 on the lab PC, SQLite 3.54 in the phone pack) |
| **MySQL** | **Step 1:** `mysql -e "CREATE DATABASE IF NOT EXISTS nexus"`, shown in Build details. **Step 2:** `mysql --table --abort-source-on-error nexus -e "source main.sql"`. The client prints the tables and stops at the first error with a failing exit code | **PC:** XAMPP MySQL running. NEXUS finds `C:\xampp\mysql\bin\mysql.exe` even when it isn't on PATH. **Phone:** the bundled MariaDB, started with the local server, and the `mariadb` client |

- **Settings:** host `127.0.0.1`, user `root`, no password. The student's own work goes in database `nexus`.
- **Learn practice:** each practice copy gets its **own** MySQL database, named after it (for example `nexus_lesson_db_join`). Without that, one lesson's tables and foreign keys blocked another lesson's `DROP TABLE`. The verify tool found this.
- **Errors:** messages from both engines (`at line N in file: 'main.sql'`) are tappable and jump to that line.
- **XAMPP fallback:** `Toolchains.resolve` checks `C:\xampp\<tool>.exe` after the bundled tools and before PATH. That also finds XAMPP's PHP when it isn't on PATH.

## 2. The Database Learn track ("Databases: SQLite & MySQL")

The workspace overview, and every lesson, has an **"I am learning with: SQLite | MySQL"** switch. It's the same setting as the editor's. Each lesson shows what differs on the chosen engine, with the other engine underneath.

| Lesson | Covers |
|---|---|
| What a database is, and its types | Tables, rows, columns. Server databases (MySQL, MariaDB, PostgreSQL) vs embedded/file databases (SQLite). A mention of NoSQL |
| Creating tables and data types | CREATE TABLE, INTEGER, VARCHAR, DATE, DECIMAL, NOT NULL, PRIMARY KEY. Type affinity vs strict types. AUTO_INCREMENT vs INTEGER PRIMARY KEY |
| Adding rows: INSERT | Single and multi-row inserts, quoting, COUNT(*) |
| Asking questions: SELECT | WHERE, AND/OR, comparisons, LIKE, ORDER BY, LIMIT |
| Changing data: UPDATE and DELETE | Always with WHERE; safe updates |
| Related tables: keys and JOIN | FOREIGN KEY, JOIN … ON, aliases, LEFT JOIN. `PRAGMA foreign_keys` vs InnoDB |
| Summaries: GROUP BY | COUNT, SUM, AVG, MIN, MAX, HAVING, and how AVG decimals differ |
| Using the database from PHP | PDO with SQLite or MySQL by changing one connection line; prepared statements; SQL injection |

- **Quiz:** 10 questions on database types, keys, AUTO_INCREMENT, WHERE/HAVING, foreign keys and PDO.
- **Exercises:** **BSIT class list** (Beginner), **Students per course** (Intermediate, GROUP BY) and **Who failed what** (Challenge, two JOINs). They're checked automatically by running the student's SQL on SQLite in its own folder.

### References (every page was opened on 2026-11-01)

The links were found with web search. sqlite.org, w3schools.com, sqlitetutorial.net, mysqltutorial.org, getbootstrap.com and php.net answered a scripted check with HTTP 200. dev.mysql.com refuses scripts (HTTP 403), so its pages were opened in the browser and their titles checked.

- **SQLite:**
  - [When to use](https://www.sqlite.org/whentouse.html)
  - [Serverless](https://www.sqlite.org/serverless.html)
  - [CREATE TABLE](https://www.sqlite.org/lang_createtable.html)
  - [Datatypes](https://www.sqlite.org/datatype3.html)
  - [INSERT](https://www.sqlite.org/lang_insert.html)
  - [SELECT](https://www.sqlite.org/lang_select.html)
  - [UPDATE](https://www.sqlite.org/lang_update.html)
  - [DELETE](https://www.sqlite.org/lang_delete.html)
  - [Foreign keys](https://www.sqlite.org/foreignkeys.html)
  - [Aggregate functions](https://www.sqlite.org/lang_aggfunc.html)
- **MySQL 8.4 Reference Manual:**
  - [Creating and Using a Database](https://dev.mysql.com/doc/refman/8.4/en/database-use.html)
  - [Creating a Table](https://dev.mysql.com/doc/refman/8.4/en/creating-tables.html)
  - [Data Types](https://dev.mysql.com/doc/refman/8.4/en/data-types.html)
  - [INSERT](https://dev.mysql.com/doc/refman/8.4/en/insert.html)
  - [SELECT](https://dev.mysql.com/doc/refman/8.4/en/select.html)
  - [UPDATE](https://dev.mysql.com/doc/refman/8.4/en/update.html)
  - [DELETE](https://dev.mysql.com/doc/refman/8.4/en/delete.html)
  - [JOIN](https://dev.mysql.com/doc/refman/8.4/en/join.html)
  - [FOREIGN KEY](https://dev.mysql.com/doc/refman/8.4/en/create-table-foreign-keys.html)
  - [Aggregate functions](https://dev.mysql.com/doc/refman/8.4/en/aggregate-functions.html)
- **PHP:**
  - [PDO](https://www.php.net/manual/en/book.pdo.php)
  - [Prepared statements](https://www.php.net/manual/en/pdo.prepared-statements.php)
  - [PDO SQLite driver](https://www.php.net/manual/en/ref.pdo-sqlite.php)
- **Free tutorials:**
  - [W3Schools SQL](https://www.w3schools.com/sql/), with [Joins](https://www.w3schools.com/sql/sql_join.asp) and [GROUP BY](https://www.w3schools.com/sql/sql_groupby.asp)
  - [SQLite Tutorial](https://www.sqlitetutorial.net/)
  - [MySQL Tutorial](https://www.mysqltutorial.org/)

The lesson text is original. Every lesson example runs on **both** SQLite and MySQL. XAMPP ships MariaDB 10.4, which is MySQL-compatible for everything taught here.

## 3. Tech stacks for htdocs projects

New project (htdocs) offers five stacks. The chosen stack is stored in `.nexus-stack` in the project folder and shown on the project card.

| Stack | Starts with |
|---|---|
| HTML + CSS + JS | `index.html` (the Web template) |
| HTML + Bootstrap 5 | A responsive page: navbar, grid of cards, button. **Bootstrap 5.3.8 copied into `assets/bootstrap/`** |
| PHP + MySQL | The mysqli guest book |
| PHP + SQLite | A guest book in `guestbook.db` with PDO: no database server |
| PHP + Bootstrap + MySQL | A student list with add and delete (CRUD), prepared statements, a redirect after POST, Bootstrap styling |

- **Bootstrap** ships inside NEXUS (`assets/stacks/bootstrap`, MIT license, with `LICENSE` copied into each project). Its SHA-384 hashes match the ones published on getbootstrap.com's download page for 5.3.8.
- **Learn:** the Web track has a new lesson, **"Frameworks: Bootstrap"**: the grid, container, components, offline files, and other frameworks students will meet (Tailwind, React/Vue, Laravel). It links Bootstrap's [introduction](https://getbootstrap.com/docs/5.3/getting-started/introduction/), [grid](https://getbootstrap.com/docs/5.3/layout/grid/), [navbar](https://getbootstrap.com/docs/5.3/components/navbar/) and [forms](https://getbootstrap.com/docs/5.3/forms/overview/).

## 4. Tests (2026-11-01, Windows lab PC with XAMPP running)

| Check | Result |
|---|---|
| `TRACK=sql flutter test tool/verify_learn_test.dart` | 17 passed: the 7 runnable lessons on SQLite, the same 7 on XAMPP's MySQL, and the 3 exercises (solutions pass, starters don't) |
| `test/terminal_flow_test.dart` (Database tile) | The template runs on SQLite, then on MySQL (same rows), and an SQL error links to `main.sql:2` |
| `test/htdocs_test.dart` (stacks) | On a real PHP server: the SQLite guest book saves and escapes a posted name; Bootstrap 5.3.8 and the navbar page are served offline; the Bootstrap + MySQL page adds a student to XAMPP's MySQL (then removed) |
| `flutter test` / `flutter analyze` | All pass / no issues |

**Not verified:**
- **On a phone:** none of this was run on a phone, including the bundled `mariadb` client, PHP's PDO SQLite driver in the phone's PHP, and Python's `_sqlite3` (present in the pack).
- **The PDO lesson (`db-php`):** it was not run automatically, because it needs the server.
