import 'dart:io';

import 'package:flutter/material.dart';

import '../currency.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../services/photos.dart';
import '../services/rates.dart';
import '../settings.dart';
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

/// Подпись для SegmentedButton — в одну строку, при нехватке места уменьшается.
Widget segLabel(String text) => FittedBox(fit: BoxFit.scaleDown, child: Text(text, maxLines: 1, softWrap: false));

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
  final String? photo;
  final double size;

  const Avatar(this.name, {super.key, this.photo, this.size = 44});

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(size * 0.36);
    if (Photos.exists(photo)) {
      return PhotoBox(photo: photo!, size: size, radius: radius);
    }
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
        borderRadius: radius,
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

/// Квадратная фотография со скруглением.
class PhotoBox extends StatelessWidget {
  final String photo;
  final double size;
  final BorderRadius radius;

  const PhotoBox({super.key, required this.photo, required this.size, required this.radius});

  @override
  Widget build(BuildContext context) {
    final dpr = MediaQuery.of(context).devicePixelRatio;
    return ClipRRect(
      borderRadius: radius,
      child: Image.file(
        Photos.file(photo),
        width: size,
        height: size,
        fit: BoxFit.cover,
        cacheWidth: (size * dpr).round(),
        errorBuilder: (_, __, ___) => Container(width: size, height: size, color: context.cs.surfaceContainerHigh),
      ),
    );
  }
}

/// Миниатюра заказа: фото работы или значок.
class OrderThumb extends StatelessWidget {
  final Order order;
  final double size;

  const OrderThumb(this.order, {super.key, this.size = 52});

  @override
  Widget build(BuildContext context) {
    if (Photos.exists(order.photo)) {
      return PhotoBox(photo: order.photo!, size: size, radius: BorderRadius.circular(size * 0.3));
    }
    final c = context.colors;
    final done = order.isDone;
    return IconBadge(
      done ? Icons.task_alt_rounded : Icons.handyman_outlined,
      size: size,
      color: done ? c.income : context.cs.primary,
      background: done ? c.incomeBg : context.cs.primaryContainer.withValues(alpha: 0.6),
    );
  }
}

/// Выбор фото: камера / галерея / удалить. Возвращает null при отмене.
Future<({String? name, bool removed})?> choosePhoto(
  BuildContext context, {
  required bool hasPhoto,
  required String prefix,
}) async {
  final action = await showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: Text(t.takePhoto),
            onTap: () => Navigator.pop(ctx, 'camera'),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: Text(t.fromGallery),
            onTap: () => Navigator.pop(ctx, 'gallery'),
          ),
          if (hasPhoto)
            ListTile(
              leading: Icon(Icons.delete_outline_rounded, color: ctx.colors.expense),
              title: Text(t.removePhoto, style: TextStyle(color: ctx.colors.expense)),
              onTap: () => Navigator.pop(ctx, 'remove'),
            ),
        ]),
      ),
    ),
  );
  if (action == null) return null;
  if (action == 'remove') return (name: null, removed: true);
  try {
    final name = await Photos.pick(camera: action == 'camera', prefix: prefix);
    if (name == null) return null;
    return (name: name, removed: false);
  } catch (e) {
    if (context.mounted) toast(context, t.error(e));
    return null;
  }
}

/// Полноэкранный просмотр фото с масштабированием.
class PhotoViewerPage extends StatelessWidget {
  final String photo;

  const PhotoViewerPage({super.key, required this.photo});

  static void open(BuildContext context, String photo) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => PhotoViewerPage(photo: photo)));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Center(
        child: InteractiveViewer(
          maxScale: 5,
          child: Image.file(File(Photos.file(photo).path)),
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

/// Долг / переплата / рассчитан.
class BalancePill extends StatelessWidget {
  final int cents;
  final String? cur;
  final bool approx;

  const BalancePill(this.cents, {super.key, this.cur, this.approx = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final a = approx ? '≈ ' : '';
    if (cents > 0) return Pill(t.debtPill('$a${money(cents, cur: cur)}'), color: c.debt, background: c.debtBg);
    if (cents < 0) {
      return Pill(t.overpaidPill('$a${money(-cents, cur: cur)}'), color: c.income, background: c.incomeBg);
    }
    return Pill(t.settledPill, color: c.muted, background: context.cs.surfaceContainerHigh, icon: Icons.check_rounded);
  }
}

/// Остаток по заказу: «долг X» или «оплачен».
class RemainingPill extends StatelessWidget {
  final int cents;
  final String? cur;

  const RemainingPill(this.cents, {super.key, this.cur});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return cents > 0
        ? Pill(t.debtPill(money(cents, cur: cur)), color: c.debt, background: c.debtBg)
        : Pill(t.paidPill, color: c.income, background: c.incomeBg, icon: Icons.check_rounded);
  }
}

// ---------------------------------------------------------------------------
// Валюта
// ---------------------------------------------------------------------------

/// Кнопка выбора валюты: «🇺🇸 USD ▾».
class CurrencyButton extends StatelessWidget {
  final String value;
  final ValueChanged<String> onChanged;

  const CurrencyButton({super.key, required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final c = currencyOf(value);
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () async {
          final code = await pickCurrency(context, current: value);
          if (code != null) onChanged(code);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: context.cs.primaryContainer.withValues(alpha: 0.6),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Text(c.flag, style: const TextStyle(fontSize: 16)),
            const SizedBox(width: 6),
            Text(c.code, style: context.tt.labelLarge?.copyWith(color: context.cs.onPrimaryContainer)),
            Icon(Icons.expand_more_rounded, size: 18, color: context.cs.onPrimaryContainer),
          ]),
        ),
      ),
    );
  }
}

/// Список валют для выбора (включённые в настройках + текущая).
Future<String?> pickCurrency(BuildContext context, {required String current, bool all = false}) {
  final codes = all ? currencies.map((c) => c.code).toList() : AppSettings.I.currencyChoices(current);
  final main = AppSettings.I.currency;
  return showModalBottomSheet<String>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(alignment: Alignment.centerLeft, child: Text(t.chooseCurrency, style: ctx.tt.titleLarge)),
          ),
          for (final code in codes)
            ListTile(
              leading: Text(currencyOf(code).flag, style: const TextStyle(fontSize: 24)),
              title: Text('${currencyOf(code).name(AppSettings.I.lang)} · $code'),
              subtitle: code == main ? null : Text('1 ${currencySymbol(code)} = ${rateStr(Fx.I.cross(code, main))} ${currencySymbol(main)}'),
              trailing: code == current ? Icon(Icons.check_rounded, color: ctx.cs.primary) : null,
              onTap: () => Navigator.pop(ctx, code),
            ),
        ]),
      ),
    ),
  );
}

/// Статус заказа: в работе / выполнен / просрочен.
class StatusPill extends StatelessWidget {
  final Order order;

  const StatusPill(this.order, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    if (order.isDone) return Pill(t.done, color: c.income, background: c.incomeBg, icon: Icons.check_rounded);
    if (order.isOverdue) {
      return Pill(t.overdue, color: c.expense, background: c.expenseBg, icon: Icons.warning_amber_rounded);
    }
    return Pill(t.inWork,
        color: context.cs.primary,
        background: context.cs.primaryContainer.withValues(alpha: 0.6),
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

Future<bool> confirm(BuildContext context, String text, {String? ok, bool danger = true}) async {
  final r = await showDialog<bool>(
    context: context,
    builder: (ctx) => AlertDialog(
      content: Text(text, style: const TextStyle(fontSize: 16)),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
        FilledButton(
          style: danger
              ? FilledButton.styleFrom(backgroundColor: ctx.colors.expense, minimumSize: const Size(64, 44))
              : FilledButton.styleFrom(minimumSize: const Size(64, 44)),
          onPressed: () => Navigator.pop(ctx, true),
          child: Text(ok ?? t.delete),
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

/// «Сегодня», «Вчера», «12 ноября, ср» / «Bugun», «12-noyabr, ch».
String dayLabel(DateTime d, {bool withYear = false}) {
  final now = today();
  final day = DateTime(d.year, d.month, d.day);
  final diff = now.difference(day).inDays;
  final base = '${t.dayMonth(d.day, d.month)}${withYear || d.year != now.year ? ' ${d.year}' : ''}';
  if (diff == 0) return withYear ? '${t.today}, $base' : t.today;
  if (diff == 1) return withYear ? '${t.yesterday}, $base' : t.yesterday;
  return '$base, ${t.weekdays[d.weekday - 1]}';
}

/// «12 ноя» / «12-noy».
String shortDay(DateTime d) {
  final m = t.monthShort[d.month - 1];
  final base = t.code == 'uz' ? '${d.day}-$m' : '${d.day} $m';
  return d.year == today().year ? base : '$base ${d.year}';
}
