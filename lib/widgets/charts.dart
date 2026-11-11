import 'package:flutter/material.dart';

import '../currency.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';

/// Столбики «пришло / потрачено» за последние [count] месяцев.
class MonthBars extends StatelessWidget {
  final int count;
  final ValueChanged<YearMonth>? onTap;

  const MonthBars({super.key, this.count = 6, this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    final months = <YearMonth>[];
    var m = YearMonth.now();
    for (var i = 0; i < count; i++) {
      months.insert(0, m);
      m = m.prev;
    }
    final sums = [for (final x in months) store.summary(x)];
    var maxV = 1;
    for (final s in sums) {
      if (s.incomeCents > maxV) maxV = s.incomeCents;
      if (s.expenseCents > maxV) maxV = s.expenseCents;
    }
    final c = context.colors;
    final current = YearMonth.now();

    return Column(children: [
      SizedBox(
        height: 150,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            for (final s in sums)
              Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: onTap == null ? null : () => onTap!(s.month),
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    padding: const EdgeInsets.fromLTRB(4, 6, 4, 0),
                    decoration: BoxDecoration(
                      color: s.month == current ? context.cs.primaryContainer.withValues(alpha: 0.45) : null,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          s.profitCents == 0 ? '' : _compact(s.profitCents),
                          maxLines: 1,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: s.profitCents >= 0 ? c.income : c.expense,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              _bar(s.incomeCents / maxV, c.income),
                              const SizedBox(width: 3),
                              _bar(s.expenseCents / maxV, c.expense),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
      const SizedBox(height: 6),
      Row(children: [
        for (final s in sums)
          Expanded(
            child: Text(
              s.month.shortLabel,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                fontWeight: s.month == current ? FontWeight.w700 : FontWeight.w500,
                color: s.month == current ? context.cs.primary : c.muted,
              ),
            ),
          ),
      ]),
      const SizedBox(height: 10),
      Row(mainAxisAlignment: MainAxisAlignment.center, children: [
        _legend(context, c.income, t.income),
        const SizedBox(width: 18),
        _legend(context, c.expense, t.expense),
      ]),
    ]);
  }

  Widget _bar(double frac, Color color) => Flexible(
        child: FractionallySizedBox(
          alignment: Alignment.bottomCenter,
          heightFactor: frac.clamp(0.02, 1.0),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 12),
            decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(5)),
          ),
        ),
      );

  Widget _legend(BuildContext context, Color color, String text) => Row(children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3))),
        const SizedBox(width: 6),
        Text(text, style: context.tt.bodySmall),
      ]);

  static String _compact(int cents) {
    final v = cents / 100;
    final sign = v < 0 ? '−' : '';
    final a = v.abs();
    String n;
    if (a >= 1e6) {
      n = '${(a / 1e6).toStringAsFixed(a >= 1e7 ? 0 : 1)}M';
    } else if (a >= 1000) {
      n = '${(a / 1000).toStringAsFixed(a >= 10000 ? 0 : 1)}k';
    } else {
      n = '${a.round()}';
    }
    final c = currencyOf(AppSettings.I.currency);
    final sym = currencySymbol(c.code);
    return c.prefix ? '$sign$sym$n' : '$sign$n $sym';
  }
}

/// Горизонтальная полоса доли (для категорий расходов).
class ShareBar extends StatelessWidget {
  final String label;
  final int cents;
  final double share;
  final Color color;
  final IconData? icon;

  const ShareBar({super.key, required this.label, required this.cents, required this.share, required this.color, this.icon});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          if (icon != null) ...[Icon(icon, size: 18, color: color), const SizedBox(width: 8)],
          Expanded(child: Text(label, style: context.tt.bodyMedium?.copyWith(fontWeight: FontWeight.w600))),
          Text('${(share * 100).round()}%', style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
          const SizedBox(width: 10),
          Text(money(cents), style: amountStyle(14)),
        ]),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: share,
            minHeight: 8,
            color: color,
            backgroundColor: color.withValues(alpha: 0.12),
          ),
        ),
      ]),
    );
  }
}
