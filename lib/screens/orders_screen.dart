import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../store.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

enum _Filter { active, done, all }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _Filter _filter = _Filter.active;

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final list = store.orders.where((o) {
          switch (_filter) {
            case _Filter.active:
              return !o.isDone;
            case _Filter.done:
              return o.isDone;
            case _Filter.all:
              return true;
          }
        }).toList();
        final sum = list.fold(0, (a, o) => a + o.amountCents);
        final weight = list.fold(0.0, (a, o) => a + (o.weightKg ?? 0));

        return Scaffold(
          appBar: AppBar(title: const Text('Заказы')),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add),
            label: const Text('Заказ'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderFormPage())),
          ),
          body: Column(children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
              child: SegmentedButton<_Filter>(
                segments: const [
                  ButtonSegment(value: _Filter.active, label: Text('В работе')),
                  ButtonSegment(value: _Filter.done, label: Text('Выполнены')),
                  ButtonSegment(value: _Filter.all, label: Text('Все')),
                ],
                selected: {_filter},
                showSelectedIcon: false,
                onSelectionChanged: (s) => setState(() => _filter = s.first),
              ),
            ),
            if (list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(children: [
                  Text('${list.length} шт', style: Theme.of(context).textTheme.labelLarge),
                  if (weight > 0) Text(' · ${kg(weight)}', style: Theme.of(context).textTheme.labelLarge),
                  const Spacer(),
                  Text(money(sum), style: Theme.of(context).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700)),
                ]),
              ),
            Expanded(
              child: list.isEmpty
                  ? const EmptyState(icon: Icons.local_shipping_outlined, text: 'Заказов нет')
                  : ListView.separated(
                      padding: const EdgeInsets.only(bottom: 88),
                      itemCount: list.length,
                      separatorBuilder: (_, __) => const Divider(height: 1, indent: 72),
                      itemBuilder: (ctx, i) => OrderTile(list[i]),
                    ),
            ),
            if (list.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text(
                  'Долгое нажатие — отметить выполненным',
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Theme.of(context).colorScheme.outline),
                ),
              ),
          ]),
        );
      },
    );
  }
}
