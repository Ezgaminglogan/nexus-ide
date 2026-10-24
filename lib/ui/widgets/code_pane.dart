import 'package:flutter/material.dart';
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

  @override
  void dispose() {
    _focus.dispose();
    super.dispose();
  }

  void _tapBelow(TapUpDetails d) {
    final box = _field.currentContext?.findRenderObject() as RenderBox?;
    if (box == null || d.globalPosition.dy <= box.localToGlobal(Offset(0, box.size.height)).dy) return;
    widget.controller.selection = TextSelection.collapsed(offset: widget.controller.text.length);
    _focus.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return CodeTheme(
      data: CodeThemeData(styles: {...vs2015Theme, 'root': vs2015Theme['root']!.copyWith(backgroundColor: const Color(0xFF151A28))}),
      child: GestureDetector(
        behavior: HitTestBehavior.translucent, // taps on the code itself still reach the field
        onTapUp: _tapBelow,
        child: Container(
          color: const Color(0xFF151A28),
          child: SingleChildScrollView(
            child: CodeField(
              key: _field,
              controller: widget.controller,
              focusNode: _focus,
              textStyle: const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 14, height: 1.45),
              gutterStyle: const GutterStyle(
                textStyle: TextStyle(color: Color(0xFF5C6680), height: 1.45),
                background: Color(0xFF121726),
                showFoldingHandles: true,
                showErrors: false,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
