import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../l10n.dart';
import '../models.dart';
import '../services/photos.dart';
import '../services/rates.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/actions.dart';
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
          appBar: AppBar(title: Text(t.tabClients)),
          floatingActionButton: FloatingActionButton.extended(
            icon: const Icon(Icons.person_add_alt_1_rounded),
            label: Text(t.client),
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
                      label: t.owe,
                      value: money(store.totalDebt),
                      color: context.colors.debt,
                      background: context.colors.debtBg,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SummaryTile(
                      label: t.overpayments,
                      value: money(store.totalOverpaid),
                      color: context.colors.income,
                      background: context.colors.incomeBg,
                    ),
                  ),
                ]),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 4),
                child: TextField(
                  decoration: InputDecoration(hintText: t.clientsSearchHint, prefixIcon: const Icon(Icons.search_rounded)),
                  onChanged: (v) => setState(() => _q = v.trim().toLowerCase()),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 6, 16, 10),
                child: Row(children: [
                  Text(t.clientsCount(list.length), style: context.tt.labelLarge?.copyWith(color: context.colors.muted)),
                  const Spacer(),
                  ChoiceChip(
                    label: Text(t.sortDebtors),
                    selected: _sort == _Sort.debt,
                    onSelected: (_) => setState(() => _sort = _Sort.debt),
                  ),
                  const SizedBox(width: 6),
                  ChoiceChip(
                    label: Text(t.sortAz),
                    selected: _sort == _Sort.name,
                    onSelected: (_) => setState(() => _sort = _Sort.name),
                  ),
                ]),
              ),
              if (list.isEmpty)
                EmptyState(
                  icon: Icons.people_outline_rounded,
                  title: store.clients.isEmpty ? t.noClients : t.nobodyFound,
                  text: store.clients.isEmpty ? t.noClientsHint : null,
                )
              else ...[
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
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
                  child: Text(t.swipeHint,
                      textAlign: TextAlign.center,
                      style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
                ),
              ],
            ],
          ),
        );
      },
    );
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
            body: EmptyState(icon: Icons.person_off_outlined, title: t.clientDeleted),
          );
        }
        final orders = store.ordersOf(c.id!);
        final payments = store.paymentsOf(c.id!);
        final balance = store.balanceOf(c.id!);
        final fx = Fx.I;
        final main = AppSettings.I.currency;
        final totalOrders = orders.fold(0, (a, o) => a + fx.convert(o.priceCents, o.currency, main, o.acceptedAt));
        final totalDeposits =
            orders.fold(0, (a, o) => a + fx.convert(o.depositCents, o.currency, main, o.depositDate));
        final totalPaid = payments.fold(0, (a, p) => a + fx.convert(p.amountCents, p.currency, main, p.paidAt));
        final buckets = store.bucketsOf(c.id!);
        final single = buckets.length == 1 ? buckets.entries.first : null;
        final col = context.colors;
        final balColor = balance > 0 ? col.debt : (balance < 0 ? col.income : col.muted);

        return Scaffold(
          appBar: AppBar(
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                tooltip: t.edit,
                onPressed: () async {
                  final r = await Navigator.push<int>(
                    context,
                    MaterialPageRoute(builder: (_) => ClientFormPage(client: c)),
                  );
                  if (r == -1 && context.mounted) Navigator.pop(context);
                },
              ),
              PopupMenuButton<String>(
                onSelected: (v) async {
                  if (v == 'edit') {
                    final r = await Navigator.push<int>(
                      context,
                      MaterialPageRoute(builder: (_) => ClientFormPage(client: c)),
                    );
                    if (r == -1 && context.mounted) Navigator.pop(context);
                  } else if (v == 'delete') {
                    final nav = Navigator.of(context);
                    if (await deleteClientFlow(context, c)) nav.pop();
                  }
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: ListTile(leading: const Icon(Icons.edit_outlined), title: Text(t.editClient)),
                  ),
                  PopupMenuItem(
                    value: 'delete',
                    child: ListTile(
                      leading: Icon(Icons.delete_outline_rounded, color: context.colors.expense),
                      title: Text(t.deleteClient, style: TextStyle(color: context.colors.expense)),
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  GestureDetector(
                    onTap: () async {
                      if (Photos.exists(c.photo)) {
                        PhotoViewerPage.open(context, c.photo!);
                        return;
                      }
                      final r = await choosePhoto(context, hasPhoto: false, prefix: 'c');
                      if (r?.name != null) {
                        await store.saveClient(Client(
                          id: c.id,
                          name: c.name,
                          phone: c.phone,
                          note: c.note,
                          photo: r!.name,
                        ));
                      }
                    },
                    child: Avatar(c.name, photo: c.photo, size: 68),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(c.name, style: context.tt.headlineSmall),
                      if (c.phone.isNotEmpty) Text(c.phone, style: context.tt.bodyMedium?.copyWith(color: col.muted)),
                    ]),
                  ),
                ]),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SectionCard(children: [
                  Text(
                    balance > 0 ? t.debt : (balance < 0 ? t.overpaid : t.settled),
                    style: context.tt.labelLarge?.copyWith(color: balColor),
                  ),
                  if (single != null) ...[
                    Text(money(single.value.abs(), cur: single.key), style: amountStyle(32, color: balColor)),
                    if (single.key != main)
                      Text('≈ ${money(balance.abs())}', style: context.tt.bodyMedium?.copyWith(color: col.muted)),
                  ] else if (balance != 0) ...[
                    Text('≈ ${money(balance.abs())}', style: amountStyle(32, color: balColor)),
                    const SizedBox(height: 6),
                    for (final e in buckets.entries)
                      KeyValue(
                        e.value > 0 ? '${t.debt} · ${e.key}' : '${t.overpaid} · ${e.key}',
                        money(e.value.abs(), cur: e.key),
                        color: e.value > 0 ? col.debt : col.income,
                      ),
                  ],
                  const SizedBox(height: 10),
                  const Divider(),
                  const SizedBox(height: 6),
                  KeyValue(t.ordersTotal, money(totalOrders)),
                  if (totalDeposits > 0) KeyValue(t.deposits, money(totalDeposits), color: col.income),
                  KeyValue(t.paymentsLabel, money(totalPaid), color: col.income),
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
                      label: Text(t.payment),
                      onPressed: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => PaymentFormPage(clientId: c.id)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.handyman_outlined),
                      label: Text(t.order),
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
                    ButtonSegment(value: 0, label: segLabel(t.ordersTab(orders.length))),
                    ButtonSegment(value: 1, label: segLabel(t.paymentsTab(payments.length))),
                  ],
                  selected: {_tab},
                  showSelectedIcon: false,
                  onSelectionChanged: (s) => setState(() => _tab = s.first),
                ),
              ),
              if (orders.isNotEmpty || payments.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: Text(t.swipeHint,
                      textAlign: TextAlign.center, style: context.tt.bodySmall?.copyWith(color: col.muted)),
                ),
              if (_tab == 0)
                orders.isEmpty
                    ? EmptyState(icon: Icons.handyman_outlined, title: t.noOrders)
                    : GroupCard(children: [for (final o in orders) OrderTile(o, showClient: false)])
              else
                payments.isEmpty
                    ? EmptyState(icon: Icons.payments_outlined, title: t.noPayments)
                    : GroupCard(children: [for (final p in payments) PaymentTile(p, showClient: false, showDate: true)]),
            ],
          ),
        );
      },
    );
  }
}
