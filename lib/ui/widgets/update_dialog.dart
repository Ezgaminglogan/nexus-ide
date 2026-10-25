import 'dart:io';

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/update.dart';
import '../theme.dart';

/// "Update available" dialog: what changes, what it costs, and the next action for the current state.
Future<void> showUpdateDialog(BuildContext context) async {
  await showDialog<void>(context: context, builder: (_) => const _UpdateDialog());
  Updater.instance.releaseModal();
}

String _date(DateTime? d) => d == null ? 'unknown date' : '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

String _mb(int bytes) => '${(bytes / 1e6).toStringAsFixed(0)} MB';

const _sectionHelp = {
  'New Features': 'Things you can do that you could not before.',
  'Improvements': 'Things that work better or faster.',
  'Bug Fixes': 'Problems that are fixed.',
  'Breaking Changes': 'Changes that may need you to do something differently.',
};

class _UpdateDialog extends StatelessWidget {
  const _UpdateDialog();

  @override
  Widget build(BuildContext context) {
    final u = Updater.instance;
    return ListenableBuilder(
      listenable: u,
      builder: (context, _) {
        final r = u.latest;
        if (r == null) return AlertDialog(title: const Text('No update found'), actions: [_close(context)]);
        final notes = parseNotes(r.body);
        final asset = assetFor(r);
        final restart = Platform.isWindows ? 'NEXUS closes, updates itself and reopens.' : 'Android asks you to confirm, then reinstalls NEXUS.';
        return AlertDialog(
          title: Text('Update available: ${u.current ?? '?'} → ${r.version}'),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [
                Text('${r.title} · released ${_date(r.published)}${r.prerelease ? ' · beta' : ''}', style: const TextStyle(color: Nx.muted)),
                const SizedBox(height: 12),
                Text(notes.summary.isNotEmpty ? notes.summary : notes.sections.isEmpty ? 'No release notes were published for this version.' : 'Here is what changed:'),
                for (final s in noteSections)
                  if (notes.sections[s] case final items?) ...[
                    const SizedBox(height: 12),
                    Text(s, style: TextStyle(fontWeight: FontWeight.w700, color: s == 'Breaking Changes' ? Nx.stop : null)),
                    Text(_sectionHelp[s]!, style: const TextStyle(fontSize: 12, color: Nx.muted)),
                    for (final i in items) Padding(padding: const EdgeInsets.only(top: 4, left: 8), child: Text('•  $i')),
                  ],
                const Divider(height: 24),
                Text(asset == null
                    ? 'This release has no package for ${Platform.operatingSystem}, so it cannot be installed here.'
                    : 'Download: ${_mb(asset.size)} · ${asset.name}\n${asset.sha256 == null ? 'Checked by size after download.' : 'Checked against GitHub\'s SHA-256 after download.'}\n$restart\nYour files and settings are kept.'),
                const SizedBox(height: 12),
                Semantics(liveRegion: true, child: _Status(u)),
              ]),
            ),
          ),
          actions: [
            TextButton(onPressed: () => launchUrl(Uri.parse(r.page), mode: LaunchMode.externalApplication), child: const Text('View Release Notes')),
            if (u.status == UpdateStatus.available || u.status == UpdateStatus.failed || u.status == UpdateStatus.offline)
              TextButton(
                onPressed: () {
                  u.remindLater();
                  Navigator.pop(context);
                },
                child: const Text('Remind Me Later'),
              ),
            if (asset != null)
              switch (u.status) {
                UpdateStatus.ready || UpdateStatus.installing =>
                  FilledButton(onPressed: u.status == UpdateStatus.ready ? u.install : null, child: const Text('Install and Restart')),
                UpdateStatus.downloading || UpdateStatus.verifying => const FilledButton(onPressed: null, child: Text('Downloading…')),
                UpdateStatus.failed || UpdateStatus.offline => FilledButton(onPressed: u.download, child: const Text('Retry Download')),
                _ => FilledButton(onPressed: u.download, child: const Text('Download Update')),
              }
            else
              _close(context),
          ],
        );
      },
    );
  }

  Widget _close(BuildContext context) => TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'));
}

/// One line (plus a bar while downloading) saying what the updater is doing.
class _Status extends StatelessWidget {
  const _Status(this.u);
  final Updater u;

  @override
  Widget build(BuildContext context) {
    final text = switch (u.status) {
      UpdateStatus.downloading => 'Downloading… ${(u.progress * 100).toStringAsFixed(0)}%',
      UpdateStatus.verifying => 'Checking the download…',
      UpdateStatus.ready => 'Downloaded and checked. Ready to install.',
      UpdateStatus.installing => 'Saving your files and starting the installer…',
      UpdateStatus.failed || UpdateStatus.offline => u.error,
      _ => '',
    };
    if (text.isEmpty) return const SizedBox.shrink();
    final bad = u.status == UpdateStatus.failed || u.status == UpdateStatus.offline;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      if (u.status == UpdateStatus.downloading) LinearProgressIndicator(value: u.progress),
      if (u.status == UpdateStatus.verifying) const LinearProgressIndicator(),
      const SizedBox(height: 6),
      Text(text, style: TextStyle(color: bad ? Nx.stop : Nx.run)),
    ]);
  }
}
