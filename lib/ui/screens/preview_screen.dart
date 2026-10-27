import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../core/core.dart';

/// Shows a web page (the Web tile's index.html or the PHP server). Phones get an in-app
/// WebView with a phone/full-width switch; PCs open the default browser (no WebView there).
Future<void> openPreview(BuildContext context, Uri uri) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    await launchUrl(uri, mode: LaunchMode.externalApplication); // the student's own browser
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PreviewScreen(uri: uri)));
}

/// Shows a project the XAMPP way: its folder's parent is served at http://localhost/ and the
/// project at `http://localhost/<project>/` (plus [file]). PCs open the real browser (Chrome, Edge...);
/// phones show it inside NEXUS. A Web (HTML) project on a phone, or when PHP is missing, opens
/// straight from the file, which needs no server.
Future<void> openProjectSite(BuildContext context, Language lang, {String file = ''}) async {
  final dir = RunSession.workDir(lang);
  final page = file.endsWith('.php') || file.endsWith('.html') || file.endsWith('.htm') ? file : '';
  Future<void> fromFile() => openPreview(context, File('${dir.path}/${page.isEmpty ? lang.fileName : page}').absolute.uri);
  if (lang.id == 'web' && (Platform.isAndroid || Platform.isIOS)) return fromFile();
  final server = LocalServer.instance;
  if (!await server.ensure(dir.parent.path)) {
    if (!context.mounted) return;
    if (lang.id == 'web') return fromFile(); // plain HTML still opens without a server
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(server.error)));
    return;
  }
  if (context.mounted) await openPreview(context, server.url(dir.uri.pathSegments.where((s) => s.isNotEmpty).last, page));
}

class PreviewScreen extends StatefulWidget {
  const PreviewScreen({super.key, required this.uri});
  final Uri uri;

  @override
  State<PreviewScreen> createState() => _PreviewScreenState();
}

class _PreviewScreenState extends State<PreviewScreen> {
  late final _web = WebViewController()..setJavaScriptMode(JavaScriptMode.unrestricted);
  bool _phoneWidth = false; // see the page at phone width on a tablet / landscape

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() => widget.uri.isScheme('file') ? _web.loadFile(widget.uri.toFilePath()) : _web.loadRequest(widget.uri);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.uri.isScheme('file') ? 'Preview' : widget.uri.toString(), style: const TextStyle(fontSize: 15)),
        actions: [
          IconButton(
            tooltip: _phoneWidth ? 'Full width' : 'Phone width',
            onPressed: () => setState(() => _phoneWidth = !_phoneWidth),
            icon: Icon(_phoneWidth ? Icons.desktop_windows_outlined : Icons.smartphone),
          ),
          IconButton(tooltip: 'Reload', onPressed: _load, icon: const Icon(Icons.refresh)),
        ],
      ),
      body: Center(
        child: SizedBox(width: _phoneWidth ? 390 : double.infinity, child: WebViewWidget(controller: _web)),
      ),
    );
  }
}
