import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../store.dart';
import 'common.dart';

final _store = AppStore.I;

class PaymentTile extends StatelessWidget {
  final Payment p;
  final bool showClient;

  const PaymentTile(this.p, {super.key, this.showClient = true});

  @override
  Widget build(BuildContext context) {
    final order = p.orderId == null ? null : _store.orderById(p.orderId!);
    final parts = <String>[
      dateStr(p.paidAt),
      if (order != null) 'за «${order.description.isEmpty ? 'заказ' : order.description}»',
      if (p.note.isNotEmpty) p.note,
    ];
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0x221B8A4B),
        child: Icon(Icons.arrow_downward, color: incomeColor),
      ),
      title: Text(showClient ? _store.clientName(p.clientId) : 'Оплата'),
      subtitle: Text(parts.join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(
        money(p.amountCents, plus: true),
        style: const TextStyle(color: incomeColor, fontWeight: FontWeight.w700, fontSize: 15),
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => PaymentFormPage(payment: p))),
    );
  }
}

class ExpenseTile extends StatelessWidget {
  final Expense e;

  const ExpenseTile(this.e, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const CircleAvatar(
        backgroundColor: Color(0x22C62828),
        child: Icon(Icons.arrow_upward, color: expenseColor),
      ),
      title: Text(e.category),
      subtitle: Text(
        [dateStr(e.spentAt), if (e.note.isNotEmpty) e.note].join(' · '),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: Text(
        money(-e.amountCents),
        style: const TextStyle(color: expenseColor, fontWeight: FontWeight.w700, fontSize: 15),
      ),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ExpenseFormPage(expense: e))),
    );
  }
}

class OrderTile extends StatelessWidget {
  final Order o;
  final bool showClient;

  const OrderTile(this.o, {super.key, this.showClient = true});

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final details = <String>[
      if (o.weightKg != null) kg(o.weightKg!),
      if (o.quantity != null) '${o.quantity} шт',
      'принят ${dateStr(o.acceptedAt)}',
      if (o.doneAt != null) 'выполнен ${dateStr(o.doneAt!)}',
    ];
    final title = showClient
        ? '${_store.clientName(o.clientId)}${o.description.isEmpty ? '' : ' · ${o.description}'}'
        : (o.description.isEmpty ? 'Заказ' : o.description);
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: o.isDone ? cs.secondaryContainer : cs.primaryContainer,
        child: Icon(
          o.isDone ? Icons.check : Icons.local_shipping_outlined,
          color: o.isDone ? cs.onSecondaryContainer : cs.onPrimaryContainer,
        ),
      ),
      title: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis),
      subtitle: Text(details.join(' · '), maxLines: 2, overflow: TextOverflow.ellipsis),
      trailing: Text(money(o.amountCents), style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
      onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => OrderFormPage(order: o))),
      onLongPress: () async {
        await _store.setOrderDone(o, !o.isDone);
        if (context.mounted) toast(context, o.isDone ? 'Заказ снова в работе' : 'Заказ выполнен');
      },
    );
  }
}

class SectionHeader extends StatelessWidget {
  final String text;
  final Widget? trailing;

  const SectionHeader(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 18, 8, 4),
      child: Row(children: [
        Expanded(
          child: Text(
            text,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        if (trailing != null) trailing!,
      ]),
    );
  }
}
