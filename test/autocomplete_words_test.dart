import 'package:flutter_test/flutter_test.dart';
import 'package:nexus_ide/core/toolchains.dart';
import 'package:nexus_ide/ui/widgets/code_pane.dart';

/// Typing [prefix] in a [lang] file must offer [expected] (what the editor's popup shows).
Future<void> suggests(String lang, String prefix, String expected) async {
  final ac = NexusCodeController().autocompleter..setCustomWords(languages.firstWhere((l) => l.id == lang).words);
  expect(await ac.getSuggestions(prefix), contains(expected), reason: '$lang: "$prefix"');
}

void main() {
  // Students import with confidence: the real library names show up while typing the import.
  test('import names are suggested for every language', () async {
    await suggests('java', 'java', 'java.util.Scanner'); // import java…
    await suggests('java', 'ut', 'util'); // import java.ut…
    await suggests('java', 'Sca', 'Scanner'); // import java.util.Sca…
    await suggests('c', 'std', 'stdio.h'); // #include <std…
    await suggests('c', 'mat', 'math.h');
    await suggests('arduino', 'Ser', 'Servo.h');
    await suggests('python', 'ran', 'random'); // import ran…
    await suggests('python', 'dat', 'datetime');
    await suggests('csharp', 'System.C', 'System.Collections.Generic'); // using System.C…
    await suggests('csharp', 'Lin', 'Linq');
    await suggests('raspi', 'RPi', 'RPi.GPIO'); // import RPi…
    await suggests('raspi', 'gpio', 'gpiozero');
    await suggests('php', 'requ', 'require_once');
    await suggests('web', 'getE', 'getElementById');
    await suggests('sql', 'INNER', 'INNER JOIN');
  });
}
