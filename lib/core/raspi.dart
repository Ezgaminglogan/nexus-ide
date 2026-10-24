import 'dart:io';

import 'package:path/path.dart' as p;

/// Raspberry Pi simulator: the student's Python imports a stand-in `RPi.GPIO` (written into the
/// workspace) that keeps pin states in [stateFile] and reads button presses from [inputFile].
/// The editor's pin panel polls one and writes the other, so no output parsing is needed.

const stateFile = 'gpio_state.txt'; // "18 out 1" / "17 in 0 up", one line per set-up pin (BCM numbers)
const inputFile = 'gpio_in.txt'; // BCM numbers of buttons held down, one per line

/// One set-up pin as the program left it.
typedef PinState = ({int pin, bool output, bool high, bool pullUp});

List<PinState> parseState(String text) => [
      for (final line in text.split('\n'))
        if (line.trim().split(' ') case [final pin, final mode, final v, ...final rest] when int.tryParse(pin) != null)
          (pin: int.parse(pin), output: mode == 'out', high: v == '1', pullUp: rest.contains('up')),
    ];

List<PinState> readState(String dir) {
  try {
    return parseState(File(p.join(dir, stateFile)).readAsStringSync());
  } on FileSystemException {
    return const [];
  }
}

void writePressed(String dir, Set<int> pins) {
  try {
    File(p.join(dir, inputFile)).writeAsStringSync(pins.join('\n'));
  } on FileSystemException {
    // workspace not created yet: nothing is running to read it
  }
}

/// 40-pin header, physical pin -> BCM GPIO number, or the power/ground label.
const header = <int, Object>{
  1: '3V3', 2: '5V', 3: 2, 4: '5V', 5: 3, 6: 'GND', 7: 4, 8: 14, 9: 'GND', 10: 15,
  11: 17, 12: 18, 13: 27, 14: 'GND', 15: 22, 16: 23, 17: '3V3', 18: 24, 19: 10, 20: 'GND',
  21: 9, 22: 25, 23: 11, 24: 8, 25: 'GND', 26: 7, 27: 0, 28: 1, 29: 5, 30: 'GND',
  31: 6, 32: 12, 33: 13, 34: 'GND', 35: 19, 36: 16, 37: 26, 38: 20, 39: 'GND', 40: 21,
};

const _gpioPy = r'''
# NEXUS IDE stand-in for RPi.GPIO: same calls as a real Raspberry Pi.
# LEDs and buttons appear in the NEXUS pin panel instead of on real hardware.
import os

BCM, BOARD = 11, 10
OUT, IN = 0, 1
LOW, HIGH = 0, 1
PUD_OFF, PUD_DOWN, PUD_UP = 20, 21, 22
RISING, FALLING, BOTH = 31, 32, 33
RPI_INFO = {"TYPE": "NEXUS simulator"}

_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
_STATE = os.path.join(_DIR, "gpio_state.txt")
_INPUT = os.path.join(_DIR, "gpio_in.txt")
_BOARD = {3: 2, 5: 3, 7: 4, 8: 14, 10: 15, 11: 17, 12: 18, 13: 27, 15: 22, 16: 23, 18: 24, 19: 10,
          21: 9, 22: 25, 23: 11, 24: 8, 26: 7, 27: 0, 28: 1, 29: 5, 31: 6, 32: 12, 33: 13, 35: 19,
          36: 16, 37: 26, 38: 20, 40: 21}
_mode = None
_pins = {}  # BCM -> [direction, value, pull]


def _save():
    lines = ["%d %s %d%s" % (p, "out" if d == OUT else "in", v, " up" if u == PUD_UP else "")
             for p, (d, v, u) in sorted(_pins.items())]
    with open(_STATE + ".tmp", "w") as f:
        f.write("\n".join(lines))
    os.replace(_STATE + ".tmp", _STATE)  # the panel never sees half a file


def _bcm(channel):
    if _mode is None:
        raise RuntimeError("Please set pin numbering mode using GPIO.setmode(GPIO.BOARD) or GPIO.setmode(GPIO.BCM)")
    if _mode == BOARD:
        if channel not in _BOARD:
            raise ValueError("The channel sent is invalid on a Raspberry Pi: %r" % channel)
        return _BOARD[channel]
    if not 0 <= channel <= 27:
        raise ValueError("The channel sent is invalid on a Raspberry Pi: %r" % channel)
    return channel


def _each(channel):
    return channel if isinstance(channel, (list, tuple)) else [channel]


def setmode(mode):
    global _mode
    _mode = mode


def getmode():
    return _mode


def setwarnings(flag):
    pass


def setup(channel, direction, pull_up_down=PUD_OFF, initial=None):
    for c in _each(channel):
        _pins[_bcm(c)] = [direction, (initial or LOW) if direction == OUT else LOW, pull_up_down]
    _save()


def output(channel, value):
    values = value if isinstance(value, (list, tuple)) else [value] * len(_each(channel))
    for c, v in zip(_each(channel), values):
        pin = _bcm(c)
        if pin not in _pins or _pins[pin][0] != OUT:
            raise RuntimeError("The GPIO channel has not been set up as an OUTPUT")
        _pins[pin][1] = 1 if v else 0
    _save()


def input(channel):
    pin = _bcm(channel)
    if pin not in _pins:
        raise RuntimeError("You must setup() the GPIO channel first")
    d, v, pull = _pins[pin]
    if d == OUT:
        return v
    try:
        with open(_INPUT) as f:
            pressed = str(pin) in f.read().split()
    except OSError:
        pressed = False
    # A button wired to GND with a pull-up reads LOW when pressed, like on a real Pi.
    return (LOW if pressed else HIGH) if pull == PUD_UP else (HIGH if pressed else LOW)


def cleanup(channel=None):
    for c in (_each(channel) if channel is not None else list(_pins)):
        _pins.pop(_bcm(c) if channel is not None else c, None)
    _save()


_save()  # a fresh run starts with no pins set up
''';

/// Written next to the student's main.py so `import RPi.GPIO as GPIO` finds it.
const raspiFiles = {'RPi/__init__.py': '', 'RPi/GPIO.py': _gpioPy};

const raspiTemplate = '''import time
import RPi.GPIO as GPIO

LED = 18     # LED on GPIO 18
BUTTON = 17  # push button on GPIO 17 (tap and hold it in the pin panel)

GPIO.setmode(GPIO.BCM)
GPIO.setup(LED, GPIO.OUT)
GPIO.setup(BUTTON, GPIO.IN, pull_up_down=GPIO.PUD_UP)

try:
    # Blink 3 times
    for i in range(3):
        GPIO.output(LED, GPIO.HIGH)
        print("LED on")
        time.sleep(0.5)
        GPIO.output(LED, GPIO.LOW)
        print("LED off")
        time.sleep(0.5)

    # Then: LED on while the button is held (press Stop to end)
    print("Hold the button on GPIO 17...")
    while True:
        pressed = GPIO.input(BUTTON) == GPIO.LOW
        GPIO.output(LED, pressed)
        time.sleep(0.05)
finally:
    GPIO.cleanup()
''';
