import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'month_report_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenClients;

  const HomeScreen({super.key, required this.onOpenClients});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  YearMonth _month = YearMonth.now();

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.summary(_month);
        final ops = <(DateTime, int, Widget)>[
          for (final p in store.payments)
            if (_month.contains(p.paidAt)) (p.paidAt, p.id!, PaymentTile(p)),
          for (final e in store.expenses)
            if (_month.contains(e.spentAt)) (e.spentAt, e.id!, ExpenseTile(e)),
        ]..sort((a, b) {
            final d = b.$1.compareTo(a.$1);
            return d != 0 ? d : b.$2.compareTo(a.$2);
          });

        return Scaffold(
          appBar: AppBar(
            title: const Text('Учёт'),
            actions: [
              IconButton(
                tooltip: 'Отчёт за месяц',
                icon: const Icon(Icons.summarize_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => MonthReportScreen(month: _month)),
                ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(children: [
                  Row(children: [
                    Expanded(
                      child: StatCard(
                        title: 'Пришло',
                        value: money(s.incomeCents),
                        icon: Icons.arrow_downward,
                        color: incomeColor,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: StatCard(
                        title: 'Потрачено',
                        value: money(s.expenseCents),
                        icon: Icons.arrow_upward,
                        color: expenseColor,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 10),
                  StatCard(
                    title: s.profitCents >= 0 ? 'Прибыль за месяц' : 'Убыток за месяц',
                    value: money(s.profitCents),
                    icon: s.profitCents >= 0 ? Icons.trending_up : Icons.trending_down,
                    color: amountColor(s.profitCents),
                    big: true,
                  ),
                  const SizedBox(height: 10),
                  Card(
                    margin: EdgeInsets.zero,
                    child: ListTile(
                      leading: const Icon(Icons.account_balance_wallet_outlined, color: debtColor),
                      title: const Text('Долг клиентов (всего)'),
                      subtitle: store.totalAdvance > 0 ? Text('Авансы: ${money(store.totalAdvance)}') : null,
                      trailing: Text(
                        money(store.totalDebt),
                        style: const TextStyle(color: debtColor, fontWeight: FontWeight.w700, fontSize: 18),
                      ),
                      onTap: widget.onOpenClients,
                    ),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(56),
                      backgroundColor: incomeColor,
                    ),
                    icon: const Icon(Icons.add),
                    label: const Text('Оплата от клиента', style: TextStyle(fontSize: 17)),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaymentFormPage()),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                        icon: const Icon(Icons.local_shipping_outlined),
                        label: const Text('Заказ'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const OrderFormPage()),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                          foregroundColor: expenseColor,
                        ),
                        icon: const Icon(Icons.remove),
                        label: const Text('Расход'),
                        onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ExpenseFormPage()),
                        ),
                      ),
                    ),
                  ]),
                ]),
              ),
              SectionHeader('Движение денег · ${_month.label}'),
              if (ops.isEmpty)
                const EmptyState(icon: Icons.receipt_long_outlined, text: 'В этом месяце пока нет оплат и расходов')
              else
                ...ops.map((o) => o.$3),
            ],
          ),
        );
      },
    );
  }
}
