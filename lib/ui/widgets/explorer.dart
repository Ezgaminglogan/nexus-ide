import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';

import '../../core/workspace.dart' as ws;
import '../theme.dart';

/// VS Code-style file tree for one language's workspace folder. Sidebar on PCs, drawer on phones.
/// Every action goes straight to the files on disk (core/workspace.dart keeps it inside [root]).
class Explorer extends StatefulWidget {
  const Explorer({
    super.key,
    required this.root,
    required this.project,
    required this.mainFile,
    required this.selected,
    required this.expanded,
    required this.onOpen,
    required this.onRenamed,
    required this.onDeleted,
    required this.onExpandedChanged,
  });

  final String root, project, mainFile, selected;
  final Set<String> expanded;
  final ValueChanged<String> onOpen, onDeleted;
  final void Function(String from, String to) onRenamed;
  final VoidCallback onExpandedChanged;

  @override
  State<Explorer> createState() => _ExplorerState();
}

const _iconFor = <String, List<List<dynamic>>>{
  'html': HugeIcons.strokeRoundedHtml5,
  'htm': HugeIcons.strokeRoundedHtml5,
  'css': HugeIcons.strokeRoundedCss3,
  'js': HugeIcons.strokeRoundedJsx01,
  'php': HugeIcons.strokeRoundedPhp,
  'py': HugeIcons.strokeRoundedPython,
  'java': HugeIcons.strokeRoundedJava,
  'c': HugeIcons.strokeRoundedCProgramming,
  'h': HugeIcons.strokeRoundedCProgramming,
  'ino': HugeIcons.strokeRoundedChip02,
  'cs': HugeIcons.strokeRoundedCodeSquare,
};

class _ExplorerState extends State<Explorer> {
  void _refresh() => setState(() {});

  void _say(String msg) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  Future<String?> _ask(String title, {String hint = '', String initial = ''}) {
    final c = TextEditingController(text: initial);
    return showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: TextField(controller: c, autofocus: true, decoration: InputDecoration(hintText: hint), onSubmitted: (v) => Navigator.pop(context, v)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text), child: const Text('OK')),
        ],
      ),
    );
  }

  Future<void> _new({required bool folder, String inside = ''}) async {
    final name = await _ask(folder ? 'New folder' : 'New file', hint: folder ? 'assets/images' : 'about.php  ·  css/style.css');
    if (name == null || name.trim().isEmpty) return;
    final rel = inside.isEmpty ? name.trim() : '$inside/${name.trim()}';
    final err = folder ? ws.createFolder(widget.root, rel) : ws.createFile(widget.root, rel);
    if (err != null) return _say(err);
    // Open every folder on the way so the new item is visible.
    final parts = (ws.safeRel(rel) ?? rel).split('/');
    for (var i = 1; i < parts.length + (folder ? 1 : 0); i++) {
      widget.expanded.add(parts.take(i).join('/'));
    }
    widget.onExpandedChanged();
    _refresh();
    if (!folder) widget.onOpen(ws.safeRel(rel)!);
  }

  Future<void> _rename(String rel) async {
    if (rel == widget.mainFile) return _say('${widget.mainFile} is the file NEXUS runs, so it keeps its name.');
    final name = await _ask('Rename', initial: rel.split('/').last);
    if (name == null || name.trim().isEmpty || name.trim() == rel.split('/').last) return;
    final err = ws.rename(widget.root, rel, name.trim(), (to) => widget.onRenamed(rel, to));
    if (err != null) return _say(err);
    _refresh();
  }

  Future<void> _delete(String rel, bool folder) async {
    if (rel == widget.mainFile) return _say('${widget.mainFile} is the file NEXUS runs, so it can\'t be deleted.');
    final n = folder ? ws.fileCount(widget.root, rel) : 1;
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${folder ? 'folder' : 'file'}?'),
        content: Text(folder ? '"$rel" and the $n file${n == 1 ? '' : 's'} inside it will be deleted for good.' : '"$rel" will be deleted for good.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Nx.stop), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    ws.delete(widget.root, rel);
    widget.onDeleted(rel);
    _refresh();
  }

  List<Widget> _rows(String dir, int depth) => [
        for (final e in ws.listDir(widget.root, dir)) ...[
          _row(e.rel, e.name, e.folder, depth),
          if (e.folder && widget.expanded.contains(e.rel)) ..._rows(e.rel, depth + 1),
        ],
      ];

  Widget _row(String rel, String name, bool folder, int depth) {
    final selected = rel == widget.selected;
    final open = widget.expanded.contains(rel);
    final ext = name.contains('.') ? name.split('.').last.toLowerCase() : '';
    return Material(
      color: selected ? const Color(0xFF24304F) : Colors.transparent,
      child: InkWell(
        onTap: () {
          if (!folder) return widget.onOpen(rel);
          setState(() => open ? widget.expanded.remove(rel) : widget.expanded.add(rel));
          widget.onExpandedChanged();
        },
        child: Padding(
          padding: EdgeInsets.only(left: 8.0 + depth * 14),
          child: SizedBox(
            height: MediaQuery.sizeOf(context).width < 900 ? 44 : 32, // finger-sized on phones, compact with a mouse
            child: Row(children: [
              SizedBox(width: 18, child: folder ? Icon(open ? Icons.expand_more : Icons.chevron_right, size: 18, color: Nx.muted) : null),
              const SizedBox(width: 4),
              folder
                  ? Icon(open ? Icons.folder_open : Icons.folder, size: 18, color: const Color(0xFFDCB67A))
                  : HugeIcon(icon: _iconFor[ext] ?? HugeIcons.strokeRoundedFile01, size: 18, color: selected ? Colors.white : Nx.muted),
              const SizedBox(width: 8),
              Expanded(
                child: Text(name, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 13.5, color: selected ? Colors.white : const Color(0xFFD6DCEA))),
              ),
              PopupMenuButton<String>(
                tooltip: 'More actions for $name',
                iconSize: 18,
                icon: const Icon(Icons.more_horiz, color: Nx.muted),
                onSelected: (a) => switch (a) {
                  'file' => _new(folder: false, inside: rel),
                  'folder' => _new(folder: true, inside: rel),
                  'rename' => _rename(rel),
                  _ => _delete(rel, folder),
                },
                itemBuilder: (_) => [
                  if (folder) const PopupMenuItem(value: 'file', child: Text('New file here')),
                  if (folder) const PopupMenuItem(value: 'folder', child: Text('New folder here')),
                  const PopupMenuItem(value: 'rename', child: Text('Rename')),
                  const PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: const Color(0xFF111729),
      child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 10, 4, 6),
          child: Row(children: [
            Expanded(
              child: Text(widget.project.toUpperCase(),
                  overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11.5, letterSpacing: 1.1, color: Nx.muted, fontWeight: FontWeight.w700)),
            ),
            IconButton(tooltip: 'New file', iconSize: 19, onPressed: () => _new(folder: false), icon: const Icon(Icons.note_add_outlined)),
            IconButton(tooltip: 'New folder', iconSize: 19, onPressed: () => _new(folder: true), icon: const Icon(Icons.create_new_folder_outlined)),
            IconButton(
              tooltip: 'Collapse all folders',
              iconSize: 19,
              onPressed: () {
                setState(widget.expanded.clear);
                widget.onExpandedChanged();
              },
              icon: const Icon(Icons.unfold_less),
            ),
          ]),
        ),
        Expanded(child: ListView(children: _rows('', 0))),
      ]),
    );
  }
}
