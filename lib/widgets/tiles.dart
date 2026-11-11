import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../l10n.dart';
import '../models.dart';
import '../screens/order_screen.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

final _store = AppStore.I;

/// Карточка-группа: элементы через тонкие разделители.
class GroupCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;
  final double indent;

  const GroupCard({
    super.key,
    required this.children,
    this.margin = const EdgeInsets.symmetric(horizontal: 16),
    this.indent = 72,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) Divider(indent: indent),
            children[i],
          ],
        ]),
      ),
    );
  }
}

/// Базовая строка списка: значок | заголовок + подзаголовок | справа.
class ListRow extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? meta;
  final Widget trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const ListRow({
    super.key,
    required this.leading,
    required this.title,
    this.subtitle,
    this.meta,
    required this.trailing,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Row(children: [
          leading,
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: context.tt.titleSmall?.copyWith(fontSize: 15)),
              if (subtitle != null && subtitle!.isNotEmpty) ...[
                const SizedBox(height: 2),
                Text(
                  subtitle!,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: context.tt.bodySmall?.copyWith(color: context.colors.muted, fontSize: 13),
                ),
              ],
              if (meta != null) ...[const SizedBox(height: 6), meta!],
            ]),
          ),
          const SizedBox(width: 10),
          trailing,
        ]),
      ),
    );
  }
}

class PaymentTile extends StatelessWidget {
  final Payment p;
  final bool showClient;
  final bool showDate;

  const PaymentTile(this.p, {super.key, this.showClient = true, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final order = p.orderId == null ? null : _store.orderById(p.orderId!);
    final client = _store.clientById(p.clientId);
    final sub = <String>[
      if (showDate) shortDay(p.paidAt),
      if (order != null) t.forOrder(order.title),
      if (p.note.isNotEmpty) p.note,
    ].join(' · ');
    return ListRow(
      leading: showClient
          ? Avatar(client?.name ?? '—', photo: client?.photo)
          : IconBadge(Icons.south_west_rounded, color: c.income, background: c.incomeBg),
      title: showClient ? (client?.name ?? '—') : t.payment,
      subtitle: showClient && sub.isEmpty ? t.payment : sub,
      trailing: Text(money(p.amountCents, plus: true), style: amountStyle(15, color: c.income)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentFormPage(payment: p))),
    );
  }
}

/// Залог по заказу — тоже приход денег.
class DepositTile extends StatelessWidget {
  final Order o;

  const DepositTile(this.o, {super.key});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    final client = _store.clientById(o.clientId);
    return ListRow(
      leading: Avatar(client?.name ?? '—', photo: client?.photo),
      title: client?.name ?? '—',
      subtitle: '${t.deposit} · ${o.title}',
      trailing: Text(money(o.depositCents, plus: true), style: amountStyle(15, color: c.income)),
      onTap: () => OrderScreen.open(context, o.id!),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  final Expense e;
  final bool showDate;

  const ExpenseTile(this.e, {super.key, this.showDate = false});

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return ListRow(
      leading: IconBadge(categoryIcon(e.category), color: c.expense, background: c.expenseBg),
      title: e.category,
      subtitle: [if (showDate) shortDay(e.spentAt), if (e.note.isNotEmpty) e.note].join(' · '),
      trailing: Text(money(-e.amountCents), style: amountStyle(15, color: c.expense)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: e))),
    );
  }
}

IconData categoryIcon(String category) {
  final c = category.toLowerCase();
  bool has(List<String> words) => words.any(c.contains);
  if (has(['китай', 'xitoy', 'хитой'])) return Icons.flight_takeoff_rounded;
  if (has(['груз', 'yuk', 'доставк', 'yetkaz'])) return Icons.inventory_2_outlined;
  if (has(['машин', 'mashin', 'бензин', 'benzin', 'топлив', 'yoqilgʻi'])) return Icons.local_shipping_outlined;
  if (has(['материал', 'material'])) return Icons.construction_rounded;
  if (has(['аренд', 'ijara', 'склад', 'ombor'])) return Icons.warehouse_outlined;
  if (has(['зарплат', 'ish haqi', 'oylik', 'maosh'])) return Icons.groups_outlined;
  if (has(['тамож', 'bojxona'])) return Icons.verified_user_outlined;
  if (has(['связ', 'телефон', 'aloqa', 'telefon'])) return Icons.phone_iphone_rounded;
  if (has(['еда', 'обед', 'ovqat', 'tushlik'])) return Icons.restaurant_outlined;
  return Icons.receipt_long_outlined;
}

/// Подпись к сроку сдачи: «осталось 3 дн.» / «просрочен на 2 дн.» / «сдать сегодня».
String? dueText(Order o) {
  if (o.dueAt == null || o.isDone) return null;
  final d = o.dueAt!.difference(today()).inDays;
  if (d == 0) return t.dueToday;
  if (d < 0) return t.daysOverdue(-d);
  return t.daysLeft(d);
}

class OrderTile extends StatelessWidget {
  final Order o;
  final bool showClient;

  /// Для предпросмотра в настройках: имя клиента-примера, без нажатий.
  final String? previewName;

  const OrderTile(this.o, {super.key, this.showClient = true, this.previewName});

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.I;
    final c = context.colors;
    final client = previewName == null ? _store.clientById(o.clientId) : null;
    final clientName = previewName ?? client?.name ?? '—';
    final remaining = previewName != null ? o.priceCents - o.depositCents : _store.remainingOf(o);
    final showPhoto = s.show(OrderField.photo);

    final lines = <String>[
      if (showClient && s.show(OrderField.description) && o.description.isNotEmpty) o.description,
      [
        shortDay(o.acceptedAt),
        if (s.show(OrderField.due) && dueText(o) != null) dueText(o)!,
      ].join(' · '),
    ];

    return ListRow(
      leading: showPhoto
          ? (o.photo != null || !showClient ? OrderThumb(o) : Avatar(clientName, photo: client?.photo, size: 52))
          : Avatar(clientName, photo: client?.photo),
      title: showClient ? clientName : (s.show(OrderField.description) ? o.title : t.order),
      subtitle: lines.join('\n'),
      meta: Wrap(spacing: 6, runSpacing: 4, children: [
        if (s.show(OrderField.done) || o.isOverdue) StatusPill(o),
        RemainingPill(remaining),
      ]),
      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(money(o.priceCents), style: amountStyle(15, color: context.cs.onSurface)),
        if (s.show(OrderField.deposit) && o.depositCents > 0) ...[
          const SizedBox(height: 4),
          Text('${t.deposit} ${money(o.depositCents)}', style: context.tt.bodySmall?.copyWith(color: c.muted)),
        ],
      ]),
      onTap: previewName != null ? null : () => OrderScreen.open(context, o.id!),
      onLongPress: previewName == null && s.show(OrderField.done)
          ? () async {
              await _store.setOrderDone(o, !o.isDone);
              if (context.mounted) toast(context, o.isDone ? t.orderBackInWork : t.orderDone);
            }
          : null,
    );
  }
}

class ClientTile extends StatelessWidget {
  final Client client;
  final VoidCallback onTap;

  const ClientTile(this.client, {super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final active = _store.ordersOf(client.id!).where((o) => !o.isDone).length;
    final sub = <String>[
      if (client.phone.isNotEmpty) client.phone,
      if (active > 0 && AppSettings.I.show(OrderField.done)) t.activeOrders(active),
    ].join(' · ');
    return ListRow(
      leading: Avatar(client.name, photo: client.photo),
      title: client.name,
      subtitle: sub.isEmpty ? null : sub,
      trailing: BalancePill(_store.balanceOf(client.id!)),
      onTap: onTap,
    );
  }
}

/// Список операций, сгруппированный по дням.
class DayGroupedList extends StatelessWidget {
  final List<(DateTime, Widget)> items;

  const DayGroupedList({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    final groups = <DateTime, List<Widget>>{};
    for (final (d, w) in items) {
      groups.putIfAbsent(DateTime(d.year, d.month, d.day), () => []).add(w);
    }
    final days = groups.keys.toList()..sort((a, b) => b.compareTo(a));
    return Column(children: [
      for (final d in days) ...[
        Padding(
          padding: const EdgeInsets.fromLTRB(22, 14, 16, 8),
          child: Align(
            alignment: Alignment.centerLeft,
            child: Text(dayLabel(d), style: context.tt.labelLarge?.copyWith(color: context.colors.muted)),
          ),
        ),
        GroupCard(children: groups[d]!),
      ],
    ]);
  }
}
