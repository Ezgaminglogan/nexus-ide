import '../model.dart';

const _ms = 'Microsoft Learn';
const _v = 'C# 7 syntax (Mono mcs on phones); .NET 10 SDK on the lab PCs';
const _learn = 'https://learn.microsoft.com/en-us/dotnet/csharp';

const csharpTrack = Track(
  langId: 'csharp',
  title: 'C#',
  intro: 'C# is the language of .NET: console apps, Windows apps and games. In NEXUS every program is Program.cs with a class Program and a '
      'static void Main(). The lessons stick to classic C# 7 syntax so the same code builds on the lab PC\'s .NET 10 and on the phone\'s Mono '
      'compiler (top-level statements, records and switch expressions are left out on purpose).',
  runtime: 'Lab PC: the bundled .NET 10 SDK builds and runs a console project. Phone: Mono\'s mcs compiles Program.cs and Mono runs it.',
  run: [
    'Open the C# tile (or press Try in Editor to open a practice copy).',
    'Keep class Program with static void Main() in Program.cs.',
    'Press Run. The first build on a PC takes a few seconds; type any input under the terminal and press Enter.',
  ],
  lessons: [
    Lesson(
      id: 'cs-structure',
      title: 'Program structure',
      summary: 'using, class Program and the Main method.',
      objective: 'Write and run a Program class that prints two lines.',
      explanation: 'A C# program starts in a static method called Main inside a class. using System; at the top lets you write Console instead of '
          'System.Console. Console.WriteLine prints a line; every statement ends with a semicolon.',
      syntax: r'''using System;

class Program {
    static void Main() {
        // statements
    }
}''',
      syntaxNotes: [
        ('using System;', 'Lets you use Console, Math and friends by their short names.'),
        ('static void Main()', 'Where the program starts.'),
        ('Console.WriteLine(...)', 'Prints a value and a new line.'),
      ],
      example: r'''using System;

class Program {
    static void Main() {
        Console.WriteLine("Hello, CTU Naga!");
        Console.WriteLine("C# runs here too.");
    }
}
''',
      output: 'Hello, CTU Naga!\nC# runs here too.',
      lines: ['The two WriteLine calls run top to bottom.', 'C# is case sensitive: console.writeline does not exist.'],
      mistake: 'Writing main in lower case. C# only starts a method called Main.',
      mistakeCode: r'''static void main() {''',
      fixCode: r'''static void Main() {''',
      practice: 'Print your name, course and year level on three lines.',
      refs: [
        Ref('General structure of a C# program', _ms, '$_learn/fundamentals/program-structure/', version: _v),
        Ref('Main() and command-line arguments', _ms, '$_learn/fundamentals/program-structure/main-command-line', version: _v),
      ],
      keywords: ['using', 'class', 'Main', 'WriteLine', 'Console'],
    ),
    Lesson(
      id: 'cs-variables',
      title: 'Variables and types',
      summary: 'int, double, bool, char and string, and printing them.',
      objective: 'Declare variables of the common types and print them with string interpolation.',
      explanation: 'Every C# variable has a type. int is a whole number, double a decimal, bool is true/false, char one character, string text. '
          r'A $"..." string puts values inside {braces}; {gpa:F2} shows two decimals.',
      syntax: r'''int age = 18;
double gpa = 1.754;
bool enrolled = true;
string name = "Ana";
Console.WriteLine($"{name} is {age}");''',
      syntaxNotes: [
        ('string', 'Text in double quotes.'),
        (r'$"... {x} ..."', 'String interpolation: the value of x appears in the text.'),
        ('{gpa:F2}', 'The value with 2 decimals.'),
      ],
      example: r'''using System;

class Program {
    static void Main() {
        string name = "Ana";
        int age = 18;
        double gpa = 1.754;
        bool enrolled = true;

        Console.WriteLine($"Name: {name}");
        Console.WriteLine($"Age next year: {age + 1}");
        Console.WriteLine($"GPA: {gpa:F2}");
        Console.WriteLine($"Enrolled: {enrolled}");
    }
}
''',
      output: 'Name: Ana\nAge next year: 19\nGPA: 1.75\nEnrolled: True',
      lines: ['{age + 1} is worked out before it is placed in the text.', 'A bool prints as True or False (capital letter).'],
      mistake: r'Forgetting the $: the braces are printed as they are.',
      mistakeCode: r'''Console.WriteLine("Name: {name}");   // Name: {name}''',
      fixCode: r'''Console.WriteLine($"Name: {name}");  // Name: Ana''',
      practice: 'Store a product name, price and quantity, and print the total with two decimals.',
      refs: [Ref('The C# type system', _ms, '$_learn/fundamentals/types/', version: _v)],
      keywords: ['int', 'double', 'bool', 'string', 'interpolation', 'F2'],
    ),
    Lesson(
      id: 'cs-io',
      title: 'Input with Console.ReadLine',
      summary: 'Read text, then turn it into numbers.',
      objective: 'Read two scores and print their average.',
      explanation: 'Console.ReadLine() returns the line the user typed, as a string. Turn it into a number with int.Parse or double.Parse. '
          'int.TryParse is safer: it returns false instead of crashing when the text is not a number.',
      syntax: r'''string line = Console.ReadLine();
int n = int.Parse(line);
double d = double.Parse(Console.ReadLine());''',
      syntaxNotes: [
        ('Console.ReadLine()', 'Waits for a line and returns it as a string.'),
        ('double.Parse(text)', 'Text to number (crashes on "abc").'),
        ('Console.Write', 'Prints without a new line, for prompts.'),
      ],
      example: r'''using System;

class Program {
    static void Main() {
        Console.Write("First score: ");
        double a = double.Parse(Console.ReadLine());
        Console.Write("Second score: ");
        double b = double.Parse(Console.ReadLine());
        Console.WriteLine($"Average: {(a + b) / 2}");
    }
}
''',
      input: '80\n91',
      output: 'First score: 80\nSecond score: 91\nAverage: 85.5',
      checks: ['Average: 85.5'],
      lines: ['Each ReadLine reads one line, so each score goes on its own line.', 'The brackets in {(a + b) / 2} make the sum happen before dividing.'],
      mistake: 'Adding two ReadLine results joins the text: "80" + "91" is "8091".',
      mistakeCode: r'''Console.WriteLine(Console.ReadLine() + Console.ReadLine());''',
      fixCode: r'''int a = int.Parse(Console.ReadLine());
int b = int.Parse(Console.ReadLine());
Console.WriteLine(a + b);''',
      practice: 'Read a name and an age and print a greeting with the age next year.',
      refs: [Ref('Console.ReadLine Method', _ms, 'https://learn.microsoft.com/en-us/dotnet/api/system.console.readline', version: '.NET API reference (net-10.0 view); exists in every .NET version')],
      keywords: ['ReadLine', 'Parse', 'TryParse', 'Write', 'input'],
    ),
    Lesson(
      id: 'cs-conditions',
      title: 'Conditions: if and switch',
      summary: 'Choose what runs with if / else if / else and switch.',
      objective: 'Turn a score into a remark, and a day number into a name.',
      explanation: 'if runs a block when its condition is true; only the first true branch of an if / else if chain runs. switch compares one '
          'value against several case labels; each case ends with break.',
      syntax: r'''if (score >= 90) { ... }
else if (score >= 75) { ... }
else { ... }

switch (day) {
    case 1: ...; break;
    default: ...; break;
}''',
      syntaxNotes: [
        ('== != < > <= >=', 'Comparisons; strings can use == in C#.'),
        ('&& / ||', 'And / or.'),
        ('break', 'Ends a switch case (required).'),
      ],
      example: r'''using System;

class Program {
    static void Main() {
        int score = int.Parse(Console.ReadLine());
        if (score >= 90) Console.WriteLine("Excellent");
        else if (score >= 75) Console.WriteLine("Passed");
        else Console.WriteLine("Needs improvement");

        int day = 6;
        switch (day) {
            case 6:
            case 7:
                Console.WriteLine("Weekend");
                break;
            default:
                Console.WriteLine("School day");
                break;
        }
    }
}
''',
      input: '82',
      output: '82\nPassed\nWeekend',
      checks: ['Passed', 'Weekend'],
      lines: ['82 is not >= 90 but is >= 75, so "Passed".', 'case 6 has no code of its own, so it shares case 7\'s.'],
      mistake: 'Leaving out break: C# refuses to compile a case that falls through to the next one.',
      mistakeCode: r'''case 1:
    Console.WriteLine("Monday");
case 2:''',
      fixCode: r'''case 1:
    Console.WriteLine("Monday");
    break;
case 2:''',
      practice: 'Read a month number (1-12) and print its number of days (ignore leap years).',
      refs: [Ref('Selection statements: if, if-else and switch', _ms, '$_learn/language-reference/statements/selection-statements', version: _v)],
      keywords: ['if', 'else', 'switch', 'case', 'break', 'bool'],
    ),
    Lesson(
      id: 'cs-loops',
      title: 'Loops: for, while, foreach',
      summary: 'Repeat code a counted number of times, until a condition, or for each item.',
      objective: 'Sum numbers with for and count down with while.',
      explanation: 'for (start; condition; step) is for counted loops, while (condition) for "until something changes", and foreach visits every '
          'item of an array or list.',
      syntax: r'''for (int i = 1; i <= 5; i++) { ... }
while (n > 0) { ...; n--; }
foreach (int s in scores) { ... }''',
      syntaxNotes: [
        ('i++', 'Adds 1 after every pass.'),
        ('foreach (T x in items)', 'x is each item in turn.'),
        ('break / continue', 'Leave the loop / skip to the next pass.'),
      ],
      example: r'''using System;

class Program {
    static void Main() {
        int total = 0;
        for (int i = 1; i <= 5; i++) {
            total += i;
        }
        Console.WriteLine($"Sum 1..5 = {total}");

        int n = 3;
        while (n > 0) {
            Console.WriteLine($"{n}...");
            n--;
        }
        Console.WriteLine("Go!");
    }
}
''',
      output: 'Sum 1..5 = 15\n3...\n2...\n1...\nGo!',
      lines: ['total += i adds i to the running total.', 'Without n-- the while loop would never end.'],
      mistake: 'Changing a list inside foreach over that same list throws an InvalidOperationException.',
      mistakeCode: r'''foreach (int s in scores) scores.Add(s);''',
      fixCode: r'''for (int i = 0, n = scores.Count; i < n; i++) scores.Add(scores[i]);''',
      practice: 'Print the multiplication table of a number the user types (1 to 10).',
      refs: [Ref('Iteration statements: for, foreach, do and while', _ms, '$_learn/language-reference/statements/iteration-statements', version: _v)],
      keywords: ['for', 'while', 'foreach', 'do', 'loop', 'break', 'continue'],
    ),
    Lesson(
      id: 'cs-methods',
      title: 'Methods',
      summary: 'Name a piece of logic, pass it values, get a result back.',
      objective: 'Write static methods that compute an average and a remark.',
      explanation: 'A method has a return type, a name and parameters. Methods called from Main are static for now. void means the method '
          'returns nothing; other methods must return a value of their type.',
      syntax: r'''static double Average(int a, int b) {
    return (a + b) / 2.0;
}''',
      syntaxNotes: [
        ('static', 'Called on the class itself, so Main can use it directly.'),
        ('double', 'The type of the returned value.'),
        ('return', 'Sends the result back to the caller.'),
      ],
      example: r'''using System;

class Program {
    static double Average(int[] scores) {
        int total = 0;
        foreach (int s in scores) total += s;
        return (double) total / scores.Length;
    }

    static string Remark(double avg) {
        return avg >= 75 ? "passed" : "failed";
    }

    static void Main() {
        int[] ana = { 90, 85, 88 };
        double avg = Average(ana);
        Console.WriteLine($"Ana: {avg:F2} ({Remark(avg)})");
    }
}
''',
      output: 'Ana: 87.67 (passed)',
      lines: ['(double) total makes the division keep its decimals.', 'C# methods are usually named in PascalCase: Average, Remark.'],
      mistake: 'A method that says it returns a value but has a path with no return does not compile.',
      mistakeCode: r'''static string Remark(double avg) {
    if (avg >= 75) return "passed";
}''',
      fixCode: r'''static string Remark(double avg) {
    if (avg >= 75) return "passed";
    return "failed";
}''',
      practice: 'Write static int Max(int a, int b, int c) and call it with three numbers.',
      refs: [Ref('Methods in C#', _ms, '$_learn/methods', version: _v)],
      keywords: ['method', 'static', 'return', 'void', 'parameter'],
    ),
    Lesson(
      id: 'cs-collections',
      title: 'Arrays and List<T>',
      summary: 'Fixed-size arrays and growable lists.',
      objective: 'Collect scores in a List<int> and find the passing ones.',
      explanation: 'An array (int[]) has a fixed size; its size is .Length. A List<int> grows with Add and its size is .Count. Both start at index 0. '
          'List needs using System.Collections.Generic;.',
      syntax: r'''int[] fixedScores = { 90, 72, 85 };
List<int> scores = new List<int>();
scores.Add(90);
scores.Count''',
      syntaxNotes: [
        ('using System.Collections.Generic;', 'Makes List<T> and Dictionary<K,V> available.'),
        ('.Length / .Count', 'Size of an array / of a list.'),
        ('scores[0]', 'The first item.'),
      ],
      example: r'''using System;
using System.Collections.Generic;

class Program {
    static void Main() {
        List<int> scores = new List<int> { 90, 72, 85, 64, 99 };
        scores.Add(77);

        List<int> passed = new List<int>();
        foreach (int s in scores) {
            if (s >= 75) passed.Add(s);
        }
        Console.WriteLine($"Scores: {scores.Count}");
        Console.WriteLine("Passed: " + string.Join(", ", passed));
    }
}
''',
      output: 'Scores: 6\nPassed: 90, 85, 99, 77',
      lines: ['Add puts 77 at the end of the list.', 'string.Join(", ", passed) turns the list into one line of text.'],
      mistake: 'Reading index Count (or Length): the last item is at Count - 1.',
      mistakeCode: r'''int last = scores[scores.Count];''',
      fixCode: r'''int last = scores[scores.Count - 1];''',
      practice: 'Read 5 names into a List<string> and print them in reverse order.',
      refs: [Ref('Collections and Data Structures', _ms, 'https://learn.microsoft.com/en-us/dotnet/standard/collections/', version: '.NET documentation')],
      keywords: ['array', 'List', 'Add', 'Count', 'Length', 'Join', 'Dictionary'],
    ),
    Lesson(
      id: 'cs-classes',
      title: 'Classes and objects',
      summary: 'Your own type: a Student with fields, a constructor and methods.',
      objective: 'Define a Student class and create two objects from it.',
      explanation: 'A class is a blueprint and new makes an object from it. The constructor (a method named like the class) sets the fields; '
          'public members can be used from other classes. Put extra classes in Program.cs next to Program.',
      syntax: r'''class Student {
    public string Name;
    public double Gpa;
    public Student(string name, double gpa) {
        Name = name;
        Gpa = gpa;
    }
}''',
      syntaxNotes: [
        ('public', 'Usable from other classes (members are private by default).'),
        ('Student(...)', 'The constructor, run by new Student(...).'),
        ('new Student("Ana", 1.5)', 'Makes a new object.'),
      ],
      example: r'''using System;

class Student {
    public string Name;
    public double Gpa;

    public Student(string name, double gpa) {
        Name = name;
        Gpa = gpa;
    }

    public bool IsDeansLister() {
        return Gpa <= 1.75;
    }
}

class Program {
    static void Main() {
        Student ana = new Student("Ana", 1.5);
        Student ben = new Student("Ben", 2.25);
        foreach (Student s in new[] { ana, ben }) {
            Console.WriteLine($"{s.Name}: {(s.IsDeansLister() ? "Dean's lister" : "regular")}");
        }
    }
}
''',
      output: "Ana: Dean's lister\nBen: regular",
      lines: ['Each object keeps its own Name and Gpa.', 'new[] { ana, ben } makes a Student array on the spot.'],
      mistake: 'Leaving out public: the field is private and Program cannot read it.',
      mistakeCode: r'''class Student {
    string Name;   // private
}''',
      fixCode: r'''class Student {
    public string Name;
}''',
      practice: 'Add a Book class with Title and Pages, and print which of two books is longer.',
      refs: [Ref('The C# type system: classes', _ms, '$_learn/fundamentals/types/', version: _v)],
      keywords: ['class', 'object', 'new', 'constructor', 'public', 'field'],
    ),
    Lesson(
      id: 'cs-exceptions',
      title: 'Exceptions and TryParse',
      summary: 'Handle bad input without crashing.',
      objective: 'Catch a FormatException, then do the same thing with int.TryParse.',
      explanation: 'When something fails, C# throws an exception. try { } catch (FormatException) { } handles one kind. For user input, '
          'int.TryParse(text, out n) is simpler: it returns false instead of throwing.',
      syntax: r'''try {
    int n = int.Parse(text);
} catch (FormatException) {
    ...
}

if (int.TryParse(text, out int n)) { ... }''',
      syntaxNotes: [
        ('catch (FormatException)', 'Runs only when the text is not a number.'),
        ('out int n', 'TryParse puts the number in n when it succeeds.'),
      ],
      example: r'''using System;

class Program {
    static void Main() {
        try {
            int a = int.Parse("ten");
            Console.WriteLine(a);
        } catch (FormatException) {
            Console.WriteLine("\"ten\" is not a number.");
        }

        while (true) {
            Console.WriteLine("Age:");
            if (int.TryParse(Console.ReadLine(), out int age)) {
                Console.WriteLine($"Next year you will be {age + 1}.");
                break;
            }
            Console.WriteLine("Please type a whole number.");
        }
    }
}
''',
      input: 'abc\n18',
      output: '"ten" is not a number.\nAge:\nabc\nPlease type a whole number.\nAge:\n18\nNext year you will be 19.',
      checks: ['"ten" is not a number.', 'Please type a whole number.', 'Next year you will be 19.'],
      lines: ['int.Parse("ten") throws, so the catch block runs.', 'TryParse("abc") returns false, so the loop asks again.'],
      mistake: 'An empty catch hides the error; the program just carries on with a wrong value.',
      mistakeCode: r'''try { n = int.Parse(text); } catch { }''',
      fixCode: r'''if (!int.TryParse(text, out n)) Console.WriteLine("Please type a whole number.");''',
      practice: 'Divide two numbers typed by the user and catch DivideByZeroException.',
      refs: [Ref('Exceptions and Exception Handling', _ms, '$_learn/fundamentals/exceptions/', version: _v)],
      keywords: ['try', 'catch', 'exception', 'FormatException', 'TryParse', 'DivideByZeroException'],
    ),
  ],
  quiz: [
    Question('Where does a C# console program start?', ['The first line', 'static void Main()', 'class Program', 'using System;'], 1, 'Main is the entry point.'),
    Question('What does using System; give you?', ['Faster code', 'Short names like Console', 'A new class', 'Nothing'], 1,
        'Without it you would write System.Console.'),
    Question('What does Console.ReadLine() return?', ['An int', 'A string', 'A char', 'A double'], 1, 'Always text; parse it for numbers.'),
    Question(r'What prints Total: 5 when a = 2 and b = 3?', [r'"Total: {a + b}"', r'$"Total: {a + b}"', r'$"Total: a + b"', r'"Total: " + a + b'], 1,
        r'Only the $ string evaluates the braces; "Total: " + a + b gives 23.'),
    Question('What does int.TryParse("abc", out n) return?', ['0', 'false', 'An exception', 'null'], 1, 'It returns false instead of throwing.'),
    Question('How do you get the number of items in a List<int> scores?', ['scores.Length', 'scores.Count', 'scores.Size()', 'len(scores)'], 1,
        'Lists use Count, arrays use Length.'),
    Question('What must every switch case end with (unless it is empty)?', ['continue', 'break (or return)', 'end', 'Nothing'], 1,
        'C# does not allow falling through to the next case.'),
    Question('A field without public is...', ['public', 'private', 'static', 'read-only'], 1, 'Class members are private by default.'),
    Question('What does (double) 7 / 2 give?', ['3', '3.5', '4', '3.0'], 1, 'The cast turns it into a decimal division.'),
    Question('Which loop visits every item of a list without an index?', ['for', 'while', 'foreach', 'do'], 2, 'foreach (var x in list).'),
  ],
  exercises: [
    Exercise(
      id: 'cs-ex-temp',
      level: 'Beginner',
      title: 'Celsius to Fahrenheit',
      task: 'Read a temperature in Celsius and print "Fahrenheit: " and the value with one decimal (F = C × 9 / 5 + 32).',
      starter: r'''using System;

class Program {
    static void Main() {
        double c = double.Parse(Console.ReadLine());
        // convert and print
    }
}
''',
      requirements: ['Read one number.', 'Print Fahrenheit: and the result with 1 decimal (F1).'],
      cases: [
        TestCase(input: '100', expect: ['Fahrenheit: 212.0'], note: 'boiling'),
        TestCase(input: '0', expect: ['Fahrenheit: 32.0'], note: 'freezing'),
        TestCase(input: '36.6', expect: ['Fahrenheit: 97.9'], note: 'decimal'),
      ],
      criteria: 'All three tests pass.',
      hint: r'Use 9.0 / 5 so the division keeps decimals, and {f:F1} to show one decimal.',
      solution: r'''using System;

class Program {
    static void Main() {
        double c = double.Parse(Console.ReadLine());
        double f = c * 9.0 / 5 + 32;
        Console.WriteLine($"Fahrenheit: {f:F1}");
    }
}
''',
    ),
    Exercise(
      id: 'cs-ex-list',
      level: 'Intermediate',
      title: 'Above the average',
      task: 'Read numbers, one per line, until a line says "done". Print "Average: " with two decimals and then "Above: " followed by how many '
          'numbers are above the average. With no numbers, print "No numbers".',
      starter: r'''using System;
using System.Collections.Generic;

class Program {
    static void Main() {
        List<double> nums = new List<double>();
        // read until "done"
    }
}
''',
      requirements: ['Use a List to store the numbers.', 'Stop at the line done.', 'Handle the case with no numbers.'],
      cases: [
        TestCase(input: '70\n80\n90\ndone', expect: ['Average: 80.00', 'Above: 1'], note: 'three numbers'),
        TestCase(input: '5\n5\ndone', expect: ['Average: 5.00', 'Above: 0'], note: 'all equal'),
        TestCase(input: 'done', expect: ['No numbers'], note: 'no numbers'),
      ],
      criteria: 'All three tests pass.',
      hint: 'Loop with while (true), read a line, break when it is "done", otherwise Add double.Parse(line).',
      solution: r'''using System;
using System.Collections.Generic;

class Program {
    static void Main() {
        List<double> nums = new List<double>();
        while (true) {
            string line = Console.ReadLine();
            if (line == null || line.Trim() == "done") break;
            nums.Add(double.Parse(line));
        }
        if (nums.Count == 0) {
            Console.WriteLine("No numbers");
            return;
        }
        double total = 0;
        foreach (double n in nums) total += n;
        double avg = total / nums.Count;
        int above = 0;
        foreach (double n in nums) if (n > avg) above++;
        Console.WriteLine($"Average: {avg:F2}");
        Console.WriteLine($"Above: {above}");
    }
}
''',
    ),
    Exercise(
      id: 'cs-ex-inventory',
      level: 'Challenge',
      title: 'Inventory with a class',
      task: 'Write a class Item with Name, Price and Qty. Read lines "name price qty" until "end". Print each item as "name: total" '
          '(price × qty, two decimals), then "Grand total: " with two decimals. Skip lines that do not have three parts and print "Skipped: " and the line.',
      starter: r'''using System;
using System.Collections.Generic;

class Item {
    // Name, Price, Qty
}

class Program {
    static void Main() {
        // read items until "end"
    }
}
''',
      requirements: ['An Item class with a Total() method.', 'Bad lines are skipped with a message.', 'Totals show two decimals.'],
      cases: [
        TestCase(input: 'pen 12.50 4\nnotebook 45 2\nend', expect: ['pen: 50.00', 'notebook: 90.00', 'Grand total: 140.00'], note: 'two items'),
        TestCase(input: 'eraser 5\nruler 20 1\nend', expect: ['Skipped: eraser 5', 'ruler: 20.00', 'Grand total: 20.00'], note: 'a bad line'),
        TestCase(input: 'end', expect: ['Grand total: 0.00'], note: 'nothing'),
      ],
      criteria: 'All three tests pass and Item is its own class.',
      hint: r"Split each line with line.Split(' '); a good line gives 3 parts.",
      solution: r'''using System;
using System.Collections.Generic;

class Item {
    public string Name;
    public double Price;
    public int Qty;

    public Item(string name, double price, int qty) {
        Name = name;
        Price = price;
        Qty = qty;
    }

    public double Total() {
        return Price * Qty;
    }
}

class Program {
    static void Main() {
        List<Item> items = new List<Item>();
        while (true) {
            string line = Console.ReadLine();
            if (line == null || line.Trim() == "end") break;
            string[] parts = line.Trim().Split(' ');
            if (parts.Length != 3) {
                Console.WriteLine($"Skipped: {line.Trim()}");
                continue;
            }
            items.Add(new Item(parts[0], double.Parse(parts[1]), int.Parse(parts[2])));
        }
        double grand = 0;
        foreach (Item it in items) {
            Console.WriteLine($"{it.Name}: {it.Total():F2}");
            grand += it.Total();
        }
        Console.WriteLine($"Grand total: {grand:F2}");
    }
}
''',
    ),
  ],
);
