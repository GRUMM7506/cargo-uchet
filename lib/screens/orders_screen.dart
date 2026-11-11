import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'settings_screen.dart';

enum _Filter { active, done, all }

class OrdersScreen extends StatefulWidget {
  const OrdersScreen({super.key});

  @override
  State<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends State<OrdersScreen> {
  _Filter _filter = _Filter.active;
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final set = AppSettings.I;
        final showStatus = set.show(OrderField.done);
        final filter = showStatus ? _filter : _Filter.all;
        final list = store.orders.where((o) {
          final okStatus = switch (filter) {
            _Filter.active => !o.isDone,
            _Filter.done => o.isDone,
            _Filter.all => true,
          };
          if (!okStatus) return false;
          if (_q.isEmpty) return true;
          return store.clientName(o.clientId).toLowerCase().contains(_q) ||
              o.description.toLowerCase().contains(_q) ||
              o.code.toLowerCase().contains(_q);
        }).toList();
        final sum = list.fold(0, (a, o) => a + o.amountCents);
        final weight = list.fold(0.0, (a, o) => a + (o.weightKg ?? 0));

        return Scaffold(
          appBar: AppBar(
            title: const Text('Заказы'),
            actions: [
              IconButton(
                tooltip: 'Настроить поля',
                icon: const Icon(Icons.view_agenda_outlined),
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SettingsScreen(focusOrders: true)),
                ),
              ),
              const SizedBox(width: 4),
            ],
          ),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.add_rounded),
            label: const Text('Заказ'),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderFormPage())),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: set.show(OrderField.code) ? 'Клиент, груз или трек-номер' : 'Клиент или груз',
                    prefixIcon: const Icon(Icons.search_rounded),
                  ),
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
              ),
              if (showStatus)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                  child: SegmentedButton<_Filter>(
                    segments: [
                      ButtonSegment(
                        value: _Filter.active,
                        label: Text('В работе · ${store.orders.where((o) => !o.isDone).length}'),
                      ),
                      const ButtonSegment(value: _Filter.done, label: Text('Выполнены')),
                      const ButtonSegment(value: _Filter.all, label: Text('Все')),
                    ],
                    selected: {_filter},
                    showSelectedIcon: false,
                    onSelectionChanged: (s) => setState(() => _filter = s.first),
                  ),
                ),
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                  child: Row(children: [
                    Text(
                      [
                        '${list.length} шт',
                        if (set.show(OrderField.weight) && weight > 0) kg(weight),
                      ].join(' · '),
                      style: context.tt.labelLarge?.copyWith(color: context.colors.muted),
                    ),
                    const Spacer(),
                    Text(money(sum), style: amountStyle(15)),
                  ]),
                ),
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.local_shipping_outlined,
                  title: store.orders.isEmpty ? 'Заказов пока нет' : 'Ничего не найдено',
                  text: store.orders.isEmpty ? 'Нажмите «Заказ», чтобы добавить первый' : null,
                )
              else
                GroupCard(children: [for (final o in list) OrderTile(o)]),
              if (list.isNotEmpty && showStatus)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text(
                    'Удерживайте заказ, чтобы отметить его выполненным',
                    textAlign: TextAlign.center,
                    style: context.tt.bodySmall?.copyWith(color: context.colors.muted),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}
