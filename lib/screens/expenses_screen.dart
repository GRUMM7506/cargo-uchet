import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../store.dart';
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
      listenable: store,
      builder: (context, _) {
        final list = store.expenses.where((e) => _month.contains(e.spentAt)).toList();
        final s = store.summary(_month);
        return Scaffold(
          appBar: AppBar(title: const Text('Расходы')),
          floatingActionButton: FloatingActionButton.extended(
            backgroundColor: expenseColor,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.remove),
            label: const Text('Расход'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ExpenseFormPage())),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 88),
            children: [
              MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: StatCard(
                  title: 'Всего за месяц',
                  value: money(s.expenseCents),
                  icon: Icons.arrow_upward,
                  color: expenseColor,
                  big: true,
                ),
              ),
              if (s.expensesByCategory.isNotEmpty) ...[
                const SectionHeader('По категориям'),
                ...s.expensesByCategory.entries.map((e) => _CategoryBar(
                      name: e.key,
                      cents: e.value,
                      share: s.expenseCents == 0 ? 0 : e.value / s.expenseCents,
                    )),
              ],
              const SectionHeader('Записи'),
              if (list.isEmpty)
                const EmptyState(icon: Icons.money_off, text: 'Расходов в этом месяце нет')
              else
                ...list.map((e) => ExpenseTile(e)),
            ],
          ),
        );
      },
    );
  }
}

class _CategoryBar extends StatelessWidget {
  final String name;
  final int cents;
  final double share;

  const _CategoryBar({required this.name, required this.cents, required this.share});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Expanded(child: Text(name)),
            Text('${money(cents)}  ·  ${(share * 100).round()}%',
                style: const TextStyle(fontWeight: FontWeight.w600)),
          ]),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: share,
              minHeight: 6,
              color: expenseColor,
              backgroundColor: expenseColor.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
    );
  }
}
