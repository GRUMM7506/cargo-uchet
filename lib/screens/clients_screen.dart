import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

enum _Sort { name, debt }

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
      listenable: store,
      builder: (context, _) {
        final list = store.clients
            .where((c) => _q.isEmpty || c.name.toLowerCase().contains(_q) || c.phone.contains(_q))
            .toList();
        if (_sort == _Sort.debt) {
          list.sort((a, b) => store.balanceOf(b.id!).compareTo(store.balanceOf(a.id!)));
        }
        return Scaffold(
          appBar: AppBar(
            title: const Text('Клиенты'),
            actions: [
              PopupMenuButton<_Sort>(
                icon: const Icon(Icons.sort),
                initialValue: _sort,
                onSelected: (s) => setState(() => _sort = s),
                itemBuilder: (_) => const [
                  PopupMenuItem(value: _Sort.debt, child: Text('Сначала должники')),
                  PopupMenuItem(value: _Sort.name, child: Text('По имени')),
                ],
              ),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.person_add),
            label: const Text('Клиент'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ClientFormPage())),
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
              child: TextField(
                decoration: const InputDecoration(
                  hintText: 'Поиск по имени или телефону',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
              ),
            ),
            Expanded(
              child: list.isEmpty
                  ? EmptyState(
                      icon: Icons.people_outline,
                      text: store.clients.isEmpty ? 'Клиентов пока нет.\nДобавьте первого кнопкой ниже.' : 'Никого не найдено',
                    )
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (ctx, i) {
                        final c = list[i];
                        final active = store.ordersOf(c.id!).where((o) => !o.isDone).length;
                        return ListTile(
                          leading: CircleAvatar(child: Text(c.name.isEmpty ? '?' : c.name[0].toUpperCase())),
                          title: Text(c.name),
                          subtitle: Text(
                            [
                              if (c.phone.isNotEmpty) c.phone,
                              if (active > 0) 'в работе: $active',
                            ].join(' · '),
                          ),
                          trailing: BalanceText(store.balanceOf(c.id!)),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(builder: (_) => ClientDetailScreen(clientId: c.id!)),
                          ),
                        );
                      },
                    ),
            ),
          ]),
        );
      },
    );
  }
}

class ClientDetailScreen extends StatelessWidget {
  final int clientId;

  const ClientDetailScreen({super.key, required this.clientId});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final c = store.clientById(clientId);
        if (c == null) {
          return Scaffold(appBar: AppBar(), body: const EmptyState(icon: Icons.person_off, text: 'Клиент удалён'));
        }
        final orders = store.ordersOf(clientId);
        final payments = store.paymentsOf(clientId);
        final balance = store.balanceOf(clientId);
        final totalOrders = orders.fold(0, (a, o) => a + o.amountCents);
        final totalPaid = payments.fold(0, (a, p) => a + p.amountCents);
        final weight = orders.fold(0.0, (a, o) => a + (o.weightKg ?? 0));

        return Scaffold(
          appBar: AppBar(
            title: Text(c.name),
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
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Padding(
                padding: const EdgeInsets.all(12),
                child: Card(
                  margin: EdgeInsets.zero,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        BalanceText(balance, style: Theme.of(context).textTheme.headlineSmall),
                        const SizedBox(height: 10),
                        _kv('Заказов на сумму', money(totalOrders)),
                        _kv('Оплачено', money(totalPaid)),
                        if (weight > 0) _kv('Общий вес', kg(weight)),
                        if (c.phone.isNotEmpty) _kv('Телефон', c.phone),
                        if (c.note.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(c.note, style: TextStyle(color: Theme.of(context).colorScheme.outline)),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Row(children: [
                  Expanded(
                    child: FilledButton.icon(
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48), backgroundColor: incomeColor),
                      icon: const Icon(Icons.add),
                      label: const Text('Оплата'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentFormPage(clientId: clientId)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
                      icon: const Icon(Icons.local_shipping_outlined),
                      label: const Text('Заказ'),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => OrderFormPage(clientId: clientId)),
                      ),
                    ),
                  ),
                ]),
              ),
              SectionHeader('Заказы (${orders.length})'),
              if (orders.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('Заказов нет'))
              else
                ...orders.map((o) => OrderTile(o, showClient: false)),
              SectionHeader('Оплаты (${payments.length})'),
              if (payments.isEmpty)
                const Padding(padding: EdgeInsets.all(16), child: Text('Оплат нет'))
              else
                ...payments.map((p) => PaymentTile(p, showClient: false)),
            ],
          ),
        );
      },
    );
  }

  Widget _kv(String k, String v) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(children: [Expanded(child: Text(k)), Text(v, style: const TextStyle(fontWeight: FontWeight.w600))]),
      );
}

// Используется в отчётах: список клиентов с ненулевым балансом.
List<Client> clientsWithBalance() {
  final s = AppStore.I;
  return s.clients.where((c) => s.balanceOf(c.id!) != 0).toList()
    ..sort((a, b) => s.balanceOf(b.id!).compareTo(s.balanceOf(a.id!)));
}
