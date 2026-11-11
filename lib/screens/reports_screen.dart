import 'package:flutter/material.dart';

import '../format.dart';
import '../l10n.dart';
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
        var totalIncome = 0, totalExpense = 0, totalOrders = 0, ordersCount = 0;
        for (final m in months) {
          final s = store.summary(m);
          totalIncome += s.incomeCents;
          totalExpense += s.expenseCents;
          totalOrders += s.ordersCents;
          ordersCount += s.ordersCount;
        }
        final totalProfit = totalIncome - totalExpense;
        final c = context.colors;
        return Scaffold(
          appBar: AppBar(
            title: Text(t.tabReports),
            actions: [
              IconButton(
                tooltip: t.excelAll,
                icon: const Icon(Icons.table_view_outlined),
                onPressed: () async {
                  try {
                    await ExportService.excel();
                  } catch (e) {
                    if (context.mounted) toast(context, t.error(e));
                  }
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              SectionCard(title: t.last6, children: [MonthBars(onTap: (m) => _openMonth(context, m))]),
              const SizedBox(height: 12),
              SectionCard(
                title: '${t.allTime} · ${t.ordersAndDebt}',
                children: [
                  KeyValue(t.ordersSumCount(ordersCount), money(totalOrders)),
                  KeyValue('− ${t.receivedMoney}', money(totalIncome), color: c.income),
                  if (store.totalOverpaid > 0) KeyValue('+ ${t.overpaidLine}', money(store.totalOverpaid), color: c.income),
                  const Divider(height: 18),
                  KeyValue(t.debtLeft, money(store.totalDebt), color: c.debt, strong: true),
                  const SizedBox(height: 4),
                  Text(t.debtFormula, style: context.tt.bodySmall?.copyWith(color: c.muted)),
                ],
              ),
              const SizedBox(height: 12),
              SectionCard(
                title: '${t.allTime} · ${t.moneySection}',
                children: [
                  KeyValue(t.income, money(totalIncome), color: c.income),
                  KeyValue(t.expense, money(totalExpense), color: c.expense),
                  const Divider(height: 18),
                  KeyValue(totalProfit >= 0 ? t.profit : t.loss, money(totalProfit),
                      color: totalProfit >= 0 ? c.income : c.expense, strong: true),
                ],
              ),
              SectionHeader(t.byMonths, padding: const EdgeInsets.fromLTRB(4, 22, 4, 10)),
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
                  Pill(t.current, color: context.cs.primary, background: context.cs.primaryContainer.withValues(alpha: 0.6)),
                ],
                const Spacer(),
                Text(money(s.profitCents), style: amountStyle(18, color: s.profitCents >= 0 ? c.income : c.expense)),
              ]),
              const SizedBox(height: 12),
              Row(children: [
                _mini(context, t.income, money(s.incomeCents), c.income),
                _mini(context, t.expense, money(s.expenseCents), c.expense),
                _mini(context, t.ordersCountLabel, '${s.ordersCount} · ${money(s.ordersCents)}', null),
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
