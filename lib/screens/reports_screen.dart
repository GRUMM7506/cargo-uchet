import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/export_service.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import 'month_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  void _openMonth(BuildContext context, YearMonth m) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => MonthReportScreen(month: m)));

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final months = store.months;
        var totalIncome = 0, totalExpense = 0;
        for (final m in months) {
          final s = store.summary(m);
          totalIncome += s.incomeCents;
          totalExpense += s.expenseCents;
        }
        final totalProfit = totalIncome - totalExpense;
        return Scaffold(
          appBar: AppBar(
            title: const Text('Отчёты'),
            actions: [
              IconButton(
                tooltip: 'Excel за всё время',
                icon: const Icon(Icons.table_view_outlined),
                onPressed: () async {
                  try {
                    await ExportService.excel();
                  } catch (e) {
                    if (context.mounted) toast(context, 'Ошибка: $e');
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              SectionCard(
                title: 'Последние 6 месяцев',
                children: [MonthBars(onTap: (m) => _openMonth(context, m))],
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: 'За всё время',
                children: [
                  KeyValue('Пришло', money(totalIncome), color: context.colors.income),
                  KeyValue('Потрачено', money(totalExpense), color: context.colors.expense),
                  const Divider(height: 18),
                  KeyValue(totalProfit >= 0 ? 'Прибыль' : 'Убыток', money(totalProfit),
                      color: totalProfit >= 0 ? context.colors.income : context.colors.expense, strong: true),
                ],
              ),
              const SectionHeader('По месяцам', padding: EdgeInsets.fromLTRB(4, 22, 4, 10)),
              for (final m in months) ...[
                _MonthCard(month: m, onTap: () => _openMonth(context, m)),
                const SizedBox(height: 10),
              ],
            ],
          ),
        );
      },
    );
  }
}

class _MonthCard extends StatelessWidget {
  final YearMonth month;
  final VoidCallback onTap;

  const _MonthCard({required this.month, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I.summary(month);
    final c = context.colors;
    final isCurrent = month == YearMonth.now();
    final set = AppSettings.I;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Text(month.label, style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                if (isCurrent) ...[
                  const SizedBox(width: 8),
                  Pill('текущий', color: context.cs.primary, background: context.cs.primaryContainer.withValues(alpha: 0.6)),
                ],
                const Spacer(),
                Text(money(s.profitCents), style: amountStyle(18, color: s.profitCents >= 0 ? c.income : c.expense)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _mini(context, 'Пришло', money(s.incomeCents), c.income),
                _mini(context, 'Потрачено', money(s.expenseCents), c.expense),
                _mini(
                  context,
                  'Заказы',
                  '${s.ordersCount}${set.show(OrderField.weight) && s.weightKg > 0 ? ' · ${kg(s.weightKg)}' : ''}',
                  null,
                ),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(BuildContext context, String label, String value, Color? color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(value, style: amountStyle(14, color: color ?? context.cs.onSurface, weight: FontWeight.w600)),
          ),
        ]),
      );
}
