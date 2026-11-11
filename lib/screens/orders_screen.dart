import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../l10n.dart';
import '../models.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'settings_screen.dart';

enum _Filter { active, debt, all }

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
        var filter = _filter;
        if (!showStatus && filter == _Filter.active) filter = _Filter.debt;

        var list = store.orders.where((o) {
          final ok = switch (filter) {
            _Filter.active => !o.isDone,
            _Filter.debt => store.remainingOf(o) > 0,
            _Filter.all => true,
          };
          if (!ok) return false;
          if (_q.isEmpty) return true;
          return store.clientName(o.clientId).toLowerCase().contains(_q) || o.description.toLowerCase().contains(_q);
        }).toList();
        // просроченные — наверх
        if (filter == _Filter.active) {
          list = [...list.where((o) => o.isOverdue), ...list.where((o) => !o.isOverdue)];
        }
        final sum = list.fold(0, (a, o) => a + o.priceCents);
        final remain = list.fold(0, (a, o) => a + store.remainingOf(o));
        final activeCount = store.orders.where((o) => !o.isDone).length;

        return Scaffold(
          appBar: AppBar(
            title: Text(t.tabOrders),
            actions: [
              IconButton(
                tooltip: t.fieldsTooltip,
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
            label: Text(t.order),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const OrderFormPage())),
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 96),
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: TextField(
                  decoration: InputDecoration(hintText: t.ordersSearchHint, prefixIcon: const Icon(Icons.search_rounded)),
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
                child: SegmentedButton<_Filter>(
                  segments: [
                    if (showStatus) ButtonSegment(value: _Filter.active, label: Text(t.filterActive(activeCount))),
                    ButtonSegment(value: _Filter.debt, label: Text(t.filterDebt)),
                    ButtonSegment(value: _Filter.all, label: Text(t.seeAll)),
                  ],
                  selected: {filter},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _filter = s.first),
                ),
              ),
              if (list.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                  child: Row(children: [
                    Text('${t.pcs(list.length)} · ${money(sum)}',
                        style: context.tt.labelLarge?.copyWith(color: context.colors.muted)),
                    const Spacer(),
                    if (remain > 0) Text(t.debtPill(money(remain)), style: amountStyle(15, color: context.colors.debt)),
                  ]),
                ),
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.handyman_outlined,
                  title: store.orders.isEmpty ? t.noOrdersYet : t.nothingFound,
                  text: store.orders.isEmpty ? t.noOrdersHint : null,
                )
              else
                GroupCard(children: [for (final o in list) OrderTile(o)]),
              if (list.isNotEmpty && showStatus)
                Padding(
                  padding: const EdgeInsets.only(top: 12, left: 24, right: 24),
                  child: Text(
                    t.longPressHint,
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
