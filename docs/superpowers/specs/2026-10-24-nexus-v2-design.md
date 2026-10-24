# NEXUS IDE v2 — friendly redesign, VS Code-style editor, Arduino on Windows

Approved in chat by Logan M. Panucat, 2026-10-24. Mockup chosen: **A · Dark "VS Code" style**.

## Why
Students of **all year levels** at CTU Naga should *want* to open NEXUS IDE. Today it works but feels raw:
Enter drops the cursor to column 0, there is no formatter, the console shows a wall of compiler flags,
there is no home screen, branding, or credit, and Arduino (promised in the README) does not exist.

## Goals (this round)
1. **Editor like VS Code**: Enter keeps the line's indent, adds one level after `{` / `:`; `}` dedents.
   Must also work with phone keyboards (IME sends text, not key presses).
2. **Format** button (+ Shift+Alt+F on PC), Prettier-like for brace languages (C, Arduino, Java, C#):
   re-indent by brace depth, trim trailing spaces, collapse 3+ blank lines. Python: trim only (indent is syntax).
3. **Coding key bar on phones** above the keyboard: `{ } ( ) ; " < > = Tab ⇥Format`.
4. **Clean console**: no command echo; show `● Compiling…` / `✓ Compiled` / `▶ Running`.
   The full command is printed only when a step fails (debugging stays possible).
5. **Home screen**: campus photo + CTU seal header, "NEXUS IDE · CTU Naga Extension Campus · works offline",
   language tiles **C, Arduino, Python, Java, C#** (no year labels), footer
   **"Developed by Logan M. Panucat · Developer"**. Tile → editor for that language; back returns home.
6. **App icon** = CTU seal (Android + Windows); app name "NEXUS IDE".
7. **Run button**: "▶ Run" on phones, "▶ Run (F5)" on PC.
8. **First-launch setup screen** on phones ("Setting up compilers…") instead of a frozen splash.
9. **Java / C# on phones**: tile shows "PC only"; opening shows a friendly note, not an error.
10. **Smaller phone APK**: arm64-only release build.
11. **Arduino on Windows**, Arduino-IDE-like: board picker (Uno/Nano/Mega), port picker (refresh),
    **Verify**, **Upload**, **Serial Monitor** (baud 9600 default) — via bundled portable `arduino-cli`
    + `arduino:avr` core in `toolchains/arduino/`. Upload/Verify stop the monitor first (one port owner).
    Default sketch = Blink.

## Non-goals (this round)
- Arduino on phones (upload over OTG, on-phone AVR compiler) — next round.
- Raspberry Pi / Linux build, Web/PHP/ASP.NET, file manager, recent files, settings.
- A real C parser/formatter (clang-format is ~100 MB); the brace re-indenter has a known ceiling.

## Anti-goals
- Hiding errors: compiler errors must always show in full.
- Making the app heavier for C students to get Arduino (Arduino toolchain lives only in the PC bundle).

## Decisions (builder's calls, marked)
- *Call:* Serial Monitor = `arduino-cli monitor` run through the existing `runTool` (stdin/stdout),
  so no serial plugin is needed on Windows (flutter_libserialport breaks the Android build).
- *Call:* Port list = `arduino-cli board list --format json`.
- *Call:* Smart Enter implemented as our own `CodeController` subclass that diffs old/new text,
  because the package's modifier only fires for single-character key inserts.
- *Call:* No "Show details" toggle; the failing command is shown on failure instead.
- *Call:* `flutter_launcher_icons` (dev dependency) generates icons from the seal.

## Testing without hardware
- Verify (compile) Blink for Uno/Nano/Mega on Windows — real arduino-cli, real .hex output.
- Upload with no board: must show a clear "No board found" message, not a crash.
- Serial Monitor start/stop through the runner (unit-tested runner already covers kill).
- Formatter + smart Enter: unit tests. Phone: adb-driven run of C/Python + screenshot review.
