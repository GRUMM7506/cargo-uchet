import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../l10n.dart';
import '../models.dart';
import '../services/photos.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'clients_screen.dart';

/// Карточка заказа: фото работы, цена, залог, оплаты, остаток.
class OrderScreen extends StatelessWidget {
  final int orderId;

  const OrderScreen({super.key, required this.orderId});

  static void open(BuildContext context, int id) =>
      Navigator.push(context, MaterialPageRoute(builder: (_) => OrderScreen(orderId: id)));

  Future<void> _changePhoto(BuildContext context, Order o) async {
    final r = await choosePhoto(context, hasPhoto: Photos.exists(o.photo), prefix: 'o');
    if (r == null) return;
    await AppStore.I.saveOrder(r.removed ? o.copyWith(clearPhoto: true) : o.copyWith(photo: r.name));
  }

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final o = store.orderById(orderId);
        if (o == null) {
          return Scaffold(appBar: AppBar(), body: EmptyState(icon: Icons.delete_outline, title: t.orderDeleted));
        }
        final s = AppSettings.I;
        final c = context.colors;
        final client = store.clientById(o.clientId);
        final paid = store.paidForOrder(o.id!);
        final remaining = store.remainingOf(o);
        final pays = store.paymentsForOrder(o.id!);
        final hasPhoto = Photos.exists(o.photo);
        final due = dueText(o);

        return Scaffold(
          appBar: AppBar(
            title: Text(t.order),
            actions: [
              IconButton(
                tooltip: t.edit,
                icon: const Icon(Icons.edit_outlined),
                onPressed: () async {
                  final r = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => OrderFormPage(order: o)),
                  );
                  if (r == -1 && context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              // ----- Фото -----
              if (s.show(OrderField.photo))
                hasPhoto
                    ? GestureDetector(
                        onTap: () => PhotoViewerPage.open(context, o.photo!),
                        child: Stack(children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: AspectRatio(
                              aspectRatio: 4 / 3,
                              child: Image.file(Photos.file(o.photo!), fit: BoxFit.cover),
                            ),
                          ),
                          Positioned(
                            right: 10,
                            bottom: 10,
                            child: IconButton.filledTonal(
                              tooltip: t.changePhoto,
                              icon: const Icon(Icons.photo_camera_outlined),
                              onPressed: () => _changePhoto(context, o),
                            ),
                          ),
                        ]),
                      )
                    : InkWell(
                        borderRadius: BorderRadius.circular(24),
                        onTap: () => _changePhoto(context, o),
                        child: Container(
                          height: 120,
                          decoration: BoxDecoration(
                            color: context.cs.surfaceContainer,
                            borderRadius: BorderRadius.circular(24),
                            border: Border.all(color: context.cs.outlineVariant.withValues(alpha: 0.6)),
                          ),
                          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                            Icon(Icons.add_a_photo_outlined, size: 32, color: context.cs.primary),
                            const SizedBox(height: 6),
                            Text(t.addPhoto, style: context.tt.labelLarge?.copyWith(color: context.cs.primary)),
                          ]),
                        ),
                      ),
              const SizedBox(height: 16),

              // ----- Заголовок -----
              if (s.show(OrderField.description) && o.description.isNotEmpty)
                Text(o.description, style: context.tt.headlineSmall),
              const SizedBox(height: 8),
              Wrap(spacing: 8, runSpacing: 6, crossAxisAlignment: WrapCrossAlignment.center, children: [
                if (s.show(OrderField.done) || o.isOverdue) StatusPill(o),
                RemainingPill(remaining),
                if (s.show(OrderField.due) && due != null)
                  Text(due, style: context.tt.bodySmall?.copyWith(color: o.isOverdue ? c.expense : c.muted)),
              ]),
              const SizedBox(height: 14),

              // ----- Клиент -----
              if (client != null)
                Card(
                  clipBehavior: Clip.antiAlias,
                  child: ListRow(
                    leading: Avatar(client.name, photo: client.photo),
                    title: client.name,
                    subtitle: client.phone.isEmpty ? null : client.phone,
                    trailing: BalancePill(store.balanceOf(client.id!)),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: client.id!)),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // ----- Деньги -----
              SectionCard(children: [
                KeyValue(t.price, money(o.priceCents)),
                if (s.show(OrderField.deposit) || o.depositCents > 0)
                  KeyValue(
                    o.depositCents > 0 ? '${t.deposit} · ${shortDay(o.depositDate)}' : t.deposit,
                    money(o.depositCents),
                    color: c.income,
                  ),
                KeyValue(t.paid, money(paid), color: c.income),
                const Divider(height: 18),
                remaining > 0
                    ? KeyValue(t.remaining, money(remaining), color: c.debt, strong: true)
                    : Row(children: [
                        Icon(Icons.check_circle_rounded, color: c.income),
                        const SizedBox(width: 8),
                        Text(t.fullyPaid, style: context.tt.titleSmall?.copyWith(color: c.income)),
                      ]),
              ]),
              const SizedBox(height: 12),

              // ----- Действия -----
              Row(children: [
                if (remaining > 0)
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: c.income),
                      icon: const Icon(Icons.south_west_rounded),
                      label: Text(t.takePayment),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentFormPage(clientId: o.clientId, orderId: o.id)),
                      ),
                    ),
                  ),
                if (remaining > 0 && s.show(OrderField.done)) const SizedBox(width: 10),
                if (s.show(OrderField.done))
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: Icon(o.isDone ? Icons.replay_rounded : Icons.task_alt_rounded),
                      label: Text(o.isDone ? t.markInWork : t.markDone),
                      onPressed: () => store.setOrderDone(o, !o.isDone),
                    ),
                  ),
              ]),
              const SizedBox(height: 12),

              // ----- Даты -----
              SectionCard(children: [
                KeyValue(t.accepted, dayLabel(o.acceptedAt, withYear: true)),
                if (s.show(OrderField.due) && o.dueAt != null)
                  KeyValue(t.dueDate, dayLabel(o.dueAt!, withYear: true), color: o.isOverdue ? c.expense : null),
                if (s.show(OrderField.done) && o.doneAt != null)
                  KeyValue(t.doneDate, dayLabel(o.doneAt!, withYear: true), color: c.income),
              ]),
              if (s.show(OrderField.note) && o.note.isNotEmpty) ...[
                const SizedBox(height: 12),
                SectionCard(title: t.note, children: [Text(o.note, style: context.tt.bodyMedium)]),
              ],
              if (pays.isNotEmpty) ...[
                SectionHeader(t.orderPayments, padding: const EdgeInsets.fromLTRB(4, 22, 4, 10)),
                GroupCard(
                  margin: EdgeInsets.zero,
                  children: [for (final p in pays) PaymentTile(p, showClient: false, showDate: true)],
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
