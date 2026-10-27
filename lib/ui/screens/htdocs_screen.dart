import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/core.dart';
import '../widgets/widgets.dart';
import 'editor_screen.dart';
import 'preview_screen.dart';

/// The PHP and Web tiles open here: XAMPP's htdocs folder. Every folder is one website, served
/// at `http://localhost/<folder>/`. Students make, open, view, rename and delete projects, and
/// see exactly where they live, the same workflow as XAMPP on a lab PC.
class HtdocsScreen extends StatefulWidget {
  const HtdocsScreen({super.key, this.php = true});
  final bool php; // the type a new project starts as (PHP tile: PHP, Web tile: HTML)

  @override
  State<HtdocsScreen> createState() => _HtdocsScreenState();
}

class _HtdocsScreenState extends State<HtdocsScreen> {
  @override
  void initState() {
    super.initState();
    migrateToHtdocs();
  }

  final _server = LocalServer.instance;
  bool get _pc => !Platform.isAndroid && !Platform.isIOS;

  /// What a project's address is (or will be once the server runs).
  String _address(String name) => '${_server.running ? _server.origin : (_pc ? 'http://localhost' : 'http://localhost:8080')}/$name/';

  void _say(String msg) => ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(msg)));

  Future<void> _open(String name) async {
    await Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(language: projectLanguage(name))));
    if (mounted) setState(() {});
  }

  Future<void> _new() async {
    final name = TextEditingController();
    var php = widget.php;
    String? error;
    final made = await showDialog<String>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, set) {
          void create() {
            error = createProject(name.text.trim(), php: php);
            if (error == null) return Navigator.pop(context, name.text.trim());
            set(() {});
          }

          final n = name.text.trim();
          return AlertDialog(
            title: const Text('New project'),
            content: SizedBox(
              width: 460,
              child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
                TextField(
                  key: const Key('project-name'),
                  controller: name,
                  autofocus: true,
                  decoration: InputDecoration(labelText: 'Project folder name', hintText: 'guestbook', errorText: error, errorMaxLines: 3),
                  onChanged: (_) => set(() => error = null),
                  onSubmitted: (_) => create(),
                ),
                const SizedBox(height: 14),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: true, label: Text('PHP site'), icon: Icon(Icons.storage_outlined)),
                    ButtonSegment(value: false, label: Text('HTML site'), icon: Icon(Icons.html_outlined)),
                  ],
                  selected: {php},
                  onSelectionChanged: (s) => set(() => php = s.first),
                ),
                const SizedBox(height: 14),
                Text('Folder: htdocs/${n.isEmpty ? '<name>' : n}/  ·  starts with ${php ? 'index.php' : 'index.html'}', style: const TextStyle(fontSize: 13, color: Nx.muted)),
                const SizedBox(height: 4),
                Text('Address: ${_address(n.isEmpty ? '<name>' : n)}', style: const TextStyle(fontSize: 13, color: Nx.muted)),
              ]),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              FilledButton(key: const Key('project-create'), onPressed: create, child: const Text('Create')),
            ],
          );
        },
      ),
    );
    if (made != null && mounted) await _open(made);
  }

  Future<void> _rename(String from) async {
    final c = TextEditingController(text: from);
    final to = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rename project'),
        content: TextField(controller: c, autofocus: true, decoration: const InputDecoration(helperText: 'The address changes too: localhost/<new name>/')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(context, c.text.trim()), child: const Text('Rename')),
        ],
      ),
    );
    if (to == null || to == from) return;
    final problem = projectNameProblem(to);
    if (problem != null && to.toLowerCase() != from.toLowerCase()) return _say(problem);
    try {
      Directory('$htdocsDir/$from').renameSync('$htdocsDir/$to');
    } on FileSystemException catch (e) {
      return _say('Could not rename: ${e.osError?.message ?? e.message}');
    }
    setState(() {});
  }

  Future<void> _delete(String name) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete project?'),
        content: Text('"htdocs/$name" and every file in it will be deleted for good.'),
        actions: [
          TextButton(autofocus: true, onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          FilledButton(style: FilledButton.styleFrom(backgroundColor: Nx.stop), onPressed: () => Navigator.pop(context, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok != true) return;
    Directory('$htdocsDir/$name').deleteSync(recursive: true);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final projects = listProjects();
    final wide = MediaQuery.sizeOf(context).width >= 700;
    return Scaffold(
      appBar: AppBar(
        title: const Text('htdocs'),
        actions: [
          if (Platform.isWindows)
            IconButton(
              tooltip: 'Open the htdocs folder in File Explorer',
              onPressed: () => Process.run('explorer', [htdocsDir]),
              icon: const Icon(Icons.folder_open_outlined),
            ),
          IconButton(tooltip: 'Refresh', onPressed: () => setState(() {}), icon: const Icon(Icons.refresh)),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('new-project'),
        onPressed: _new,
        icon: const Icon(Icons.create_new_folder_outlined),
        label: const Text('New project'),
      ),
      body: ListView(padding: const EdgeInsets.fromLTRB(16, 12, 16, 96), children: [
        _intro(),
        const SizedBox(height: 12),
        _serverCard(),
        const SizedBox(height: 16),
        Text('Projects (${projects.length})', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        const SizedBox(height: 8),
        if (projects.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No projects yet. Press New project to make your first website folder.', style: TextStyle(color: Nx.muted)),
          ),
        Wrap(spacing: 12, runSpacing: 12, children: [
          for (final pr in projects) SizedBox(width: wide ? 360 : double.infinity, child: _projectCard(pr)),
        ]),
      ]),
    );
  }

  Widget _intro() => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(color: Nx.surface, borderRadius: BorderRadius.circular(14)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const Text('Like XAMPP: each folder here is a website', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Put a project in htdocs/<folder> and it opens at ${_pc ? 'http://localhost/<folder>/' : 'http://localhost:8080/<folder>/'}. '
            '${_pc ? 'View opens it in your own browser (Chrome, Edge...).' : 'View shows it inside NEXUS.'} '
            'PHP pages can use MySQL: host 127.0.0.1, user root, no password, database nexus.',
            style: const TextStyle(fontSize: 13.5, height: 1.4, color: Color(0xFFC3CBE0)),
          ),
          const SizedBox(height: 8),
          Row(children: [
            const Icon(Icons.folder, size: 16, color: Color(0xFFDCB67A)),
            const SizedBox(width: 6),
            Expanded(child: SelectableText(htdocsDir, style: const TextStyle(fontFamily: 'Consolas', fontFamilyFallback: ['monospace'], fontSize: 12.5, color: Nx.muted))),
            IconButton(
              tooltip: 'Copy the folder path',
              visualDensity: VisualDensity.compact,
              iconSize: 16,
              onPressed: () => Clipboard.setData(ClipboardData(text: htdocsDir)),
              icon: const Icon(Icons.copy),
            ),
          ]),
        ]),
      );

  Widget _serverCard() => ListenableBuilder(
        listenable: _server,
        builder: (context, _) {
          final on = _server.running && _server.docroot == htdocsDir;
          final color = on ? Nx.run : Nx.muted;
          return Container(
            key: const Key('server-card'),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: color.withValues(alpha: 0.6))),
            child: Row(children: [
              Icon(on ? Icons.dns : Icons.dns_outlined, color: color),
              const SizedBox(width: 10),
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(on ? 'Server running at ${_server.origin}/' : (_server.starting ? 'Starting the server…' : 'Server stopped'),
                      style: TextStyle(fontWeight: FontWeight.w700, color: color)),
                  Text(
                    _server.error.isNotEmpty
                        ? _server.error
                        : on
                            ? (_server.port == 80 ? 'Port 80, like XAMPP\'s Apache.' : 'Port ${_server.port}: port 80 is busy (XAMPP\'s Apache or another server is running).')
                            : 'It starts by itself when you view a project${Platform.isAndroid ? ' (MySQL too)' : ''}.',
                    style: TextStyle(fontSize: 12.5, color: _server.error.isNotEmpty ? Nx.stop : Nx.muted),
                  ),
                ]),
              ),
              if (on)
                OutlinedButton(onPressed: _server.stop, child: const Text('Stop'))
              else
                OutlinedButton(onPressed: _server.starting ? null : () => _server.ensure(htdocsDir), child: const Text('Start')),
            ]),
          );
        },
      );

  Widget _projectCard(HtProject pr) {
    final lang = projectLanguage(pr.name);
    return Material(
      color: Nx.surface,
      borderRadius: BorderRadius.circular(14),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _open(pr.name),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 10, 4, 10),
          child: Row(children: [
            LanguageBadge(lang, size: 38),
            const SizedBox(width: 12),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(pr.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
                Text(_address(pr.name), style: const TextStyle(fontSize: 12.5, color: Color(0xFF8FB0FF), fontFamily: 'Consolas', fontFamilyFallback: ['monospace'])),
                Text(pr.php ? 'PHP site' : 'HTML site', style: const TextStyle(fontSize: 12, color: Nx.muted)),
              ]),
            ),
            IconButton(
              tooltip: _pc ? 'View ${pr.name} in your browser' : 'View ${pr.name}',
              onPressed: () => openProjectSite(context, lang),
              icon: const Icon(Icons.open_in_browser),
            ),
            PopupMenuButton<String>(
              tooltip: 'More for ${pr.name}',
              onSelected: (a) => a == 'rename' ? _rename(pr.name) : _delete(pr.name),
              itemBuilder: (_) => const [
                PopupMenuItem(value: 'rename', child: Text('Rename')),
                PopupMenuItem(value: 'delete', child: Text('Delete')),
              ],
            ),
          ]),
        ),
      ),
    );
  }
}
