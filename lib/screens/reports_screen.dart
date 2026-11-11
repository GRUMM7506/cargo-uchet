import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../services/export_service.dart';
import '../store.dart';
import '../widgets/common.dart';
import 'month_report_screen.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  Future<void> _run(BuildContext context, Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      if (context.mounted) toast(context, 'Ошибка: $e');
    }
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await confirm(
      context,
      'Восстановить данные из резервной копии?\n\nВСЕ текущие данные будут заменены данными из файла.',
      ok: 'Выбрать файл',
    );
    if (!ok) return;
    try {
      final path = await ExportService.pickBackup();
      if (path == null) return;
      final done = await ExportService.restore(path);
      if (context.mounted) {
        toast(context, done ? 'Данные восстановлены' : 'Этот файл не является копией учёта');
      }
    } catch (e) {
      if (context.mounted) toast(context, 'Ошибка: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final months = store.months;
        var totalProfit = 0;
        for (final m in months) {
          totalProfit += store.summary(m).profitCents;
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Отчёты'),
            actions: [
              PopupMenuButton<String>(
                onSelected: (v) {
                  switch (v) {
                    case 'excel':
                      _run(context, () => ExportService.excel());
                    case 'backup':
                      _run(context, ExportService.shareBackup);
                    case 'restore':
                      _restore(context);
                  }
                },
                itemBuilder: (_) => const [
                  PopupMenuItem(
                    value: 'excel',
                    child: ListTile(leading: Icon(Icons.table_chart_outlined), title: Text('Excel за всё время')),
                  ),
                  PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'backup',
                    child: ListTile(leading: Icon(Icons.backup_outlined), title: Text('Резервная копия')),
                  ),
                  PopupMenuItem(
                    value: 'restore',
                    child: ListTile(leading: Icon(Icons.restore), title: Text('Восстановить из копии')),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
            children: [
              Card(
                margin: const EdgeInsets.only(bottom: 10),
                color: Theme.of(context).colorScheme.primaryContainer,
                child: ListTile(
                  title: const Text('Итог за всё время'),
                  trailing: Text(
                    money(totalProfit),
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: amountColor(totalProfit),
                    ),
                  ),
                ),
              ),
              for (final m in months) _MonthCard(month: m),
              const SizedBox(height: 12),
              Text(
                'Совет: раз в неделю делайте «Резервную копию» (меню ⋮) и отправляйте её себе в Telegram. '
                'Если телефон потеряется или сломается, данные можно будет восстановить.',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.outline),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MonthCard extends StatelessWidget {
  final YearMonth month;

  const _MonthCard({required this.month});

  @override
  Widget build(BuildContext context) {
    final s = AppStore.I.summary(month);
    final t = Theme.of(context).textTheme;
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => MonthReportScreen(month: month))),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Expanded(child: Text(month.label, style: t.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
                Text(
                  money(s.profitCents),
                  style: t.titleMedium?.copyWith(color: amountColor(s.profitCents), fontWeight: FontWeight.w700),
                ),
              ]),
              const SizedBox(height: 6),
              Row(children: [
                _mini('Пришло', money(s.incomeCents), incomeColor),
                _mini('Потрачено', money(s.expenseCents), expenseColor),
                _mini('Заказов', '${s.ordersCount}${s.weightKg > 0 ? ' · ${kg(s.weightKg)}' : ''}', null),
              ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget _mini(String label, String value, Color? color) => Expanded(
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
          Text(value, style: TextStyle(fontWeight: FontWeight.w600, color: color)),
        ]),
      );
}
