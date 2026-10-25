# NEXUS IDE: Terminal lifecycle and starter templates

This covers the Android full-screen terminal, how a run's output is separated and cleared, and the starter templates used by Add File and Reset to Starter Code.

## 1. Terminal lifecycle

### One run = one session

`RunSession.run()` in `lib/core/run_session.dart`:

1. **Ignores double starts.** A second Run while one is still starting is dropped. The editor also blocks a second tap while it is saving (`_start`).
2. **Stops the previous run first.** The old process is killed and its serial port and `main.exe` are released.
3. **Starts a new session.** The session number goes up, the output and Build Details are cleared, input is reset and the state becomes **Preparing**. Anything an older run still delivers is dropped, because every write checks the session number.
4. **Saves and builds.** Every step except the last is the build (2-minute limit each).
   - Its output goes to **Build Details** only.
   - If it fails, the compiler's messages are copied to the terminal, the state becomes **Failed** ("Build failed (exit code N), so nothing was run.") and nothing runs. An older successful build is never started.
5. **Runs the program.** The last step (or a Dart step, such as a phone upload or the Serial Monitor) is the program. The state is **Running**, and its stdout and stderr are the terminal output.
6. **Ends with one of three states:**
   - **Finished:** "Exit code 0 · 1.2 s".
   - **Failed:** "Exited with code N.", "Cannot start …", or a time limit.
   - **Stopped:** Stop was pressed, or the output limit was hit.

   The output stays visible after the run ends; only the next run clears it.

### Three channels, separated where they are produced

| Channel | Where it is shown | What goes in |
|---|---|---|
| `session.console` | the terminal output | everything the program prints (stdout and stderr), what you typed (echoed), and compiler messages only when a build fails |
| `session.build` | **Build Details** (button or ⋮ menu) | each command (paths shortened to `<tools>`), compiler output, exit codes, times |
| `session.state` / `detail` | the status chip and the line under the toolbar | Preparing → Running → Finished / Failed / Stopped, with the exit code or reason |

Nothing is sorted by matching words. A program that prints "Compiling…" or "Compiled successfully." shows that text like any other output (`test/core_test.dart`, `test/terminal_flow_test.dart`).

Time and output limits are reported through `RunHandle.endedBy`, not as text injected into the output.

### Android: a full-screen terminal

`EditorScreen.terminalScreen` is `Platform.isAndroid` (tests switch it on). On Android:

- **Run opens the terminal.** Run, Verify, Upload and the Serial Monitor push `TerminalScreen` (`lib/ui/screens/terminal_screen.dart`) over the editor. PHP (server and preview) and Web (preview and designer) keep their own screens. The Raspberry Pi board panel is shown at the top of the terminal.
- **The editor is untouched underneath.** It stays as the route below, so its text, cursor, scroll, open tabs and unsaved changes are exactly as left.
- **Going back:**
  - **Back to Editor**, or Android Back, returns to the editor. If the keyboard is open, Back closes it first.
  - Going back never stops the program. The editor's **Terminal** button (with a dot while running) reopens the same session.
- **Toolbar:**
  - Back to Editor, the file name and the status chip.
  - **Stop** while running, or **Run Again** when the run has ended. Run Again repeats the last action.
  - A ⋮ menu with Clear output, Copy output and Build details.
- **Input:** an input line stays above the keyboard and sends each line to the running process, as many times as the program asks.
- **Scrolling:** the output follows new lines while you are at the bottom. Scroll up and it stays put, with a button to jump back to the latest output.
- **Errors:** error locations (`main.c:3:5`, `Main.java:4`, `Program.cs(5,3)`, Python `File "...", line 2`, PHP `on line 7`) are underlined. Tapping one returns to the editor with the cursor on that line.
- **Clear output** empties the screen only. It doesn't touch the code, restart anything, or affect the running program or its input.

On PCs, and on narrow windows that aren't Android, the terminal stays docked beside or under the editor. It uses the same status chip, Build Details, follow-scrolling output and input line.

### What can't be detected: "Waiting for input"

Programs run on pipes. Nothing tells NEXUS reliably that a program is blocked reading stdin: the prompt may have no newline, and Java or Python may buffer. So NEXUS doesn't show **Waiting for input**. While a program runs, the input line is enabled, with the hint "Type input below when your program asks for it".

## 2. Projects with more than one source file

`Toolchains.stepsFor` expands `{*.c}`, `{*.java}` and `{*.cs}` into every file of that type in the project, with the main file first. Generated and hidden folders (`build`, `classes`, `bin`, `obj`, `.nexus`, …) are skipped.

| Workspace | PC | Phone |
|---|---|---|
| C | `gcc … {*.c}` | `tcc … {*.c}` |
| Java | `java -m jdk.compiler/com.sun.tools.javac.Main -d classes {*.java}`, then `java -cp classes Main` | `ecj … {*.java}`, then dx, then dalvikvm |
| C# | `dotnet run` (the SDK already includes every .cs) | `mcs {*.cs}` |
| Python / Pi | `import helpers` works (same folder) | same |
| Arduino | arduino-cli joins every `.ino` tab | **only the main sketch** is built on phones (`sketchCpp`). Extra tabs need a PC. |

## 3. Starter templates

### One system

All templates live in `lib/core/starters.dart`. Add File, Reset to Starter Code and the docs all use `startersFor`, `starterCode` and `starterFor`.

A template is chosen from the **extension and the file's role**:

| File | Template (`id`) |
|---|---|
| the workspace's main file (`main.c`, `Main.java`, `Program.cs`, `main.py`, `arduino.ino`, `index.html`, `index.php`) | the language's runnable template (`main`) |
| other `.c` | `c-source`: includes its own `.h` if one exists, no `main()` |
| `.h` | `c-header`: guard from the name (`my-utils.h` → `MY_UTILS_H`), declarations section |
| other `.ino` | `ino-tab`: helper functions; `setup()` and `loop()` stay in the main sketch |
| `.py` (Python) | `py-script`: `def main()` and `if __name__ == "__main__":` |
| `.py` (Raspberry Pi) | `raspi-module` (RPi.GPIO helpers from the simulator) or `py-script` |
| `.java` | `java-class`: `public class <FileName>`, no `main` |
| `.cs` | `cs-class`: `class <Name>`; Program.cs keeps the only `Main` |
| `.html` / `.htm` | `html-page`: links only the `.css` and `.js` files that already exist, relative to the page |
| `.css`, `.js` | `css`, `js` (DOMContentLoaded) |
| `.php` | `php-page`, or `php-db` (a mysqli connection) for names with db, database, config or connect; both are offered |
| anything else | none: the file is created empty |

### The Add File dialog

`lib/ui/widgets/new_file_dialog.dart` has these parts:

- **Fields:** File name, Destination folder, Creates (the full resulting path), Detected type, Starter template (a dropdown when there is more than one), **Include starter code** (on by default) and a collapsible Preview.
- **Missing extension:** the workspace's own extension is added and shown before creating. A name that already has an extension is never given a second one.
- **Validation:**
  - safe characters only, kept inside the project;
  - no Windows-reserved names (`con`, `nul`, `com1`…);
  - no trailing dot or space;
  - Java names must be valid class names;
  - duplicates are refused (exclusive create, never an overwrite).

  If writing fails, nothing is left in the explorer.
- **After creating:** the file is opened in a tab with the right highlighting, the cursor is where the template marks it, and the chosen template id is recorded.

Boilerplate is added **only** here. Opening, switching, refreshing or importing files never changes them, including files that are intentionally empty.

### Reset to Starter Code

Reset uses the template recorded for the file (`workspace/.nexus/starters.json`). Records follow renames and folder renames, and are removed on delete. The template is rebuilt from the current name, so a renamed `Student.java` → `Person.java` resets to `public class Person`.

The guarded flow from `NEXUS_DOCUMENTATION_AND_RESET.md` is unchanged:

- a confirmation dialog that names the file, with Cancel focused;
- a recovery copy written first;
- Undo for 10 seconds;
- other files never change.

### Adding or changing a template

1. Write a `String _name(StarterContext c)` function in `lib/core/starters.dart`.
   - Use `c.name`, `c.base`, `c.ident` (a safe identifier) and `c.siblings('css')` (existing files, relative to the new file).
   - Put `$_cursor` where the cursor should go.
2. Add a `Starter('id', 'Label shown in the dialog', _name)` to the right `ext` case in `startersFor`, with the usual one first. Keep ids stable, because Reset looks them up from the records.
3. For a new extension, also add it to `fileType()` and, if the explorer should show an icon, to `_iconFor` in `explorer.dart`.
4. Add an expectation to `test/starters_test.dart` and run `flutter test`.

## 4. Verification (2026-10-25, Windows lab PC)

**Real device or emulator: not done.** The realme phone was not connected (`adb devices` listed none) and no emulator is installed. All "Android" checks below use the Flutter test engine, with the terminal-screen switch on and phone-sized layouts. The programs are real processes on this PC (Python 3.14 and GCC), not on Android.

| Check | Result |
|---|---|
| `flutter analyze` | no issues |
| `test/core_test.dart` | the channels; "Compiling…" printed by a program stays visible; a failed build shows its diagnostics and runs nothing; stale output from a stopped run never reaches the next; double Run is ignored; Stop gives Stopped; `{*.c}` expansion |
| `test/terminal_flow_test.dart` (5) | phone flow: Add File, edit, Run, answer two prompts, rotate, Back to Editor (text intact), reopen, Run Again (cleared), Back while waiting (still running), Stop; GCC compile error with a tappable `main.c:3` that puts the cursor on line 3 and no old build run; Python runtime error with a tappable `main.py:2` and "Exited with code 1."; 1,500 lines of output following the end, scroll-up and jump back; desktop keeps the docked terminal |
| `test/starters_test.dart` (13) | every template rule above; the dialog at desktop and phone sizes; Student → `Student.java` with `class Student` and the cursor in the body; invalid, duplicate, reserved and `..` names refused with nothing created; Include starter off → an empty file; unknown type → empty; nested destination; existing (and empty) files untouched when opened |
| `tool/verify_learn_test.dart` (Java, C) | the Learn examples and exercises still pass on the new multi-file build steps |

Screenshots, drawn by the test engine: `docs/screenshots/phone_terminal.png` and `new_file_dialog.png`.
