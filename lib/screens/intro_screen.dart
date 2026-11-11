import 'package:flutter/material.dart';

import '../l10n.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Вступление при первом запуске: 5 коротких экранов, на первом — выбор языка.
class IntroScreen extends StatefulWidget {
  /// Открыто повторно из настроек (тогда по завершении просто закрываем).
  final bool replay;

  const IntroScreen({super.key, this.replay = false});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> {
  final _page = PageController();
  int _index = 0;

  @override
  void dispose() {
    _page.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    await AppSettings.I.setIntroDone(true);
    if (widget.replay && mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.I;
    final cs = context.cs;
    final c = context.colors;
    final pages = <_IntroPage>[
      _IntroPage(
        art: ClipRRect(
          borderRadius: BorderRadius.circular(36),
          child: Image.asset('assets/images/logo.png', width: 132, height: 132),
        ),
        title: t.intro1Title,
        text: t.intro1Text,
        extra: Column(children: [
          const SizedBox(height: 22),
          SegmentedButton<String>(
            segments: [
              for (final e in AppSettings.languages.entries) ButtonSegment(value: e.key, label: segLabel(e.value)),
            ],
            selected: {s.lang},
            showSelectedIcon: false,
            onSelectionChanged: (v) => s.setLang(v.first),
          ),
        ]),
      ),
      _IntroPage(
        art: _Art(main: Icons.handyman_rounded, a: Icons.person_rounded, b: Icons.photo_camera_rounded, color: cs.primary),
        title: t.intro2Title,
        text: t.intro2Text,
      ),
      _IntroPage(
        art: _Art(main: Icons.south_west_rounded, a: Icons.savings_rounded, b: Icons.check_rounded, color: c.income),
        title: t.intro3Title,
        text: t.intro3Text,
      ),
      _IntroPage(
        art: _Art(main: Icons.insert_chart_rounded, a: Icons.north_east_rounded, b: Icons.flight_takeoff_rounded, color: c.debt),
        title: t.intro4Title,
        text: t.intro4Text,
      ),
      _IntroPage(
        art: _Art(
          main: Icons.currency_exchange_rounded,
          a: Icons.cloud_upload_rounded,
          b: Icons.send_rounded,
          color: cs.tertiary,
        ),
        title: t.intro5Title,
        text: t.intro5Text,
      ),
    ];
    final last = _index == pages.length - 1;

    return Scaffold(
      body: SafeArea(
        child: Column(children: [
          Align(
            alignment: Alignment.centerRight,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 0),
              child: AnimatedOpacity(
                opacity: last ? 0 : 1,
                duration: const Duration(milliseconds: 200),
                child: TextButton(onPressed: last ? null : _finish, child: Text(t.introSkip)),
              ),
            ),
          ),
          Expanded(
            child: PageView(
              controller: _page,
              onPageChanged: (i) => setState(() => _index = i),
              children: pages,
            ),
          ),
          Row(mainAxisAlignment: MainAxisAlignment.center, children: [
            for (var i = 0; i < pages.length; i++)
              AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: i == _index ? 22 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: i == _index ? cs.primary : cs.outlineVariant,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
          ]),
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: FilledButton(
              style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(54)),
              onPressed: last
                  ? _finish
                  : () => _page.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeOutCubic),
              child: Text(last ? t.introStart : t.introNext, style: const TextStyle(fontSize: 16)),
            ),
          ),
        ]),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  final Widget art;
  final String title;
  final String text;
  final Widget? extra;

  const _IntroPage({required this.art, required this.title, required this.text, this.extra});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
      child: Column(children: [
        const SizedBox(height: 24),
        art,
        const SizedBox(height: 32),
        Text(title, textAlign: TextAlign.center, style: context.tt.headlineSmall),
        const SizedBox(height: 14),
        Text(
          text,
          textAlign: TextAlign.center,
          style: context.tt.bodyLarge?.copyWith(color: context.cs.onSurfaceVariant, height: 1.45),
        ),
        if (extra != null) extra!,
      ]),
    );
  }
}

/// Простая «иллюстрация»: большой значок и два маленьких рядом.
class _Art extends StatelessWidget {
  final IconData main;
  final IconData a;
  final IconData b;
  final Color color;

  const _Art({required this.main, required this.a, required this.b, required this.color});

  @override
  Widget build(BuildContext context) {
    Widget badge(IconData i) => Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: context.cs.surfaceContainerLowest,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 12, offset: const Offset(0, 4))],
          ),
          child: Icon(i, color: color, size: 26),
        );
    return SizedBox(
      width: 200,
      height: 170,
      child: Stack(alignment: Alignment.center, children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [color, Color.lerp(color, Colors.black, 0.25)!],
            ),
            borderRadius: BorderRadius.circular(40),
            boxShadow: [BoxShadow(color: color.withValues(alpha: 0.35), blurRadius: 24, offset: const Offset(0, 10))],
          ),
          child: Icon(main, color: Colors.white, size: 64),
        ),
        Positioned(left: 8, top: 4, child: badge(a)),
        Positioned(right: 8, bottom: 4, child: badge(b)),
      ]),
    );
  }
}
