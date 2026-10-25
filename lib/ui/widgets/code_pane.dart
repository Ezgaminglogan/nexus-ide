import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart' show RenderEditable;
import 'package:flutter_code_editor/flutter_code_editor.dart';
import 'package:flutter_highlight/themes/vs2015.dart';

import '../../core/code_format.dart';

/// CodeController with VS Code-style Enter (works with phone keyboards too),
/// text insertion for the key bar, and Format.
class NexusCodeController extends CodeController {
  NexusCodeController({super.text, super.language})
      // The package's own Enter handler only sees single-key inserts; smartNewline replaces it.
      : super(modifiers: const [CloseBlockModifier(), TabModifier()]);

  @override
  set value(TextEditingValue newValue) => super.value = smartNewline(super.value, newValue) ?? newValue;

  void insertText(String s) {
    final sel = selection.isValid ? selection : TextSelection.collapsed(offset: text.length);
    value = TextEditingValue(
      text: text.replaceRange(sel.start, sel.end, s),
      selection: TextSelection.collapsed(offset: sel.start + s.length),
    );
  }

  void format({required bool braces}) => fullText = formatCode(fullText, braces: braces);
}

/// Syntax-highlighted editor with line numbers (VS Code dark colors). Autocomplete comes from
/// [CodeController.autocompleter] (language keywords + words in the file + custom words).
/// Shows where you are typing: the active line is tinted, the bracket or HTML tag that matches
/// the one at the cursor is boxed, and the pane gets a blue edge while it has focus.
/// Tapping the empty space below short code puts the caret at the end (new, empty files).
class CodePane extends StatefulWidget {
  const CodePane({super.key, required this.controller});
  final CodeController controller;

  @override
  State<CodePane> createState() => _CodePaneState();
}

class _CodePaneState extends State<CodePane> {
  final _focus = FocusNode();
  final _field = GlobalKey();
  final _stack = GlobalKey();
  Rect? _line;
  List<Rect> _pair = const [];

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_later);
    _focus.addListener(_later);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_later);
    _focus.dispose();
    super.dispose();
  }

  void _later() => WidgetsBinding.instance.addPostFrameCallback((_) => _measure());

  static RenderEditable? _editable(RenderObject? o) {
    if (o is RenderEditable) return o;
    RenderEditable? found;
    o?.visitChildren((c) => found ??= _editable(c));
    return found;
  }

  /// Asks the text field itself where the caret and the matching characters are drawn.
  void _measure() {
    if (!mounted) return;
    final ed = _editable(_field.currentContext?.findRenderObject());
    final stack = _stack.currentContext?.findRenderObject() as RenderBox?;
    final c = widget.controller;
    if (ed == null || stack == null || !ed.attached || !c.selection.isValid) return;
    Rect at(int offset) {
      final r = ed.getLocalRectForCaret(TextPosition(offset: offset));
      return Rect.fromPoints(stack.globalToLocal(ed.localToGlobal(r.topLeft)), stack.globalToLocal(ed.localToGlobal(r.bottomRight)));
    }

    final caret = at(c.selection.extentOffset);
    final line = Rect.fromLTWH(0, caret.top - 2, stack.size.width, ed.preferredLineHeight + 2);
    // One box per range (the bracket/tag at the caret and its partner, possibly on another line).
    final boxes = [
      for (final (a, b) in matchingPair(c.text, c.selection.extentOffset))
        if (at(b).left > at(a).left) Rect.fromLTRB(at(a).left - 1, at(a).top - 1, at(b).left + 1, at(a).top + ed.preferredLineHeight),
    ];
    if (line != _line || !_same(boxes)) {
      setState(() {
        _line = line;
        _pair = boxes;
      });
    }
  }

  bool _same(List<Rect> b) => b.length == _pair.length && [for (var i = 0; i < b.length; i++) b[i] == _pair[i]].every((x) => x);

  void _tapBelow(TapUpDetails d) {
    final box = _field.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || d.globalPosition.dy <= box.localToGlobal(Offset(0, box.size.height)).dy) return;
    widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    final focused = _focus.hasFocus;
    return CodeTheme(
      data: CodeThemeData(styles: {...vs2015Theme, 'root': vs2015Theme['root']!.copyWith(backgroundColor: const Color(0xFF151A28))}),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // taps on the code itself still reach the field
        onTapUp: _tapBelow,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF151A28),
            border: Border(left: BorderSide(color: focused ? const Color(0xFF3B6BFF) : Colors.transparent, width: 2)),
          ),
          child: SingleChildScrollView(
            child: Stack(key: _stack, children: [
              CodeField(
                key: _field,
                controller: widget.controller,
                focusNode: _focus,
                cursorColor: const Color(0xFFAEC6FF),
                textSelectionTheme: const TextSelectionThemeData(cursorColor: Color(0xFFAEC6FF), selectionColor: Color(0x663B6BFF)),
                textStyle: const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 14, height: 1.45),
                gutterStyle: const GutterStyle(
                  textStyle: TextStyle(color: Color(0xFF5C6680), height: 1.45),
                  background: Color(0xFF121726),
                  showFoldingHandles: true,
                  showErrors: false,
                ),
              ),
              if (_line != null)
                Positioned.fromRect(
                  rect: _line!,
                  child: IgnorePointer(child: ColoredBox(color: focused ? const Color(0x14FFFFFF) : const Color(0x08FFFFFF))),
                ),
              for (final r in _pair)
                Positioned.fromRect(
                  rect: r,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: const Color(0x22F2C230),
                        border: Border.all(color: const Color(0xAAF2C230)),
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
            ]),
          ),
        ),
      ),
    );
  }
}
