# NEXUS IDE: Documentation, Practice and Reset to Starter Code

This covers two features added after v1.1.2:

- **Learn & Practice:** offline lessons, a 10-question quiz and three checked exercises for each of the 8 workspaces.
- **Reset to Starter Code:** a guarded way to clear the code in the open file.

## 1. What runs each workspace (inspected, not assumed)

| Workspace | Lab PC | Phone | Learn status badge |
|---|---|---|---|
| C | GCC (MinGW-w64, bundled) | TCC (bundled) | installed / missing, probed with `gcc --version` |
| Python | Python 3 (bundled or PATH) | bundled Python | installed / missing |
| Java | JDK 21, single-file `java Main.java` | ecj at Java 8 level, then Android's ART | installed / missing |
| C# | .NET 10 SDK (`dotnet build` / `run`) | Mono `mcs` (C# 7 level) | installed / missing |
| PHP + MySQL | PHP (toolchains, XAMPP or PATH); MySQL from XAMPP | bundled PHP + MariaDB | installed / missing (MySQL is not probed; lessons that need it say so) |
| Raspberry Pi | Python + NEXUS GPIO stand-in | same | **simulated** (RPi.GPIO subset + GPIO Zero LED/Button; no PWM, events, I2C/SPI) |
| Arduino | arduino-cli + AVR core | avr-gcc, upload over USB OTG | installed / missing; behaviour needs a real board (no simulator) |
| Web | none: the system web view | none | **built-in** |

`runtimeStatus()` in `lib/learn/practice.dart` starts the real tool on the PC, or checks that the bundled file exists on a phone. That is what the badge on each track's overview shows.

Because of these runtimes, the lessons are written to work on both PC and phone:

- **Java:** Java 8 syntax only (no `var` or records). Extra classes go *after* `class Main`, because single-file mode runs the first class in the file.
- **C#:** the classic `class Program { static void Main() }` form, with no top-level statements.
- **C:** standard C, with no GCC-only extensions.

## 2. Content structure

```
lib/learn/
  model.dart          Ref, Lesson, Question, Exercise, TestCase, CheckKind, Track
  tracks.dart         the list of tracks (home order) + trackFor(langId)
  tracks/<id>.dart    one track per workspace: c, python, java, csharp, php, raspi, arduino, web
  practice.dart       checkExercise(), outputMatches(), runtimeStatus(), PracticeRun (Stop)
lib/ui/screens/learn_screen.dart   the reader: sidebar/drawer, search, lessons, quiz, exercises
tool/verify_learn_test.dart        runs every example and exercise against the real toolchains
test/learn_test.dart               content completeness + UI behaviour
```

### Each lesson has these parts

1. Objective.
2. Explanation.
3. Syntax with per-part notes.
4. A complete example.
5. How to run it.
6. Sample input and expected output.
7. The important lines explained.
8. A common mistake with wrong and fixed code.
9. A practice task.
10. References.

`needs` says which hardware or software a lesson needs. Output labels separate *simulated* results (Pi) from *on a real board* (Arduino) and *what the preview shows* (Web).

### Exercises and how each kind is checked

| `CheckKind` | What Check does | Can it say "Passed"? |
|---|---|---|
| `output` | Compiles once (2-minute limit), then runs each test case with its input (10 s each) and looks for the expected lines, in order | Yes, only when every case passes |
| `gpio` | Runs in the Pi simulator with the given buttons held, then compares the printed lines and the final pin states | Yes, labelled as a simulator check |
| `staticHtml` | Reads the .html/.css/.js files for the required parts (regexes); does not run the page | Yes for the static checks; looks and behaviour are a separate checklist |
| `compileOnly` | Compiles for an Arduino Uno | **Never**: shows "Not checked automatically" plus a checklist |
| `manual` | Nothing (for example, it needs MySQL running) | **Never**: checklist only |

`CheckResult.passed` is true only when `automatic && cases.isNotEmpty && every case passed`. A missing runtime, a timeout or Stop never counts as a pass.

Other exercise rules:

- **Isolated code:** exercise code lives in `workspace/practice/<exercise id>/<lang>`. Lesson "Try in Editor" copies live in `workspace/practice/lesson-<lesson id>/<lang>`. The student's own workspace files are never touched. If a practice copy has changed, Try in Editor asks before replacing it, and Start over asks before restoring the starter.
- **Progress:** saved in `workspace/.nexus/learn.json`. It holds lessons opened, best quiz score, attempts, passes and checklist ticks.
- **Hints and solutions:** the hint is always available. The solution unlocks only after the first Check.

### The reader

- **Entry points:** a *Learn & Practice* card on the home screen, and a *Learn* button in every editor (in the ⋮ menu on phones), which opens that workspace's track.
- **Navigation:** a topic sidebar that can be hidden on wide screens, or a drawer on phones. Breadcrumbs and Previous/Next buttons on every page.
- **Search:** covers language, title, summary, keywords (functions and symbols such as `printf` or `addEventListener`), explanations and syntax.
- **Code blocks:** highlighted with a Copy button.
- **View Source:** opens the reference in the external browser; the page notes that this needs the internet and that the lesson itself works offline.

Screenshots: `docs/screenshots/learn_lesson.png`, `learn_lesson_mistake.png`, `learn_exercise.png`, `phone_learn_lesson.png`, `desktop_home.png`.

## 3. Content per workspace

| Workspace | Lessons | Quiz | Exercises (kind) |
|---|---|---|---|
| C | 9 | 10 | Beginner: Pass or fail (output); Intermediate: Class average (output); Challenge: Count the vowels (output) |
| Python | 9 | 10 | Beginner: Odd or even (output); Intermediate: Score statistics (output); Challenge: Most common word (output) |
| Java | 9 | 10 | Beginner: Bigger of two (output); Intermediate: Grade counter (output); Challenge: Bank account object (output) |
| C# | 9 | 10 | Beginner: Celsius to Fahrenheit (output); Intermediate: Above the average (output); Challenge: Inventory with a class (output) |
| PHP + MySQL | 9 | 10 | Beginner: Multiplication table (output); Intermediate: Grade report (output); Challenge: Guest book with MySQL (manual) |
| Raspberry Pi GPIO | 6 | 10 | Beginner: Traffic light (gpio); Intermediate: Button check (gpio); Challenge: Blink n times (gpio) |
| Arduino | 7 | 10 | Beginner: SOS blink (compileOnly); Intermediate: Press counter (compileOnly); Challenge: Serial-controlled blink rate (compileOnly) |
| Web: HTML, CSS, JavaScript | 8 | 10 | Beginner: Profile page (staticHtml); Intermediate: Responsive cards (staticHtml); Challenge: To-do list (staticHtml) |

## 4. Reference records

All lesson text is original, written for NEXUS. Each reference was opened and checked on **2026-10-25**:

- **Fetched by script:** most pages.
- **Opened in a browser:** pages whose sites refuse scripts (HTTP 403: gnu.org, dev.mysql.com, raspberrypi.com) or that render with JavaScript (docs.arduino.cc).
- **Redirects:** the final URL after redirects is the one stored (dev.java, MariaDB, Microsoft Learn's `?view=` redirect).
- **Not available:** the GNU C manual has no page dedicated to GCC extensions (the guessed URL returned 404), so the C introduction says so in words instead of linking one.
- **Partly simulated:** GPIO Zero 2.0.1 is cited, but NEXUS simulates only `LED` and `Button`, and the lesson says so.

The records live in the lessons (`Ref(title, publisher, url, version:, verified:)`). This table is generated from them:

| Workspace | Title | Publisher | URL | Version | Verified | Used by |
|---|---|---|---|---|---|---|
| C | Complete Program | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Complete-Program.html | GNU C manual (current), GCC 16 / TCC 0.9 | 2026-10-25 | c-structure |
| C | GNU C Intro and Reference (describes GNU C, which is standard C plus GCC extensions) | Free Software Foundation | https://www.gnu.org/software/c-intro-and-ref/ | - | 2026-10-25 | c-structure |
| C | Variable Declarations | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Variable-Declarations.html | - | 2026-10-25 | c-variables |
| C | Formatted Output (printf) | GNU C Library manual | https://sourceware.org/glibc/manual/latest/html_node/Formatted-Output.html | - | 2026-10-25 | c-variables, c-io |
| C | Formatted Input (scanf) | GNU C Library manual | https://sourceware.org/glibc/manual/latest/html_node/Formatted-Input.html | - | 2026-10-25 | c-io |
| C | if Statement | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/if-Statement.html | - | 2026-10-25 | c-conditions |
| C | for Statement | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/for-Statement.html | - | 2026-10-25 | c-loops |
| C | while Statement | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/while-Statement.html | - | 2026-10-25 | c-loops |
| C | Function Definitions | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Function-Definitions.html | - | 2026-10-25 | c-functions |
| C | Arrays | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Arrays.html | - | 2026-10-25 | c-arrays |
| C | Strings | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Strings.html | - | 2026-10-25 | c-strings |
| C | Pointers | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Pointers.html | - | 2026-10-25 | c-pointers |
| C | Pointers and Arrays | GNU C Language Manual (GNU C Intro and Reference) | https://www.gnu.org/software/c-intro-and-ref/manual/html_node/Pointers-and-Arrays.html | - | 2026-10-25 | c-pointers |
| Python | An Informal Introduction to Python: numbers and text | Python Software Foundation | https://docs.python.org/3.14/tutorial/introduction.html | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-indentation, py-variables |
| Python | Lexical analysis: indentation | Python Software Foundation | https://docs.python.org/3.14/reference/lexical_analysis.html#indentation | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-indentation |
| Python | Built-in Functions: input() | Python Software Foundation | https://docs.python.org/3.14/library/functions.html#input | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-io |
| Python | Input and Output | Python Software Foundation | https://docs.python.org/3.14/tutorial/inputoutput.html | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-io |
| Python | More Control Flow Tools: if Statements | Python Software Foundation | https://docs.python.org/3.14/tutorial/controlflow.html#if-statements | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-conditions |
| Python | More Control Flow Tools: for Statements | Python Software Foundation | https://docs.python.org/3.14/tutorial/controlflow.html#for-statements | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-loops |
| Python | More Control Flow Tools: The range() Function | Python Software Foundation | https://docs.python.org/3.14/tutorial/controlflow.html#the-range-function | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-loops |
| Python | More Control Flow Tools: Defining Functions | Python Software Foundation | https://docs.python.org/3.14/tutorial/controlflow.html#defining-functions | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-functions |
| Python | Data Structures: More on Lists | Python Software Foundation | https://docs.python.org/3.14/tutorial/datastructures.html#more-on-lists | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-lists |
| Python | Data Structures: Dictionaries | Python Software Foundation | https://docs.python.org/3.14/tutorial/datastructures.html#dictionaries | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-dicts |
| Python | Errors and Exceptions: Handling Exceptions | Python Software Foundation | https://docs.python.org/3.14/tutorial/errors.html#handling-exceptions | Python 3.14 (NEXUS runs 3.14) | 2026-10-25 | py-errors |
| Java | Getting Started with Java | Dev.java (Oracle) | https://dev.java/learn/first-steps/first-java-code/getting-started/ | Java 8 language level on phones (ecj), Java 21 on the lab PCs | 2026-10-25 | java-structure |
| Java | Creating Variables and Naming Them | Dev.java (Oracle) | https://dev.java/learn/language/constructs/basics/variables/ | Java 8 language level on phones (ecj), Java 21 on the lab PCs | 2026-10-25 | java-variables |
| Java | Class Scanner (Java SE 21 API) | Oracle | https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Scanner.html | Java SE 21; the methods used here exist since Java 5 | 2026-10-25 | java-io |
| Java | Control Flow Statements | Dev.java (Oracle) | https://dev.java/learn/language/constructs/basics/controlling-flow/ | Java 8 language level on phones (ecj), Java 21 on the lab PCs | 2026-10-25 | java-conditions, java-loops |
| Java | Defining Methods | Dev.java (Oracle) | https://dev.java/learn/language/oop/classes-objects/defining-methods/ | Java 8 language level on phones (ecj), Java 21 on the lab PCs | 2026-10-25 | java-methods |
| Java | Creating Arrays in Your Programs | Dev.java (Oracle) | https://dev.java/learn/language/constructs/basics/arrays/ | Java 8 language level on phones (ecj), Java 21 on the lab PCs | 2026-10-25 | java-arrays |
| Java | Classes and Objects | Dev.java (Oracle) | https://dev.java/learn/language/oop/classes-objects/ | Java 8 language level on phones (ecj), Java 21 on the lab PCs | 2026-10-25 | java-objects |
| Java | Exceptions | Dev.java (Oracle) | https://dev.java/learn/language/annotations-exceptions/exceptions/ | Java 8 language level on phones (ecj), Java 21 on the lab PCs | 2026-10-25 | java-exceptions |
| C# | General structure of a C# program | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/ | C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs | 2026-10-25 | cs-structure |
| C# | Main() and command-line arguments | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/program-structure/main-command-line | C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs | 2026-10-25 | cs-structure |
| C# | The C# type system: classes | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/types/ | C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs | 2026-10-25 | cs-variables, cs-classes |
| C# | Console.ReadLine Method | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/api/system.console.readline | .NET API reference (net-10.0 view); exists in every .NET version | 2026-10-25 | cs-io |
| C# | Selection statements: if, if-else and switch | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/selection-statements | C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs | 2026-10-25 | cs-conditions |
| C# | Iteration statements: for, foreach, do and while | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/csharp/language-reference/statements/iteration-statements | C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs | 2026-10-25 | cs-loops |
| C# | Methods in C# | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/csharp/methods | C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs | 2026-10-25 | cs-methods |
| C# | Collections and Data Structures | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/standard/collections/ | .NET documentation | 2026-10-25 | cs-collections |
| C# | Exceptions and Exception Handling | Microsoft Learn | https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/exceptions/ | C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs | 2026-10-25 | cs-exceptions |
| PHP + MySQL | Basic syntax: PHP tags | The PHP Group (php.net) | https://www.php.net/manual/en/language.basic-syntax.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-syntax |
| PHP + MySQL | echo | The PHP Group (php.net) | https://www.php.net/manual/en/function.echo.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-syntax |
| PHP + MySQL | Variables: basics | The PHP Group (php.net) | https://www.php.net/manual/en/language.variables.basics.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-variables |
| PHP + MySQL | if | The PHP Group (php.net) | https://www.php.net/manual/en/control-structures.if.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-conditions |
| PHP + MySQL | for | The PHP Group (php.net) | https://www.php.net/manual/en/control-structures.for.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-loops |
| PHP + MySQL | foreach | The PHP Group (php.net) | https://www.php.net/manual/en/control-structures.foreach.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-loops, php-arrays |
| PHP + MySQL | User-defined functions | The PHP Group (php.net) | https://www.php.net/manual/en/functions.user-defined.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-functions |
| PHP + MySQL | Dealing with Forms | The PHP Group (php.net) | https://www.php.net/manual/en/tutorial.forms.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-forms |
| PHP + MySQL | htmlspecialchars | The PHP Group (php.net) | https://www.php.net/manual/en/function.htmlspecialchars.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-escaping |
| PHP + MySQL | mysqli: prepared statements | The PHP Group (php.net) | https://www.php.net/manual/en/mysqli.quickstart.prepared-statements.php | PHP 8 (XAMPP PHP on the lab PCs, Termux PHP on phones) | 2026-10-25 | php-mysql |
| PHP + MySQL | Creating a Table | Oracle (MySQL 8.4 Reference Manual) | https://dev.mysql.com/doc/refman/8.4/en/creating-tables.html | MySQL 8.4 | 2026-10-25 | php-mysql |
| PHP + MySQL | CREATE TABLE | MariaDB Documentation | https://mariadb.com/docs/server/server-usage/tables/create-table | MariaDB Server (bundled on phones) | 2026-10-25 | php-mysql |
| Raspberry Pi GPIO | Raspberry Pi hardware: GPIO and the 40-pin header | Raspberry Pi Ltd | https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#gpio | - | 2026-10-25 | pi-header |
| Raspberry Pi GPIO | RPi.GPIO basic usage | RPi.GPIO project wiki (SourceForge) | https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/ | - | 2026-10-25 | pi-header, pi-output, pi-cleanup |
| Raspberry Pi GPIO | RPi.GPIO inputs | RPi.GPIO project wiki (SourceForge) | https://sourceforge.net/p/raspberry-gpio-python/wiki/Inputs/ | - | 2026-10-25 | pi-input, pi-button-led |
| Raspberry Pi GPIO | Use GPIO from Python (GPIO Zero) | Raspberry Pi Ltd | https://www.raspberrypi.com/documentation/computers/os.html#use-gpio-from-python | - | 2026-10-25 | pi-gpiozero |
| Raspberry Pi GPIO | GPIO Zero documentation | GPIO Zero project (Read the Docs) | https://gpiozero.readthedocs.io/en/stable/ | 2.0.1 (NEXUS simulates LED and Button only) | 2026-10-25 | pi-gpiozero |
| Arduino | setup() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/structure/sketch/setup/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-structure |
| Arduino | loop() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/structure/sketch/loop/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-structure |
| Arduino | pinMode() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/functions/digital-io/pinMode/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-blink, ard-button |
| Arduino | digitalWrite() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/functions/digital-io/digitalwrite/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-blink |
| Arduino | delay() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/functions/time/delay/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-blink |
| Arduino | int | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/variables/data-types/int/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-variables |
| Arduino | Serial | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/functions/communication/serial/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-serial |
| Arduino | Serial.println() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/functions/communication/serial/println/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-serial |
| Arduino | digitalRead() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/functions/digital-io/digitalread/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-button |
| Arduino | if | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/structure/control-structure/if/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-conditions |
| Arduino | millis() | Arduino (docs.arduino.cc) | https://docs.arduino.cc/language-reference/en/functions/time/millis/ | Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli | 2026-10-25 | ard-millis |
| Web: HTML, CSS, JavaScript | Basic HTML syntax | MDN Web Docs (Mozilla) | https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Structuring_content/Basic_HTML_syntax | Living standard (HTML, CSS, DOM); NEXUS previews in the system web view | 2026-10-25 | web-html |
| Web: HTML, CSS, JavaScript | What is CSS? | MDN Web Docs (Mozilla) | https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Styling_basics/What_is_CSS | Living standard (HTML, CSS, DOM); NEXUS previews in the system web view | 2026-10-25 | web-css |
| Web: HTML, CSS, JavaScript | Flexbox | MDN Web Docs (Mozilla) | https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/CSS_layout/Flexbox | Living standard (HTML, CSS, DOM); NEXUS previews in the system web view | 2026-10-25 | web-flexbox, web-designer |
| Web: HTML, CSS, JavaScript | Responsive design | MDN Web Docs (Mozilla) | https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/CSS_layout/Responsive_Design | Living standard (HTML, CSS, DOM); NEXUS previews in the system web view | 2026-10-25 | web-responsive |
| Web: HTML, CSS, JavaScript | DOM scripting introduction | MDN Web Docs (Mozilla) | https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Scripting/DOM_scripting | Living standard (HTML, CSS, DOM); NEXUS previews in the system web view | 2026-10-25 | web-dom |
| Web: HTML, CSS, JavaScript | Introduction to events | MDN Web Docs (Mozilla) | https://developer.mozilla.org/en-US/docs/Learn_web_development/Core/Scripting/Events | Living standard (HTML, CSS, DOM); NEXUS previews in the system web view | 2026-10-25 | web-events |
| Web: HTML, CSS, JavaScript | Your first form | MDN Web Docs (Mozilla) | https://developer.mozilla.org/en-US/docs/Learn_web_development/Extensions/Forms/Your_first_form | Living standard (HTML, CSS, DOM); NEXUS previews in the system web view | 2026-10-25 | web-forms |

## 5. Reset to Starter Code

- **Where:** the ↺ button in the editor toolbar (in the ⋮ menu on phones). It is hidden in the Web designer, which owns `index.html` while Design mode is on.
- **One template source:** `lib/core/starters.dart` (`startersFor` / `starterCode` / `starterFor`). Add File, Reset and the Learn starters all use it; it picks the template by extension and the file's role. See `NEXUS_TERMINAL_AND_NEW_FILES.md` §3 for the full table and how to add one.
  - **The workspace's main file** gets the language's own template (`Language.template`).
  - **Other known types** get a skeleton named after the file: `.html/.htm`, `.css`, `.js`, `.php`, `.py`, `.java` (class named like the file), `.cs`, `.c`, `.h` (include guard), `.ino`.
  - **Anything else** returns `null`, so Reset refuses and explains, and New File creates an empty file.
- **Confirmation dialog** (`_resetToStarter` in `lib/ui/screens/editor_screen.dart`):
  - Title: "Reset to starter code?"
  - Message: "Are you sure you want to clear the code in '{filename}'? This will replace its current contents with the default {language} starter template."
  - Buttons: Cancel (focused first) and a red "Reset to Starter Code".
  - Escape or tapping outside changes nothing.
  - The dialog also says it changes only this file, saves at once, and stops a running program.
- **Safety:**
  - The reset is bound to the file that was open when the dialog appeared.
  - The current code is written to `workspace/.nexus/recovery/<workspace>/<file>.<timestamp>.txt` first. If that write fails, nothing is replaced.
  - A running program or server is stopped.
  - The starter is saved, the syntax mode is restored and the cursor goes to the start.
  - A message offers **Undo** for 10 seconds, which restores the exact previous code.

## 6. Test results (2026-10-25, Windows lab PC)

| Command | Result |
|---|---|
| `flutter analyze` | No issues found |
| `flutter test` | 64 passed, including `test/reset_test.dart` (3) and `test/learn_test.dart` (6) |
| `flutter test tool/verify_learn_test.dart` | 80 passed: C 12, Python 12, Java 12, C# 12, PHP 10, Raspberry Pi 9, Arduino 10, Web 3 |
| `flutter test tool/screenshots_test.dart --plain-name learn` | 2 passed (Learn screenshots rendered) |

What the verify tool proves:

- **Printable lessons:** every lesson example with printed output runs and prints its expected lines (`Lesson.checks`, or the output lines).
- **Arduino lessons:** every sketch compiles for an Uno.
- **Exercises:** every solution passes and every starter does *not* pass, so the tests really check something. `compileOnly` and `manual` exercises are confirmed never to report "Passed".

What is **not** covered:

- **Not run automatically:**
  - The PHP form and MySQL lessons and the guest-book exercise need a running server and database, so they were not run; `php -l` (PHP 8.5) found no syntax errors in them.
  - Arduino behaviour was not tested on a board.
  - Web pages were not rendered in a browser during the checks.
- **Phone runtimes:** Java on ecj, C# on Mono, and C on TCC were targeted by the syntax rules above but were not re-run on a phone in this pass.
- **Exercise screenshot:** it shows the page before Check. Flutter's fake test clock does not let a child process finish, so the real checks are covered by the verify tool instead.

## 7. How to add a lesson, exercise or track

1. **Add a lesson** to the track's `lessons` list in `lib/learn/tracks/<id>.dart`, filling every field.
   - Use `r'''...'''` for code.
   - Set `input` when the example reads input, and `checks` when the printed transcript differs from what must be verified.
   - Set `needs` for hardware or servers.
   - Add at least one `Ref` with the date you opened the page.
2. **Add an exercise** with a unique `id` (it names the practice folder and the progress keys).
   - Pick the honest `CheckKind`.
   - Give `cases` (output/gpio) or `checks` (staticHtml) **and** a `checklist` for anything a person has to look at.
   - The starter must fail the checks and the solution must pass them.
3. **Add a track:** create `lib/learn/tracks/<langId>.dart` and list it in `lib/learn/tracks.dart`. `test/learn_test.dart` requires one track per workspace, 10 questions and 3 exercises (Beginner, Intermediate, Challenge).
4. **Verify the track:**
   ```bash
   TRACK=<langId> flutter test tool/verify_learn_test.dart
   ```
5. **Run the full checks:**
   ```bash
   flutter analyze
   ```
   ```bash
   flutter test
   ```
