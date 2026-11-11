import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

final _store = AppStore.I;

/// Карточка-группа: элементы через тонкие разделители.
class GroupCard extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry margin;

  const GroupCard({super.key, required this.children, this.margin = const EdgeInsets.symmetric(horizontal: 16)});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: margin,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: Column(children: [
          for (var i = 0; i < children.length; i++) ...[
            if (i > 0) const Divider(indent: 72),
            children[i],
          ],
        ]),
      ),
    );
  }
}

/// Базовая строка списка: значок | заголовок + подзаголовок | справа.
class _Row extends StatelessWidget {
  final Widget leading;
  final String title;
  final String? subtitle;
  final Widget? meta;
  final Widget trailing;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _Row({
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
        child: Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
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
    final sub = <String>[
      if (showDate) shortDay(p.paidAt),
      if (order != null) 'за «${order.title}»',
      if (p.note.isNotEmpty) p.note,
    ].join(' · ');
    return _Row(
      leading: showClient
          ? Avatar(_store.clientName(p.clientId))
          : IconBadge(Icons.south_west_rounded, color: c.income, background: c.incomeBg),
      title: showClient ? _store.clientName(p.clientId) : 'Оплата',
      subtitle: showClient && sub.isEmpty ? 'Оплата' : sub,
      trailing: Text(money(p.amountCents, plus: true), style: amountStyle(15, color: c.income)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentFormPage(payment: p))),
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
    return _Row(
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
  if (c.contains('груз')) return Icons.inventory_2_outlined;
  if (c.contains('китай') || c.contains('доставк')) return Icons.flight_takeoff_rounded;
  if (c.contains('машин') || c.contains('бензин') || c.contains('топлив')) return Icons.local_shipping_outlined;
  if (c.contains('тамож')) return Icons.verified_user_outlined;
  if (c.contains('склад') || c.contains('аренд')) return Icons.warehouse_outlined;
  if (c.contains('связ') || c.contains('телефон')) return Icons.phone_iphone_rounded;
  if (c.contains('еда') || c.contains('обед')) return Icons.restaurant_outlined;
  return Icons.receipt_long_outlined;
}

/// Короткие метки заказа: «12.5 кг», «$3.5/кг», «3 шт».
List<String> orderMeta(Order o) {
  final s = AppSettings.I;
  return [
    if (s.show(OrderField.weight) && o.weightKg != null) kg(o.weightKg!),
    if (s.show(OrderField.quantity) && o.quantity != null) '${o.quantity} шт',
    if (s.show(OrderField.pricing) && o.pricing != Pricing.fixed && o.rateCents != null)
      '${money(o.rateCents!)}/${o.pricing == Pricing.perKg ? 'кг' : 'шт'}',
  ];
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
    final cs = context.cs;
    final c = context.colors;
    final desc = <String>[
      if (showClient && s.show(OrderField.description) && o.description.isNotEmpty) o.description,
      if (s.show(OrderField.code) && o.code.isNotEmpty) '№ ${o.code}',
    ].join(' · ');
    final dates = <String>[
      'принят ${shortDay(o.acceptedAt)}',
      if (s.show(OrderField.done) && o.doneAt != null) 'выполнен ${shortDay(o.doneAt!)}',
    ].join(' · ');
    final meta = orderMeta(o);
    final clientName = previewName ?? _store.clientName(o.clientId);

    return _Row(
      leading: showClient
          ? Avatar(clientName)
          : IconBadge(
              o.isDone ? Icons.task_alt_rounded : Icons.local_shipping_outlined,
              color: o.isDone ? c.income : cs.primary,
              background: o.isDone ? c.incomeBg : cs.primaryContainer.withValues(alpha: 0.6),
            ),
      title: showClient ? clientName : (s.show(OrderField.description) ? o.title : 'Заказ'),
      subtitle: [if (desc.isNotEmpty) desc, dates].join('\n'),
      meta: meta.isEmpty
          ? null
          : Wrap(spacing: 6, runSpacing: 4, children: [
              for (final m in meta)
                Pill(m, color: cs.onSurfaceVariant, background: cs.surfaceContainerHigh),
            ]),
      trailing: Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
        Text(money(o.amountCents), style: amountStyle(15, color: cs.onSurface)),
        if (s.show(OrderField.done)) ...[const SizedBox(height: 6), StatusPill(o.isDone)],
      ]),
      onTap: previewName != null
          ? null
          : () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderFormPage(order: o))),
      onLongPress: previewName == null && s.show(OrderField.done)
          ? () async {
              await _store.setOrderDone(o, !o.isDone);
              if (context.mounted) toast(context, o.isDone ? 'Заказ снова в работе' : 'Заказ выполнен');
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
      if (active > 0 && AppSettings.I.show(OrderField.done)) 'в работе: $active',
    ].join(' · ');
    return _Row(
      leading: Avatar(client.name),
      title: client.name,
      subtitle: sub.isEmpty ? null : sub,
      trailing: BalancePill(_store.balanceOf(client.id!)),
      onTap: onTap,
    );
  }
}

/// Список операций, сгруппированный по дням (для главной и расходов).
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
