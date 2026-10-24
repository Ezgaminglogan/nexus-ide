import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Shows a web page (the Web tile's index.html or the PHP server). Phones get an in-app
/// WebView with a phone/full-width switch; PCs open the default browser (no WebView there).
Future<void> openPreview(BuildContext context, Uri uri) async {
  if (!Platform.isAndroid && !Platform.isIOS) {
    await launchUrl(uri);
    return;
  }
  await Navigator.of(context).push(MaterialPageRoute(builder: (_) => PreviewScreen(uri: uri)));
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
