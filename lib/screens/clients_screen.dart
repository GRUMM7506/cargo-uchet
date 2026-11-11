import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

enum _Sort { debt, name }

class ClientsScreen extends StatefulWidget {
  const ClientsScreen({super.key});

  @override
  State<ClientsScreen> createState() => _ClientsScreenState();
}

class _ClientsScreenState extends State<ClientsScreen> {
  String _q = '';
  _Sort _sort = _Sort.debt;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final list = store.clients
            .where((c) => _q.isEmpty || c.name.toLowerCase().contains(_q) || c.phone.contains(_q))
            .toList();
        if (_sort == _Sort.debt) {
          list.sort((a, b) => store.balanceOf(b.id!).compareTo(store.balanceOf(a.id!)));
        }
        return Scaffold(
          appBar: AppBar(title: const Text('Клиенты')),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: const Text('Клиент'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientFormPage())),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: Row(children: [
                  Expanded(
                    child: _SummaryTile(
                      label: 'Должны',
                      value: money(store.totalDebt),
                      color: context.colors.debt,
                      background: context.colors.debtBg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: 'Авансы',
                      value: money(store.totalAdvance),
                      color: context.colors.income,
                      background: context.colors.incomeBg,
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: TextField(
                  decoration: const InputDecoration(
                    hintText: 'Поиск по имени или телефону',
                    prefixIcon: Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(children: [
                  Text('${list.length} ${_word(list.length)}',
                      style: context.tt.labelLarge?.copyWith(color: context.colors.muted)),
                  const Spacer(),
                  ChoiceChip(
                    label: const Text('Должники'),
                    selected: _sort == _Sort.debt,
                    onSelected: (_) => setState(() => _sort = _Sort.debt),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: const Text('А–Я'),
                    selected: _sort == _Sort.name,
                    onSelected: (_) => setState(() => _sort = _Sort.name),
                  ),
                ]),
              ),
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: store.clients.isEmpty ? 'Клиентов пока нет' : 'Никого не найдено',
                  text: store.clients.isEmpty ? 'Добавьте первого клиента кнопкой ниже' : null,
                )
              else
                GroupCard(children: [
                  for (final c in list)
                    ClientTile(
                      c,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c.id!)),
                      ),
                    ),
                ]),
            ],
          ),
        );
      },
    );
  }

  String _word(int n) {
    final m10 = n % 10, m100 = n % 100;
    if (m10 == 1 && m100 != 11) return 'клиент';
    if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return 'клиента';
    return 'клиентов';
  }
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final Color background;

  const _SummaryTile({required this.label, required this.value, required this.color, required this.background});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(18)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13)),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(value, style: amountStyle(20, color: color)),
        ),
      ]),
    );
  }
}

class ClientDetailScreen extends StatefulWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  State<ClientDetailScreen> createState() => _ClientDetailScreenState();
}

class _ClientDetailScreenState extends State<ClientDetailScreen> {
  int _tab = 0; // 0 — заказы, 1 — оплаты

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final c = store.clientById(widget.clientId);
        if (c == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const EmptyState(icon: Icons.person_off_outlined, title: 'Клиент удалён'),
          );
        }
        final orders = store.ordersOf(c.id!);
        final payments = store.paymentsOf(c.id!);
        final balance = store.balanceOf(c.id!);
        final totalOrders = orders.fold(0, (a, o) => a + o.amountCents);
        final totalPaid = payments.fold(0, (a, p) => a + p.amountCents);
        final weight = orders.fold(0.0, (a, o) => a + (o.weightKg ?? 0));
        final set = AppSettings.I;
        final col = context.colors;
        final balColor = balance > 0 ? col.debt : (balance < 0 ? col.income : col.muted);

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Изменить',
                onPressed: () async {
                  final r = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(builder: (_) => ClientFormPage(client: c)),
                  );
                  if (r == -1 && context.mounted) Navigator.pop(context);
                },
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: Row(children: [
                  Avatar(c.name, size: 60),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: context.tt.headlineSmall),
                      if (c.phone.isNotEmpty)
                        Text(c.phone, style: context.tt.bodyMedium?.copyWith(color: col.muted)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionCard(children: [
                  Text(
                    balance > 0 ? 'Долг' : (balance < 0 ? 'Аванс' : 'Баланс'),
                    style: context.tt.labelLarge?.copyWith(color: balColor),
                  ),
                  Text(
                    balance == 0 ? 'Рассчитан' : money(balance.abs()),
                    style: amountStyle(32, color: balColor),
                  ),
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  KeyValue('Заказов на сумму', money(totalOrders)),
                  KeyValue('Оплачено', money(totalPaid), color: col.income),
                  if (set.show(OrderField.weight) && weight > 0) KeyValue('Общий вес', kg(weight)),
                  if (set.show(OrderField.pricing) && c.rateKgCents != null)
                    KeyValue('Своя цена за кг', money(c.rateKgCents!)),
                  if (c.note.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(c.note, style: context.tt.bodyMedium?.copyWith(color: col.muted)),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(backgroundColor: col.income),
                      icon: const Icon(Icons.south_west_rounded),
                      label: const Text('Оплата'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentFormPage(clientId: c.id)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Заказ'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderFormPage(clientId: c.id)),
                      ),
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
                child: SegmentedButton<int>(
                  segments: [
                    ButtonSegment(value: 0, label: Text('Заказы · ${orders.length}')),
                    ButtonSegment(value: 1, label: Text('Оплаты · ${payments.length}')),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              if (_tab == 0)
                orders.isEmpty
                    ? const EmptyState(icon: Icons.local_shipping_outlined, title: 'Заказов нет')
                    : GroupCard(children: [for (final o in orders) OrderTile(o, showClient: false)])
              else
                payments.isEmpty
                    ? const EmptyState(icon: Icons.payments_outlined, title: 'Оплат нет')
                    : GroupCard(children: [for (final p in payments) PaymentTile(p, showClient: false, showDate: true)]),
            ],
          ),
        );
      },
    );
  }
}
