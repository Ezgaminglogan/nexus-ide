import '../model.dart';

const _gnu = 'GNU C Language Manual (GNU C Intro and Reference)';
const _fsf = 'Free Software Foundation';
const _base = 'https://www.gnu.org/software/c-intro-and-ref/manual/html_node';
const _glibc = 'https://sourceware.org/glibc/manual/latest/html_node';

const cTrack = Track(
  langId: 'c',
  title: 'C',
  intro: 'C is where most programming courses start: you tell the computer exactly what to store and what to do, step by step. '
      'These lessons use standard C that both NEXUS compilers accept: GCC on the lab PCs and TCC on phones. '
      'The GNU manual also describes GCC-only extensions; the lessons avoid them so your code runs everywhere.',
  runtime: 'Lab PC: GCC (MinGW-w64, bundled). Phone: TCC (bundled). Both compile your main.c and then run it.',
  run: [
    'Open the C tile (or press Try in Editor to open a practice copy).',
    'Press Run. NEXUS compiles main.c, then runs it.',
    'If the program asks for input, type it in the box under the terminal and press Enter.',
  ],
  lessons: [
    Lesson(
      id: 'c-structure',
      title: 'Program structure',
      summary: 'What every C program needs: an include line and a main function.',
      objective: 'Write, run and read a complete C program that prints a message.',
      explanation: 'A C program is a list of instructions inside a function called main. When you press Run, the computer starts at the first '
          'line inside main and goes down one statement at a time. Most statements end with a semicolon. '
          'The #include line at the top brings in the standard input/output tools, such as printf, so your program can show text.',
      syntax: r'''#include <stdio.h>

int main(void) {
    /* your statements go here */
    return 0;
}''',
      syntaxNotes: [
        ('#include <stdio.h>', 'Adds the standard input/output library (printf, scanf, puts).'),
        ('int main(void)', 'The function where the program starts. "int" means it gives back a number when it ends.'),
        ('{ ... }', 'Braces group the statements that belong to main.'),
        ('return 0;', 'Ends main and tells the system the program finished without errors.'),
      ],
      example: r'''#include <stdio.h>

int main(void) {
    printf("Hello, CTU Naga!\n");
    printf("I am learning C.\n");
    return 0;
}
''',
      output: 'Hello, CTU Naga!\nI am learning C.',
      lines: [
        'printf("Hello, CTU Naga!\\n"); prints the text between the quotes. \\n moves to a new line.',
        'The two printf lines run in order, top to bottom.',
        'return 0; ends the program.',
      ],
      mistake: 'Forgetting the semicolon at the end of a statement. The compiler stops and points at the next line.',
      mistakeCode: r'''printf("Hello")
return 0;''',
      fixCode: r'''printf("Hello");
return 0;''',
      practice: 'Change the program so it prints your full name on one line and your course on the next.',
      refs: [
        Ref('Complete Program', _gnu, '$_base/Complete-Program.html', version: 'GNU C manual (current), GCC 16 / TCC 0.9'),
        Ref('GNU C Intro and Reference (describes GNU C, which is standard C plus GCC extensions)', _fsf, 'https://www.gnu.org/software/c-intro-and-ref/'),
      ],
      keywords: ['main', 'include', 'stdio.h', 'printf', 'return', 'semicolon'],
    ),
    Lesson(
      id: 'c-variables',
      title: 'Variables and types',
      summary: 'Store numbers and letters in named boxes: int, double and char.',
      objective: 'Declare int, double and char variables, give them values and print them.',
      explanation: 'A variable is a named place in memory that holds one value. In C you must say what type of value it holds before you use it. '
          'int holds whole numbers (like 18), double holds numbers with a decimal point (like 1.75), and char holds one character (like \'A\'). '
          'printf uses a placeholder for each value: %d for int, %f for double (%.2f for two decimals) and %c for char.',
      syntax: r'''type name = value;
int age = 18;
double height = 1.75;
char section = 'A';''',
      syntaxNotes: [
        ('int', 'Whole numbers: -3, 0, 42.'),
        ('double', 'Numbers with a decimal part: 85.5, 1.75.'),
        ('char', 'A single character in single quotes: \'A\'.'),
        ('%d  %.2f  %c', 'printf placeholders for int, double (2 decimals) and char.'),
      ],
      example: r'''#include <stdio.h>

int main(void) {
    int age = 18;
    double height = 1.75;
    char section = 'A';

    printf("Age: %d\n", age);
    printf("Height: %.2f m\n", height);
    printf("Section: %c\n", section);

    age = age + 1;  /* a variable can change */
    printf("Next year: %d\n", age);
    return 0;
}
''',
      output: 'Age: 18\nHeight: 1.75 m\nSection: A\nNext year: 19',
      lines: [
        'int age = 18; creates a whole-number variable named age that starts at 18.',
        '%.2f prints the double with exactly two digits after the point.',
        'age = age + 1; reads age (18), adds 1 and stores 19 back in age.',
      ],
      mistake: 'Using the wrong placeholder: %d for a double prints a wrong number.',
      mistakeCode: r'''double price = 9.50;
printf("%d\n", price);''',
      fixCode: r'''double price = 9.50;
printf("%.2f\n", price);''',
      practice: 'Make variables for a student\'s ID number (int), GPA (double) and year level letter (char), then print all three.',
      refs: [
        Ref('Variable Declarations', _gnu, '$_base/Variable-Declarations.html'),
        Ref('Formatted Output (printf)', 'GNU C Library manual', '$_glibc/Formatted-Output.html'),
      ],
      keywords: ['int', 'double', 'char', 'float', '%d', '%f', '%c', 'assignment'],
    ),
    Lesson(
      id: 'c-io',
      title: 'Input and output',
      summary: 'Read numbers with scanf and print results with printf.',
      objective: 'Read two numbers typed by the user and print their average.',
      explanation: 'scanf reads what the user types. Like printf it uses placeholders, but each variable needs an & in front so scanf '
          'knows where to store the value. For a double, scanf uses %lf. After reading, you can compute with the values and print the result.',
      syntax: r'''scanf("%d", &whole);
scanf("%lf", &decimal);''',
      syntaxNotes: [
        ('scanf("%d", &x);', 'Reads a whole number into x.'),
        ('%lf', 'Use %lf (not %f) to read a double with scanf.'),
        ('&x', 'The address of x: where scanf should put the value.'),
      ],
      example: r'''#include <stdio.h>

int main(void) {
    double a, b;
    printf("Enter two scores: ");
    scanf("%lf %lf", &a, &b);
    double average = (a + b) / 2;
    printf("Average: %.1f\n", average);
    return 0;
}
''',
      input: '80 91',
      output: 'Enter two scores: 80 91\nAverage: 85.5',
      checks: ['Average: 85.5'],
      lines: [
        'printf("Enter two scores: "); shows a prompt without a new line, so the typing appears after it.',
        'scanf("%lf %lf", &a, &b); reads two decimal numbers separated by a space or Enter.',
        '(a + b) / 2 adds first because of the parentheses, then divides.',
      ],
      mistake: 'Forgetting the & in scanf. The program may crash or read nothing.',
      mistakeCode: r'''scanf("%lf", a);''',
      fixCode: r'''scanf("%lf", &a);''',
      practice: 'Read three quiz scores and print their total and their average with one decimal.',
      refs: [
        Ref('Formatted Input (scanf)', 'GNU C Library manual', '$_glibc/Formatted-Input.html'),
        Ref('Formatted Output (printf)', 'GNU C Library manual', '$_glibc/Formatted-Output.html'),
      ],
      keywords: ['scanf', 'printf', '%lf', 'address', '&', 'average', 'input'],
    ),
    Lesson(
      id: 'c-conditions',
      title: 'Conditions: if and else',
      summary: 'Make decisions: run different code depending on a value.',
      objective: 'Use if, else if and else to turn a score into a remark.',
      explanation: 'An if statement checks a condition. If it is true, the block in braces runs; otherwise the program checks the next else if, '
          'and finally the else. Conditions compare values with >, <, >=, <=, == (equal) and != (not equal). '
          'Only the first true branch runs.',
      syntax: r'''if (condition) {
    ...
} else if (other condition) {
    ...
} else {
    ...
}''',
      syntaxNotes: [
        ('>=  <=  ==  !=', 'Compare two values. == checks equality; a single = assigns.'),
        ('&&  ||', 'And / or: (score >= 75 && score <= 100).'),
        ('else if', 'Checked only when the conditions above were false.'),
      ],
      example: r'''#include <stdio.h>

int main(void) {
    int score;
    printf("Enter your score: ");
    scanf("%d", &score);

    if (score >= 90) {
        printf("Excellent\n");
    } else if (score >= 75) {
        printf("Passed\n");
    } else {
        printf("Needs improvement\n");
    }
    return 0;
}
''',
      input: '82',
      output: 'Enter your score: 82\nPassed',
      checks: ['Passed'],
      lines: [
        'score >= 90 is false for 82, so C checks the next condition.',
        'score >= 75 is true, so "Passed" prints and the else part is skipped.',
      ],
      mistake: 'Writing = instead of == in a condition. It assigns the value and the condition is almost always true.',
      mistakeCode: r'''if (score = 100) {''',
      fixCode: r'''if (score == 100) {''',
      practice: 'Read an age and print "Minor" if it is under 18, otherwise "Adult".',
      refs: [Ref('if Statement', _gnu, '$_base/if-Statement.html')],
      keywords: ['if', 'else', 'comparison', '==', '>=', '&&', '||', 'grade'],
    ),
    Lesson(
      id: 'c-loops',
      title: 'Loops: for and while',
      summary: 'Repeat code a set number of times, or while something is true.',
      objective: 'Use a for loop to add up numbers and a while loop to count down.',
      explanation: 'A for loop repeats a block a known number of times. It has three parts: where to start, when to keep going, and how to change '
          'the counter each time. A while loop repeats as long as its condition is true, so something inside must eventually make it false.',
      syntax: r'''for (int i = 1; i <= 5; i++) {
    ...
}
while (condition) {
    ...
}''',
      syntaxNotes: [
        ('int i = 1', 'Start: runs once before the loop.'),
        ('i <= 5', 'Keep looping while this is true.'),
        ('i++', 'After each pass, add 1 to i.'),
      ],
      example: r'''#include <stdio.h>

int main(void) {
    int total = 0;
    for (int i = 1; i <= 5; i++) {
        total = total + i;
    }
    printf("1 + 2 + 3 + 4 + 5 = %d\n", total);

    int seconds = 3;
    while (seconds > 0) {
        printf("%d...\n", seconds);
        seconds--;
    }
    printf("Go!\n");
    return 0;
}
''',
      output: '1 + 2 + 3 + 4 + 5 = 15\n3...\n2...\n1...\nGo!',
      lines: [
        'The for loop runs with i = 1, 2, 3, 4, 5 and adds each one to total.',
        'seconds-- subtracts 1 each pass, so the while loop stops when seconds reaches 0.',
      ],
      mistake: 'A while loop whose condition never becomes false runs forever. Press Stop, then make sure the loop changes its variable.',
      mistakeCode: r'''int n = 3;
while (n > 0) {
    printf("%d\n", n);
}''',
      fixCode: r'''int n = 3;
while (n > 0) {
    printf("%d\n", n);
    n--;
}''',
      practice: 'Print the multiplication table of 7 from 7 x 1 to 7 x 10.',
      refs: [
        Ref('for Statement', _gnu, '$_base/for-Statement.html'),
        Ref('while Statement', _gnu, '$_base/while-Statement.html'),
      ],
      keywords: ['for', 'while', 'loop', 'i++', 'counter', 'sum'],
    ),
    Lesson(
      id: 'c-functions',
      title: 'Functions',
      summary: 'Give a piece of code a name, pass it values, get a result back.',
      objective: 'Write a function that computes an average and call it from main.',
      explanation: 'A function is a named block of code. You give it inputs (parameters), it does its work and can give back one value with return. '
          'Writing a function once lets you use it many times and keeps main short. In C, write the function above main (or declare it there) '
          'so the compiler knows it before main uses it.',
      syntax: r'''return_type name(type param1, type param2) {
    ...
    return value;
}''',
      syntaxNotes: [
        ('double average(int a, int b)', 'A function named average that takes two ints and gives back a double.'),
        ('return', 'Sends the result back to whoever called the function.'),
        ('void', 'A function that gives nothing back uses void as its return type.'),
      ],
      example: r'''#include <stdio.h>

double average(int a, int b, int c) {
    return (a + b + c) / 3.0;
}

void show(char name[], double avg) {
    printf("%s: %.2f\n", name, avg);
}

int main(void) {
    show("Ana", average(90, 85, 88));
    show("Ben", average(70, 75, 80));
    return 0;
}
''',
      output: 'Ana: 87.67\nBen: 75.00',
      lines: [
        'Dividing by 3.0 (not 3) keeps the decimal part; int / int would drop it.',
        'average(90, 85, 88) runs the function and is replaced by its result, 87.666...',
        'show is void: it prints but returns nothing.',
      ],
      mistake: 'Dividing two whole numbers loses the decimals: 5 / 2 is 2 in C.',
      mistakeCode: r'''return (a + b + c) / 3;''',
      fixCode: r'''return (a + b + c) / 3.0;''',
      practice: 'Write a function int max_of(int a, int b) that returns the bigger number, and test it with three pairs.',
      refs: [Ref('Function Definitions', _gnu, '$_base/Function-Definitions.html')],
      keywords: ['function', 'return', 'void', 'parameter', 'argument', 'average'],
    ),
    Lesson(
      id: 'c-arrays',
      title: 'Arrays',
      summary: 'Keep many values of the same type in one variable.',
      objective: 'Store scores in an array, then count and average them with a loop.',
      explanation: 'An array holds a fixed number of values of one type, one after another. You reach each value with its index in square brackets. '
          'Indexes start at 0, so an array of 5 has indexes 0 to 4. Loops and arrays work well together.',
      syntax: r'''int scores[5] = {90, 72, 85, 64, 99};
scores[0]   /* first value */
scores[4]   /* last value  */''',
      syntaxNotes: [
        ('int scores[5]', 'Room for exactly 5 ints.'),
        ('{90, 72, ...}', 'Starting values, in order.'),
        ('scores[i]', 'The value at index i (0 = first).'),
      ],
      example: r'''#include <stdio.h>

int main(void) {
    int scores[5] = {90, 72, 85, 64, 99};
    int total = 0, passed = 0;

    for (int i = 0; i < 5; i++) {
        total += scores[i];
        if (scores[i] >= 75) passed++;
    }
    printf("Average: %.1f\n", total / 5.0);
    printf("Passed: %d of 5\n", passed);
    return 0;
}
''',
      output: 'Average: 82.0\nPassed: 3 of 5',
      lines: [
        'i goes 0, 1, 2, 3, 4: every index of the array.',
        'total += scores[i] is short for total = total + scores[i].',
        'passed++ counts the scores of 75 or more.',
      ],
      mistake: 'Going one past the end: i <= 5 reads scores[5], which does not exist.',
      mistakeCode: r'''for (int i = 0; i <= 5; i++)''',
      fixCode: r'''for (int i = 0; i < 5; i++)''',
      practice: 'Find and print the highest score in the array.',
      refs: [Ref('Arrays', _gnu, '$_base/Arrays.html')],
      keywords: ['array', 'index', '[]', 'count', 'total'],
    ),
    Lesson(
      id: 'c-strings',
      title: 'Strings',
      summary: 'Text in C is an array of characters ending with a hidden \\0.',
      objective: 'Read a name, measure it and build a greeting.',
      explanation: 'C has no separate text type: a string is a char array, and the end is marked by the character \'\\0\'. '
          'string.h has helpers such as strlen (length), strcpy (copy) and strcmp (compare). '
          'Use fgets to read a whole line safely; it keeps the Enter key as \'\\n\', which you usually remove.',
      syntax: r'''char name[50];
fgets(name, sizeof name, stdin);
name[strcspn(name, "\n")] = '\0';  /* remove the Enter */
strlen(name)''',
      syntaxNotes: [
        ('char name[50]', 'Room for up to 49 characters plus the \\0 end mark.'),
        ('fgets(name, sizeof name, stdin)', 'Reads one line, never more than fits.'),
        ('strlen(name)', 'Number of characters before the \\0.'),
        ('strcmp(a, b) == 0', 'True when the two strings are the same.'),
      ],
      example: r'''#include <stdio.h>
#include <string.h>

int main(void) {
    char name[50];
    printf("Your name: ");
    fgets(name, sizeof name, stdin);
    name[strcspn(name, "\n")] = '\0';

    printf("Hello, %s!\n", name);
    printf("Your name has %d letters.\n", (int) strlen(name));
    if (strcmp(name, "Logan") == 0) {
        printf("Same name as the developer!\n");
    }
    return 0;
}
''',
      input: 'Maria',
      output: 'Your name: Maria\nHello, Maria!\nYour name has 5 letters.',
      checks: ['Hello, Maria!', 'Your name has 5 letters.'],
      lines: [
        'strcspn(name, "\\n") finds where the Enter is; writing \'\\0\' there cuts it off.',
        '%s prints a string.',
        'strcmp returns 0 when the strings match, so we compare with == 0.',
      ],
      mistake: 'Comparing strings with ==. That compares where they are stored, not their letters.',
      mistakeCode: r'''if (name == "Logan")''',
      fixCode: r'''if (strcmp(name, "Logan") == 0)''',
      practice: 'Read a word and print it backwards, one character at a time.',
      refs: [Ref('Strings', _gnu, '$_base/Strings.html')],
      keywords: ['string', 'char', 'fgets', 'strlen', 'strcmp', 'strcpy', '\\0'],
    ),
    Lesson(
      id: 'c-pointers',
      title: 'Introduction to pointers',
      summary: 'A pointer holds the address of a variable, so a function can change it.',
      objective: 'Use a pointer parameter to let a function update the caller\'s variable.',
      explanation: 'Every variable lives at an address in memory. & gives you that address, and a pointer variable stores it. '
          'Writing *p means "the variable p points to". Passing a pointer to a function lets the function change the original variable; '
          'that is why scanf needs &.',
      syntax: r'''int x = 5;
int *p = &x;   /* p holds the address of x */
*p = 10;       /* changes x to 10 */''',
      syntaxNotes: [
        ('int *p', 'p is a pointer to an int.'),
        ('&x', 'The address of x.'),
        ('*p', 'The value at that address (here: x itself).'),
      ],
      example: r'''#include <stdio.h>

void add_bonus(int *score, int bonus) {
    *score = *score + bonus;
}

int main(void) {
    int score = 80;
    add_bonus(&score, 5);
    printf("Score with bonus: %d\n", score);

    int *p = &score;
    *p = 100;
    printf("After *p = 100: %d\n", score);
    return 0;
}
''',
      output: 'Score with bonus: 85\nAfter *p = 100: 100',
      lines: [
        'add_bonus gets the address of score, so *score inside it is main\'s score.',
        'Without the pointer, the function would only change its own copy.',
        '*p = 100 writes through the pointer, changing score.',
      ],
      mistake: 'Using a pointer that does not point anywhere yet. Always point it at a real variable first.',
      mistakeCode: r'''int *p;
*p = 5;''',
      fixCode: r'''int x;
int *p = &x;
*p = 5;''',
      practice: 'Write void swap(int *a, int *b) that swaps two variables, and print them before and after.',
      refs: [
        Ref('Pointers', _gnu, '$_base/Pointers.html'),
        Ref('Pointers and Arrays', _gnu, '$_base/Pointers-and-Arrays.html'),
      ],
      keywords: ['pointer', '*', '&', 'address', 'swap'],
    ),
  ],
  quiz: [
    Question('Where does a C program start running?', ['At the first line of the file', 'In the main function', 'At #include', 'In the last function'], 1,
        'Execution always begins in main.'),
    Question('Which placeholder prints a double with two decimals?', ['%d', '%c', '%.2f', '%s'], 2, '%.2f is for doubles; %d is for ints.'),
    Question('Which scanf line correctly reads a double into x?', ['scanf("%d", x);', 'scanf("%lf", &x);', 'scanf("%f", x);', 'scanf(x);'], 1,
        'scanf needs %lf for a double and the address &x.'),
    Question('What does 7 / 2 give in C when both are ints?', ['3.5', '3', '4', 'An error'], 1, 'Whole-number division drops the decimal part.'),
    Question('Which condition checks if score equals 100?', ['score = 100', 'score == 100', 'score =< 100', 'score := 100'], 1,
        '== compares; = assigns.'),
    Question('How many times does for (int i = 0; i < 4; i++) run?', ['3', '4', '5', 'Forever'], 1, 'i takes the values 0, 1, 2, 3.'),
    Question('What is the index of the first element of an array?', ['1', '0', '-1', 'It depends'], 1, 'C arrays start at index 0.'),
    Question('How should you compare two strings a and b?', ['a == b', 'strcmp(a, b) == 0', 'a.equals(b)', 'strlen(a) == strlen(b)'], 1,
        'strcmp compares the characters; == compares addresses.'),
    Question('In int *p = &x;, what does p hold?', ['The value of x', 'The address of x', 'A copy of x', 'Nothing yet'], 1, '& gives the address.'),
    Question('What does a void function return?', ['0', 'Nothing', 'An int', 'The last variable'], 1, 'void means no return value.'),
  ],
  exercises: [
    Exercise(
      id: 'c-ex-grade',
      level: 'Beginner',
      title: 'Pass or fail',
      task: 'Read one whole-number score. Print "PASS" if it is 75 or higher, otherwise print "FAIL".',
      starter: r'''#include <stdio.h>

int main(void) {
    int score;
    scanf("%d", &score);
    /* print PASS or FAIL */
    return 0;
}
''',
      requirements: ['Read the score with scanf.', 'Print exactly PASS or FAIL.', '75 itself passes.'],
      cases: [
        TestCase(input: '90', expect: ['PASS'], note: 'clearly passing'),
        TestCase(input: '75', expect: ['PASS'], note: 'exactly 75'),
        TestCase(input: '74', expect: ['FAIL'], note: 'just below'),
        TestCase(input: '0', expect: ['FAIL'], note: 'zero'),
      ],
      criteria: 'All four tests print the right word. Prompts before it are fine.',
      hint: 'Use if (score >= 75) { ... } else { ... }.',
      solution: r'''#include <stdio.h>

int main(void) {
    int score;
    scanf("%d", &score);
    if (score >= 75) {
        printf("PASS\n");
    } else {
        printf("FAIL\n");
    }
    return 0;
}
''',
    ),
    Exercise(
      id: 'c-ex-average',
      level: 'Intermediate',
      title: 'Class average',
      task: 'First read how many scores there are (n), then read n scores. Print "Average: " and the average with two decimals. '
          'If n is 0, print "No scores".',
      starter: r'''#include <stdio.h>

int main(void) {
    int n;
    scanf("%d", &n);
    /* read n scores and print the average */
    return 0;
}
''',
      requirements: ['Handle any n from 0 to 100.', 'Print the average with two decimals, like Average: 85.50.', 'n = 0 prints No scores (no division by zero).'],
      cases: [
        TestCase(input: '4\n80 90 85 87', expect: ['Average: 85.50'], note: 'four scores'),
        TestCase(input: '1\n100', expect: ['Average: 100.00'], note: 'one score'),
        TestCase(input: '3\n1 2 2', expect: ['Average: 1.67'], note: 'needs rounding'),
        TestCase(input: '0', expect: ['No scores'], note: 'no scores'),
      ],
      criteria: 'All four tests pass, including n = 0.',
      hint: 'Add each score to a total in a loop, then divide by n as a double: total / (double) n.',
      solution: r'''#include <stdio.h>

int main(void) {
    int n, x, total = 0;
    scanf("%d", &n);
    if (n == 0) {
        printf("No scores\n");
        return 0;
    }
    for (int i = 0; i < n; i++) {
        scanf("%d", &x);
        total += x;
    }
    printf("Average: %.2f\n", total / (double) n);
    return 0;
}
''',
    ),
    Exercise(
      id: 'c-ex-vowels',
      level: 'Challenge',
      title: 'Count the vowels',
      task: 'Read one line of text and print "Vowels: " followed by how many vowels (a, e, i, o, u, upper or lower case) it has.',
      starter: r'''#include <stdio.h>
#include <string.h>

int main(void) {
    char line[200];
    fgets(line, sizeof line, stdin);
    /* count the vowels */
    return 0;
}
''',
      requirements: ['Count both upper and lower case vowels.', 'Other characters (spaces, digits, y) are not vowels.', 'An empty line gives Vowels: 0.'],
      cases: [
        TestCase(input: 'Hello World', expect: ['Vowels: 3'], note: 'mixed case'),
        TestCase(input: 'AEIOU aeiou', expect: ['Vowels: 10'], note: 'all vowels'),
        TestCase(input: 'rhythm 123', expect: ['Vowels: 0'], note: 'no vowels'),
        TestCase(input: '', expect: ['Vowels: 0'], note: 'empty line'),
      ],
      criteria: 'All four tests pass.',
      hint: 'Loop over line[i] until \'\\0\' and check each character with strchr("aeiouAEIOU", c) or a switch.',
      solution: r'''#include <stdio.h>
#include <string.h>

int main(void) {
    char line[200] = "";
    fgets(line, sizeof line, stdin);
    int count = 0;
    for (int i = 0; line[i] != '\0'; i++) {
        if (line[i] != '\n' && strchr("aeiouAEIOU", line[i]) != NULL) count++;
    }
    printf("Vowels: %d\n", count);
    return 0;
}
''',
    ),
  ],
);
