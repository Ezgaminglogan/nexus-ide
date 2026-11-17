// Autocomplete words per language (Language.words): import/include names, both whole paths and
// their parts (the popup completes only the part being typed, e.g. `ut` after `java.`), plus the
// standard functions and classes students call from them.

const cWords = [
  'stdio.h', 'stdlib.h', 'string.h', 'math.h', 'ctype.h', 'time.h', 'stdbool.h', 'limits.h', 'stdint.h', 'float.h', 'assert.h',
  'include', 'define', 'printf', 'scanf', 'puts', 'putchar', 'fgets', 'getchar', 'sprintf', 'fprintf', 'fscanf', 'fopen', 'fclose',
  'malloc', 'calloc', 'realloc', 'free', 'atoi', 'atof', 'rand', 'srand', 'abs', 'exit', 'sqrt', 'pow', 'fabs', 'ceil', 'floor',
  'sin', 'cos', 'toupper', 'tolower', 'isdigit', 'isalpha', 'isspace', 'strlen', 'strcpy', 'strncpy', 'strcmp', 'strncmp', 'strcat',
  'strchr', 'strstr', 'memset', 'memcpy', 'sizeof', 'bool', 'true', 'false', 'NULL', 'EOF', 'INT_MAX', 'INT_MIN', 'RAND_MAX',
  'EXIT_SUCCESS', 'EXIT_FAILURE',
];

const arduinoWords = [
  'Arduino.h', 'Servo.h', 'Wire.h', 'SPI.h', 'EEPROM.h', 'SoftwareSerial.h', 'LiquidCrystal.h', 'LiquidCrystal_I2C.h', 'DHT.h',
  'include', 'define', 'pinMode', 'digitalWrite', 'digitalRead', 'analogRead', 'analogWrite', 'delay', 'delayMicroseconds', 'millis',
  'micros', 'pulseIn', 'attachInterrupt', 'random', 'randomSeed', 'Serial', 'begin', 'println', 'print', 'available', 'read',
  'parseInt', 'readString', 'HIGH', 'LOW', 'INPUT', 'OUTPUT', 'INPUT_PULLUP', 'LED_BUILTIN', 'A0', 'A1', 'A2', 'A3', 'A4', 'A5',
  'setup', 'loop', 'map', 'constrain', 'tone', 'noTone', 'Servo', 'attach', 'write', 'Wire', 'EEPROM', 'SoftwareSerial',
  'LiquidCrystal', 'setCursor', 'clear',
];

const pythonWords = [
  'math', 'random', 'time', 'datetime', 'os', 'sys', 'json', 'csv', 'statistics', 'string', 'collections', 'itertools', 'functools',
  're', 'turtle', 'tkinter', 'sqlite3', 'pathlib', 'fractions', 'decimal', 'typing',
  'print', 'input', 'range', 'len', 'int', 'float', 'str', 'bool', 'list', 'dict', 'tuple', 'set', 'enumerate', 'sum', 'min', 'max',
  'abs', 'round', 'sorted', 'reversed', 'zip', 'map', 'filter', 'open', 'type', 'isinstance', 'append', 'extend', 'insert', 'remove',
  'pop', 'split', 'join', 'strip', 'upper', 'lower', 'replace', 'format', 'items', 'keys', 'values', 'get', 'sqrt', 'pi', 'floor',
  'ceil', 'randint', 'choice', 'shuffle', 'sleep', 'now', 'mean', 'median', 'mode', 'Counter', 'defaultdict', 'Path',
  'ValueError', 'ZeroDivisionError', 'IndexError', 'KeyError', 'TypeError', 'Exception',
];

const javaWords = [
  'java.util.Scanner', 'java.util.ArrayList', 'java.util.HashMap', 'java.util.HashSet', 'java.util.List', 'java.util.Map',
  'java.util.Arrays', 'java.util.Collections', 'java.util.Random', 'java.util.*', 'java.io.*', 'java.time.LocalDate',
  'java', 'util', 'io', 'time', 'Scanner', 'ArrayList', 'HashMap', 'HashSet', 'LinkedList', 'List', 'Map', 'Set', 'Arrays',
  'Collections', 'Random', 'Math', 'Integer', 'Double', 'Boolean', 'Character', 'String', 'StringBuilder', 'LocalDate',
  'LocalDateTime', 'File', 'FileReader', 'FileWriter', 'BufferedReader', 'IOException', 'InputMismatchException', 'Exception',
  'System', 'println', 'print', 'printf', 'nextInt', 'nextDouble', 'nextLine', 'next', 'nextBoolean', 'hasNextInt', 'close',
  'length', 'charAt', 'equals', 'equalsIgnoreCase', 'substring', 'indexOf', 'toUpperCase', 'toLowerCase', 'trim', 'split',
  'contains', 'parseInt', 'parseDouble', 'valueOf', 'add', 'get', 'set', 'remove', 'size', 'isEmpty', 'put', 'containsKey',
  'keySet', 'sort', 'toString', 'sqrt', 'pow', 'abs', 'max', 'min', 'random', 'round',
];

const csharpWords = [
  'System', 'System.Collections.Generic', 'System.Linq', 'System.Text', 'System.IO', 'Collections', 'Generic', 'Linq', 'Text', 'IO',
  'Console', 'WriteLine', 'ReadLine', 'Write', 'ReadKey', 'Clear', 'Convert', 'ToInt32', 'ToDouble', 'ToString', 'int.Parse',
  'double.Parse', 'TryParse', 'Parse', 'Math', 'Sqrt', 'Pow', 'Abs', 'Max', 'Min', 'Round', 'Random', 'Next', 'List', 'Dictionary',
  'Add', 'Remove', 'Count', 'Contains', 'ContainsKey', 'Length', 'Split', 'Join', 'Trim', 'ToUpper', 'ToLower', 'Substring',
  'IndexOf', 'Replace', 'string', 'StringBuilder', 'DateTime', 'Now', 'Exception', 'FormatException', 'DivideByZeroException',
];

const webWords = [
  'div', 'section', 'header', 'footer', 'nav', 'main', 'article', 'aside', 'button', 'input', 'form', 'label', 'select', 'option',
  'textarea', 'table', 'thead', 'tbody', 'tr', 'th', 'td', 'img', 'link', 'script', 'meta', 'title', 'href', 'src', 'alt',
  'placeholder', 'class', 'style', 'display', 'flex', 'grid', 'margin', 'padding', 'color', 'background', 'border', 'border-radius',
  'width', 'height', 'font-family', 'font-size', 'font-weight', 'text-align', 'justify-content', 'align-items', 'flex-direction',
  'gap', 'position', 'absolute', 'relative', 'box-shadow', 'transition', 'hover', 'media',
  'document', 'querySelector', 'querySelectorAll', 'getElementById', 'innerHTML', 'textContent', 'value', 'classList',
  'createElement', 'appendChild', 'addEventListener', 'preventDefault', 'console', 'log', 'alert', 'fetch', 'JSON', 'parse',
  'stringify', 'localStorage', 'setTimeout', 'setInterval', 'Math', 'random', 'floor', 'length', 'push', 'map', 'filter', 'forEach',
];

const phpWords = [
  'include', 'include_once', 'require', 'require_once', 'echo', 'isset', 'empty', 'session_start', r'$_SESSION', r'$_POST', r'$_GET',
  'header', 'die', 'exit', 'mysqli', 'mysqli_connect', 'connect_error', 'query', 'prepare', 'bind_param', 'execute', 'get_result',
  'fetch_assoc', 'fetch_all', 'num_rows', 'close', 'PDO', 'fetch', 'fetchAll', 'rowCount', 'password_hash', 'password_verify',
  'htmlspecialchars', 'json_encode', 'json_decode', 'date', 'time', 'strlen', 'strtoupper', 'strtolower', 'trim', 'explode',
  'implode', 'str_replace', 'substr', 'in_array', 'array_push', 'array_keys', 'array_sum', 'count', 'sort', 'foreach', 'array',
  'var_dump', 'print_r', 'is_numeric', 'intval', 'number_format', 'filter_input', 'FILTER_VALIDATE_EMAIL',
];

const sqlWords = [
  'SELECT', 'FROM', 'WHERE', 'AND', 'OR', 'NOT', 'ORDER BY', 'GROUP BY', 'HAVING', 'ASC', 'DESC', 'LIMIT', 'DISTINCT', 'AS',
  'INSERT INTO', 'VALUES', 'UPDATE', 'SET', 'DELETE', 'CREATE TABLE', 'CREATE DATABASE', 'DROP TABLE', 'ALTER TABLE', 'ADD COLUMN',
  'IF NOT EXISTS', 'IF EXISTS', 'USE', 'SHOW TABLES', 'DESCRIBE', 'PRIMARY KEY', 'FOREIGN KEY', 'REFERENCES', 'UNIQUE', 'DEFAULT',
  'NULL', 'NOT NULL', 'IS NULL', 'AUTO_INCREMENT', 'AUTOINCREMENT', 'INTEGER', 'INT', 'VARCHAR', 'TEXT', 'DATE', 'DECIMAL', 'REAL',
  'JOIN', 'INNER JOIN', 'LEFT JOIN', 'RIGHT JOIN', 'ON', 'LIKE', 'IN', 'BETWEEN', 'CASE', 'WHEN', 'THEN', 'ELSE', 'END',
  'COUNT', 'AVG', 'SUM', 'MIN', 'MAX', 'ROUND', 'UPPER', 'LOWER', 'LENGTH', 'NOW', 'CURRENT_DATE',
];

const raspiWords = [
  'RPi.GPIO', 'RPi', 'GPIO', 'gpiozero', 'LED', 'Button', 'PWMLED', 'Buzzer', 'on', 'off', 'toggle', 'blink', 'is_pressed',
  'wait_for_press', 'when_pressed', 'setmode', 'setwarnings', 'setup', 'output', 'input', 'cleanup', 'BCM', 'BOARD', 'OUT', 'IN',
  'HIGH', 'LOW', 'PUD_UP', 'PUD_DOWN', 'pull_up_down', 'PWM', 'start', 'ChangeDutyCycle', 'stop', 'add_event_detect', 'FALLING',
  'RISING', 'BOTH', 'bouncetime', 'KeyboardInterrupt', ...pythonWords,
];
