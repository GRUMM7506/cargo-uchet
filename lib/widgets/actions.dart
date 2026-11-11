import 'package:flutter/material.dart';

import '../forms.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../theme.dart';
import 'common.dart';

/// Пункт меню действий.
class ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool danger;

  const ActionItem(this.icon, this.label, this.onTap, {this.danger = false});
}

/// Меню действий снизу (по долгому нажатию на запись).
Future<void> showActions(BuildContext context, {required String title, required List<ActionItem> items}) {
  return showModalBottomSheet<void>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 12),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: ctx.tt.titleMedium),
            ),
          ),
          for (final a in items)
            ListTile(
              leading: Icon(a.icon, color: a.danger ? ctx.colors.expense : ctx.cs.primary),
              title: Text(a.label, style: a.danger ? TextStyle(color: ctx.colors.expense) : null),
              onTap: () {
                Navigator.pop(ctx);
                a.onTap();
              },
            ),
        ]),
      ),
    ),
  );
}

void _push(BuildContext context, Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

// ----------------------------- удаление -----------------------------

Future<bool> deletePaymentFlow(BuildContext context, Payment p) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirm(context, t.deletePaymentQ)) return false;
  await AppStore.I.deletePayment(p.id!);
  messenger.showSnackBar(SnackBar(content: Text(t.deleted)));
  return true;
}

Future<bool> deleteExpenseFlow(BuildContext context, Expense e) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirm(context, t.deleteExpenseQ)) return false;
  await AppStore.I.deleteExpense(e.id!);
  messenger.showSnackBar(SnackBar(content: Text(t.deleted)));
  return true;
}

Future<bool> deleteOrderFlow(BuildContext context, Order o) async {
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirm(context, t.deleteOrderQ)) return false;
  await AppStore.I.deleteOrder(o.id!);
  messenger.showSnackBar(SnackBar(content: Text(t.deleted)));
  return true;
}

Future<bool> deleteClientFlow(BuildContext context, Client c) async {
  final s = AppStore.I;
  final n = s.ordersOf(c.id!).length + s.paymentsOf(c.id!).length;
  final messenger = ScaffoldMessenger.of(context);
  if (!await confirm(context, n == 0 ? t.deleteClientQ(c.name) : t.deleteClientWithQ(c.name, n))) return false;
  await s.deleteClient(c.id!);
  messenger.showSnackBar(SnackBar(content: Text(t.deleted)));
  return true;
}

// ----------------------------- меню -----------------------------

void paymentActions(BuildContext context, Payment p) => showActions(context, title: t.payment, items: [
      ActionItem(Icons.edit_outlined, t.edit, () => _push(context, PaymentFormPage(payment: p))),
      ActionItem(Icons.delete_outline_rounded, t.delete, () => deletePaymentFlow(context, p), danger: true),
    ]);

void expenseActions(BuildContext context, Expense e) => showActions(context, title: e.category, items: [
      ActionItem(Icons.edit_outlined, t.edit, () => _push(context, ExpenseFormPage(expense: e))),
      ActionItem(Icons.delete_outline_rounded, t.delete, () => deleteExpenseFlow(context, e), danger: true),
    ]);

void clientActions(BuildContext context, Client c) => showActions(context, title: c.name, items: [
      ActionItem(Icons.edit_outlined, t.editClient, () => _push(context, ClientFormPage(client: c))),
      ActionItem(Icons.delete_outline_rounded, t.deleteClient, () => deleteClientFlow(context, c), danger: true),
    ]);

void orderActions(BuildContext context, Order o, {required bool showDone, VoidCallback? onOpen}) {
  final store = AppStore.I;
  final remaining = store.remainingOf(o);
  showActions(context, title: '${store.clientName(o.clientId)} · ${o.title}', items: [
    if (onOpen != null) ActionItem(Icons.open_in_new_rounded, t.open, onOpen),
    if (showDone)
      ActionItem(
        o.isDone ? Icons.replay_rounded : Icons.task_alt_rounded,
        o.isDone ? t.markInWork : t.markDone,
        () async {
          await store.setOrderDone(o, !o.isDone);
          if (context.mounted) toast(context, o.isDone ? t.orderBackInWork : t.orderDone);
        },
      ),
    if (remaining > 0)
      ActionItem(Icons.south_west_rounded, t.takePayment,
          () => _push(context, PaymentFormPage(clientId: o.clientId, orderId: o.id))),
    ActionItem(Icons.edit_outlined, t.editOrder, () => _push(context, OrderFormPage(order: o))),
    ActionItem(Icons.delete_outline_rounded, t.deleteOrder, () => deleteOrderFlow(context, o), danger: true),
  ]);
}

/// Обёртка «смахнуть влево — удалить» (с подтверждением).
class SwipeToDelete extends StatelessWidget {
  final Key itemKey;
  final Future<bool> Function() onDelete;
  final Widget child;

  const SwipeToDelete({super.key, required this.itemKey, required this.onDelete, required this.child});

  @override
  Widget build(BuildContext context) {
    return Dismissible(
      key: itemKey,
      direction: DismissDirection.endToStart,
      background: Container(
        color: context.colors.expense,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Row(mainAxisSize: MainAxisSize.min, children: [
          Text(t.delete, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
          const SizedBox(width: 8),
          const Icon(Icons.delete_outline_rounded, color: Colors.white),
        ]),
      ),
      // удаляем сами (после подтверждения), а строка пропадёт при обновлении списка
      confirmDismiss: (_) async {
        await onDelete();
        return false;
      },
      child: child,
    );
  }
}
