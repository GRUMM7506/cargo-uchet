import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';

const incomeColor = Color(0xFF1B8A4B);
const expenseColor = Color(0xFFC62828);
const debtColor = Color(0xFFE65100);

Color amountColor(int cents) => cents >= 0 ? incomeColor : expenseColor;

/// Переключатель месяца:  ‹  Ноябрь 2026  ›
class MonthSwitcher extends StatelessWidget {
  final YearMonth month;
  final ValueChanged<YearMonth> onChanged;

  const MonthSwitcher({super.key, required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isCurrent = month == YearMonth.now();
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: () => onChanged(month.prev),
        ),
        GestureDetector(
          onTap: isCurrent ? null : () => onChanged(YearMonth.now()),
          child: SizedBox(
            width: 170,
            child: Column(
              children: [
                Text(
                  month.label,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                ),
                if (!isCurrent)
                  Text('к текущему', style: Theme.of(context).textTheme.labelSmall),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: () => onChanged(month.next),
        ),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color? color;
  final IconData icon;
  final bool big;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.icon,
    this.color,
    this.big = false,
  });

  @override
  Widget build(BuildContext context) {
    final t = Theme.of(context).textTheme;
    final c = color ?? Theme.of(context).colorScheme.onSurface;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, size: 18, color: c),
              const SizedBox(width: 6),
              Expanded(child: Text(title, style: t.labelLarge, overflow: TextOverflow.ellipsis)),
            ]),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(
                value,
                style: (big ? t.headlineMedium : t.titleLarge)?.copyWith(color: c, fontWeight: FontWeight.w700),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String text;

  const EmptyState({super.key, required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Theme.of(context).colorScheme.outline),
            const SizedBox(height: 12),
            Text(text, textAlign: TextAlign.center, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
          ],
        ),
      ),
    );
  }
}

/// Текст баланса клиента: «Долг $500» / «Аванс $200» / «Рассчитан».
class BalanceText extends StatelessWidget {
  final int cents;
  final TextStyle? style;

  const BalanceText(this.cents, {super.key, this.style});

  @override
  Widget build(BuildContext context) {
    final base = style ?? Theme.of(context).textTheme.bodyMedium;
    if (cents > 0) {
      return Text('Долг ${money(cents)}', style: base?.copyWith(color: debtColor, fontWeight: FontWeight.w600));
    }
    if (cents < 0) {
      return Text('Аванс ${money(-cents)}', style: base?.copyWith(color: incomeColor, fontWeight: FontWeight.w600));
    }
    return Text('Рассчитан', style: base?.copyWith(color: Theme.of(context).colorScheme.outline));
  }
}

Future<bool> confirm(BuildContext context, String text, {String ok = 'Удалить'}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(text),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: expenseColor),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok),
        ),
      ],
    ),
  );
  return r ?? false;
}

void toast(BuildContext context, String text) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(content: Text(text)));
}

/// Поле выбора даты.
class DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;

  const DateField({super.key, required this.label, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () async {
        final d = await showDatePicker(
          context: context,
          initialDate: value,
          firstDate: DateTime(2020),
          lastDate: DateTime(2100),
        );
        if (d != null) onChanged(d);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
        ),
        child: Text(dateStr(value)),
      ),
    );
  }
}
