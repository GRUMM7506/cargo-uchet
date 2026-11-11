import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../l10n.dart';
import '../models.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

class ExpensesScreen extends StatefulWidget {
  const ExpensesScreen({super.key});

  @override
  State<ExpensesScreen> createState() => _ExpensesScreenState();
}

class _ExpensesScreenState extends State<ExpensesScreen> {
  YearMonth _month = YearMonth.now();

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final list = store.expenses.where((e) => _month.contains(e.spentAt)).toList();
        final s = store.summary(_month);
        final c = context.colors;
        final prev = store.summary(_month.prev).expenseCents;
        return Scaffold(
          appBar: AppBar(title: Text(t.tabExpenses)),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: c.expense,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.add_rounded),
            label: Text(t.expenseOne),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseFormPage())),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Center(child: MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m))),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionCard(
                  children: [
                    Row(children: [
                      IconBadge(Icons.north_east_rounded, color: c.expense, background: c.expenseBg),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(t.spentIn(_month.name), style: context.tt.bodyMedium?.copyWith(color: c.muted)),
                          Text(money(s.expenseCents), style: amountStyle(28, color: c.expense)),
                        ]),
                      ),
                    ]),
                    if (prev > 0 || s.expenseCents > 0) ...[
                      const SizedBox(height: 10),
                      Text(_compare(s.expenseCents, prev), style: context.tt.bodySmall?.copyWith(color: c.muted)),
                    ],
                    if (s.expensesByCategory.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      const Divider(),
                      const SizedBox(height: 6),
                      for (final e in s.expensesByCategory.entries)
                        ShareBar(
                          label: e.key,
                          cents: e.value,
                          share: s.expenseCents == 0 ? 0 : e.value / s.expenseCents,
                          color: c.expense,
                          icon: categoryIcon(e.key),
                        ),
                    ],
                  ],
                ),
              ),
              if (list.isEmpty)
                EmptyState(icon: Icons.savings_outlined, title: t.noExpenses, text: t.noExpensesHint)
              else ...[
                DayGroupedList(items: [for (final e in list) (e.spentAt, ExpenseTile(e))]),
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text(t.swipeHint,
                      textAlign: TextAlign.center, style: context.tt.bodySmall?.copyWith(color: c.muted)),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  String _compare(int now, int prev) {
    if (prev == 0) return t.noExpensesPrev;
    final diff = now - prev;
    final pct = (diff.abs() / prev * 100).round();
    if (diff == 0) return t.sameAsPrev;
    return diff > 0 ? t.moreThanPrev(money(diff), pct) : t.lessThanPrev(money(-diff), pct);
  }
}
