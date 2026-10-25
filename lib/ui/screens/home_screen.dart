import 'dart:io';

import 'package:flutter/material.dart';
import 'package:hugeicons/hugeicons.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/core.dart';
import '../theme.dart';
import '../widgets/update_dialog.dart';
import 'editor_screen.dart';
import 'learn_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    // Settings shows the version right away; after an update, say what's new (once).
    Updater.instance.loadCurrent().then((_) {
      final r = Updater.instance.takeWhatsNew();
      if (r != null && mounted) showWhatsNewDialog(context, r);
    });
    // Once a day, quietly: offline labs just skip it. Never in widget tests (no network).
    if (!Platform.environment.containsKey('FLUTTER_TEST')) {
      Updater.instance.autoCheck().then((show) {
        if (show && mounted) showUpdateDialog(context);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width > 720;
    return Scaffold(
      body: CustomScrollView(slivers: [
        SliverToBoxAdapter(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 2400), // fills a lab PC screen, caps ultrawide
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _Header(),
                  const _LearnCard(),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
                    child: Text('Start coding', style: Theme.of(context).textTheme.titleMedium?.copyWith(color: Nx.muted)),
                  ),
                  GridView(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                    gridDelegate: wide
                        ? const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 4, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 215)
                        : const SliverGridDelegateWithFixedCrossAxisCount(crossAxisCount: 2, mainAxisSpacing: 12, crossAxisSpacing: 12, mainAxisExtent: 215),
                    children: [for (final l in languages) _LanguageTile(l)],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
        // Footer sits at the bottom of the screen, or after the tiles when they need scrolling.
        const SliverFillRemaining(hasScrollBody: false, child: Align(alignment: Alignment.bottomCenter, child: _Footer())),
      ]),
    );
  }
}

class _Footer extends StatelessWidget {
  const _Footer();

  static const _links = [
    (HugeIcons.strokeRoundedFacebook01, 'Facebook', 'https://www.facebook.com/Cflogan.Panucat2nd'),
    (HugeIcons.strokeRoundedGithub, 'GitHub', 'https://github.com/Ezgaminglogan'),
    (HugeIcons.strokeRoundedLinkedin01, 'LinkedIn', 'https://www.linkedin.com/in/logan-panucat-b319562a9/'),
    (HugeIcons.strokeRoundedMail01, 'Email', 'mailto:logan.panucat2@gmail.com'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      const Divider(color: Nx.line, height: 1),
      const SizedBox(height: 12),
      const Text.rich(
        TextSpan(children: [
          TextSpan(text: 'Developed by '),
          TextSpan(text: 'Logan M. Panucat', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
          TextSpan(text: ' · Developer'),
        ]),
        style: TextStyle(color: Nx.muted, fontSize: 12.5),
      ),
      Padding(
        padding: const EdgeInsets.fromLTRB(0, 4, 0, 12),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          for (final (icon, name, url) in _links)
            IconButton(
              tooltip: name,
              onPressed: () => launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication),
              icon: HugeIcon(icon: icon, color: Nx.muted, size: 22),
            ),
        ]),
      ),
    ]);
  }
}

class _Header extends StatelessWidget {
  const _Header();

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        SizedBox(
          height: 190,
          width: double.infinity,
          child: Image.asset('assets/images/CTU_Image.jpg', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Nx.bg.withValues(alpha: 0.05), Nx.bg],
              ),
            ),
          ),
        ),
        Positioned(
          left: 20,
          bottom: -26,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Container(
                width: 76,
                height: 76,
                decoration: const BoxDecoration(shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black54, blurRadius: 12)]),
                child: ClipOval(child: Image.asset('assets/images/CTU Logo.png', semanticLabel: 'CTU seal')),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('NEXUS IDE', style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
                  Text('CTU Naga Extension Campus · works offline', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5)),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          top: 8,
          right: 8,
          child: SafeArea(
            child: IconButton.filledTonal(
              tooltip: 'Settings and updates',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const SettingsScreen())),
              icon: const Icon(Icons.settings_outlined),
            ),
          ),
        ),
      ],
    ).withBottomSpace(34);
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile(this.lang);
  final Language lang;

  @override
  Widget build(BuildContext context) {
    final pcOnly = !lang.availableHere;
    final big = MediaQuery.sizeOf(context).width > 720; // lab PC: bigger icons and text
    final color = Color(lang.color);
    return Material(
      color: Nx.surface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => EditorScreen(language: lang))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Name and tagline beside the icon, what you do with it below, where it runs at the bottom.
              Row(
                children: [
                  LanguageBadge(lang, size: big ? 56 : 38),
                  SizedBox(width: big ? 14 : 10),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(lang.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: big ? 24 : 16, fontWeight: FontWeight.w700)),
                      Text(lang.blurb, maxLines: big ? 1 : 2, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: big ? 14 : 11, height: 1.25, color: color)),
                    ]),
                  ),
                ],
              ),
              SizedBox(height: big ? 14 : 8),
              Expanded(
                child: Text(
                  lang.description,
                  maxLines: big ? 4 : 7,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: big ? 14.5 : 12, height: 1.4, color: const Color(0xFFC3CBE0)),
                ),
              ),
              Row(children: [
                Container(height: 3, width: 28, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
                const Spacer(),
                Text(
                  pcOnly ? (Platform.isIOS ? 'Android & PC' : 'PC only') : (lang.androidSteps != null ? 'Phone · PC' : 'PC'),
                  style: TextStyle(fontSize: big ? 12 : 10.5, color: Nx.muted),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

/// Entry to Learn & Practice: lessons, a quiz and checked exercises for every workspace.
class _LearnCard extends StatelessWidget {
  const _LearnCard();

  @override
  Widget build(BuildContext context) {
    void open() => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const LearnScreen()));
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      child: Material(
        color: Nx.surface,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: open,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              const HugeIcon(icon: HugeIcons.strokeRoundedMortarboard02, color: Color(0xFF8FB0FF), size: 34),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('Learn & Practice', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
                  SizedBox(height: 2),
                  Text('Offline lessons, quizzes and checked exercises for all 8 workspaces.', style: TextStyle(fontSize: 13, color: Nx.muted)),
                ]),
              ),
              const SizedBox(width: 8),
              FilledButton.tonal(onPressed: open, child: const Text('Open')),
            ]),
          ),
        ),
      ),
    );
  }
}

extension on Widget {
  Widget withBottomSpace(double h) => Padding(padding: EdgeInsets.only(bottom: h), child: this);
}
