# NEXUS IDE: portfolio kit

Everything for a portfolio entry, ready to copy: titles, descriptions in three lengths, features, tech stack, your role, highlights, links, and a caption for each image in this folder.

---

## Title

**NEXUS IDE: An Offline Coding Classroom for Phones and Lab PCs**

## Tagline (one line)

Write, run and learn C, Python, Java, C#, Web, PHP, SQL, Arduino and Raspberry Pi on an Android phone or a Windows lab PC, with no internet needed.

## Short description (about 50 words, for cards and previews)

NEXUS IDE is an offline programming environment I built with Flutter for CTU Naga Extension Campus. It compiles and runs nine kinds of projects directly on Android phones and Windows PCs. It also includes Learn & Practice: 75 lessons, 90 quiz questions and 27 automatically checked exercises.

## Full description (for the project page)

Many students at CTU Naga Extension Campus learn to program on shared lab PCs or on their own phones, often without a reliable internet connection. NEXUS IDE puts a complete coding classroom into one free app that works offline on **Android and Windows**.

Students pick a workspace (C, Python, Java, C#, Web, PHP, Database/SQL, Arduino or Raspberry Pi), write code in a syntax-highlighted editor with auto-indent, autocomplete and a coding key bar for phone keyboards, and press **Run**. The compilers are bundled inside the app: GCC/TCC for C, Python, Java (JDK on PCs, ecj with Android's own runtime on phones), .NET/Mono for C#, PHP with MariaDB, and avr-gcc for Arduino, which uploads to a real board over USB OTG. On phones, the program runs in a full-screen terminal with an input bar for interactive programs.

Web and PHP projects work **the XAMPP way**: each project is a folder in `htdocs`, opened at `http://localhost/<project>/` in the student's real browser on Windows, or inside the app on phones. New projects can start from ready-made **tech stacks** (HTML + Bootstrap 5, PHP + MySQL, PHP + SQLite, and a Bootstrap + MySQL CRUD app), all working offline. The **Database** workspace runs SQL on SQLite (built in) or MySQL, and prints the results as tables. The **Raspberry Pi** workspace simulates GPIO pins on a 2D board or on a 3D Raspberry Pi 3 model that students can turn, with LEDs lighting up and buttons to press.

**Learn & Practice** turns the IDE into a classroom: nine tracks with 75 lessons. Each lesson has an objective, an explanation, the syntax, a complete example, a common mistake and its fix, a practice task and references to the official documentation. There are 90 quiz questions and 27 exercises that NEXUS checks by actually running the student's code against test cases. Every lesson example is verified automatically against the real compilers, and the database lessons on both SQLite and MySQL.

The app updates itself from GitHub Releases (with checksum verification), and it is open source under the MIT license.

## Key features

- **9 workspaces:** C, Python, Java, C#, Web (HTML/CSS/JS with a drag-and-drop designer), PHP + MySQL, Database (SQLite or MySQL), Arduino and Raspberry Pi.
- **Fully offline:** compilers and runtimes are bundled for Android and Windows.
- **Code editor:** syntax highlighting, auto-indent, autocomplete, Format, find, a file explorer with tabs, an active-line highlight, bracket matching, and arrow and coding keys for phones.
- **Separated terminal output:** program output, build details and run status are kept apart. Each run starts clean, with Stop / Run again, clickable error locations, and a full-screen terminal with an input bar on phones.
- **XAMPP-style htdocs:** project folders at `localhost/<project>/`, a local PHP server, the real browser on Windows, and five tech-stack templates with offline Bootstrap 5.
- **Database workspace:** SQL on SQLite or MySQL, with identical result tables on both.
- **Arduino:** compile on the phone and upload over USB OTG (STK500), with board detection and a Serial Monitor.
- **Raspberry Pi simulator:** RPi.GPIO and GPIO Zero stand-ins, live pins, and an interactive 3D Raspberry Pi 3.
- **Learn & Practice:** 9 tracks, 75 lessons, 90 quiz questions, 27 auto-checked exercises, progress tracking, and references to official docs.
- **Smart new files:** starter code chosen by file type and role (for example, `Student.java` becomes `public class Student`), and a guarded "Reset to Starter Code" with undo.
- **Self-updating:** reads GitHub Releases, verifies the SHA-256 checksum, shows what's new after an update, and displays an update banner.

## Tech stack

- **App:** Flutter / Dart (Material 3, a custom dark theme, Hugeicons). Targets Android (arm64) and Windows (x64).
- **Bundled toolchains:**
  - **C:** GCC (MinGW-w64), TCC.
  - **Python:** Python 3.
  - **Java:** JDK / ecj + Android's ART.
  - **C#:** .NET SDK / Mono.
  - **PHP:** PHP 8 + MariaDB.
  - **Arduino:** arduino-cli / avr-gcc.
  - **SQLite:** through Python's sqlite3.
- **Other:** USB serial with a custom STK500 bootloader protocol, a WebView preview on Android, a Flutter-rendered 3D glTF model, and a GitHub Releases auto-updater.
- **Quality:** about 100 automated Flutter tests, plus a verification tool that runs every Learn example and exercise through the real compilers. Static analysis is clean.

## My role

I designed and developed the whole application as the sole developer: the product idea, UI/UX, the Flutter app, packaging the offline toolchains for Android and Windows, the Learn & Practice curriculum and its automatic checking, testing, and nine public releases (v1.0.0 to v1.1.7) on GitHub.

## Highlights (engineering challenges)

- **Real compilers on a phone, offline:** C, Java, C#, Python and PHP run on Android by bundling and wiring up Linux toolchains. Arduino sketches are compiled and uploaded over USB OTG with a hand-written STK500 implementation.
- **Honest auto-grading:** exercises run the student's real code against test cases with time limits. Hardware and visual exercises never claim "Passed" without a real check; a checklist covers those parts instead.
- **XAMPP-like local hosting:** NEXUS picks port 80, or 8080 when Apache is running, checks both IPv4 and IPv6 so the browser never reaches another server, and stops the server cleanly when the app closes.
- **3D without a web view:** the Raspberry Pi 3 glTF model is drawn with Flutter's own canvas (depth-sorted triangles), so it works offline on Windows and Android with live GPIO pins on its header.
- **Verified content:** every lesson example is run automatically, and the SQL lessons on both SQLite and MySQL. This caught real problems before students could.

## Numbers

| | |
|---|---|
| Workspaces | 9 |
| Learn tracks / lessons | 9 / 75 |
| Quiz questions / exercises | 90 / 27 |
| Automated tests | ~100 (plus every lesson example verified) |
| Code | ~13,000 lines of Dart |
| Releases | 9 (v1.0.0 to v1.1.7) |
| Platforms | Android (arm64), Windows (x64) |

## Links

- Source code (MIT): https://github.com/Ezgaminglogan/nexus-ide
- Downloads (APK and Windows zip): https://github.com/Ezgaminglogan/nexus-ide/releases/latest

## Screenshots and captions

| File | Caption |
|---|---|
| `00-cover.png` | NEXUS IDE on Windows and Android: one offline coding classroom. |
| `01-home-desktop.png` | Home on a lab PC: nine workspaces, each with what you can build and where it runs. |
| `02-editor-and-terminal-desktop.png` | Python running on Windows: the editor with a file explorer and a docked terminal showing the program's output and exit status. |
| `03-home-phone.png` | The same home screen on an Android phone. |
| `04-full-screen-terminal-phone.png` | On phones, Run opens a full-screen terminal. Interactive programs read input from the bar above the keyboard. |
| `05-learn-lesson.png` | Learn & Practice: a lesson with search, topics, highlighted syntax and runnable examples. |
| `06-learn-databases-track.png` | The Databases track: pick SQLite or MySQL and every lesson adapts. The runtime badge shows what runs your code. |
| `07-htdocs-projects.png` | PHP and Web projects the XAMPP way: folders in htdocs, opened at localhost/project/. |
| `08-tech-stacks.png` | Start a project from a tech stack: Bootstrap, PHP + MySQL, PHP + SQLite, or a full CRUD app. |
| `09-sql-on-sqlite-phone.png` | SQL on a phone: SQLite runs offline and prints results as tables. |
| `10-raspberry-pi-3d.png` | The Raspberry Pi simulator on a 3D Raspberry Pi 3 you can turn, with live GPIO pins. |
| `11-new-file-starter-code.png` | New files start with the right starter code for their type and role, with a preview. |
| `12-checked-exercise.png` | Exercises are checked by running the student's code against real test cases. |

## Credits (keep these when you publish)

- 3D model: "Raspberry Pi 3" by JoSaCo (Sketchfab), licensed CC BY 4.0, shown in `10-raspberry-pi-3d.png`.
- Bootstrap 5 (MIT) is bundled for the tech stacks.
- The screenshots are rendered from the real app's widgets with Flutter's test engine at desktop and phone sizes.
