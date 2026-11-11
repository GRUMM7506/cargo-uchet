import 'package:flutter/material.dart';

import '../forms.dart';
import '../l10n.dart';
import '../services/export_service.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

/// Карточка «С чего начать» на главной: шаги отмечаются сами по мере работы.
class GettingStartedCard extends StatelessWidget {
  const GettingStartedCard({super.key});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    final set = AppSettings.I;
    void open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

    final steps = <(bool, IconData, String, String, VoidCallback)>[
      (store.clients.isNotEmpty, Icons.person_add_alt_1_outlined, t.gsStep1, t.gsStep1Hint,
          () => open(const ClientFormPage())),
      (store.orders.isNotEmpty, Icons.handyman_outlined, t.gsStep2, t.gsStep2Hint, () => open(const OrderFormPage())),
      (
        store.payments.isNotEmpty || store.orders.any((o) => o.depositCents > 0),
        Icons.south_west_rounded,
        t.gsStep3,
        t.gsStep3Hint,
        () => open(const PaymentFormPage())
      ),
      (store.expenses.isNotEmpty, Icons.north_east_rounded, t.gsStep4, t.gsStep4Hint,
          () => open(const ExpenseFormPage())),
      (set.backupDone, Icons.cloud_upload_outlined, t.gsStep5, t.gsStep5Hint, () async {
        try {
          await ExportService.shareBackup();
        } catch (e) {
          if (context.mounted) toast(context, t.error(e));
        }
      }),
    ];
    final done = steps.where((s) => s.$1).length;
    final all = done == steps.length;
    final cs = context.cs;

    return Card(
      color: cs.primaryContainer.withValues(alpha: context.isDark ? 0.35 : 0.45),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 8, 10),
        child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
          Row(children: [
            Icon(all ? Icons.celebration_rounded : Icons.school_outlined, color: cs.primary),
            const SizedBox(width: 10),
            Expanded(child: Text(all ? t.gsDoneTitle : t.gsTitle, style: context.tt.titleMedium)),
            Text('$done/${steps.length}', style: context.tt.labelLarge?.copyWith(color: cs.primary)),
            TextButton(onPressed: () => set.setChecklistHidden(true), child: Text(t.gsHide)),
          ]),
          Padding(
            padding: const EdgeInsets.only(right: 8, top: 4, bottom: 6),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: done / steps.length,
                minHeight: 6,
                backgroundColor: cs.surface.withValues(alpha: 0.6),
              ),
            ),
          ),
          if (all)
            Padding(
              padding: const EdgeInsets.fromLTRB(0, 4, 8, 6),
              child: Text(t.gsDoneText, style: context.tt.bodyMedium),
            )
          else
            for (final s in steps)
              InkWell(
                borderRadius: BorderRadius.circular(12),
                onTap: s.$1 ? null : s.$5,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 7),
                  child: Row(children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: s.$1 ? context.colors.income : cs.surface,
                        shape: BoxShape.circle,
                        border: s.$1 ? null : Border.all(color: cs.outlineVariant),
                      ),
                      child: Icon(s.$1 ? Icons.check_rounded : s.$2,
                          size: 17, color: s.$1 ? Colors.white : cs.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Text(
                          s.$3,
                          style: context.tt.titleSmall?.copyWith(
                            decoration: s.$1 ? TextDecoration.lineThrough : null,
                            color: s.$1 ? context.colors.muted : null,
                          ),
                        ),
                        if (!s.$1)
                          Text(s.$4, style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
                      ]),
                    ),
                    if (!s.$1) Icon(Icons.chevron_right_rounded, color: cs.primary),
                    const SizedBox(width: 6),
                  ]),
                ),
              ),
        ]),
      ),
    );
  }
}
