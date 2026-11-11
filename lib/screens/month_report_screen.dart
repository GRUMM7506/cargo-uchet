import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/export_service.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

class MonthReportScreen extends StatefulWidget {
  final YearMonth month;

  const MonthReportScreen({super.key, required this.month});

  @override
  State<MonthReportScreen> createState() => _MonthReportScreenState();
}

class _MonthReportScreenState extends State<MonthReportScreen> {
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
    final m = widget.month;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final s = store.summary(m);
        // Оплаты месяца по клиентам
        final byClient = <int, int>{};
        for (final p in store.payments) {
          if (m.contains(p.paidAt)) byClient[p.clientId] = (byClient[p.clientId] ?? 0) + p.amountCents;
        }
        final payers = byClient.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final debtors = store.clients.where((c) => store.balanceOf(c.id!) > 0).toList()
          ..sort((a, b) => store.balanceOf(b.id!).compareTo(store.balanceOf(a.id!)));

        return Scaffold(
          appBar: AppBar(title: Text(m.label)),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(children: [
                      _kv(context, 'Пришло (оплаты)', money(s.incomeCents), incomeColor),
                      _kv(context, 'Потрачено (расходы)', money(s.expenseCents), expenseColor),
                      const Divider(height: 20),
                      _kv(context, s.profitCents >= 0 ? 'Прибыль' : 'Убыток', money(s.profitCents),
                          amountColor(s.profitCents),
                          big: true),
                      const SizedBox(height: 10),
                      _kv(context, 'Заказов принято', '${s.ordersCount} на ${money(s.ordersCents)}', null),
                      if (s.weightKg > 0) _kv(context, 'Общий вес', kg(s.weightKg), null),
                      _kv(context, 'Долг клиентов сейчас', money(store.totalDebt), debtColor),
                    ]),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: _busy
                    ? const Center(child: Padding(padding: EdgeInsets.all(12), child: CircularProgressIndicator()))
                    : Row(children: [
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            icon: const Icon(Icons.table_chart_outlined),
                            label: const Text('Excel'),
                            onPressed: () => _export(() => ExportService.excel(month: m)),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FilledButton.tonalIcon(
                            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                            icon: const Icon(Icons.picture_as_pdf_outlined),
                            label: const Text('PDF'),
                            onPressed: () => _export(() => ExportService.pdf(m)),
                          ),
                        ),
                      ]),
              ),
              if (s.expensesByCategory.isNotEmpty) ...[
                const SectionHeader('Расходы по категориям'),
                for (final e in s.expensesByCategory.entries)
                  ListTile(dense: true, title: Text(e.key), trailing: Text(money(e.value))),
              ],
              if (payers.isNotEmpty) ...[
                const SectionHeader('Кто сколько заплатил'),
                for (final e in payers)
                  ListTile(
                    dense: true,
                    title: Text(store.clientName(e.key)),
                    trailing: Text(money(e.value), style: const TextStyle(color: incomeColor, fontWeight: FontWeight.w600)),
                  ),
              ],
              if (debtors.isNotEmpty) ...[
                const SectionHeader('Должники на сегодня'),
                for (final c in debtors)
                  ListTile(dense: true, title: Text(c.name), trailing: BalanceText(store.balanceOf(c.id!))),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _kv(BuildContext context, String k, String v, Color? color, {bool big = false}) {
    final t = Theme.of(context).textTheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(children: [
        Expanded(child: Text(k, style: big ? t.titleMedium : t.bodyMedium)),
        Text(
          v,
          style: (big ? t.headlineSmall : t.titleSmall)?.copyWith(color: color, fontWeight: FontWeight.w700),
        ),
      ]),
    );
  }
}
