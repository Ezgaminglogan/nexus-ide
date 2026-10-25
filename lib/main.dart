import 'package:flutter/material.dart';

import 'core/core.dart';
import 'ui/screens/home_screen.dart';
import 'ui/theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  registerHighlighting(); // HTML/PHP: CSS, JS and PHP inside the page
  runApp(NexusApp(ready: Toolchains.init()));
}

class NexusApp extends StatelessWidget {
  const NexusApp({super.key, required this.ready});

  /// Toolchain setup (unzips compilers on a phone's first launch).
  final Future<void> ready;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NEXUS IDE',
      debugShowCheckedModeBanner: false,
      theme: Nx.theme(),
      home: FutureBuilder(
        future: ready,
        builder: (context, snap) => snap.connectionState == ConnectionState.done ? const HomeScreen() : const _SetupScreen(),
      ),
    );
  }
}

class _SetupScreen extends StatelessWidget {
  const _SetupScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ClipOval(child: Image.asset('assets/images/CTU Logo.png', width: 110)),
          const SizedBox(height: 24),
          const Text('NEXUS IDE', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 16),
          const SizedBox(width: 160, child: LinearProgressIndicator()),
          const SizedBox(height: 12),
          const Text('Setting up compilers…', style: TextStyle(color: Nx.muted)),
          const Text('(first launch only)', style: TextStyle(color: Nx.muted, fontSize: 12)),
        ]),
      ),
    );
  }
}
