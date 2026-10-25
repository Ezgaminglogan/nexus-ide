import '../model.dart';

const _py = 'Python Software Foundation';
const _v = 'Python 3.14 (NEXUS runs 3.14)';
const _t = 'https://docs.python.org/3.14/tutorial';

const pythonTrack = Track(
  langId: 'python',
  title: 'Python',
  intro: 'Python reads almost like English, so you can focus on the problem instead of the punctuation. '
      'These lessons use Python 3.14, the version NEXUS bundles on phones and the one installed on the lab PCs.',
  runtime: 'Lab PC: Python 3.14 (bundled or installed). Phone: Python 3.14 (bundled). NEXUS runs main.py with it.',
  run: [
    'Open the Python tile (or press Try in Editor to open a practice copy).',
    'Press Run. NEXUS runs main.py from top to bottom.',
    'When the program asks a question, type the answer under the terminal and press Enter.',
  ],
  lessons: [
    Lesson(
      id: 'py-indentation',
      title: 'Your first program and indentation',
      summary: 'print, comments, and why spaces at the start of a line matter.',
      objective: 'Print messages and use indentation to group lines under an if.',
      explanation: 'A Python program runs from the top line down. print shows a value on its own line. '
          'Lines that belong together (for example, the lines inside an if) are indented by the same amount, usually 4 spaces. '
          'Python uses indentation instead of braces, so the spaces are part of the code. # starts a comment that Python ignores.',
      syntax: r'''print("text")
if condition:
    # indented lines belong to the if
    print("inside")
print("outside")''',
      syntaxNotes: [
        ('print(...)', 'Shows text or numbers, then moves to a new line.'),
        (':', 'Ends the line that starts a block (if, for, def...).'),
        ('4 spaces', 'Every line in the block starts with the same indentation.'),
        ('#', 'A comment: a note for people, skipped by Python.'),
      ],
      example: r'''# My first Python program
print("Hello, CTU Naga!")
print("Python is fun.")

ready = True
if ready:
    print("Let's start coding.")
print("Done.")
''',
      output: "Hello, CTU Naga!\nPython is fun.\nLet's start coding.\nDone.",
      lines: [
        'The two print lines run first, in order.',
        'print("Let\'s start coding.") is indented, so it only runs when ready is True.',
        'print("Done.") is not indented: it runs after the if, either way.',
      ],
      mistake: 'Mixing indentation levels inside one block gives IndentationError.',
      mistakeCode: r'''if ready:
    print("one")
      print("two")''',
      fixCode: r'''if ready:
    print("one")
    print("two")''',
      practice: 'Print a three-line "student card": your name, course and year.',
      refs: [
        Ref('An Informal Introduction to Python', _py, '$_t/introduction.html', version: _v),
        Ref('Lexical analysis: indentation', _py, 'https://docs.python.org/3.14/reference/lexical_analysis.html#indentation', version: _v),
      ],
      keywords: ['print', 'indentation', 'comment', '#', 'IndentationError'],
    ),
    Lesson(
      id: 'py-variables',
      title: 'Variables and types',
      summary: 'Store numbers and text in names: int, float, str and bool.',
      objective: 'Create variables of the four basic types and combine them in f-strings.',
      explanation: 'A variable is a name for a value. Python works out the type from the value: 18 is an int, 1.75 is a float, "Ana" is a str (text) '
          'and True/False are bool. An f-string (f"...") puts variables inside text with {braces}; {x:.2f} shows two decimals.',
      syntax: r'''name = "Ana"
age = 18
height = 1.75
enrolled = True
print(f"{name} is {age}")''',
      syntaxNotes: [
        ('=', 'Stores the value on the right in the name on the left.'),
        ('f"...{x}..."', 'An f-string: {x} is replaced by the value of x.'),
        ('{x:.2f}', 'Shows a number with two decimals.'),
        ('type(x)', 'Tells you the type of a value.'),
      ],
      example: r'''name = "Ana"
age = 18
height = 1.75
enrolled = True

print(f"Name: {name}")
print(f"Age next year: {age + 1}")
print(f"Height: {height:.2f} m")
print(f"Enrolled: {enrolled}")
print(type(age), type(height))
''',
      output: "Name: Ana\nAge next year: 19\nHeight: 1.75 m\nEnrolled: True\n<class 'int'> <class 'float'>",
      lines: [
        '{age + 1} works out 19 inside the f-string; age itself stays 18.',
        '{height:.2f} prints 1.75 with two decimals.',
        "type(age) shows <class 'int'>.",
      ],
      mistake: 'Adding text and a number with + gives TypeError. Use an f-string (or str()).',
      mistakeCode: r'''print("Age: " + age)''',
      fixCode: r'''print(f"Age: {age}")''',
      practice: 'Store a product name, price and quantity, then print the total cost with two decimals.',
      refs: [Ref('An Informal Introduction to Python: numbers and text', _py, '$_t/introduction.html', version: _v)],
      keywords: ['variable', 'int', 'float', 'str', 'bool', 'f-string', 'type'],
    ),
    Lesson(
      id: 'py-io',
      title: 'Input and output',
      summary: 'Ask the user with input() and turn the answer into a number.',
      objective: 'Read two numbers from the user and print their average.',
      explanation: 'input("prompt") shows the prompt, waits for the user to type and press Enter, and gives back what they typed as text (str). '
          'To do math, convert it with int(...) or float(...).',
      syntax: r'''text = input("Prompt: ")
number = float(input("Score: "))''',
      syntaxNotes: [
        ('input(...)', 'Always gives back text (str).'),
        ('int(...) / float(...)', 'Turn text into a whole number / a decimal number.'),
      ],
      example: r'''a = float(input("First score: "))
b = float(input("Second score: "))
average = (a + b) / 2
print(f"Average: {average:.1f}")
''',
      input: '80\n91',
      output: 'First score: 80\nSecond score: 91\nAverage: 85.5',
      checks: ['Average: 85.5'],
      lines: [
        'input("First score: ") waits for the first line typed; float(...) turns "80" into 80.0.',
        '(a + b) / 2 always gives a float in Python, even for whole numbers.',
      ],
      mistake: 'Forgetting to convert: "80" + "91" joins text into "8091".',
      mistakeCode: r'''a = input("First: ")
b = input("Second: ")
print(a + b)''',
      fixCode: r'''a = float(input("First: "))
b = float(input("Second: "))
print(a + b)''',
      practice: 'Ask for a name and a birth year, and print how old the person turns this year.',
      refs: [
        Ref('Built-in Functions: input()', _py, 'https://docs.python.org/3.14/library/functions.html#input', version: _v),
        Ref('Input and Output', _py, '$_t/inputoutput.html', version: _v),
      ],
      keywords: ['input', 'int', 'float', 'conversion', 'average'],
    ),
    Lesson(
      id: 'py-conditions',
      title: 'Conditions: if, elif, else',
      summary: 'Choose what to do based on a value.',
      objective: 'Turn a score into a grade with if, elif and else.',
      explanation: 'if checks a condition; if it is True, its indented block runs. elif ("else if") is checked only when everything above was False, '
          'and else runs when nothing matched. Compare with ==, !=, <, >, <=, >= and combine with and, or, not.',
      syntax: r'''if score >= 90:
    ...
elif score >= 75:
    ...
else:
    ...''',
      syntaxNotes: [
        ('==', 'Equal to (one = is assignment).'),
        ('elif', 'Another condition, checked only if the ones above were False.'),
        ('and / or / not', 'Combine conditions: 75 <= score and score <= 100.'),
      ],
      example: r'''score = int(input("Score: "))
if score >= 90:
    print("Grade: A")
elif score >= 80:
    print("Grade: B")
elif score >= 75:
    print("Grade: C")
else:
    print("Grade: F")
''',
      input: '84',
      output: 'Score: 84\nGrade: B',
      checks: ['Grade: B'],
      lines: [
        '84 >= 90 is False, so Python tries the next condition.',
        '84 >= 80 is True: "Grade: B" prints and the rest is skipped.',
      ],
      mistake: 'Forgetting the colon at the end of the if line gives SyntaxError.',
      mistakeCode: r'''if score >= 90
    print("A")''',
      fixCode: r'''if score >= 90:
    print("A")''',
      practice: 'Ask for a temperature and print "Cold" (below 20), "Nice" (20 to 30) or "Hot" (above 30).',
      refs: [Ref('More Control Flow Tools: if Statements', _py, '$_t/controlflow.html#if-statements', version: _v)],
      keywords: ['if', 'elif', 'else', 'and', 'or', 'not', 'grade'],
    ),
    Lesson(
      id: 'py-loops',
      title: 'Loops: for and while',
      summary: 'Repeat work with for over a range or a list, and while for "until".',
      objective: 'Count and total with a for loop and repeat until a condition with while.',
      explanation: 'for goes through the items of a sequence one at a time; range(1, 6) gives 1, 2, 3, 4, 5. '
          'while repeats as long as its condition is True. break leaves a loop early.',
      syntax: r'''for i in range(1, 6):
    ...
while condition:
    ...''',
      syntaxNotes: [
        ('range(1, 6)', 'The numbers 1 up to, but not including, 6.'),
        ('for x in items', 'x takes each item in turn.'),
        ('while', 'Repeats while the condition stays True.'),
        ('break', 'Stops the loop immediately.'),
      ],
      example: r'''total = 0
for i in range(1, 6):
    total += i
print(f"1 to 5 adds up to {total}")

count = 3
while count > 0:
    print(f"{count}...")
    count -= 1
print("Go!")
''',
      output: '1 to 5 adds up to 15\n3...\n2...\n1...\nGo!',
      lines: [
        'total += i adds i to total; it runs 5 times.',
        'count -= 1 makes the while condition eventually False.',
      ],
      mistake: 'range(1, 5) stops before 5, so it gives only 1, 2, 3, 4.',
      mistakeCode: r'''for i in range(1, 5):   # 1..4
    print(i)''',
      fixCode: r'''for i in range(1, 6):   # 1..5
    print(i)''',
      practice: 'Print the even numbers from 2 to 20 using range with a step: range(2, 21, 2).',
      refs: [
        Ref('More Control Flow Tools: for Statements', _py, '$_t/controlflow.html#for-statements', version: _v),
        Ref('More Control Flow Tools: The range() Function', _py, '$_t/controlflow.html#the-range-function', version: _v),
      ],
      keywords: ['for', 'while', 'range', 'break', 'loop', '+='],
    ),
    Lesson(
      id: 'py-functions',
      title: 'Functions',
      summary: 'Name a block of code with def, give it inputs, return a result.',
      objective: 'Write a function that returns an average and call it several times.',
      explanation: 'def creates a function. The names in brackets are its parameters. return sends a value back to where the function was called. '
          'A function only runs when you call it, and it can be called as often as you like.',
      syntax: r'''def name(param1, param2):
    ...
    return result''',
      syntaxNotes: [
        ('def', 'Defines (creates) a function.'),
        ('return', 'Gives a value back and ends the function.'),
        ('average(90, 85)', 'Calls the function with these values.'),
      ],
      example: r'''def average(scores):
    return sum(scores) / len(scores)

def remark(avg):
    if avg >= 75:
        return "passed"
    return "failed"

for name, scores in [("Ana", [90, 85, 88]), ("Ben", [60, 70, 72])]:
    avg = average(scores)
    print(f"{name}: {avg:.2f} ({remark(avg)})")
''',
      output: 'Ana: 87.67 (passed)\nBen: 67.33 (failed)',
      lines: [
        'sum(scores) adds the list; len(scores) counts it.',
        'remark returns early with "passed"; otherwise the last line returns "failed".',
        'The for loop calls both functions once per student.',
      ],
      mistake: 'Printing inside the function instead of returning, then using the result: you get None.',
      mistakeCode: r'''def double(x):
    print(x * 2)
y = double(4) + 1''',
      fixCode: r'''def double(x):
    return x * 2
y = double(4) + 1''',
      practice: 'Write is_even(n) that returns True or False, and use it to print which numbers from 1 to 10 are even.',
      refs: [Ref('More Control Flow Tools: Defining Functions', _py, '$_t/controlflow.html#defining-functions', version: _v)],
      keywords: ['def', 'return', 'function', 'parameter', 'sum', 'len'],
    ),
    Lesson(
      id: 'py-lists',
      title: 'Lists',
      summary: 'Keep many values in order and work with all of them.',
      objective: 'Add to, count, sort and loop over a list of scores.',
      explanation: 'A list holds values in order inside square brackets. Positions start at 0, and -1 is the last item. '
          'append adds to the end, len counts, sorted gives a sorted copy, and max/min find the biggest/smallest.',
      syntax: r'''scores = [90, 72, 85]
scores.append(64)
scores[0]      # first
scores[-1]     # last
len(scores)''',
      syntaxNotes: [
        ('[ ... ]', 'A list literal.'),
        ('.append(x)', 'Adds x to the end.'),
        ('items[i]', 'The item at position i (0 is first).'),
        ('[x for x in items if ...]', 'Builds a new list from the items that match.'),
      ],
      example: r'''scores = [90, 72, 85]
scores.append(64)
print("Scores:", scores)
print("How many:", len(scores))
print("Highest:", max(scores))
print("Sorted:", sorted(scores))
passed = [s for s in scores if s >= 75]
print("Passed:", passed)
''',
      output: 'Scores: [90, 72, 85, 64]\nHow many: 4\nHighest: 90\nSorted: [64, 72, 85, 90]\nPassed: [90, 85]',
      lines: [
        'scores.append(64) changes the list itself.',
        'sorted(scores) returns a new sorted list; scores keeps its order.',
        'The last list keeps only scores of 75 or more.',
      ],
      mistake: 'Reading past the end gives IndexError: a list of 4 has positions 0 to 3.',
      mistakeCode: r'''scores = [90, 72, 85, 64]
print(scores[4])''',
      fixCode: r'''scores = [90, 72, 85, 64]
print(scores[3])   # or scores[-1]''',
      practice: 'Read five names into a list with a loop, then print them in alphabetical order.',
      refs: [Ref('Data Structures: More on Lists', _py, '$_t/datastructures.html#more-on-lists', version: _v)],
      keywords: ['list', 'append', 'len', 'sorted', 'max', 'min', 'index', 'comprehension'],
    ),
    Lesson(
      id: 'py-dicts',
      title: 'Dictionaries',
      summary: 'Look values up by name: a student profile as key → value pairs.',
      objective: 'Build a student profile dictionary, read, change and loop over it.',
      explanation: 'A dictionary stores pairs: a key (like "name") and its value (like "Ana"). You look up a value with its key instead of a position. '
          'Use .get(key, default) when the key might be missing, and .items() to loop over pairs.',
      syntax: r'''student = {"name": "Ana", "age": 18}
student["age"]          # 18
student["course"] = "BSIT"
for key, value in student.items():
    ...''',
      syntaxNotes: [
        ('{"key": value}', 'A dictionary literal.'),
        ('d["key"]', 'Reads (or, with =, sets) the value for key.'),
        ('d.get("key", x)', 'The value, or x if the key is missing.'),
        ('.items()', 'All key, value pairs.'),
      ],
      example: r'''student = {"name": "Ana", "age": 18, "course": "BSIT"}
student["age"] = 19
student["section"] = "A"

for key, value in student.items():
    print(f"{key}: {value}")
print("GPA:", student.get("gpa", "not set"))
''',
      output: 'name: Ana\nage: 19\ncourse: BSIT\nsection: A\nGPA: not set',
      lines: [
        'student["age"] = 19 replaces the old value.',
        'student["section"] = "A" adds a new key.',
        'get("gpa", "not set") avoids a KeyError because there is no "gpa" key.',
      ],
      mistake: 'Reading a missing key with [ ] raises KeyError.',
      mistakeCode: r'''print(student["gpa"])''',
      fixCode: r'''print(student.get("gpa", "not set"))''',
      practice: 'Count how many times each word appears in a sentence using a dictionary.',
      refs: [Ref('Data Structures: Dictionaries', _py, '$_t/datastructures.html#dictionaries', version: _v)],
      keywords: ['dictionary', 'dict', 'key', 'value', 'items', 'get', 'KeyError'],
    ),
    Lesson(
      id: 'py-errors',
      title: 'Handling errors with try and except',
      summary: 'Keep a program running when the user types something unexpected.',
      objective: 'Catch a ValueError from bad input and ask again.',
      explanation: 'When something goes wrong, Python raises an exception and stops. try runs code that might fail; if it raises the named '
          'exception, the except block runs instead of crashing. This is how you handle typing mistakes politely.',
      syntax: r'''try:
    risky code
except ValueError:
    what to do instead''',
      syntaxNotes: [
        ('try:', 'The code that might fail.'),
        ('except ValueError:', 'Runs only if that kind of error happens.'),
        ('ValueError', 'Raised by int("abc"): the text is not a number.'),
      ],
      example: r'''while True:
    try:
        age = int(input("Age: "))
        break
    except ValueError:
        print("Please type a whole number.")
print(f"Next year you will be {age + 1}.")
''',
      input: 'eighteen\n18',
      output: 'Age: eighteen\nPlease type a whole number.\nAge: 18\nNext year you will be 19.',
      checks: ['Please type a whole number.', 'Next year you will be 19.'],
      lines: [
        'int("eighteen") raises ValueError, so the except block prints the message.',
        'The loop asks again; int("18") works and break leaves the loop.',
      ],
      mistake: 'A bare except: hides every error, even typos in your own code. Name the error you expect.',
      mistakeCode: r'''try:
    age = int(input("Age: "))
except:
    pass''',
      fixCode: r'''try:
    age = int(input("Age: "))
except ValueError:
    print("Please type a whole number.")''',
      practice: 'Ask for two numbers and divide them; handle ValueError (not a number) and ZeroDivisionError (dividing by 0).',
      refs: [Ref('Errors and Exceptions: Handling Exceptions', _py, '$_t/errors.html#handling-exceptions', version: _v)],
      keywords: ['try', 'except', 'ValueError', 'ZeroDivisionError', 'exception', 'error'],
    ),
  ],
  quiz: [
    Question('How does Python know which lines belong to an if?', ['Braces { }', 'Their indentation', 'A semicolon', 'The word end'], 1,
        'Lines in a block share the same indentation.'),
    Question('What type does input() give back?', ['int', 'float', 'str', 'It depends on what was typed'], 2, 'Always text; convert with int() or float().'),
    Question('What does print(f"{3.14159:.2f}") show?', ['3.14159', '3.14', '3.1', '3'], 1, ':.2f means two decimals.'),
    Question('Which numbers does range(2, 5) give?', ['2, 3, 4, 5', '2, 3, 4', '3, 4, 5', '2, 5'], 1, 'The end number is not included.'),
    Question('What does a function without return give back?', ['0', 'None', 'An error', 'The last line'], 1, 'Without return, a function gives None.'),
    Question('scores = [5, 8, 2]. What is scores[-1]?', ['5', '8', '2', 'An error'], 2, '-1 is the last item.'),
    Question('Which line adds 7 to the end of a list called nums?', ['nums.add(7)', 'nums.append(7)', 'nums + 7', 'nums.push(7)'], 1, 'Lists use append.'),
    Question('Safest way to read a dictionary key that might be missing?', ['d[key]', 'd.get(key, default)', 'd.key', 'd(key)'], 1,
        'get returns the default instead of raising KeyError.'),
    Question('What error does int("abc") raise?', ['TypeError', 'KeyError', 'ValueError', 'SyntaxError'], 2, 'The text is not a valid number.'),
    Question('Which is the elif keyword used for?', ['Ending a loop', 'Another condition after if', 'Defining a function', 'Catching errors'], 1,
        'elif is checked when the conditions above were False.'),
  ],
  exercises: [
    Exercise(
      id: 'py-ex-even',
      level: 'Beginner',
      title: 'Odd or even',
      task: 'Read one whole number and print "EVEN" or "ODD".',
      starter: r'''n = int(input())
# print EVEN or ODD
''',
      requirements: ['Read the number with input().', 'Print exactly EVEN or ODD.', 'Works for 0 and negative numbers.'],
      cases: [
        TestCase(input: '4', expect: ['EVEN'], note: 'even'),
        TestCase(input: '7', expect: ['ODD'], note: 'odd'),
        TestCase(input: '0', expect: ['EVEN'], note: 'zero'),
        TestCase(input: '-3', expect: ['ODD'], note: 'negative'),
      ],
      criteria: 'All four tests print the right word.',
      hint: 'n % 2 is the remainder after dividing by 2: 0 means even.',
      solution: r'''n = int(input())
if n % 2 == 0:
    print("EVEN")
else:
    print("ODD")
''',
    ),
    Exercise(
      id: 'py-ex-stats',
      level: 'Intermediate',
      title: 'Score statistics',
      task: 'Read one line of scores separated by spaces. Print "Count: ", "Average: " (two decimals) and "Highest: ". '
          'If the line is empty, print "No scores".',
      starter: r'''line = input()
# split the line, turn the parts into numbers, print the statistics
''',
      requirements: ['Use split() to get the separate scores.', 'Average with two decimals, like Average: 85.50.', 'An empty line prints No scores.'],
      cases: [
        TestCase(input: '80 90 85 87', expect: ['Count: 4', 'Average: 85.50', 'Highest: 90'], note: 'four scores'),
        TestCase(input: '100', expect: ['Count: 1', 'Average: 100.00', 'Highest: 100'], note: 'one score'),
        TestCase(input: '', expect: ['No scores'], note: 'empty line'),
      ],
      criteria: 'All three tests pass; lines appear in the order Count, Average, Highest.',
      hint: 'scores = [int(x) for x in line.split()] gives a list of numbers; then use len, sum and max.',
      solution: r'''line = input()
scores = [int(x) for x in line.split()]
if not scores:
    print("No scores")
else:
    print(f"Count: {len(scores)}")
    print(f"Average: {sum(scores) / len(scores):.2f}")
    print(f"Highest: {max(scores)}")
''',
    ),
    Exercise(
      id: 'py-ex-words',
      level: 'Challenge',
      title: 'Most common word',
      task: 'Read one line of text. Print the word that appears most often and how many times, like "the 3". '
          'Ignore upper/lower case. If two words tie, print the one that appears first in the text.',
      starter: r'''text = input()
# count the words with a dictionary
''',
      requirements: ['Words are separated by spaces; compare them in lower case.', 'Print the word in lower case, a space, then the count.', 'Ties go to the word seen first.'],
      cases: [
        TestCase(input: 'the cat and the dog and the bird', expect: ['the 3'], note: 'clear winner'),
        TestCase(input: 'Go go GO stop', expect: ['go 3'], note: 'mixed case'),
        TestCase(input: 'red blue red blue', expect: ['red 2'], note: 'tie: first one wins'),
      ],
      criteria: 'All three tests pass.',
      hint: 'Loop over text.lower().split(), add 1 to counts[word] (use counts.get(word, 0)). Then find the highest count, keeping the first word on ties.',
      solution: r'''text = input()
counts = {}
for word in text.lower().split():
    counts[word] = counts.get(word, 0) + 1
best = None
for word, n in counts.items():
    if best is None or n > counts[best]:
        best = word
print(best, counts[best])
''',
    ),
  ],
);
