import 'package:flutter/material.dart';

import '../../core/core.dart';
import '../../core/workspace.dart' as ws;
import '../theme.dart';

/// Add File: name, destination folder, detected type, starter template (with a preview) and
/// "Include starter code". The file and its starter are written together; only this dialog adds
/// boilerplate, so opening, switching or refreshing files never changes them.
/// Returns the new file (relative path) and where the cursor should go, or null if cancelled.
Future<({String rel, int cursor})?> showNewFileDialog(BuildContext context, {required Language lang, required String root, String folder = ''}) =>
    showDialog(context: context, builder: (_) => _NewFileDialog(lang: lang, root: root, folder: folder));

class _NewFileDialog extends StatefulWidget {
  const _NewFileDialog({required this.lang, required this.root, required this.folder});
  final Language lang;
  final String root, folder;

  @override
  State<_NewFileDialog> createState() => _NewFileDialogState();
}

class _NewFileDialogState extends State<_NewFileDialog> {
  final _name = TextEditingController();
  late String _folder = widget.folder;
  String? _template; // chosen starter id; null = the usual one
  bool _include = true;
  String? _error;

  late final List<String> _folders = ['', ..._allFolders('')];
  List<String> _allFolders(String dir) => [
        for (final e in ws.listDir(widget.root, dir))
          if (e.folder) ...[e.rel, ..._allFolders(e.rel)],
      ];

  String get _mainExt => widget.lang.fileName.split('.').last;

  /// What will be created: the folder plus the name, with the workspace's extension added only
  /// when the name has none.
  String get _rel {
    var name = _name.text.trim().replaceAll(r'\', '/');
    if (name.isEmpty) return '';
    if (!name.split('/').last.contains('.')) name = '$name.$_mainExt';
    return _folder.isEmpty ? name : '$_folder/$name';
  }

  @override
  void dispose() {
    _name.dispose();
    super.dispose();
  }

  String? _problem(String rel) {
    if (rel.isEmpty) return 'Type a file name.';
    final p = ws.nameProblem(rel);
    if (p != null) return p;
    final c = StarterContext(widget.lang, ws.safeRel(rel)!, widget.root);
    if (c.ext == 'java' && !RegExp(r'^[A-Za-z_$][A-Za-z0-9_$]*$').hasMatch(c.base)) {
      return 'A Java file is named after its class, so "${c.base}" must be a valid class name (letters, digits, _; not starting with a digit), like StudentInfo.java.';
    }
    return null;
  }

  void _create() {
    final rel = _rel;
    final problem = _problem(rel);
    if (problem != null) return setState(() => _error = problem);
    final clean = ws.safeRel(rel)!;
    final code = _include ? starterCode(widget.lang, clean, id: _template, root: widget.root) : null;
    final err = ws.createFile(widget.root, clean, code?.text ?? '');
    if (err != null) return setState(() => _error = err);
    final options = startersFor(widget.lang, clean);
    recordStarter(widget.lang, clean, code == null || options.isEmpty ? null : options.firstWhere((s) => s.id == _template, orElse: () => options.first).id);
    Navigator.pop(context, (rel: clean, cursor: code?.cursor ?? 0));
  }

  @override
  Widget build(BuildContext context) {
    final rel = _rel;
    final clean = rel.isEmpty ? null : ws.safeRel(rel);
    final type = clean == null ? null : fileType(clean, widget.lang);
    final options = clean == null ? const <Starter>[] : startersFor(widget.lang, clean);
    final chosen = options.where((s) => s.id == _template).firstOrNull ?? options.firstOrNull;
    final preview = clean == null || chosen == null ? null : starterCode(widget.lang, clean, id: chosen.id, root: widget.root)?.text;
    final appended = _name.text.trim().isNotEmpty && !_name.text.trim().split('/').last.contains('.');
    final narrow = MediaQuery.sizeOf(context).width < 600;

    Widget row(String label, Widget value) => Padding(
          padding: const EdgeInsets.only(top: 10),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            SizedBox(width: narrow ? 92 : 130, child: Text(label, style: const TextStyle(color: Nx.muted, fontSize: 13))),
            Expanded(child: value),
          ]),
        );

    return AlertDialog(
      title: const Text('New file'),
      scrollable: true,
      content: SizedBox(
        width: 520,
        child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          TextField(
            key: const Key('new-file-name'),
            controller: _name,
            autofocus: true,
            decoration: InputDecoration(labelText: 'File name', hintText: 'Student.java  ·  about.php  ·  css/style.css', errorText: _error, errorMaxLines: 3),
            onChanged: (_) => setState(() {
              _error = null;
              _template = null;
            }),
            onSubmitted: (_) => _create(),
          ),
          row(
            'Destination',
            DropdownButton<String>(
              key: const Key('new-file-folder'),
              isExpanded: true,
              isDense: true,
              value: _folders.contains(_folder) ? _folder : '',
              items: [for (final f in _folders) DropdownMenuItem(value: f, child: Text(f.isEmpty ? '${widget.lang.label} project (top)' : '$f/', overflow: TextOverflow.ellipsis))],
              onChanged: (v) => setState(() => _folder = v ?? ''),
            ),
          ),
          if (rel.isNotEmpty)
            row('Creates', Text(rel, key: const Key('new-file-result'), style: const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace']))),
          if (appended)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text('No extension typed, so .$_mainExt (this workspace\'s type) is added.', style: const TextStyle(fontSize: 12, color: Nx.muted)),
            ),
          row('Detected type', Text(rel.isEmpty ? '–' : type ?? 'Unknown type: the file will be empty', key: const Key('new-file-type'))),
          row(
            'Starter template',
            options.length > 1
                ? DropdownButton<String>(
                    isExpanded: true,
                    isDense: true,
                    value: chosen!.id,
                    items: [for (final o in options) DropdownMenuItem(value: o.id, child: Text(o.label, overflow: TextOverflow.ellipsis))],
                    onChanged: (v) => setState(() => _template = v),
                  )
                : Text(chosen?.label ?? 'None', key: const Key('new-file-template')),
          ),
          SwitchListTile(
            key: const Key('new-file-include'),
            contentPadding: EdgeInsets.zero,
            title: const Text('Include starter code'),
            subtitle: Text(chosen == null ? 'No template for this type: an empty file is created.' : _include ? 'The file starts with the template above.' : 'An empty file is created.',
                style: const TextStyle(fontSize: 12)),
            value: chosen != null && _include,
            onChanged: chosen == null ? null : (v) => setState(() => _include = v),
          ),
          if (preview != null && _include)
            ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: const Text('Preview', style: TextStyle(fontSize: 14)),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: const Color(0xFF0B0F1A), borderRadius: BorderRadius.circular(8), border: Border.all(color: Nx.line)),
                  child: SelectableText(preview, key: const Key('new-file-preview'), style: const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 12.5)),
                ),
              ],
            ),
        ]),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
        FilledButton(key: const Key('new-file-create'), onPressed: rel.isEmpty ? null : _create, child: const Text('Create File')),
      ],
    );
  }
}
