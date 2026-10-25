import '../model.dart';

const _dev = 'Dev.java (Oracle)';
const _v = 'Java 8 language level on phones (ecj), Java 21 on the lab PCs';

const javaTrack = Track(
  langId: 'java',
  title: 'Java',
  intro: 'Java organises programs into classes and objects. In NEXUS every program lives in Main.java with a class called Main. '
      'The lessons use Java 8 syntax, which both NEXUS runtimes accept: the PC\'s JDK 21 and the phone\'s ecj compiler '
      '(newer features such as var, records and text blocks are left out on purpose).',
  runtime: 'Lab PC: JDK 21 runs Main.java directly. Phone: ecj compiles Main.java at Java 8 level and Android\'s own Java engine runs it.',
  run: [
    'Open the Java tile (or press Try in Editor to open a practice copy).',
    'Keep the class named Main: the file is Main.java.',
    'Press Run. NEXUS compiles and runs it; type any input under the terminal and press Enter.',
  ],
  lessons: [
    Lesson(
      id: 'java-structure',
      title: 'Class and main method',
      summary: 'Every Java program is a class with a main method where it starts.',
      objective: 'Write and run a Main class that prints two lines.',
      explanation: 'Java code lives inside a class. The class in Main.java must be called Main. The program starts in the main method, '
          'which always looks the same: public static void main(String[] args). System.out.println prints a line.',
      syntax: r'''public class Main {
    public static void main(String[] args) {
        // statements
    }
}''',
      syntaxNotes: [
        ('public class Main', 'The class; its name must match the file name Main.java.'),
        ('public static void main(String[] args)', 'Where the program starts.'),
        ('System.out.println(...)', 'Prints a value and moves to a new line.'),
      ],
      example: r'''public class Main {
    public static void main(String[] args) {
        System.out.println("Hello, CTU Naga!");
        System.out.println("Java runs here too.");
    }
}
''',
      output: 'Hello, CTU Naga!\nJava runs here too.',
      lines: ['The two println calls run in order.', 'Each statement ends with a semicolon.'],
      mistake: 'Naming the class differently from the file. Java needs class Main in Main.java.',
      mistakeCode: r'''public class Hello {''',
      fixCode: r'''public class Main {''',
      practice: 'Print your name, course and favourite subject on three lines.',
      refs: [Ref('Getting Started with Java', _dev, 'https://dev.java/learn/first-steps/first-java-code/getting-started/', version: _v)],
      keywords: ['class', 'main', 'println', 'System.out'],
    ),
    Lesson(
      id: 'java-variables',
      title: 'Variables and types',
      summary: 'int, double, boolean, char and String.',
      objective: 'Declare variables of the common types and print them together.',
      explanation: 'Every Java variable has a type, written before its name. int is a whole number, double a decimal, boolean is true/false, '
          'char a single character and String is text. You can join text and values with +.',
      syntax: r'''int age = 18;
double gpa = 1.75;
boolean enrolled = true;
String name = "Ana";''',
      syntaxNotes: [
        ('int / double', 'Whole numbers / decimal numbers.'),
        ('String', 'Text in double quotes (capital S).'),
        ('"Age: " + age', '+ joins text with a value.'),
        ('String.format("%.2f", x)', 'Text with x shown to 2 decimals.'),
      ],
      example: r'''public class Main {
    public static void main(String[] args) {
        String name = "Ana";
        int age = 18;
        double gpa = 1.754;
        boolean enrolled = true;

        System.out.println("Name: " + name);
        System.out.println("Age next year: " + (age + 1));
        System.out.println("GPA: " + String.format("%.2f", gpa));
        System.out.println("Enrolled: " + enrolled);
    }
}
''',
      output: 'Name: Ana\nAge next year: 19\nGPA: 1.75\nEnrolled: true',
      lines: [
        '(age + 1) needs brackets; without them "Age next year: " + age + 1 joins "18" and "1" as text.',
        'String.format("%.2f", gpa) rounds 1.754 to "1.75".',
      ],
      mistake: 'Adding numbers after text without brackets joins them as text.',
      mistakeCode: r'''System.out.println("Total: " + 2 + 3);  // Total: 23''',
      fixCode: r'''System.out.println("Total: " + (2 + 3));  // Total: 5''',
      practice: 'Store a product name, price and quantity, and print the total price with two decimals.',
      refs: [
        Ref('Creating Variables and Naming Them', _dev, 'https://dev.java/learn/language/constructs/basics/variables/', version: _v),
      ],
      keywords: ['int', 'double', 'boolean', 'char', 'String', 'format'],
    ),
    Lesson(
      id: 'java-io',
      title: 'Input with Scanner',
      summary: 'Read numbers and words the user types.',
      objective: 'Read two scores with Scanner and print their average.',
      explanation: 'Scanner reads what the user types. Create one at the start of main, then call nextInt(), nextDouble(), next() (one word) '
          'or nextLine() (a whole line). It needs import java.util.Scanner; at the top of the file.',
      syntax: r'''import java.util.Scanner;
Scanner in = new Scanner(System.in);
int n = in.nextInt();
double d = in.nextDouble();''',
      syntaxNotes: [
        ('import java.util.Scanner;', 'Makes the Scanner class available.'),
        ('new Scanner(System.in)', 'A Scanner that reads the keyboard (the terminal).'),
        ('nextDouble()', 'Reads the next number.'),
      ],
      example: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        System.out.print("First score: ");
        double a = in.nextDouble();
        System.out.print("Second score: ");
        double b = in.nextDouble();
        System.out.println("Average: " + (a + b) / 2);
    }
}
''',
      input: '80\n91',
      output: 'First score: 80\nSecond score: 91\nAverage: 85.5',
      checks: ['Average: 85.5'],
      lines: [
        'System.out.print (no ln) keeps the typing on the same line as the prompt.',
        'in.nextDouble() waits for a number and returns it.',
      ],
      mistake: 'Calling nextLine() right after nextInt() reads the rest of the number\'s line (an empty string).',
      mistakeCode: r'''int age = in.nextInt();
String name = in.nextLine();  // empty!''',
      fixCode: r'''int age = in.nextInt();
in.nextLine();                // skip the rest of that line
String name = in.nextLine();''',
      practice: 'Read a name (nextLine) and an age (nextInt) and print a greeting with the age next year.',
      refs: [Ref('Class Scanner (Java SE 21 API)', 'Oracle', 'https://docs.oracle.com/en/java/javase/21/docs/api/java.base/java/util/Scanner.html', version: 'Java SE 21; the methods used here exist since Java 5')],
      keywords: ['Scanner', 'nextInt', 'nextDouble', 'nextLine', 'next', 'import', 'input'],
    ),
    Lesson(
      id: 'java-conditions',
      title: 'Conditions: if, else if, else',
      summary: 'Run different code depending on a value.',
      objective: 'Turn a score into a remark with if, else if and else.',
      explanation: 'if checks a boolean condition. Only the first true branch runs. Compare numbers with ==, !=, <, >, <=, >= and join conditions '
          'with && (and), || (or). Compare Strings with .equals(), not ==.',
      syntax: r'''if (score >= 90) {
    ...
} else if (score >= 75) {
    ...
} else {
    ...
}''',
      syntaxNotes: [
        ('==', 'Equal (numbers, chars, booleans).'),
        ('a.equals(b)', 'Same text (Strings).'),
        ('&& / ||', 'And / or.'),
      ],
      example: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        int score = in.nextInt();
        if (score >= 90) {
            System.out.println("Excellent");
        } else if (score >= 75) {
            System.out.println("Passed");
        } else {
            System.out.println("Needs improvement");
        }
    }
}
''',
      input: '74',
      output: '74\nNeeds improvement',
      checks: ['Needs improvement'],
      lines: ['74 >= 90 and 74 >= 75 are both false, so the else branch runs.'],
      mistake: 'Comparing Strings with == checks whether they are the same object, not the same text.',
      mistakeCode: r'''if (answer == "yes")''',
      fixCode: r'''if (answer.equals("yes"))''',
      practice: 'Read a year and print whether it is a leap year (divisible by 4, but not by 100 unless also by 400).',
      refs: [Ref('Control Flow Statements', _dev, 'https://dev.java/learn/language/constructs/basics/controlling-flow/', version: _v)],
      keywords: ['if', 'else', 'equals', '&&', '||', 'boolean'],
    ),
    Lesson(
      id: 'java-loops',
      title: 'Loops: for and while',
      summary: 'Repeat code a counted number of times or until a condition changes.',
      objective: 'Sum numbers with for and count down with while.',
      explanation: 'for (start; condition; step) repeats while the condition holds. while (condition) repeats until the condition becomes false. '
          'Inside, i++ adds one and i-- subtracts one.',
      syntax: r'''for (int i = 1; i <= 5; i++) { ... }
while (n > 0) { ...; n--; }''',
      syntaxNotes: [
        ('int i = 1', 'Runs once, before the loop.'),
        ('i <= 5', 'Checked before every pass.'),
        ('i++', 'Runs after every pass.'),
      ],
      example: r'''public class Main {
    public static void main(String[] args) {
        int total = 0;
        for (int i = 1; i <= 5; i++) {
            total += i;
        }
        System.out.println("Sum 1..5 = " + total);

        int n = 3;
        while (n > 0) {
            System.out.println(n + "...");
            n--;
        }
        System.out.println("Go!");
    }
}
''',
      output: 'Sum 1..5 = 15\n3...\n2...\n1...\nGo!',
      lines: ['The for loop runs 5 times, adding 1 to 5.', 'n-- moves the while loop toward its end.'],
      mistake: 'A semicolon right after for (...) makes the loop body empty.',
      mistakeCode: r'''for (int i = 0; i < 3; i++); {
    System.out.println(i);
}''',
      fixCode: r'''for (int i = 0; i < 3; i++) {
    System.out.println(i);
}''',
      practice: 'Print the squares of 1 to 10 (1, 4, 9, ...).',
      refs: [Ref('Control Flow Statements', _dev, 'https://dev.java/learn/language/constructs/basics/controlling-flow/', version: _v)],
      keywords: ['for', 'while', 'loop', 'i++', 'break'],
    ),
    Lesson(
      id: 'java-methods',
      title: 'Methods',
      summary: 'Name a piece of logic, give it parameters, return a result.',
      objective: 'Write a static method that computes an average and call it from main.',
      explanation: 'A method is a named block of code inside a class. For now, write them as static so main can call them directly. '
          'The return type comes before the name (void means nothing is returned) and the parameters go in brackets.',
      syntax: r'''static double average(int a, int b) {
    return (a + b) / 2.0;
}''',
      syntaxNotes: [
        ('static', 'Belongs to the class, so main can call it without an object.'),
        ('double', 'The type of value it returns.'),
        ('return', 'Sends the result back.'),
      ],
      example: r'''public class Main {
    static double average(int[] scores) {
        int total = 0;
        for (int s : scores) {
            total += s;
        }
        return (double) total / scores.length;
    }

    static String remark(double avg) {
        return avg >= 75 ? "passed" : "failed";
    }

    public static void main(String[] args) {
        int[] ana = {90, 85, 88};
        double avg = average(ana);
        System.out.println(String.format("Ana: %.2f (%s)", avg, remark(avg)));
    }
}
''',
      output: 'Ana: 87.67 (passed)',
      lines: [
        '(double) total turns the sum into a double so the division keeps decimals.',
        'condition ? a : b picks a when the condition is true, otherwise b.',
      ],
      mistake: 'Integer division: 5 / 2 is 2 when both are int.',
      mistakeCode: r'''return total / scores.length;''',
      fixCode: r'''return (double) total / scores.length;''',
      practice: 'Write static int max(int a, int b, int c) and test it.',
      refs: [Ref('Defining Methods', _dev, 'https://dev.java/learn/language/oop/classes-objects/defining-methods/', version: _v)],
      keywords: ['method', 'static', 'return', 'void', 'parameter', 'ternary'],
    ),
    Lesson(
      id: 'java-arrays',
      title: 'Arrays',
      summary: 'A fixed-size list of values of one type.',
      objective: 'Count passing scores in an array and find the highest.',
      explanation: 'An array holds a fixed number of values of the same type. Its length is in .length and positions start at 0. '
          'The enhanced for loop (for (int s : scores)) visits every value without an index.',
      syntax: r'''int[] scores = {90, 72, 85};
scores[0]        // 90
scores.length    // 3
for (int s : scores) { ... }''',
      syntaxNotes: [
        ('int[]', 'An array of ints.'),
        ('scores.length', 'How many values (no brackets).'),
        ('for (int s : scores)', 'Visits each value in order.'),
      ],
      example: r'''public class Main {
    public static void main(String[] args) {
        int[] scores = {90, 72, 85, 64, 99};
        int passed = 0, highest = scores[0];
        for (int s : scores) {
            if (s >= 75) passed++;
            if (s > highest) highest = s;
        }
        System.out.println("Passed: " + passed + " of " + scores.length);
        System.out.println("Highest: " + highest);
    }
}
''',
      output: 'Passed: 3 of 5\nHighest: 99',
      lines: ['highest starts at the first score and is replaced whenever a bigger one appears.'],
      mistake: 'Using index scores.length: the last index is length - 1.',
      mistakeCode: r'''int last = scores[scores.length];''',
      fixCode: r'''int last = scores[scores.length - 1];''',
      practice: 'Print the scores in reverse order with a normal for loop.',
      refs: [Ref('Creating Arrays in Your Programs', _dev, 'https://dev.java/learn/language/constructs/basics/arrays/', version: _v)],
      keywords: ['array', 'length', 'index', 'for-each'],
    ),
    Lesson(
      id: 'java-objects',
      title: 'Classes and objects',
      summary: 'Make your own type: a Student with fields, a constructor and methods.',
      objective: 'Define a Student class and create two Student objects.',
      explanation: 'A class is a blueprint; objects are made from it with new. Fields store each object\'s data, the constructor sets them up, '
          'and methods use them. In NEXUS put extra classes in Main.java after class Main, without the word public (the lab PC runs the first class in the file).',
      syntax: r'''class Student {
    String name;
    double gpa;
    Student(String name, double gpa) {
        this.name = name;
        this.gpa = gpa;
    }
}
Student s = new Student("Ana", 1.5);''',
      syntaxNotes: [
        ('class Student', 'A new type (no public: only Main can be public in Main.java).'),
        ('Student(...)', 'The constructor: runs when you write new Student(...).'),
        ('this.name', 'This object\'s field, as opposed to the parameter called name.'),
      ],
      example: r'''public class Main {
    public static void main(String[] args) {
        Student ana = new Student("Ana", 1.5);
        Student ben = new Student("Ben", 2.25);
        System.out.println(ana.profile());
        System.out.println(ben.profile());
    }
}

class Student {
    String name;
    double gpa;

    Student(String name, double gpa) {
        this.name = name;
        this.gpa = gpa;
    }

    boolean isDeansLister() {
        return gpa <= 1.75;
    }

    String profile() {
        return name + " (GPA " + gpa + ")" + (isDeansLister() ? " - Dean's lister" : "");
    }
}
''',
      output: "Ana (GPA 1.5) - Dean's lister\nBen (GPA 2.25)",
      lines: [
        'new Student("Ana", 1.5) calls the constructor, which stores the values in the fields.',
        'Each object keeps its own name and gpa.',
        'profile() calls isDeansLister() on the same object.',
      ],
      mistake: 'Forgetting this. in the constructor: the parameter is assigned to itself and the field stays empty.',
      mistakeCode: r'''Student(String name) {
    name = name;
}''',
      fixCode: r'''Student(String name) {
    this.name = name;
}''',
      practice: 'Add a Book class with title and pages, and print which of two books is longer.',
      refs: [Ref('Classes and Objects', _dev, 'https://dev.java/learn/language/oop/classes-objects/', version: _v)],
      keywords: ['class', 'object', 'new', 'constructor', 'this', 'field'],
    ),
    Lesson(
      id: 'java-exceptions',
      title: 'Exceptions',
      summary: 'Catch errors such as letters typed where a number was expected.',
      objective: 'Catch an exception from bad input and keep the program running.',
      explanation: 'When something goes wrong, Java throws an exception. try runs code that might fail; catch handles a specific exception type. '
          'Integer.parseInt throws NumberFormatException when the text is not a number.',
      syntax: r'''try {
    risky code
} catch (NumberFormatException e) {
    what to do instead
}''',
      syntaxNotes: [
        ('try { }', 'Code that might throw.'),
        ('catch (Type e)', 'Runs only for that exception type.'),
        ('Integer.parseInt(s)', 'Turns text into an int, or throws NumberFormatException.'),
      ],
      example: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        while (true) {
            System.out.println("Age:");
            String text = in.nextLine();
            try {
                int age = Integer.parseInt(text.trim());
                System.out.println("Next year you will be " + (age + 1) + ".");
                break;
            } catch (NumberFormatException e) {
                System.out.println("Please type a whole number.");
            }
        }
    }
}
''',
      input: 'eighteen\n18',
      output: 'Age:\neighteen\nPlease type a whole number.\nAge:\n18\nNext year you will be 19.',
      checks: ['Please type a whole number.', 'Next year you will be 19.'],
      lines: ['parseInt("eighteen") throws, so the catch block prints the message and the loop asks again.'],
      mistake: 'Catching Exception for everything hides real bugs. Catch the specific type you expect.',
      mistakeCode: r'''catch (Exception e) { }''',
      fixCode: r'''catch (NumberFormatException e) {
    System.out.println("Please type a whole number.");
}''',
      practice: 'Divide two numbers typed by the user and catch ArithmeticException when dividing ints by zero.',
      refs: [Ref('Exceptions', _dev, 'https://dev.java/learn/language/annotations-exceptions/exceptions/', version: _v)],
      keywords: ['try', 'catch', 'exception', 'NumberFormatException', 'parseInt', 'ArithmeticException'],
    ),
  ],
  quiz: [
    Question('In NEXUS, what must the class in Main.java be called?', ['Program', 'Main', 'App', 'Anything'], 1, 'Java requires the public class to match the file name.'),
    Question('Which line starts a Java program?', ['public void start()', 'public static void main(String[] args)', 'static main()', 'void run()'], 1,
        'The JVM looks for exactly this main method.'),
    Question('What prints "Total: 5"?', ['"Total: " + 2 + 3', '"Total: " + (2 + 3)', '"Total: " - 5', 'Total: + 5'], 1, 'Brackets make the math happen first.'),
    Question('Which Scanner method reads a whole line?', ['next()', 'nextLine()', 'readLine()', 'line()'], 1, 'next() reads one word; nextLine() the whole line.'),
    Question('How do you compare two Strings a and b?', ['a == b', 'a.equals(b)', 'a = b', 'compare(a, b)'], 1, '== compares objects, equals compares text.'),
    Question('How many values does an array int[] x = new int[4] hold?', ['3', '4', '5', 'Unlimited'], 1, 'Fixed at 4; indexes 0 to 3.'),
    Question('What does a void method return?', ['0', 'null', 'Nothing', 'An empty String'], 2, 'void means no return value.'),
    Question('What does new Student("Ana", 1.5) call?', ['main', 'The constructor', 'toString', 'A static method'], 1, 'new runs the constructor.'),
    Question('What does Integer.parseInt("abc") do?', ['Returns 0', 'Returns -1', 'Throws NumberFormatException', 'Returns null'], 2,
        'The text is not a number.'),
    Question('What is printed by (double) 7 / 2?', ['3', '3.5', '4', '3.0'], 1, 'The cast makes it a double division.'),
  ],
  exercises: [
    Exercise(
      id: 'java-ex-max',
      level: 'Beginner',
      title: 'Bigger of two',
      task: 'Read two whole numbers and print "Max: " followed by the bigger one.',
      starter: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        int a = in.nextInt();
        int b = in.nextInt();
        // print the bigger one
    }
}
''',
      requirements: ['Read both numbers with Scanner.', 'Print Max: and the bigger value.', 'Equal numbers print that number.'],
      cases: [
        TestCase(input: '3 9', expect: ['Max: 9'], note: 'second is bigger'),
        TestCase(input: '12 5', expect: ['Max: 12'], note: 'first is bigger'),
        TestCase(input: '-4 -4', expect: ['Max: -4'], note: 'equal, negative'),
      ],
      criteria: 'All three tests pass.',
      hint: 'Use if (a > b) or Math.max(a, b).',
      solution: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        int a = in.nextInt();
        int b = in.nextInt();
        System.out.println("Max: " + Math.max(a, b));
    }
}
''',
    ),
    Exercise(
      id: 'java-ex-grades',
      level: 'Intermediate',
      title: 'Grade counter',
      task: 'Read n, then n scores. Print how many are 90 and up ("A: "), 75 to 89 ("B: ") and below 75 ("C: "), each on its own line in that order.',
      starter: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        int n = in.nextInt();
        // read n scores and count them
    }
}
''',
      requirements: ['Use a loop to read the n scores.', 'Print A:, B: and C: lines in that order.', 'n can be 0 (all counts 0).'],
      cases: [
        TestCase(input: '5\n95 80 60 90 75', expect: ['A: 2', 'B: 2', 'C: 1'], note: 'mixed, includes 90 and 75'),
        TestCase(input: '0', expect: ['A: 0', 'B: 0', 'C: 0'], note: 'no scores'),
        TestCase(input: '3\n74 89 100', expect: ['A: 1', 'B: 1', 'C: 1'], note: 'edges 74 and 89'),
      ],
      criteria: 'All three tests pass.',
      hint: 'Keep three counters and use if / else if / else on each score.',
      solution: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        int n = in.nextInt();
        int a = 0, b = 0, c = 0;
        for (int i = 0; i < n; i++) {
            int s = in.nextInt();
            if (s >= 90) a++;
            else if (s >= 75) b++;
            else c++;
        }
        System.out.println("A: " + a);
        System.out.println("B: " + b);
        System.out.println("C: " + c);
    }
}
''',
    ),
    Exercise(
      id: 'java-ex-account',
      level: 'Challenge',
      title: 'Bank account object',
      task: 'Write a class Account with a balance, deposit(amount) and withdraw(amount) that refuses to go below 0. '
          'main reads lines like "D 500" or "W 200" until "END", then prints "Balance: " and the final balance. '
          'A refused withdrawal prints "Insufficient funds".',
      starter: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        // read commands until END
    }
}

class Account {
    // balance, deposit, withdraw
}
''',
      requirements: ['An Account class with deposit and withdraw methods.', 'withdraw prints Insufficient funds and changes nothing if the amount is too big.', 'Print Balance: at the end.'],
      cases: [
        TestCase(input: 'D 500\nW 200\nEND', expect: ['Balance: 300'], note: 'deposit then withdraw'),
        TestCase(input: 'D 100\nW 150\nEND', expect: ['Insufficient funds', 'Balance: 100'], note: 'refused withdrawal'),
        TestCase(input: 'END', expect: ['Balance: 0'], note: 'no commands'),
      ],
      criteria: 'All three tests pass and Account is a separate class.',
      hint: 'Read with in.next() for the letter and in.nextInt() for the amount; stop when the letter is END.',
      solution: r'''import java.util.Scanner;

public class Main {
    public static void main(String[] args) {
        Scanner in = new Scanner(System.in);
        Account acc = new Account();
        while (true) {
            String cmd = in.next();
            if (cmd.equals("END")) break;
            int amount = in.nextInt();
            if (cmd.equals("D")) acc.deposit(amount);
            else if (cmd.equals("W")) acc.withdraw(amount);
        }
        System.out.println("Balance: " + acc.getBalance());
    }
}

class Account {
    private int balance = 0;

    void deposit(int amount) {
        balance += amount;
    }

    void withdraw(int amount) {
        if (amount > balance) {
            System.out.println("Insufficient funds");
        } else {
            balance -= amount;
        }
    }

    int getBalance() {
        return balance;
    }
}
''',
    ),
  ],
);
