import '../model.dart';

const _ard = 'Arduino (docs.arduino.cc)';
const _v = 'Arduino language reference; NEXUS builds for AVR boards (Uno, Nano, Mega) with arduino-cli';
const _ref = 'https://docs.arduino.cc/language-reference/en';
const _uno = 'Arduino Uno (or Nano/Mega) and a USB cable';
const _led = 'Arduino Uno, USB cable, LED + 220 Ω resistor (or the built-in LED on pin 13)';
const _btn = 'Arduino Uno, USB cable, push button, jumper wires';

const arduinoTrack = Track(
  langId: 'arduino',
  title: 'Arduino',
  intro: 'An Arduino sketch is C++ with two required functions: setup() runs once, loop() runs over and over. NEXUS compiles sketches for AVR '
      'boards and uploads them over USB (OTG on phones). NEXUS does not simulate an Arduino: compiling proves the code is valid, but what the '
      'LEDs and the Serial Monitor show can only be seen on a real board.',
  runtime: 'Lab PC: bundled arduino-cli with the AVR core. Phone: bundled avr-gcc builds the sketch and NEXUS uploads it over USB OTG.',
  run: [
    'Open the Arduino tile (or press Try in Editor to open a practice copy).',
    'Plug in the board; NEXUS detects which board it is.',
    'Press Verify to compile, then Upload. Open the Serial Monitor at 9600 baud to see Serial.println output.',
  ],
  lessons: [
    Lesson(
      id: 'ard-structure',
      title: 'Sketch structure: setup and loop',
      summary: 'setup() runs once at power-on, loop() repeats forever.',
      objective: 'Write a sketch that prints once in setup and repeatedly in loop.',
      explanation: 'Every sketch has setup() and loop(). setup() runs once when the board powers up or resets: set pin modes and start Serial there. '
          'loop() then runs again and again for as long as the board has power. There is no main(): the Arduino core provides it.',
      syntax: r'''void setup() {
  // runs once
}

void loop() {
  // runs forever
}''',
      syntaxNotes: [
        ('void setup()', 'Runs once after power-on or reset.'),
        ('void loop()', 'Runs repeatedly afterwards.'),
        ('Serial.begin(9600)', 'Starts the USB serial link at 9600 baud.'),
      ],
      example: r'''void setup() {
  Serial.begin(9600);
  Serial.println("Board started");
}

void loop() {
  Serial.println("Still running...");
  delay(1000);
}
''',
      output: 'Serial Monitor (9600 baud):\nBoard started\nStill running...\nStill running...\n(one more line every second)',
      lines: ['"Board started" appears once; pressing the board\'s reset button shows it again.', 'delay(1000) waits one second between lines.'],
      mistake: 'Leaving out loop() (or setup()): the sketch does not compile, even if one of them is empty.',
      mistakeCode: r'''void setup() {
  Serial.begin(9600);
}''',
      fixCode: r'''void setup() {
  Serial.begin(9600);
}

void loop() {
}''',
      practice: 'Print your name once in setup and a counter that goes up by one in loop.',
      refs: [
        Ref('setup()', _ard, '$_ref/structure/sketch/setup/', version: _v),
        Ref('loop()', _ard, '$_ref/structure/sketch/loop/', version: _v),
      ],
      keywords: ['setup', 'loop', 'sketch', 'Serial.begin', 'delay'],
      needs: _uno,
    ),
    Lesson(
      id: 'ard-blink',
      title: 'Digital output: Blink',
      summary: 'pinMode, digitalWrite and delay.',
      objective: 'Blink the built-in LED once a second.',
      explanation: 'pinMode(pin, OUTPUT) makes a pin an output. digitalWrite(pin, HIGH) puts 5 V on it (on a Uno) and lights an LED; LOW turns it off. '
          'LED_BUILTIN is the on-board LED (pin 13 on a Uno), so this needs no wiring.',
      syntax: r'''pinMode(LED_BUILTIN, OUTPUT);
digitalWrite(LED_BUILTIN, HIGH);
delay(500);''',
      syntaxNotes: [
        ('OUTPUT', 'The pin drives an LED or other part.'),
        ('HIGH / LOW', '5 V / 0 V on a Uno (3.3 V boards use 3.3 V).'),
        ('delay(ms)', 'Pause in milliseconds; the board does nothing else meanwhile.'),
      ],
      example: r'''const int LED = LED_BUILTIN;  // pin 13 on a Uno

void setup() {
  pinMode(LED, OUTPUT);
}

void loop() {
  digitalWrite(LED, HIGH);
  delay(500);
  digitalWrite(LED, LOW);
  delay(500);
}
''',
      output: 'On the board: the built-in LED blinks, half a second on, half a second off.',
      lines: ['const int gives the pin a name you can change in one place.', 'loop() repeats, so the blink never stops.'],
      mistake: 'Forgetting pinMode: the pin stays an input and the LED only glows faintly.',
      mistakeCode: r'''void setup() { }''',
      fixCode: r'''void setup() {
  pinMode(LED, OUTPUT);
}''',
      practice: 'Wire an LED with a 220 Ω resistor to pin 8 and blink it in an SOS pattern.',
      refs: [
        Ref('pinMode()', _ard, '$_ref/functions/digital-io/pinMode/', version: _v),
        Ref('digitalWrite()', _ard, '$_ref/functions/digital-io/digitalwrite/', version: _v),
        Ref('delay()', _ard, '$_ref/functions/time/delay/', version: _v),
      ],
      keywords: ['pinMode', 'digitalWrite', 'OUTPUT', 'HIGH', 'LOW', 'LED_BUILTIN', 'blink', 'delay'],
      needs: _led,
    ),
    Lesson(
      id: 'ard-variables',
      title: 'Variables and types',
      summary: 'int, long, unsigned long, float, bool and char on an 8-bit board.',
      objective: 'Choose types that fit the values, and print them to Serial.',
      explanation: 'On a Uno, int is only 16 bits (-32768 to 32767). Use long or unsigned long for big numbers such as milliseconds, '
          'float for decimals and bool for true/false. A value that does not fit wraps around without any error.',
      syntax: r'''int count = 0;
unsigned long started = millis();
float volts = 3.3;
bool ready = true;''',
      syntaxNotes: [
        ('int', '16-bit on AVR boards: -32768 to 32767.'),
        ('unsigned long', '0 to about 4.29 billion: use it for millis().'),
        ('Serial.println(x, 2)', 'Prints a float with 2 decimals.'),
      ],
      example: r'''void setup() {
  Serial.begin(9600);
  int small = 32767;
  small = small + 1;              // too big for a 16-bit int: wraps
  long big = 32767L + 1;
  float volts = 5.0 * 512 / 1023;

  Serial.println(small);
  Serial.println(big);
  Serial.println(volts, 2);
}

void loop() {
}
''',
      output: 'Serial Monitor (9600 baud):\n-32768\n32768\n2.50',
      lines: ['32767 + 1 does not fit in an int on a Uno, so it becomes -32768.', 'The L in 32767L makes the math use long.'],
      mistake: 'Storing millis() in an int: after about 33 seconds it overflows and timing breaks.',
      mistakeCode: r'''int start = millis();''',
      fixCode: r'''unsigned long start = millis();''',
      practice: 'Count loop() passes in an unsigned long and print the count every second.',
      refs: [Ref('int', _ard, '$_ref/variables/data-types/int/', version: _v)],
      keywords: ['int', 'long', 'unsigned long', 'float', 'bool', 'overflow', 'types'],
      needs: _uno,
    ),
    Lesson(
      id: 'ard-serial',
      title: 'Serial: print and read',
      summary: 'Talk to the computer over USB with the Serial Monitor.',
      objective: 'Echo back numbers typed into the Serial Monitor.',
      explanation: 'Serial.begin(9600) starts the link; Serial.print and Serial.println send text. Serial.available() says how many bytes are waiting, '
          'and Serial.parseInt() reads a number. The Serial Monitor must use the same baud rate as Serial.begin.',
      syntax: r'''Serial.begin(9600);
Serial.println("text");
if (Serial.available() > 0) {
  int n = Serial.parseInt();
}''',
      syntaxNotes: [
        ('Serial.print / println', 'Send text without / with a new line.'),
        ('Serial.available()', 'Bytes received and not read yet.'),
        ('Serial.parseInt()', 'Reads digits as a number (waits up to 1 s).'),
      ],
      example: r'''void setup() {
  Serial.begin(9600);
  Serial.println("Type a number:");
}

void loop() {
  if (Serial.available() > 0) {
    int n = Serial.parseInt();
    while (Serial.available() > 0) Serial.read();  // drop the rest of the line
    Serial.print("Double: ");
    Serial.println(n * 2);
  }
}
''',
      input: '21 (typed in the Serial Monitor)',
      output: 'Serial Monitor (9600 baud):\nType a number:\nDouble: 42',
      lines: ['loop() keeps checking for input without waiting.', 'Reading the leftover bytes stops the newline from being read as a second 0.'],
      mistake: 'A Serial Monitor set to a different baud rate shows garbage characters.',
      mistakeCode: r'''Serial.begin(115200);   // Monitor set to 9600''',
      fixCode: r'''Serial.begin(9600);     // same as the Monitor''',
      practice: 'Read a number and turn the LED on for that many seconds.',
      refs: [
        Ref('Serial', _ard, '$_ref/functions/communication/serial/', version: _v),
        Ref('Serial.println()', _ard, '$_ref/functions/communication/serial/println/', version: _v),
      ],
      keywords: ['Serial', 'println', 'print', 'available', 'parseInt', 'baud', 'monitor'],
      needs: _uno,
    ),
    Lesson(
      id: 'ard-button',
      title: 'Digital input: a button',
      summary: 'INPUT_PULLUP and digitalRead.',
      objective: 'Turn the built-in LED on while a button is pressed.',
      explanation: 'pinMode(pin, INPUT_PULLUP) turns on the board\'s internal pull-up, so the pin reads HIGH until a button connects it to GND. '
          'Wire the button between the pin and GND: pressed reads LOW. digitalRead(pin) returns HIGH or LOW.',
      syntax: r'''pinMode(2, INPUT_PULLUP);
if (digitalRead(2) == LOW) { /* pressed */ }''',
      syntaxNotes: [
        ('INPUT_PULLUP', 'Input with the internal pull-up resistor: no extra resistor needed.'),
        ('digitalRead(pin)', 'HIGH or LOW.'),
      ],
      example: r'''const int BUTTON = 2;  // button between pin 2 and GND

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  bool pressed = digitalRead(BUTTON) == LOW;
  digitalWrite(LED_BUILTIN, pressed ? HIGH : LOW);
}
''',
      output: 'On the board: the built-in LED is lit while the button is held.',
      lines: ['With the pull-up, an unpressed button reads HIGH.', 'condition ? HIGH : LOW picks the LED level.'],
      mistake: 'Using INPUT with no resistor: the pin "floats" and the LED flickers randomly.',
      mistakeCode: r'''pinMode(BUTTON, INPUT);''',
      fixCode: r'''pinMode(BUTTON, INPUT_PULLUP);''',
      practice: 'Count presses and print the count to Serial (count once per press, not while held).',
      refs: [
        Ref('digitalRead()', _ard, '$_ref/functions/digital-io/digitalread/', version: _v),
        Ref('pinMode()', _ard, '$_ref/functions/digital-io/pinMode/', version: _v),
      ],
      keywords: ['digitalRead', 'INPUT_PULLUP', 'button', 'input', 'pull-up'],
      needs: _btn,
    ),
    Lesson(
      id: 'ard-conditions',
      title: 'if and for',
      summary: 'Decisions and counted loops inside setup and loop.',
      objective: 'Blink the LED a number of times chosen in code, and react to a value with if.',
      explanation: 'Arduino code uses the same if / else and for as C. A for loop inside setup() runs a fixed number of times, once; '
          'loop() is the never-ending loop.',
      syntax: r'''for (int i = 0; i < 3; i++) { ... }
if (value > 100) { ... } else { ... }''',
      syntaxNotes: [
        ('for (int i = 0; i < 3; i++)', 'Runs 3 times: i = 0, 1, 2.'),
        ('if / else', 'Runs one block or the other.'),
      ],
      example: r'''void blink(int times) {
  for (int i = 0; i < times; i++) {
    digitalWrite(LED_BUILTIN, HIGH);
    delay(200);
    digitalWrite(LED_BUILTIN, LOW);
    delay(200);
  }
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);
  int score = 82;
  if (score >= 75) {
    Serial.println("Passed: 3 blinks");
    blink(3);
  } else {
    Serial.println("Failed: 1 blink");
    blink(1);
  }
}

void loop() {
}
''',
      output: 'Serial Monitor (9600 baud):\nPassed: 3 blinks\nOn the board: the LED blinks 3 times, once.',
      lines: ['blink() is a function, so the loop is written once.', 'Everything is in setup(), so it happens once per reset.'],
      mistake: 'Writing if (x = 5) assigns 5 instead of comparing.',
      mistakeCode: r'''if (score = 100) {''',
      fixCode: r'''if (score == 100) {''',
      practice: 'Blink as many times as the last digit of your student number.',
      refs: [Ref('if', _ard, '$_ref/structure/control-structure/if/', version: _v)],
      keywords: ['if', 'else', 'for', 'function', 'loop'],
      needs: _led,
    ),
    Lesson(
      id: 'ard-millis',
      title: 'Timing without delay: millis()',
      summary: 'Do two things at once by checking the clock.',
      objective: 'Blink the LED with millis() while still reading a button.',
      explanation: 'delay() freezes the board. millis() returns the milliseconds since start-up, so you can check "has 500 ms passed?" '
          'each time through loop() and do other work in between. Store times in unsigned long.',
      syntax: r'''unsigned long last = 0;
if (millis() - last >= 500) {
  last = millis();
  // time to act
}''',
      syntaxNotes: [
        ('millis()', 'Milliseconds since the board started (unsigned long).'),
        ('millis() - last >= interval', 'Works correctly even when millis() wraps after ~49 days.'),
      ],
      example: r'''const int BUTTON = 2;
unsigned long lastBlink = 0;
bool ledOn = false;

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  pinMode(BUTTON, INPUT_PULLUP);
  Serial.begin(9600);
}

void loop() {
  if (millis() - lastBlink >= 500) {
    lastBlink = millis();
    ledOn = !ledOn;
    digitalWrite(LED_BUILTIN, ledOn);
  }
  if (digitalRead(BUTTON) == LOW) {
    Serial.println("Button!");
    delay(200);  // crude debounce
  }
}
''',
      output: 'On the board: the LED keeps blinking while button presses print "Button!" to the Serial Monitor.',
      lines: ['Nothing waits for the blink, so the button is read many times a second.', 'ledOn = !ledOn flips true and false.'],
      mistake: 'Comparing millis() > last + 500 breaks when millis() wraps around.',
      mistakeCode: r'''if (millis() > last + 500) {''',
      fixCode: r'''if (millis() - last >= 500) {''',
      practice: 'Blink two LEDs at different speeds (300 ms and 700 ms) with millis().',
      refs: [Ref('millis()', _ard, '$_ref/functions/time/millis/', version: _v)],
      keywords: ['millis', 'timing', 'delay', 'non-blocking', 'unsigned long'],
      needs: _btn,
    ),
  ],
  quiz: [
    Question('Which function runs only once?', ['loop()', 'setup()', 'main()', 'start()'], 1, 'setup() runs once after reset; loop() repeats.'),
    Question('What does pinMode(13, OUTPUT) do?', ['Turns the LED on', 'Makes pin 13 an output', 'Reads pin 13', 'Nothing'], 1,
        'It sets the pin direction; digitalWrite changes the level.'),
    Question('What is the range of int on an Arduino Uno?', ['-2 billion to 2 billion', '-32768 to 32767', '0 to 255', '0 to 65535'], 1,
        'AVR ints are 16-bit.'),
    Question('Which type should hold millis()?', ['int', 'float', 'unsigned long', 'char'], 2, 'It grows past what int can hold in about 33 seconds.'),
    Question('With INPUT_PULLUP and a button to GND, pressed reads...', ['HIGH', 'LOW', 'Random', '1023'], 1, 'The button pulls the pin to ground.'),
    Question('Garbage characters in the Serial Monitor usually mean...', ['A broken board', 'A different baud rate', 'No USB cable', 'An int overflow'], 1,
        'Serial.begin and the Monitor must match.'),
    Question('Why avoid long delay() calls?', ['They use memory', 'The board can do nothing else meanwhile', 'They break Serial', 'They are slow to compile'], 1,
        'Use millis() to stay responsive.'),
    Question('What does a successful Verify in NEXUS prove?', ['The LEDs work', 'The sketch compiles', 'The wiring is right', 'Everything'], 1,
        'Behaviour can only be seen on a real board.'),
    Question('Which compares correctly?', ['if (x = 5)', 'if (x == 5)', 'if (x := 5)', 'if x == 5'], 1, '= assigns, == compares.'),
    Question('LED_BUILTIN on a Uno is pin...', ['2', '13', '0', 'A0'], 1, 'The on-board LED is on pin 13.'),
  ],
  exercises: [
    Exercise(
      id: 'ard-ex-sos',
      level: 'Beginner',
      title: 'SOS blink',
      task: 'Blink the built-in LED in Morse SOS: three short (200 ms), three long (600 ms), three short, with 200 ms gaps, then wait 2 s and repeat.',
      kind: CheckKind.compileOnly,
      starter: r'''void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  // S O S
}
''',
      requirements: ['A helper function for one flash with a length parameter.', 'The pattern repeats forever.'],
      checklist: [
        'The sketch compiles (Check).',
        'Uploaded to the board, the LED shows three short, three long, three short flashes.',
        'There is a clear 2-second pause before the pattern repeats.',
      ],
      criteria: 'NEXUS checks that it compiles for an Arduino Uno. The blinking is checked by you on a real board with the checklist.',
      hint: 'void flash(int ms) { digitalWrite(LED_BUILTIN, HIGH); delay(ms); digitalWrite(LED_BUILTIN, LOW); delay(200); }',
      solution: r'''void flash(int ms) {
  digitalWrite(LED_BUILTIN, HIGH);
  delay(ms);
  digitalWrite(LED_BUILTIN, LOW);
  delay(200);
}

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
}

void loop() {
  for (int i = 0; i < 3; i++) flash(200);
  for (int i = 0; i < 3; i++) flash(600);
  for (int i = 0; i < 3; i++) flash(200);
  delay(2000);
}
''',
    ),
    Exercise(
      id: 'ard-ex-counter',
      level: 'Intermediate',
      title: 'Press counter',
      task: 'Count presses of a button on pin 2 (INPUT_PULLUP). Each press (not each loop while held) adds one and prints "Presses: n" to Serial at 9600 baud.',
      kind: CheckKind.compileOnly,
      starter: r'''const int BUTTON = 2;

void setup() {
  // pin mode and Serial
}

void loop() {
  // count each press once
}
''',
      requirements: ['INPUT_PULLUP on pin 2.', 'Detect the change from not pressed to pressed.', 'A short debounce delay.'],
      checklist: [
        'The sketch compiles (Check).',
        'One press prints exactly one new "Presses:" line in the Serial Monitor (9600 baud).',
        'Holding the button down does not keep counting.',
        'Ten quick presses give a count of 10.',
      ],
      criteria: 'NEXUS checks that it compiles. Counting is checked by you with a button and the Serial Monitor.',
      hint: 'Keep bool wasPressed; count when pressed && !wasPressed, then delay(30).',
      solution: r'''const int BUTTON = 2;
int presses = 0;
bool wasPressed = false;

void setup() {
  pinMode(BUTTON, INPUT_PULLUP);
  Serial.begin(9600);
}

void loop() {
  bool pressed = digitalRead(BUTTON) == LOW;
  if (pressed && !wasPressed) {
    presses++;
    Serial.print("Presses: ");
    Serial.println(presses);
    delay(30);  // debounce
  }
  wasPressed = pressed;
}
''',
    ),
    Exercise(
      id: 'ard-ex-timer',
      level: 'Challenge',
      title: 'Serial-controlled blink rate',
      task: 'Blink the built-in LED with millis() (no delay in loop). Typing a number from 50 to 2000 in the Serial Monitor changes the blink interval '
          'and prints "Interval: n ms"; other numbers print "Out of range".',
      kind: CheckKind.compileOnly,
      starter: r'''unsigned long interval = 500;
unsigned long last = 0;

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  // read Serial, blink with millis()
}
''',
      requirements: ['No delay() inside loop().', 'Times stored in unsigned long.', 'Range check 50 to 2000.'],
      checklist: [
        'The sketch compiles (Check).',
        'The LED blinks at the start (every 500 ms).',
        'Typing 100 makes it blink fast and prints "Interval: 100 ms".',
        'Typing 5000 prints "Out of range" and the rate does not change.',
      ],
      criteria: 'NEXUS checks that it compiles. The rest is checked by you on the board with the Serial Monitor.',
      hint: 'In loop: if (Serial.available() > 0) { long n = Serial.parseInt(); ... } then the millis() blink from the lesson.',
      solution: r'''unsigned long interval = 500;
unsigned long last = 0;
bool ledOn = false;

void setup() {
  pinMode(LED_BUILTIN, OUTPUT);
  Serial.begin(9600);
}

void loop() {
  if (Serial.available() > 0) {
    long n = Serial.parseInt();
    while (Serial.available() > 0) Serial.read();
    if (n >= 50 && n <= 2000) {
      interval = n;
      Serial.print("Interval: ");
      Serial.print(n);
      Serial.println(" ms");
    } else {
      Serial.println("Out of range");
    }
  }
  if (millis() - last >= interval) {
    last = millis();
    ledOn = !ledOn;
    digitalWrite(LED_BUILTIN, ledOn);
  }
}
''',
    ),
  ],
);
