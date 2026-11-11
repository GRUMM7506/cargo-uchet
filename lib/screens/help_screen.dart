import 'package:flutter/material.dart';

import '../l10n.dart';
import '../theme.dart';
import '../widgets/common.dart';
import 'intro_screen.dart';

/// «Как пользоваться» — короткая инструкция по разделам.
class HelpScreen extends StatelessWidget {
  const HelpScreen({super.key});

  static const _icons = [
    Icons.people_outline_rounded,
    Icons.handyman_outlined,
    Icons.savings_outlined,
    Icons.calculate_outlined,
    Icons.north_east_rounded,
    Icons.insert_chart_outlined_rounded,
    Icons.currency_exchange_rounded,
    Icons.edit_note_rounded,
    Icons.cloud_upload_outlined,
  ];

  @override
  Widget build(BuildContext context) {
    final sections = t.helpSections;
    return Scaffold(
      appBar: AppBar(title: Text(t.help)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
        children: [
          for (var i = 0; i < sections.length; i++) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  IconBadge(
                    _icons[i % _icons.length],
                    size: 42,
                    color: context.cs.primary,
                    background: context.cs.primaryContainer.withValues(alpha: 0.6),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(sections[i].$1, style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 6),
                      Text(sections[i].$2, style: context.tt.bodyMedium?.copyWith(height: 1.45)),
                    ]),
                  ),
                ]),
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 6),
          OutlinedButton.icon(
            icon: const Icon(Icons.slideshow_rounded),
            label: Text(t.replayIntro),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const IntroScreen(replay: true)),
            ),
          ),
        ],
      ),
    );
  }
}
