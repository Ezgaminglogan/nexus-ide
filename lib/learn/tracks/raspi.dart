import '../model.dart';

const _rpi = 'Raspberry Pi Ltd';
const _sf = 'RPi.GPIO project wiki (SourceForge)';
const _sim = 'Simulated in NEXUS: RPi.GPIO subset (setmode, setup, output, input, cleanup) and GPIO Zero LED/Button. No PWM, events or I2C/SPI.';
const _hw = 'Real hardware (optional): Raspberry Pi with a 40-pin header, LED + 330 Ω resistor, push button, jumper wires';

const raspiTrack = Track(
  langId: 'raspi',
  title: 'Raspberry Pi GPIO',
  intro: 'A Raspberry Pi controls LEDs, buttons and sensors through its 40-pin GPIO header, using Python. NEXUS does not have real pins: '
      'it runs your Python with a stand-in RPi.GPIO (and a small part of GPIO Zero) and draws the pins on a board instead. '
      'Everything you see here is a simulated result. The same code runs on a real Pi, but only a real Pi with wired parts proves the wiring.',
  runtime: 'Python 3 (bundled on phones, from the lab PC) with the NEXUS GPIO stand-in. $_sim',
  run: [
    'Open the Raspberry Pi tile (or press Try in Editor to open a practice copy).',
    'Press Run. The board panel shows each pin you set up: lit for HIGH outputs.',
    'Tap and hold a button pin in the panel to press it. Press Stop to end a program that loops forever.',
  ],
  lessons: [
    Lesson(
      id: 'pi-header',
      title: 'The GPIO header and pin numbers',
      summary: 'BCM (GPIO) numbers versus physical BOARD numbers.',
      objective: 'Choose a numbering mode and set up a pin as an output.',
      explanation: 'The 40 pins include power (3.3 V, 5 V), ground and GPIO pins. RPi.GPIO can number them two ways: GPIO.BCM uses the GPIO '
          'numbers (GPIO 18), GPIO.BOARD uses the physical position on the header (pin 12 is GPIO 18). Pick one with setmode before anything else. '
          'GPIO pins work at 3.3 V: never connect 5 V to a GPIO pin on a real Pi.',
      syntax: r'''import RPi.GPIO as GPIO
GPIO.setmode(GPIO.BCM)       # or GPIO.BOARD
GPIO.setup(18, GPIO.OUT)''',
      syntaxNotes: [
        ('GPIO.setmode(GPIO.BCM)', 'Use GPIO numbers (what most diagrams and GPIO Zero use).'),
        ('GPIO.setup(pin, GPIO.OUT)', 'Make the pin an output.'),
        ('GPIO.getmode()', 'The current mode (None before setmode).'),
      ],
      example: r'''import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BOARD)
GPIO.setup(12, GPIO.OUT)        # physical pin 12 ...
print("Pin 12 is set up")

GPIO.cleanup()
GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)        # ... is GPIO 18
print("GPIO 18 is set up")
print("Mode is BCM:", GPIO.getmode() == GPIO.BCM)
''',
      output: 'Pin 12 is set up\nGPIO 18 is set up\nMode is BCM: True',
      lines: [
        'Physical pin 12 and GPIO 18 are the same pin, named two ways.',
        'cleanup() releases the pins before switching modes.',
        'Simulated: the board panel shows GPIO 18 as an output.',
      ],
      mistake: 'Calling setup before setmode: RPi.GPIO raises "Please set pin numbering mode...".',
      mistakeCode: r'''GPIO.setup(18, GPIO.OUT)
GPIO.setmode(GPIO.BCM)''',
      fixCode: r'''GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)''',
      practice: 'Set up GPIO 17, 27 and 22 as outputs in BCM mode, then find their physical pin numbers on the board panel.',
      refs: [
        Ref('Raspberry Pi hardware: GPIO and the 40-pin header', _rpi, 'https://www.raspberrypi.com/documentation/computers/raspberry-pi.html#gpio'),
        Ref('RPi.GPIO basic usage', _sf, 'https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/'),
      ],
      keywords: ['gpio', 'bcm', 'board', 'setmode', 'header', 'pin', '3.3v'],
      needs: _hw,
    ),
    Lesson(
      id: 'pi-output',
      title: 'Outputs: blink an LED',
      summary: 'Turn a pin HIGH and LOW with pauses in between.',
      objective: 'Blink an LED on GPIO 18 three times.',
      explanation: 'GPIO.output(pin, GPIO.HIGH) puts 3.3 V on the pin and lights an LED wired to it; GPIO.LOW turns it off. time.sleep(seconds) '
          'pauses between changes. On a real Pi the LED needs a resistor (about 330 Ω) in series, or it can burn out.',
      syntax: r'''GPIO.output(18, GPIO.HIGH)
time.sleep(0.5)
GPIO.output(18, GPIO.LOW)''',
      syntaxNotes: [
        ('GPIO.HIGH / GPIO.LOW', 'On (3.3 V) / off (0 V). True/False and 1/0 also work.'),
        ('time.sleep(0.5)', 'Wait half a second.'),
      ],
      example: r'''import time
import RPi.GPIO as GPIO

LED = 18
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED, GPIO.OUT)

for i in range(3):
    GPIO.output(LED, GPIO.HIGH)
    print("Blink", i + 1, "on")
    time.sleep(0.3)
    GPIO.output(LED, GPIO.LOW)
    time.sleep(0.3)
print("Done")
''',
      output: 'Blink 1 on\nBlink 2 on\nBlink 3 on\nDone',
      lines: ['The loop turns the LED on, waits, off, waits, three times.', 'Simulated: watch GPIO 18 light up on the board panel.'],
      mistake: 'Writing to a pin that was not set up as an output raises "The GPIO channel has not been set up as an OUTPUT".',
      mistakeCode: r'''GPIO.setmode(GPIO.BCM)
GPIO.output(18, GPIO.HIGH)''',
      fixCode: r'''GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)
GPIO.output(18, GPIO.HIGH)''',
      practice: 'Blink faster each time: start at 0.5 s and halve the pause on every blink.',
      refs: [Ref('RPi.GPIO basic usage', _sf, 'https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/')],
      keywords: ['output', 'high', 'low', 'led', 'blink', 'sleep'],
      needs: _hw,
    ),
    Lesson(
      id: 'pi-input',
      title: 'Inputs: read a button',
      summary: 'Pull-up resistors and why a pressed button reads LOW.',
      objective: 'Read a button on GPIO 17 with the internal pull-up.',
      explanation: 'A button input needs a defined level when not pressed. With pull_up_down=GPIO.PUD_UP the pin rests HIGH; wire the button '
          'between the pin and ground, and pressing it pulls the pin LOW. So "pressed" is GPIO.input(pin) == GPIO.LOW.',
      syntax: r'''GPIO.setup(17, GPIO.IN, pull_up_down=GPIO.PUD_UP)
pressed = GPIO.input(17) == GPIO.LOW''',
      syntaxNotes: [
        ('GPIO.IN', 'Make the pin an input.'),
        ('GPIO.PUD_UP', 'Internal pull-up: reads HIGH until the button connects it to ground.'),
        ('GPIO.input(17)', 'The current level: GPIO.HIGH (1) or GPIO.LOW (0).'),
      ],
      example: r'''import time
import RPi.GPIO as GPIO

BUTTON = 17
GPIO.setmode(GPIO.BCM)
GPIO.setup(BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)

level = GPIO.input(BUTTON)
print("Level:", "HIGH" if level == GPIO.HIGH else "LOW")
print("Pressed" if level == GPIO.LOW else "Not pressed")
''',
      output: 'Level: HIGH\nNot pressed',
      lines: [
        'Nobody is holding the button, so the pull-up keeps it HIGH.',
        'Hold GPIO 17 in the board panel while pressing Run to see "Level: LOW" and "Pressed".',
      ],
      mistake: 'Forgetting the pull-up: on a real Pi a floating input reads random values.',
      mistakeCode: r'''GPIO.setup(17, GPIO.IN)''',
      fixCode: r'''GPIO.setup(17, GPIO.IN, pull_up_down=GPIO.PUD_UP)''',
      practice: 'Read two buttons (GPIO 17 and 27) and print which ones are pressed.',
      refs: [Ref('RPi.GPIO inputs', _sf, 'https://sourceforge.net/p/raspberry-gpio-python/wiki/Inputs/')],
      keywords: ['input', 'button', 'pull-up', 'pud_up', 'pud_down', 'read'],
      needs: _hw,
    ),
    Lesson(
      id: 'pi-button-led',
      title: 'Button controls an LED',
      summary: 'Poll an input in a loop and copy it to an output.',
      objective: 'Light the LED while the button is held, for five seconds.',
      explanation: 'Programs that react to buttons usually loop: read the input, update the output, sleep a little, repeat. A short sleep '
          '(0.05 s) keeps the Pi from running at 100% CPU. This example stops after 5 seconds; real projects often loop forever until Stop.',
      syntax: r'''while time.time() < end:
    GPIO.output(LED, GPIO.input(BUTTON) == GPIO.LOW)
    time.sleep(0.05)''',
      syntaxNotes: [
        ('time.time()', 'Seconds since a fixed point; used here to stop after 5 s.'),
        ('GPIO.output(LED, True/False)', 'True lights the LED.'),
      ],
      example: r'''import time
import RPi.GPIO as GPIO

LED, BUTTON = 18, 17
GPIO.setmode(GPIO.BCM)
GPIO.setup(LED, GPIO.OUT)
GPIO.setup(BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)

print("Hold the button on GPIO 17 for the next 5 seconds")
presses = 0
was_pressed = False
end = time.time() + 5
while time.time() < end:
    pressed = GPIO.input(BUTTON) == GPIO.LOW
    GPIO.output(LED, pressed)
    if pressed and not was_pressed:
        presses += 1
    was_pressed = pressed
    time.sleep(0.05)
print("Presses:", presses)
''',
      output: 'Hold the button on GPIO 17 for the next 5 seconds\nPresses: 0',
      lines: [
        'was_pressed remembers the last reading, so one long press counts once.',
        'With nobody pressing, the count is 0; hold GPIO 17 in the panel to light GPIO 18 and count presses.',
      ],
      mistake: 'A loop with no sleep keeps a real Pi\'s CPU at 100% and can make it hot.',
      mistakeCode: r'''while True:
    GPIO.output(LED, GPIO.input(BUTTON) == GPIO.LOW)''',
      fixCode: r'''while True:
    GPIO.output(LED, GPIO.input(BUTTON) == GPIO.LOW)
    time.sleep(0.05)''',
      practice: 'Make each press toggle the LED (press once: on, press again: off).',
      refs: [Ref('RPi.GPIO inputs', _sf, 'https://sourceforge.net/p/raspberry-gpio-python/wiki/Inputs/')],
      keywords: ['loop', 'poll', 'button', 'led', 'toggle', 'edge'],
      needs: _hw,
    ),
    Lesson(
      id: 'pi-cleanup',
      title: 'try / finally and cleanup',
      summary: 'Leave the pins safe when the program ends or is stopped.',
      objective: 'Wrap GPIO code in try/finally so cleanup always runs.',
      explanation: 'GPIO.cleanup() sets every pin you used back to a safe input. Put it in finally so it runs even when the program crashes or '
          'is stopped with Ctrl+C. In the NEXUS simulator, cleanup removes the pins from the board panel.',
      syntax: r'''try:
    ...
finally:
    GPIO.cleanup()''',
      syntaxNotes: [('finally:', 'Always runs, after the try block or after an error.')],
      example: r'''import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)
try:
    GPIO.output(18, GPIO.HIGH)
    print("LED on")
    GPIO.output(99, GPIO.HIGH)   # there is no GPIO 99
    print("never printed")
except ValueError as e:
    print("Error:", e)
finally:
    GPIO.cleanup()
    print("Pins cleaned up")
''',
      output: 'LED on\nError: The channel sent is invalid on a Raspberry Pi: 99\nPins cleaned up',
      lines: ['GPIO 99 does not exist, so output raises ValueError.', 'finally runs anyway and releases GPIO 18.'],
      mistake: 'Calling cleanup only at the end of the file: an error earlier leaves the pins set.',
      mistakeCode: r'''GPIO.output(18, GPIO.HIGH)
risky()
GPIO.cleanup()''',
      fixCode: r'''try:
    GPIO.output(18, GPIO.HIGH)
    risky()
finally:
    GPIO.cleanup()''',
      practice: 'Add try/finally to the blink lesson and press Stop during a blink.',
      refs: [Ref('RPi.GPIO basic usage', _sf, 'https://sourceforge.net/p/raspberry-gpio-python/wiki/BasicUsage/')],
      keywords: ['cleanup', 'try', 'finally', 'error', 'safe'],
    ),
    Lesson(
      id: 'pi-gpiozero',
      title: 'GPIO Zero: LED and Button',
      summary: 'The friendlier library the Raspberry Pi documentation recommends.',
      objective: 'Blink an LED and read a button with GPIO Zero objects.',
      explanation: 'GPIO Zero wraps pins in objects: LED(17).on(), Button(2).is_pressed. It uses GPIO (BCM) numbers and sets up pull-ups for buttons '
          'by itself. NEXUS simulates only LED (on, off, toggle, is_lit, blink) and Button (is_pressed, wait_for_press, wait_for_release). '
          'In NEXUS, blink(n=...) blinks n times and then returns; the real library blinks in the background.',
      syntax: r'''from gpiozero import LED, Button
led = LED(17)
button = Button(2)
led.on()
if button.is_pressed: ...''',
      syntaxNotes: [
        ('LED(17)', 'An LED on GPIO 17, already set up as an output.'),
        ('Button(2)', 'A button on GPIO 2 with the pull-up on.'),
        ('button.is_pressed', 'True while held.'),
      ],
      example: r'''from gpiozero import LED, Button

led = LED(17)
button = Button(2)

led.blink(on_time=0.2, off_time=0.2, n=2)
print("Blinked twice")
led.on()
print("LED lit:", led.is_lit)
print("Button pressed:", button.is_pressed)
led.off()
print("LED lit:", led.is_lit)
''',
      output: 'Blinked twice\nLED lit: True\nButton pressed: False\nLED lit: False',
      lines: ['No pin numbering mode is needed: GPIO Zero always uses GPIO numbers.', 'is_lit reads the LED\'s own pin back.'],
      mistake: 'Calling is_pressed like a method: it is a property, so no brackets.',
      mistakeCode: r'''if button.is_pressed():''',
      fixCode: r'''if button.is_pressed:''',
      practice: 'Use button.wait_for_press() and then light the LED (hold GPIO 2 in the board panel).',
      refs: [
        Ref('Use GPIO from Python (GPIO Zero)', _rpi, 'https://www.raspberrypi.com/documentation/computers/os.html#use-gpio-from-python'),
        Ref('GPIO Zero documentation', 'GPIO Zero project (Read the Docs)', 'https://gpiozero.readthedocs.io/en/stable/', version: '2.0.1 (NEXUS simulates LED and Button only)'),
      ],
      keywords: ['gpiozero', 'led', 'button', 'is_pressed', 'wait_for_press', 'blink'],
      needs: _hw,
    ),
  ],
  quiz: [
    Question('What does GPIO.setmode(GPIO.BCM) choose?', ['Physical pin positions', 'GPIO (Broadcom) numbers', 'The voltage', 'The speed'], 1,
        'BOARD would be the physical positions.'),
    Question('Physical pin 12 is which GPIO?', ['GPIO 12', 'GPIO 18', 'GPIO 17', 'GPIO 2'], 1, 'Shown on the board panel and in the Pi header diagram.'),
    Question('What voltage do Raspberry Pi GPIO pins use?', ['5 V', '3.3 V', '12 V', '1.8 V'], 1, 'Never connect 5 V to a GPIO pin.'),
    Question('With PUD_UP and a button wired to ground, a pressed button reads...', ['HIGH', 'LOW', 'Random', 'An error'], 1,
        'The button connects the pin to ground.'),
    Question('What must come before GPIO.setup?', ['GPIO.cleanup()', 'GPIO.setmode(...)', 'time.sleep()', 'Nothing'], 1,
        'Without a mode, setup raises an error.'),
    Question('Why put a resistor in series with an LED on a real Pi?', ['To make it brighter', 'To limit the current', 'It is not needed', 'To blink it'], 1,
        'Too much current can damage the LED or the pin.'),
    Question('Where should GPIO.cleanup() go?', ['At the start', 'In a finally block', 'Inside the loop', 'Nowhere'], 1, 'finally runs even after an error.'),
    Question('In GPIO Zero, how do you check a Button?', ['button.read()', 'button.is_pressed', 'GPIO.input(button)', 'button.pressed()'], 1,
        'is_pressed is a property.'),
    Question('What does NEXUS show when you run GPIO code?', ['A real Pi\'s pins', 'A simulated board panel', 'Nothing', 'A video'], 1,
        'Results are simulated; only real hardware proves wiring.'),
    Question('Why sleep a little inside a button loop?', ['To debounce only', 'So the CPU is not busy 100% of the time', 'Python needs it', 'To save memory'], 1,
        'A short sleep keeps the loop light.'),
  ],
  exercises: [
    Exercise(
      id: 'pi-ex-traffic',
      level: 'Beginner',
      title: 'Traffic light',
      task: 'Wire a traffic light (BCM numbers): red on GPIO 17, yellow on GPIO 27, green on GPIO 22. Show red, then yellow, then green, '
          'printing each colour name, about 0.3 s apart. End with only green lit. Do not call GPIO.cleanup() at the end in this exercise: '
          'the check reads the final pins, and cleanup would clear them.',
      kind: CheckKind.gpio,
      starter: r'''import time
import RPi.GPIO as GPIO

RED, YELLOW, GREEN = 17, 27, 22
GPIO.setmode(GPIO.BCM)
# set up the three pins and show red, yellow, green
''',
      requirements: ['All three pins are outputs.', 'Prints Red, Yellow, Green in order.', 'Ends with GPIO 22 HIGH and 17, 27 LOW.'],
      cases: [TestCase(expect: ['Red', 'Yellow', 'Green'], pins: {17: false, 27: false, 22: true}, note: 'sequence and final lights')],
      criteria: 'The simulator test passes (printed order and final pin states). This checks the simulator, not real wiring.',
      hint: 'Write a helper show(pin) that sets all three LOW, then the chosen one HIGH.',
      solution: r'''import time
import RPi.GPIO as GPIO

RED, YELLOW, GREEN = 17, 27, 22
GPIO.setmode(GPIO.BCM)
GPIO.setup([RED, YELLOW, GREEN], GPIO.OUT)

def show(pin, name):
    GPIO.output([RED, YELLOW, GREEN], GPIO.LOW)
    GPIO.output(pin, GPIO.HIGH)
    print(name)
    time.sleep(0.3)

show(RED, "Red")
show(YELLOW, "Yellow")
show(GREEN, "Green")
''',
    ),
    Exercise(
      id: 'pi-ex-button',
      level: 'Intermediate',
      title: 'Button check',
      task: 'Read a button on GPIO 2 (pull-up) once. If it is pressed, print "Pressed" and turn the LED on GPIO 17 on; otherwise print '
          '"Not pressed" and leave it off. Do not call GPIO.cleanup() at the end.',
      kind: CheckKind.gpio,
      starter: r'''import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
# button on GPIO 2 (pull-up), LED on GPIO 17
''',
      requirements: ['GPIO 2 is an input with PUD_UP.', 'GPIO 17 is an output.', 'Pressed means the input reads LOW.'],
      cases: [
        TestCase(pressed: {2}, expect: ['Pressed'], pins: {17: true}, note: 'button held'),
        TestCase(expect: ['Not pressed'], pins: {17: false}, note: 'button not held'),
      ],
      criteria: 'Both simulator tests pass. The checker holds GPIO 2 for the first test.',
      hint: 'pressed = GPIO.input(2) == GPIO.LOW, then GPIO.output(17, pressed).',
      solution: r'''import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(2, GPIO.IN, pull_up_down=GPIO.PUD_UP)
GPIO.setup(17, GPIO.OUT)

pressed = GPIO.input(2) == GPIO.LOW
GPIO.output(17, pressed)
print("Pressed" if pressed else "Not pressed")
''',
    ),
    Exercise(
      id: 'pi-ex-blinks',
      level: 'Challenge',
      title: 'Blink n times',
      task: 'Read a whole number n. Blink the LED on GPIO 18 n times (0.1 s on, 0.1 s off), printing "Blink 1", "Blink 2", ..., then print "Done". '
          'A negative or non-number input prints "Invalid" and blinks nothing. The LED must end off. Do not call GPIO.cleanup() at the end.',
      kind: CheckKind.gpio,
      starter: r'''import time
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)
text = input()
# blink n times
''',
      requirements: ['Validates the input with try/except and a range check.', 'Prints Blink i for each blink, then Done.', 'GPIO 18 ends LOW.'],
      cases: [
        TestCase(input: '3', expect: ['Blink 1', 'Blink 2', 'Blink 3', 'Done'], pins: {18: false}, note: 'three blinks'),
        TestCase(input: '0', expect: ['Done'], pins: {18: false}, note: 'zero blinks'),
        TestCase(input: 'abc', expect: ['Invalid'], pins: {18: false}, note: 'not a number'),
      ],
      criteria: 'All three simulator tests pass.',
      hint: 'try: n = int(text) except ValueError: n = -1; then if n < 0: print("Invalid").',
      solution: r'''import time
import RPi.GPIO as GPIO

GPIO.setmode(GPIO.BCM)
GPIO.setup(18, GPIO.OUT)
text = input()
try:
    n = int(text)
except ValueError:
    n = -1

if n < 0:
    print("Invalid")
else:
    for i in range(n):
        GPIO.output(18, GPIO.HIGH)
        print("Blink", i + 1)
        time.sleep(0.1)
        GPIO.output(18, GPIO.LOW)
        time.sleep(0.1)
    print("Done")
''',
    ),
  ],
);
