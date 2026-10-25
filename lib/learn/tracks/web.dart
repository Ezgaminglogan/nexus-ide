import '../model.dart';

const _mdn = 'MDN Web Docs (Mozilla)';
const _v = 'Living standard (HTML, CSS, DOM); NEXUS previews in the system web view';
const _learn = 'https://developer.mozilla.org/en-US/docs/Learn_web_development';

const webTrack = Track(
  langId: 'web',
  title: 'Web: HTML, CSS, JavaScript',
  intro: 'A web page is HTML for the content, CSS for the look and JavaScript for behaviour. The Web tile has two ways to build: Code, where '
      'you write index.html (plus .css and .js files), and Design, where you drag blocks into rows and NEXUS writes a responsive index.html. '
      'Nothing needs installing: pages open in the preview, offline.',
  runtime: 'Built in: no compiler. The preview uses the device\'s own web view (WebView2 on Windows, Android System WebView on phones).',
  run: [
    'Open the Web tile (or press Try in Editor to open a practice copy).',
    'Edit index.html; the preview refreshes when you save.',
    'Switch between Code and Design at the top; add .css or .js files with the + in the explorer.',
  ],
  lessons: [
    Lesson(
      id: 'web-html',
      title: 'HTML page structure',
      summary: 'doctype, html, head, body, and elements made of tags.',
      objective: 'Write a complete HTML page with a heading, a paragraph and a link.',
      explanation: 'HTML marks up content with elements: an opening tag, content and a closing tag, like <p>Hello</p>. Attributes go in the '
          'opening tag (href, src, class). Every page has <!DOCTYPE html>, then <html> with a <head> (title, settings) and a <body> (what you see). '
          'The viewport meta tag makes the page fit phone screens.',
      syntax: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Page title</title>
</head>
<body>
  ...
</body>
</html>''',
      syntaxNotes: [
        ('<h1> ... <h6>', 'Headings, h1 the most important.'),
        ('<p>', 'A paragraph.'),
        ('<a href="...">', 'A link; href is where it goes.'),
        ('<img src="..." alt="...">', 'An image; alt describes it for screen readers. No closing tag.'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>About Me</title>
</head>
<body>
  <h1>Ana Santos</h1>
  <p>BS Information Technology, <strong>CTU Naga Extension Campus</strong>.</p>
  <h2>My subjects</h2>
  <ul>
    <li>Programming 1</li>
    <li>Web Development</li>
  </ul>
  <p><a href="https://developer.mozilla.org">Learn more on MDN</a></p>
</body>
</html>
''',
      output: 'The preview shows a large "Ana Santos" heading, a paragraph with the campus name in bold, a "My subjects" heading with a bulleted list, and a link.',
      lines: ['<strong> marks important text (bold by default).', '<ul> is a bulleted list; each item is an <li>.', 'The link needs the internet only when you click it.'],
      mistake: 'Forgetting to close a tag can swallow the rest of the page into it.',
      mistakeCode: r'''<p>First paragraph
<h2>Next section</h2>''',
      fixCode: r'''<p>First paragraph</p>
<h2>Next section</h2>''',
      practice: 'Make an "About me" page with your name, a short bio, a list of hobbies and a table of your class schedule.',
      refs: [Ref('Basic HTML syntax', _mdn, '$_learn/Core/Structuring_content/Basic_HTML_syntax', version: _v)],
      keywords: ['html', 'head', 'body', 'tag', 'element', 'attribute', 'h1', 'p', 'a', 'img', 'ul', 'li'],
    ),
    Lesson(
      id: 'web-css',
      title: 'CSS basics',
      summary: 'Selectors, properties and the box model.',
      objective: 'Style a page with a separate style.css file.',
      explanation: 'CSS rules pick elements with a selector and set properties: h1 { color: navy; }. A .class selector matches class="..." and '
          '#id matches id="...". Every element is a box: content, padding (inside), border, margin (outside). Link a stylesheet with <link rel="stylesheet">.',
      syntax: r'''selector {
  property: value;
}

/* in index.html: */
<link rel="stylesheet" href="style.css">''',
      syntaxNotes: [
        ('p', 'Every <p>.'),
        ('.card', 'Every element with class="card".'),
        ('#main', 'The element with id="main".'),
        ('padding / margin', 'Space inside / outside the border.'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Styled</title>
  <style>
    body { font-family: sans-serif; background: #f4f6fb; margin: 0; padding: 16px; }
    h1 { color: #1d3a8a; }
    .card {
      background: white;
      padding: 16px;
      border: 1px solid #d0d7e6;
      border-radius: 8px;
      margin-bottom: 12px;
    }
    .card.highlight { border-color: #e44d26; }
  </style>
</head>
<body>
  <h1>Announcements</h1>
  <div class="card">Classes resume on Monday.</div>
  <div class="card highlight">Midterm exams next week!</div>
</body>
</html>
''',
      output: 'The preview shows a blue heading and two white rounded cards on a light grey page; the second card has an orange border.',
      lines: ['.card.highlight matches elements that have both classes.', 'The <style> block works like a style.css file; separate files are easier to reuse.'],
      mistake: 'Missing semicolons make the next property get ignored.',
      mistakeCode: r'''.card { padding: 16px background: white; }''',
      fixCode: r'''.card { padding: 16px; background: white; }''',
      practice: 'Move the CSS into style.css (+ in the explorer) and link it from index.html.',
      refs: [Ref('What is CSS?', _mdn, '$_learn/Core/Styling_basics/What_is_CSS', version: _v)],
      keywords: ['css', 'selector', 'class', 'id', 'padding', 'margin', 'border', 'color', 'style'],
    ),
    Lesson(
      id: 'web-flexbox',
      title: 'Layout with Flexbox',
      summary: 'Rows and columns that line up and share space.',
      objective: 'Lay out three cards in a row that wraps on small screens.',
      explanation: 'display: flex on a container lines its children up in a row. justify-content spreads them along the row, align-items lines them up '
          'across it, gap adds space between them, and flex-wrap: wrap lets them move to the next line when they do not fit.',
      syntax: r'''.row {
  display: flex;
  gap: 12px;
  flex-wrap: wrap;
  justify-content: center;
}
.row > * { flex: 1 1 200px; }''',
      syntaxNotes: [
        ('display: flex', 'Children sit in a row.'),
        ('justify-content: center', 'Center them along the row (also space-between, flex-end).'),
        ('flex: 1 1 200px', 'Grow, shrink, and start at 200px wide.'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Flex</title>
  <style>
    body { font-family: sans-serif; padding: 16px; }
    .row { display: flex; flex-wrap: wrap; gap: 12px; }
    .card { flex: 1 1 200px; padding: 16px; background: #eef2ff; border-radius: 8px; }
  </style>
</head>
<body>
  <div class="row">
    <div class="card">IT</div>
    <div class="card">Engineering</div>
    <div class="card">Education</div>
  </div>
</body>
</html>
''',
      output: 'Wide preview: three cards side by side, equal width. Narrow (phone) preview: they wrap onto separate lines.',
      lines: ['Each card starts at 200px and grows to fill the row.', 'When three 200px cards do not fit, flex-wrap moves one down.'],
      mistake: 'Putting display: flex on the children instead of their container.',
      mistakeCode: r'''.card { display: flex; }''',
      fixCode: r'''.row { display: flex; }''',
      practice: 'Make a navigation bar: logo on the left, three links on the right (justify-content: space-between).',
      refs: [Ref('Flexbox', _mdn, '$_learn/Core/CSS_layout/Flexbox', version: _v)],
      keywords: ['flex', 'flexbox', 'justify-content', 'align-items', 'gap', 'wrap', 'layout'],
    ),
    Lesson(
      id: 'web-responsive',
      title: 'Responsive design',
      summary: 'The viewport tag and media queries for phones and PCs.',
      objective: 'Change the layout on narrow screens with a media query.',
      explanation: 'With <meta name="viewport" content="width=device-width, initial-scale=1"> a phone shows the page at its real width. '
          'A media query applies CSS only when the screen matches: @media (max-width: 600px) { ... } for phones. Use max-width: 100% on images '
          'so they never overflow.',
      syntax: r'''@media (max-width: 600px) {
  .sidebar { display: none; }
}
img { max-width: 100%; height: auto; }''',
      syntaxNotes: [
        ('@media (max-width: 600px)', 'Only on screens 600px wide or less.'),
        ('max-width: 100%', 'Never wider than its container.'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Responsive</title>
  <style>
    body { font-family: sans-serif; margin: 0; }
    .layout { display: flex; }
    nav { width: 180px; background: #1d3a8a; color: white; padding: 16px; }
    main { flex: 1; padding: 16px; }
    @media (max-width: 600px) {
      .layout { flex-direction: column; }
      nav { width: auto; }
    }
  </style>
</head>
<body>
  <div class="layout">
    <nav>Menu</nav>
    <main><h1>Welcome</h1><p>Resize the preview to see the menu move on top.</p></main>
  </div>
</body>
</html>
''',
      output: 'Wide: a blue menu on the left of the content. Narrow (600px or less): the menu sits above the content.',
      lines: ['flex-direction: column stacks the menu and content on phones.', 'Without the viewport tag, phones would zoom the page out instead.'],
      mistake: 'Leaving out the viewport meta tag: phones show a tiny desktop page.',
      mistakeCode: r'''<head>
  <title>Page</title>
</head>''',
      fixCode: r'''<head>
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Page</title>
</head>''',
      practice: 'Make a three-column card grid that becomes one column on phones.',
      refs: [Ref('Responsive design', _mdn, '$_learn/Core/CSS_layout/Responsive_Design', version: _v)],
      keywords: ['responsive', 'media query', '@media', 'viewport', 'mobile', 'max-width'],
    ),
    Lesson(
      id: 'web-dom',
      title: 'JavaScript and the DOM',
      summary: 'Find elements and change their text and style.',
      objective: 'Change a heading and a list with JavaScript.',
      explanation: 'The browser turns HTML into the DOM, a tree of objects JavaScript can change. document.querySelector(css) finds the first matching '
          'element; textContent changes its text and classList adds or removes classes. Put <script> at the end of <body> so the elements exist first.',
      syntax: r'''const title = document.querySelector("h1");
title.textContent = "New text";
title.classList.add("big");''',
      syntaxNotes: [
        ('document.querySelector(".x")', 'The first element matching a CSS selector.'),
        ('textContent', 'The element\'s text (safe: never treated as HTML).'),
        ('document.createElement("li")', 'A new element to add with append().'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>DOM</title>
</head>
<body>
  <h1>Loading...</h1>
  <ul id="subjects"></ul>
  <script>
    document.querySelector("h1").textContent = "My subjects";
    const list = document.querySelector("#subjects");
    for (const name of ["Programming", "Web Development", "Database"]) {
      const li = document.createElement("li");
      li.textContent = name;
      list.append(li);
    }
  </script>
</body>
</html>
''',
      output: 'The preview shows "My subjects" (not "Loading...") and a list of three subjects built by JavaScript.',
      lines: ['The script runs after the h1 and ul exist, because it is at the end of body.', 'append adds each new <li> to the list.'],
      mistake: 'Running the script in <head> before the elements exist: querySelector returns null.',
      mistakeCode: r'''<head>
  <script>document.querySelector("h1").textContent = "Hi";</script>
</head>''',
      fixCode: r'''<body>
  <h1></h1>
  <script>document.querySelector("h1").textContent = "Hi";</script>
</body>''',
      practice: 'Show today\'s date in a paragraph with new Date().toLocaleDateString().',
      refs: [Ref('DOM scripting introduction', _mdn, '$_learn/Core/Scripting/DOM_scripting', version: _v)],
      keywords: ['javascript', 'dom', 'querySelector', 'textContent', 'createElement', 'append', 'classList'],
    ),
    Lesson(
      id: 'web-events',
      title: 'Events',
      summary: 'Run code when the user clicks or types.',
      objective: 'Make a button that counts clicks.',
      explanation: 'element.addEventListener("click", function) runs the function every time the element is clicked. Other events: "input" (typing), '
          '"submit" (forms), "keydown". The function receives an event object with details.',
      syntax: r'''button.addEventListener("click", () => {
  // runs on every click
});''',
      syntaxNotes: [
        ('"click"', 'The event name.'),
        ('() => { ... }', 'An arrow function: the code to run.'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Counter</title>
</head>
<body style="font-family: sans-serif; padding: 16px">
  <button id="add">Add one</button>
  <p>Clicks: <span id="count">0</span></p>
  <input id="name" placeholder="Type your name">
  <p id="hello"></p>
  <script>
    let clicks = 0;
    document.querySelector("#add").addEventListener("click", () => {
      clicks++;
      document.querySelector("#count").textContent = clicks;
    });
    document.querySelector("#name").addEventListener("input", (e) => {
      document.querySelector("#hello").textContent = "Hello, " + e.target.value;
    });
  </script>
</body>
</html>
''',
      output: 'Each click on "Add one" raises the count by 1. Typing in the box shows "Hello, " followed by what you type, as you type.',
      lines: ['let clicks keeps its value between clicks.', 'e.target is the input that fired the event.'],
      mistake: 'Writing onclick = doThis() calls the function right away instead of on click.',
      mistakeCode: r'''button.addEventListener("click", addOne());''',
      fixCode: r'''button.addEventListener("click", addOne);''',
      practice: 'Add a Reset button that sets the count back to 0.',
      refs: [Ref('Introduction to events', _mdn, '$_learn/Core/Scripting/Events', version: _v)],
      keywords: ['event', 'addEventListener', 'click', 'input', 'arrow function'],
    ),
    Lesson(
      id: 'web-forms',
      title: 'Forms',
      summary: 'Inputs, labels, built-in validation and reading values.',
      objective: 'Build a sign-up form that checks its fields before accepting them.',
      explanation: 'A <form> groups inputs. Each input should have a <label>. Attributes like required, type="email" and minlength make the browser '
          'check the value before the form is submitted. In JavaScript, listen for "submit" and call event.preventDefault() to handle it yourself.',
      syntax: r'''<form id="signup">
  <label>Email <input type="email" name="email" required></label>
  <button>Sign up</button>
</form>''',
      syntaxNotes: [
        ('<label>', 'Clicking the label focuses the input; screen readers read it.'),
        ('required', 'The browser refuses to submit an empty field.'),
        ('type="email"', 'Must look like an email address.'),
        ('event.preventDefault()', 'Stop the page from reloading on submit.'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Sign up</title>
</head>
<body style="font-family: sans-serif; padding: 16px">
  <form id="signup">
    <p><label>Name <input name="name" required minlength="2"></label></p>
    <p><label>Email <input type="email" name="email" required></label></p>
    <button>Sign up</button>
  </form>
  <p id="result"></p>
  <script>
    document.querySelector("#signup").addEventListener("submit", (e) => {
      e.preventDefault();
      const data = new FormData(e.target);
      document.querySelector("#result").textContent = "Thanks, " + data.get("name") + "!";
      e.target.reset();
    });
  </script>
</body>
</html>
''',
      output: 'Submitting with an empty name or a bad email shows the browser\'s warning. A valid form shows "Thanks, <name>!" and clears the fields.',
      lines: ['The browser checks required, minlength and type="email" before "submit" fires.', 'FormData reads every field by its name.'],
      mistake: r'An input without a name is not included in FormData or in a PHP $_POST.',
      mistakeCode: r'''<input type="email" required>''',
      fixCode: r'''<input type="email" name="email" required>''',
      practice: 'Add a password field with minlength="8" and a confirm field that must match (check it in the submit handler).',
      refs: [Ref('Your first form', _mdn, '$_learn/Extensions/Forms/Your_first_form', version: _v)],
      keywords: ['form', 'input', 'label', 'required', 'validation', 'submit', 'FormData'],
    ),
    Lesson(
      id: 'web-designer',
      title: 'The NEXUS page designer',
      summary: 'Build a page by dragging blocks, then read the HTML it writes.',
      objective: 'Make a page in Design mode and find each block in the generated HTML.',
      explanation: 'In the Web tile, switch the top toggle from Code to Design. Drag blocks (heading, text, button, input, image, link) into rows, '
          'choose each row\'s alignment (left, center, right) and colours. NEXUS saves the layout in design.json and writes index.html for you: '
          'each row becomes a wrapping flex row, so the page works on phones too. Switching back to Code shows that HTML.',
      syntax: r'''<!-- one designer row, as NEXUS writes it (simplified) -->
<div class="row" style="justify-content: center">
  <h1 style="color: #222222">My Heading</h1>
  <button>Click me</button>
</div>''',
      syntaxNotes: [
        ('Row alignment', 'Left / Center / Right become justify-content on the row.'),
        ('Image block', 'Uses a file in the web folder (works offline) or a link.'),
        ('Code / Design toggle', 'Design rewrites index.html; edits made in Code mode are replaced the next time you change the design.'),
      ],
      example: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Designer-style page</title>
  <style>
    body { font-family: sans-serif; margin: 0; padding: 16px; }
    .row { display: flex; flex-wrap: wrap; gap: 12px; align-items: center; margin-bottom: 12px; }
  </style>
</head>
<body>
  <div class="row" style="justify-content: center">
    <h1 style="color: #1d3a8a">CTU Naga IT Week</h1>
  </div>
  <div class="row" style="justify-content: center">
    <input placeholder="Your name">
    <button>Register</button>
  </div>
</body>
</html>
''',
      output: 'A centred blue heading, and below it a centred name box with a Register button; on a phone they wrap if they do not fit.',
      lines: ['This is the same pattern the designer uses: rows of blocks in wrapping flex containers.', 'Edit it in Code mode to learn what each block turns into.'],
      mistake: 'Hand-editing index.html and then changing the design: the designer writes index.html again and your hand edits are lost.',
      mistakeCode: r'''(edit index.html in Code mode, then move a block in Design mode)''',
      fixCode: r'''Pick one way per page: keep using Design, or copy the generated HTML into a new file (e.g. about.html) and edit that.''',
      practice: 'Design a contact page with a heading row, a text row and a centred row with an input and a button; then open the HTML in Code mode.',
      refs: [Ref('Flexbox', _mdn, '$_learn/Core/CSS_layout/Flexbox', version: _v)],
      keywords: ['designer', 'design', 'drag', 'drop', 'blocks', 'rows', 'layout', 'no-code'],
    ),
  ],
  quiz: [
    Question('Which part of the page holds what the user sees?', ['<head>', '<body>', '<title>', '<meta>'], 1, '<head> is settings; <body> is the content.'),
    Question('What does the alt attribute of an <img> do?', ['Sets the size', 'Describes the image for screen readers', 'Links it', 'Nothing'], 1,
        'It is also shown when the image cannot load.'),
    Question('Which selector matches class="card"?', ['#card', '.card', 'card', '*card'], 1, 'A dot selects by class, # by id.'),
    Question('Padding is space...', ['outside the border', 'inside the border', 'between lines', 'between pages'], 1, 'Margin is outside.'),
    Question('What does flex-wrap: wrap do?', ['Hides overflow', 'Lets items move to the next line', 'Adds borders', 'Centres text'], 1,
        'Useful for phone layouts.'),
    Question('Which tag makes phones show the page at their real width?', ['<meta charset>', '<meta name="viewport" ...>', '<link>', '<base>'], 1,
        'width=device-width, initial-scale=1.'),
    Question('What does document.querySelector("#total") return?', ['All elements', 'The element with id="total"', 'Its text', 'A number'], 1,
        'The first match, or null.'),
    Question('How do you run code on every click of a button?', ['button.click = code', 'button.addEventListener("click", fn)', 'onclick()', 'button.run(fn)'], 1,
        'Pass the function, do not call it.'),
    Question('What does the required attribute do?', ['Makes text bold', 'Blocks submitting an empty field', 'Sends the form', 'Nothing'], 1,
        'The browser checks it before submit.'),
    Question('In the NEXUS designer, what happens to each row?', ['It becomes a table', 'It becomes a wrapping flex row in index.html', 'It becomes an image', 'It is saved online'], 1,
        'That is why designer pages fit phones.'),
  ],
  exercises: [
    Exercise(
      id: 'web-ex-profile',
      level: 'Beginner',
      title: 'Profile page',
      task: 'Make index.html a profile page: a complete HTML document with the viewport tag, an <h1> with your name, a paragraph about you, '
          'a list (<ul> or <ol>) of at least three skills, and an image with alt text.',
      kind: CheckKind.staticHtml,
      starter: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <title>Profile</title>
</head>
<body>

</body>
</html>
''',
      requirements: ['The viewport meta tag.', 'One <h1>, a <p>, a list with 3+ <li>, an <img> with alt.'],
      checks: [
        ('Has the viewport meta tag', r'<meta[^>]+name\s*=\s*"viewport"'),
        ('Has an <h1> heading', r'<h1[^>]*>[^<]+</h1>'),
        ('Has a paragraph', r'<p[^>]*>[^<]+'),
        ('Has a list with at least three items', r'<(ul|ol)[^>]*>(\s*<li[^>]*>[\s\S]*?</li>\s*){3,}'),
        ('Has an image with alt text', r'<img[^>]+alt\s*=\s*"[^"]+"'),
      ],
      checklist: [
        'The preview shows your name as the biggest text.',
        'The skills appear as a list.',
        'The image shows (or its alt text shows when the file is missing).',
        'On a narrow preview nothing is cut off.',
      ],
      criteria: 'All static checks pass (NEXUS reads your HTML; it does not run the page) and you tick the checklist in the preview.',
      hint: 'Copy the viewport line from the HTML lesson; put an image file in the web folder or use alt text that describes it.',
      solution: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Profile</title>
</head>
<body>
  <h1>Ana Santos</h1>
  <img src="photo.jpg" alt="Ana smiling in the CTU Naga campus garden" style="max-width: 100%">
  <p>I am a first-year IT student who likes building websites.</p>
  <ul>
    <li>HTML</li>
    <li>CSS</li>
    <li>Graphic design</li>
  </ul>
</body>
</html>
''',
    ),
    Exercise(
      id: 'web-ex-cards',
      level: 'Intermediate',
      title: 'Responsive cards',
      task: 'Show at least three course cards side by side with Flexbox. They must wrap on narrow screens, and a media query for max-width 600px '
          'must make the page padding smaller. The CSS can go in a <style> block or in a style.css file linked from index.html.',
      kind: CheckKind.staticHtml,
      starter: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Courses</title>
</head>
<body>
  <!-- three .card elements inside a .cards container -->
</body>
</html>
''',
      requirements: ['display: flex and flex-wrap: wrap on the container.', 'A @media (max-width: 600px) rule.', 'Three or more elements with class card.'],
      checks: [
        ('Uses display: flex', r'display\s*:\s*flex'),
        ('Lets the cards wrap', r'flex-wrap\s*:\s*wrap'),
        ('Has a phone media query', r'@media[^{]*max-width\s*:\s*600px'),
        ('Has at least three cards', r'(class\s*=\s*"[^"]*\bcard\b[^"]*"[\s\S]*){3,}'),
      ],
      checklist: [
        'Wide preview: the cards sit in one row.',
        'Narrow preview: the cards wrap onto new lines and nothing scrolls sideways.',
        'The padding is smaller on the narrow preview.',
      ],
      criteria: 'All static checks pass and the checklist is true in the preview at both widths.',
      hint: '.cards { display: flex; flex-wrap: wrap; gap: 12px; } .card { flex: 1 1 200px; }',
      solution: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>Courses</title>
  <style>
    body { font-family: sans-serif; padding: 32px; }
    .cards { display: flex; flex-wrap: wrap; gap: 12px; }
    .card { flex: 1 1 200px; padding: 16px; background: #eef2ff; border-radius: 8px; }
    @media (max-width: 600px) { body { padding: 12px; } }
  </style>
</head>
<body>
  <h1>Our courses</h1>
  <div class="cards">
    <div class="card"><h2>BSIT</h2><p>Information Technology</p></div>
    <div class="card"><h2>BEEd</h2><p>Elementary Education</p></div>
    <div class="card"><h2>BSIE</h2><p>Industrial Engineering</p></div>
  </div>
</body>
</html>
''',
    ),
    Exercise(
      id: 'web-ex-todo',
      level: 'Challenge',
      title: 'To-do list',
      task: 'Build a to-do list: a form with a text input and an Add button. Submitting adds the text as a new <li> (with textContent, not innerHTML), '
          'clears the input, and ignores empty text. Clicking an item toggles a "done" class that strikes it through.',
      kind: CheckKind.staticHtml,
      starter: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>To-do</title>
</head>
<body>
  <form id="add-form">
    <input id="task" placeholder="New task">
    <button>Add</button>
  </form>
  <ul id="list"></ul>
  <script>
    // handle submit and clicks
  </script>
</body>
</html>
''',
      requirements: ['A submit listener with preventDefault.', 'New items use createElement and textContent.', 'Empty text is ignored.', 'A .done style with line-through, toggled on click.'],
      checks: [
        ('Listens for submit', r'''addEventListener\(\s*["']submit["']'''),
        ('Stops the page reloading', r'preventDefault\(\)'),
        ('Creates list items', r'''createElement\(\s*["']li["']\s*\)'''),
        ('Uses textContent for the text', r'textContent\s*='),
        ('Toggles a done class', r'''classList\.toggle\(\s*["']done["']'''),
        ('Styles .done with line-through', r'\.done\s*\{[^}]*line-through'),
      ],
      checklist: [
        'Typing a task and pressing Add (or Enter) adds it to the list and empties the box.',
        'Pressing Add with an empty box adds nothing.',
        'Clicking a task strikes it through; clicking again un-strikes it.',
        'A task like <b>hi</b> shows the tags as text, not bold.',
      ],
      criteria: 'All static checks pass and you tick the checklist in the preview.',
      hint: 'In the submit handler: const text = input.value.trim(); if (!text) return; then create the li, set textContent, add a click listener, append.',
      solution: r'''<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="utf-8">
  <meta name="viewport" content="width=device-width, initial-scale=1">
  <title>To-do</title>
  <style>
    body { font-family: sans-serif; padding: 16px; }
    li { cursor: pointer; padding: 4px 0; }
    .done { text-decoration: line-through; color: #888; }
  </style>
</head>
<body>
  <form id="add-form">
    <input id="task" placeholder="New task">
    <button>Add</button>
  </form>
  <ul id="list"></ul>
  <script>
    const input = document.querySelector("#task");
    const list = document.querySelector("#list");
    document.querySelector("#add-form").addEventListener("submit", (e) => {
      e.preventDefault();
      const text = input.value.trim();
      if (!text) return;
      const li = document.createElement("li");
      li.textContent = text;
      li.addEventListener("click", () => li.classList.toggle("done"));
      list.append(li);
      input.value = "";
    });
  </script>
</body>
</html>
''',
    ),
  ],
);
