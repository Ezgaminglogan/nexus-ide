import 'package:flutter/material.dart';

import '../../core/web_design.dart';
import '../theme.dart';

/// Drag-and-drop page builder for the Web tile. Drop a control between rows for a new row, or
/// onto a row to place it side by side. Tap a row to align it, tap a control to edit it.
/// Every change calls [onChanged]; the editor turns [rows] into index.html.
class WebDesigner extends StatefulWidget {
  const WebDesigner({super.key, required this.rows, required this.onChanged});
  final List<DesignRow> rows;
  final VoidCallback onChanged;

  @override
  State<WebDesigner> createState() => _WebDesignerState();
}

const _labels = {
  BlockKind.heading: ('Heading', Icons.title),
  BlockKind.text: ('Text', Icons.notes),
  BlockKind.button: ('Button', Icons.smart_button_outlined),
  BlockKind.input: ('Text box', Icons.input),
  BlockKind.image: ('Image', Icons.image_outlined),
  BlockKind.link: ('Link', Icons.link),
};
const _colors = ['#222222', '#3B6BFF', '#E5484D', '#3DDC84', '#E76F00', '#8E5BD8', '#FFFFFF'];

Color _hex(String h) => Color(int.parse('FF${h.substring(1)}', radix: 16));

class _WebDesignerState extends State<WebDesigner> {
  List<DesignRow> get rows => widget.rows;

  void _change(VoidCallback f) {
    setState(f);
    widget.onChanged();
  }

  Widget _gap(int at) => DragTarget<BlockKind>(
        onAcceptWithDetails: (d) => _change(() => rows.insert(at, DesignRow([Block(d.data)]))),
        builder: (context, hover, _) => AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          height: rows.isEmpty ? 160 : (hover.isEmpty ? 14 : 40),
          margin: const EdgeInsets.symmetric(vertical: 2),
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: hover.isEmpty ? Colors.transparent : const Color(0x333B6BFF),
            borderRadius: BorderRadius.circular(8),
            border: rows.isEmpty || hover.isNotEmpty ? Border.all(color: const Color(0xFF3B6BFF)) : null,
          ),
          child: rows.isEmpty ? const Text('Drag a control here', style: TextStyle(color: Colors.black45)) : null,
        ),
      );

  Widget _preview(Block b) {
    final c = _hex(b.color);
    return switch (b.kind) {
      BlockKind.heading => Text(b.text, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: c)),
      BlockKind.text => Text(b.text, style: TextStyle(color: c)),
      BlockKind.button => Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(color: const Color(0xFF3B6BFF), borderRadius: BorderRadius.circular(8)),
          child: Text(b.text, style: const TextStyle(color: Colors.white))),
      BlockKind.input => Container(
          width: 160,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(border: Border.all(color: Colors.black26), borderRadius: BorderRadius.circular(8)),
          child: Text(b.text, style: const TextStyle(color: Colors.black38))),
      BlockKind.image => Container(
          width: 120,
          height: 70,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(8)),
          child: Text(b.text, style: const TextStyle(fontSize: 11, color: Colors.black54))),
      BlockKind.link => Text(b.text, style: TextStyle(color: c, decoration: TextDecoration.underline)),
    };
  }

  Future<void> _editBlock(DesignRow row, Block b) async {
    final text = TextEditingController(text: b.text);
    var color = b.color;
    final delete = await showDialog<bool>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) => AlertDialog(
          title: Text(_labels[b.kind]!.$1),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: text, decoration: InputDecoration(labelText: b.kind == BlockKind.image ? 'Image file or link' : 'Text')),
            const SizedBox(height: 12),
            Wrap(spacing: 8, children: [
              for (final h in _colors)
                GestureDetector(
                  onTap: () => set(() => color = h),
                  child: CircleAvatar(
                    radius: 14,
                    backgroundColor: color == h ? Colors.white : Nx.line,
                    child: CircleAvatar(radius: 11, backgroundColor: _hex(h)),
                  ),
                ),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Delete', style: TextStyle(color: Nx.stop))),
            FilledButton(onPressed: () => Navigator.pop(context, false), child: const Text('Done')),
          ],
        ),
      ),
    );
    if (delete == null) return;
    _change(() {
      if (delete) {
        row.blocks.remove(b);
        if (row.blocks.isEmpty) rows.remove(row);
      } else {
        b
          ..text = text.text
          ..color = color;
      }
    });
  }

  Future<void> _editRow(DesignRow row) => showModalBottomSheet<void>(
        context: context,
        builder: (context) => SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Row', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              const SizedBox(height: 12),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'left', icon: Icon(Icons.format_align_left), label: Text('Left')),
                  ButtonSegment(value: 'center', icon: Icon(Icons.format_align_center), label: Text('Center')),
                  ButtonSegment(value: 'right', icon: Icon(Icons.format_align_right), label: Text('Right')),
                ],
                selected: {row.align},
                onSelectionChanged: (s) {
                  _change(() => row.align = s.first);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: () {
                  _change(() => rows.remove(row));
                  Navigator.pop(context);
                },
                icon: const Icon(Icons.delete_outline, color: Nx.stop),
                label: const Text('Delete row', style: TextStyle(color: Nx.stop)),
              ),
            ]),
          ),
        ),
      );

  Widget _row(DesignRow row) => DragTarget<BlockKind>(
        onAcceptWithDetails: (d) => _change(() => row.blocks.add(Block(d.data))),
        builder: (context, hover, _) => InkWell(
          onTap: () => _editRow(row),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: hover.isEmpty ? null : const Color(0x223B6BFF),
              border: Border.all(color: const Color(0x553B6BFF)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Wrap(
              spacing: 12,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: switch (row.align) { 'center' => WrapAlignment.center, 'right' => WrapAlignment.end, _ => WrapAlignment.start },
              children: [for (final b in row.blocks) GestureDetector(onTap: () => _editBlock(row, b), child: _preview(b))],
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    Widget chip(BlockKind k) {
      final (label, icon) = _labels[k]!;
      final face = Chip(avatar: Icon(icon, size: 18), label: Text(label), backgroundColor: Nx.surface);
      return Draggable<BlockKind>(
        data: k,
        feedback: Material(color: Colors.transparent, child: face),
        childWhenDragging: Opacity(opacity: 0.4, child: face),
        // Tap = add as a new row at the bottom (no dragging needed).
        child: GestureDetector(onTap: () => _change(() => rows.add(DesignRow([Block(k)]))), child: face),
      );
    }

    return Column(children: [
      Expanded(
        child: Container(
          color: Colors.white,
          child: ListView(padding: const EdgeInsets.all(12), children: [
            _gap(0),
            for (var i = 0; i < rows.length; i++) ...[_row(rows[i]), _gap(i + 1)],
          ]),
        ),
      ),
      Container(
        width: double.infinity,
        color: const Color(0xFF141B2F),
        padding: const EdgeInsets.fromLTRB(8, 6, 8, 8),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Drag onto the page · tap to add · the Design tab rewrites index.html',
              style: TextStyle(fontSize: 11.5, color: Nx.muted)),
          const SizedBox(height: 6),
          Wrap(spacing: 6, runSpacing: 6, children: [for (final k in BlockKind.values) chip(k)]),
        ]),
      ),
    ]);
  }
}
