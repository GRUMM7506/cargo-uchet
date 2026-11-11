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
      if (mounted) toast(context, t.exportError(e));
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
        // кто сколько внёс за месяц: оплаты + залоги
        final byClient = <int, int>{};
        for (final p in store.payments) {
          if (m.contains(p.paidAt)) byClient[p.clientId] = (byClient[p.clientId] ?? 0) + p.amountCents;
        }
        for (final o in store.orders) {
          if (o.depositCents > 0 && m.contains(o.depositDate)) {
            byClient[o.clientId] = (byClient[o.clientId] ?? 0) + o.depositCents;
          }
        }
        final payers = byClient.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
        final debtors = store.debtors;

        return Scaffold(
          appBar: AppBar(title: Text(t.report)),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Center(child: MonthSwitcher(month: m, onChanged: (x) => setState(() => _month = x))),
              const SizedBox(height: 14),
              SectionCard(children: [
                KeyValue(t.incomeFull, money(s.incomeCents), color: c.income),
                KeyValue(t.expenseFull, money(s.expenseCents), color: c.expense),
                const Divider(height: 18),
                KeyValue(s.profitCents >= 0 ? t.profit : t.loss, money(s.profitCents),
                    color: s.profitCents >= 0 ? c.income : c.expense, strong: true),
              ]),
              const SizedBox(height: 12),
              SectionCard(title: t.tabOrders, children: [
                KeyValue(t.ordersAccepted, '${s.ordersCount}'),
                KeyValue(t.onSum, money(s.ordersCents)),
                KeyValue(t.depositsReceived, money(s.depositsCents), color: c.income),
                KeyValue(t.debtNow, money(store.totalDebt), color: c.debt),
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
                SectionCard(title: t.byCategory, children: [
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
                SectionCard(title: t.whoPaid, children: [
                  for (final e in payers)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Avatar(store.clientName(e.key), photo: store.clientById(e.key)?.photo, size: 32),
                        const SizedBox(width: 10),
                        Expanded(child: Text(store.clientName(e.key), style: context.tt.bodyMedium)),
                        Text(money(e.value), style: amountStyle(14, color: c.income)),
                      ]),
                    ),
                ]),
              ],
              if (debtors.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(title: t.debtorsToday, children: [
                  for (final x in debtors)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Row(children: [
                        Avatar(x.name, photo: x.photo, size: 32),
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
