import 'package:flutter/material.dart';

import '../format.dart';
import '../models.dart';
import '../theme.dart';

// ---------------------------------------------------------------------------
// Месяц
// ---------------------------------------------------------------------------

/// Переключатель месяца в виде «таблетки»:  ‹  Ноябрь 2026  ›
class MonthSwitcher extends StatelessWidget {
  final YearMonth month;
  final ValueChanged<YearMonth> onChanged;

  const MonthSwitcher({super.key, required this.month, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final isCurrent = month == YearMonth.now();
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: context.cs.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _arrow(context, Icons.chevron_left_rounded, () => onChanged(month.prev)),
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: isCurrent ? null : () => onChanged(YearMonth.now()),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: Row(mainAxisSize: MainAxisSize.min, children: [
                Text(month.label, style: context.tt.titleSmall),
                if (!isCurrent) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.restore_rounded, size: 16, color: context.cs.primary),
                ],
              ]),
            ),
          ),
          _arrow(context, Icons.chevron_right_rounded, () => onChanged(month.next)),
        ],
      ),
    );
  }

  Widget _arrow(BuildContext context, IconData icon, VoidCallback onTap) => InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(width: 44, height: 44, child: Icon(icon, color: context.cs.onSurfaceVariant)),
      );
}

// ---------------------------------------------------------------------------
// Карточки и заголовки
// ---------------------------------------------------------------------------

class SectionCard extends StatelessWidget {
  final String? title;
  final Widget? trailing;
  final List<Widget> children;
  final EdgeInsetsGeometry padding;

  const SectionCard({
    super.key,
    this.title,
    this.trailing,
    required this.children,
    this.padding = const EdgeInsets.fromLTRB(16, 14, 16, 16),
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (title != null) ...[
              Row(children: [
                Expanded(
                  child: Text(
                    title!.toUpperCase(),
                    style: context.tt.labelMedium?.copyWith(
                      color: context.colors.muted,
                      letterSpacing: 0.8,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                if (trailing != null) trailing!,
              ]),
              const SizedBox(height: 12),
            ],
            ...children,
          ],
        ),
      ),
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;

  const SectionHeader(this.text, {super.key, this.trailing, this.padding = const EdgeInsets.fromLTRB(20, 22, 12, 8)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding,
      child: Row(children: [
        Expanded(child: Text(text, style: context.tt.titleMedium?.copyWith(fontWeight: FontWeight.w700))),
        if (trailing != null) trailing!,
      ]),
    );
  }
}

/// Строка «название ……… значение».
class KeyValue extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool strong;

  const KeyValue(this.label, this.value, {super.key, this.color, this.strong = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(children: [
        Expanded(
          child: Text(
            label,
            style: strong ? context.tt.titleSmall : context.tt.bodyMedium?.copyWith(color: context.cs.onSurfaceVariant),
          ),
        ),
        Text(value, style: amountStyle(strong ? 20 : 15, color: color ?? context.cs.onSurface)),
      ]),
    );
  }
}

// ---------------------------------------------------------------------------
// Аватар, баланс, статусы
// ---------------------------------------------------------------------------

const _avatarPalette = [
  Color(0xFF2357C6), Color(0xFF0E8A6A), Color(0xFF6A4CE0), Color(0xFFD9780F),
  Color(0xFFC2185B), Color(0xFF00838F), Color(0xFF7B5E57), Color(0xFF5C6BC0),
];

class Avatar extends StatelessWidget {
  final String name;
  final double size;

  const Avatar(this.name, {super.key, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final trimmed = name.trim();
    final parts = trimmed.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).toList();
    final initials = parts.isEmpty
        ? '?'
        : (parts.length == 1 ? parts[0].substring(0, 1) : parts[0].substring(0, 1) + parts[1].substring(0, 1))
            .toUpperCase();
    final color = _avatarPalette[trimmed.hashCode.abs() % _avatarPalette.length];
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDark ? 0.28 : 0.14),
        borderRadius: BorderRadius.circular(size * 0.36),
      ),
      child: Text(
        initials,
        style: TextStyle(
          fontFamily: displayFont,
          fontWeight: FontWeight.w700,
          fontSize: size * 0.36,
          color: context.isDark ? Color.lerp(color, Colors.white, 0.45) : color,
        ),
      ),
    );
  }
}

/// Квадратная иконка в цветной подложке.
class IconBadge extends StatelessWidget {
  final IconData icon;
  final Color color;
  final Color background;
  final double size;

  const IconBadge(this.icon, {super.key, required this.color, required this.background, this.size = 44});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.36)),
      child: Icon(icon, color: color, size: size * 0.5),
    );
  }
}

class Pill extends StatelessWidget {
  final String text;
  final Color color;
  final Color background;
  final IconData? icon;

  const Pill(this.text, {super.key, required this.color, required this.background, this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(9)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 4)],
        Text(text, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: color)),
      ]),
    );
  }
}

/// Долг / аванс / рассчитан.
class BalancePill extends StatelessWidget {
  final int cents;

  const BalancePill(this.cents, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (cents > 0) return Pill('долг ${money(cents)}', color: c.debt, background: c.debtBg);
    if (cents < 0) return Pill('аванс ${money(-cents)}', color: c.income, background: c.incomeBg);
    return Pill('рассчитан', color: c.muted, background: context.cs.surfaceContainerHigh, icon: Icons.check_rounded);
  }
}

class StatusPill extends StatelessWidget {
  final bool done;

  const StatusPill(this.done, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return done
        ? Pill('выполнен', color: c.income, background: c.incomeBg, icon: Icons.check_rounded)
        : Pill('в работе', color: context.cs.primary, background: context.cs.primaryContainer.withValues(alpha: 0.6),
            icon: Icons.schedule_rounded);
  }
}

// ---------------------------------------------------------------------------
// Пустые состояния, диалоги
// ---------------------------------------------------------------------------

class EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? text;

  const EmptyState({super.key, required this.icon, required this.title, this.text});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: context.cs.primaryContainer.withValues(alpha: 0.55),
                borderRadius: BorderRadius.circular(26),
              ),
              child: Icon(icon, size: 36, color: context.cs.primary),
            ),
            const SizedBox(height: 16),
            Text(title, textAlign: TextAlign.center, style: context.tt.titleMedium),
            if (text != null) ...[
              const SizedBox(height: 6),
              Text(text!, textAlign: TextAlign.center, style: context.tt.bodyMedium?.copyWith(color: context.colors.muted)),
            ],
          ],
        ),
      ),
    );
  }
}

Future<bool> confirm(BuildContext context, String text, {String ok = 'Удалить', bool danger = true}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(text, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Отмена')),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: ctx.colors.expense, minimumSize: const Size(64, 44))
              : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
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

// ---------------------------------------------------------------------------
// Поля
// ---------------------------------------------------------------------------

/// Поле выбора даты в стиле остальных полей.
class DateField extends StatelessWidget {
  final String label;
  final DateTime value;
  final ValueChanged<DateTime> onChanged;
  final IconData icon;

  const DateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.icon = Icons.event_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
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
        decoration: InputDecoration(labelText: label, prefixIcon: Icon(icon)),
        child: Text(dayLabel(value, withYear: true)),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Даты
// ---------------------------------------------------------------------------

const _monthsGen = [
  'января', 'февраля', 'марта', 'апреля', 'мая', 'июня',
  'июля', 'августа', 'сентября', 'октября', 'ноября', 'декабря',
];
const _weekdays = ['пн', 'вт', 'ср', 'чт', 'пт', 'сб', 'вс'];

/// «Сегодня», «Вчера», «12 ноября, ср».
String dayLabel(DateTime d, {bool withYear = false}) {
  final t = today();
  final day = DateTime(d.year, d.month, d.day);
  final diff = t.difference(day).inDays;
  final base = '${d.day} ${_monthsGen[d.month - 1]}${withYear || d.year != t.year ? ' ${d.year}' : ''}';
  if (diff == 0) return withYear ? 'Сегодня, $base' : 'Сегодня';
  if (diff == 1) return withYear ? 'Вчера, $base' : 'Вчера';
  return '$base, ${_weekdays[d.weekday - 1]}';
}

String shortDay(DateTime d) => '${d.day} ${_monthsGen[d.month - 1].substring(0, 3)}';
