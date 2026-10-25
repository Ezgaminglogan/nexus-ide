import 'package:flutter/material.dart';

import '../../core/update.dart';
import '../theme.dart';
import '../widgets/update_dialog.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final u = Updater.instance;
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListenableBuilder(
        listenable: u,
        builder: (context, _) {
          final last = u.lastCheck;
          final latest = switch (u.status) {
            UpdateStatus.upToDate => 'You have the latest version',
            UpdateStatus.idle || UpdateStatus.checking => 'Not checked yet',
            UpdateStatus.offline || UpdateStatus.failed when u.latest == null => 'Unknown (check failed)',
            _ => u.latest?.version.toString() ?? '—',
          };
          return ListView(padding: const EdgeInsets.all(16), children: [
            const Text('UPDATES', style: TextStyle(fontSize: 12, letterSpacing: 1.2, color: Nx.muted, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Card(
              color: Nx.surface,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  _row('Installed version', u.current?.toString() ?? 'Unknown'),
                  _row('Latest available', latest),
                  _row('Last checked', last == null ? 'Never' : '${last.toLocal()}'.substring(0, 16)),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text('Beta updates'),
                    subtitle: const Text('Also offer test versions before their official release.'),
                    value: u.beta,
                    onChanged: (b) {
                      u.beta = b;
                      u.check();
                    },
                  ),
                  const SizedBox(height: 8),
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      switch (u.status) {
                        UpdateStatus.checking => 'Checking for updates…',
                        UpdateStatus.upToDate => 'NEXUS IDE is up to date.',
                        UpdateStatus.available => 'Version ${u.latest!.version} is ready to download.',
                        UpdateStatus.incompatible => 'Version ${u.latest!.version} has no package for this device.',
                        UpdateStatus.offline || UpdateStatus.failed => u.error,
                        UpdateStatus.downloading => 'Downloading… ${(u.progress * 100).toStringAsFixed(0)}%',
                        UpdateStatus.verifying => 'Checking the download…',
                        UpdateStatus.ready => 'Update downloaded and checked.',
                        UpdateStatus.installing => 'Installing…',
                        UpdateStatus.idle => 'Updates come from the NEXUS IDE GitHub releases. Checking needs internet; everything else works offline.',
                      },
                      style: TextStyle(color: u.status == UpdateStatus.failed || u.status == UpdateStatus.offline ? Nx.stop : Nx.muted),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Wrap(spacing: 8, runSpacing: 8, children: [
                    FilledButton.icon(
                      onPressed: u.status == UpdateStatus.checking ? null : u.check,
                      icon: u.status == UpdateStatus.checking
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.refresh),
                      label: Text(u.status == UpdateStatus.offline || u.status == UpdateStatus.failed ? 'Retry' : 'Check for Updates'),
                    ),
                    if (u.latest != null && u.status != UpdateStatus.upToDate && u.status != UpdateStatus.checking)
                      OutlinedButton(
                        onPressed: () {
                          if (u.claimModal()) showUpdateDialog(context);
                        },
                        child: const Text('See What\'s New'),
                      ),
                  ]),
                ]),
              ),
            ),
          ]);
        },
      ),
    );
  }

  Widget _row(String k, String v) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(children: [
          SizedBox(width: 150, child: Text(k, style: const TextStyle(color: Nx.muted))),
          Expanded(child: Text(v, style: const TextStyle(fontWeight: FontWeight.w600))),
        ]),
      );
}
