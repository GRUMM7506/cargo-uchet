import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/export_service.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/charts.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

class MonthReportScreen extends StatefulWidget {
  final YearMonth month;

  const MonthReportScreen({super.key, required this.month});

  @override
  State<MonthReportScreen> createState() => _MonthReportScreenState();
}

class _MonthReportScreenState extends State<MonthReportScreen> {
  late YearMonth _month = widget.month;
  bool _busy = false;

  Future<void> _export(Future<void> Function() job) async {
    setState(() => _busy = true);
    try {
      await job();
    } catch (e) {
      if (mounted) toast(context, 'Ошибка экспорта: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    final m = _month;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final s = store.summary(m);
        final c = context.colors;
        final set = AppSettings.I;
        final byClient = <int, int>{};
        for (final p in store.payments) {
          if (m.contains(p.paidAt)) byClient[p.clientId] = (byClient[p.clientId] ?? 0) + p.amountCents;
        }
        final payers = byClient.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final debtors = store.clients.where((x) => store.balanceOf(x.id!) > 0).toList()
          ..sort((a, b) => store.balanceOf(b.id!).compareTo(store.balanceOf(a.id!)));

        return Scaffold(
          appBar: AppBar(title: const Text('Отчёт')),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Center(child: MonthSwitcher(month: m, onChanged: (x) => setState(() => _month = x))),
              const SizedBox(height: 14),
              SectionCard(children: [
                KeyValue('Пришло (оплаты)', money(s.incomeCents), color: c.income),
                KeyValue('Потрачено (расходы)', money(s.expenseCents), color: c.expense),
                const Divider(height: 18),
                KeyValue(s.profitCents >= 0 ? 'Прибыль' : 'Убыток', money(s.profitCents),
                    color: s.profitCents >= 0 ? c.income : c.expense, strong: true),
              ]),
              const SizedBox(height: 12),
              SectionCard(title: 'Заказы', children: [
                KeyValue('Принято заказов', '${s.ordersCount}'),
                KeyValue('На сумму', money(s.ordersCents)),
                if (set.show(OrderField.weight) && s.weightKg > 0) KeyValue('Общий вес', kg(s.weightKg)),
                if (set.show(OrderField.weight) && s.avgPerKgCents != null)
                  KeyValue('Средняя цена за кг', money(s.avgPerKgCents!)),
                KeyValue('Клиенты должны сейчас', money(store.totalDebt), color: c.debt),
              ]),
              const SizedBox(height: 12),
              _busy
                  ? const Center(child: Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator()))
                  : Row(children: [
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.table_view_outlined),
                          label: const Text('Excel'),
                          onPressed: () => _export(() => ExportService.excel(month: m)),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: FilledButton.tonalIcon(
                          icon: const Icon(Icons.picture_as_pdf_outlined),
                          label: const Text('PDF'),
                          onPressed: () => _export(() => ExportService.pdf(m)),
                        ),
                      ),
                    ]),
              if (s.expensesByCategory.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(title: 'Расходы по категориям', children: [
                  for (final e in s.expensesByCategory.entries)
                    ShareBar(
                      label: e.key,
                      cents: e.value,
                      share: s.expenseCents == 0 ? 0 : e.value / s.expenseCents,
                      color: c.expense,
                      icon: categoryIcon(e.key),
                    ),
                ]),
              ],
              if (payers.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(title: 'Кто сколько заплатил', children: [
                  for (final e in payers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Avatar(store.clientName(e.key), size: 32),
                        const SizedBox(width: 10),
                        Expanded(child: Text(store.clientName(e.key), style: context.tt.bodyMedium)),
                        Text(money(e.value), style: amountStyle(14, color: c.income)),
                      ]),
                    ),
                ]),
              ],
              if (debtors.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(title: 'Должники на сегодня', children: [
                  for (final x in debtors)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Avatar(x.name, size: 32),
                        const SizedBox(width: 10),
                        Expanded(child: Text(x.name, style: context.tt.bodyMedium)),
                        BalancePill(store.balanceOf(x.id!)),
                      ]),
                    ),
                ]),
              ],
            ],
          ),
        );
      },
    );
  }
}
