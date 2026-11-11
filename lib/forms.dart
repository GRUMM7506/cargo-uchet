import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'l10n.dart';
import 'models.dart';
import 'services/photos.dart';
import 'settings.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets/common.dart';

final _store = AppStore.I;
final _settings = AppSettings.I;

const _gap = SizedBox(height: 12);

final _decimalOnly = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))];

InputDecoration _dec(String label, {String? hint, String? prefix, IconData? icon, String? helper}) => InputDecoration(
      labelText: label,
      hintText: hint,
      prefixText: prefix,
      helperText: helper,
      prefixIcon: icon == null ? null : Icon(icon),
    );

/// Каркас формы: AppBar с удалением + кнопка «Сохранить» внизу.
class _FormScaffold extends StatelessWidget {
  final String title;
  final GlobalKey<FormState> formKey;
  final List<Widget> children;
  final VoidCallback onSave;
  final VoidCallback? onDelete;

  const _FormScaffold({
    required this.title,
    required this.formKey,
    required this.children,
    required this.onSave,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        actions: [
          if (onDelete != null)
            IconButton(
              icon: Icon(Icons.delete_outline_rounded, color: context.colors.expense),
              tooltip: t.delete,
              onPressed: onDelete,
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(padding: const EdgeInsets.fromLTRB(16, 4, 16, 24), children: children),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(56)),
            icon: const Icon(Icons.check_rounded),
            label: Text(t.save, style: const TextStyle(fontSize: 16)),
            onPressed: onSave,
          ),
        ),
      ),
    );
  }
}

/// Блок выбора фото в форме.
class _PhotoPicker extends StatelessWidget {
  final String? photo;
  final String prefix;
  final bool round;
  final ValueChanged<String?> onChanged;

  const _PhotoPicker({required this.photo, required this.prefix, required this.onChanged, this.round = false});

  @override
  Widget build(BuildContext context) {
    final has = Photos.exists(photo);
    final size = round ? 104.0 : 150.0;
    final radius = BorderRadius.circular(round ? size / 2 : 24);
    return Center(
      child: GestureDetector(
        onTap: () async {
          final r = await choosePhoto(context, hasPhoto: has, prefix: prefix);
          if (r == null) return;
          onChanged(r.removed ? null : r.name);
        },
        child: Stack(clipBehavior: Clip.none, children: [
          has
              ? PhotoBox(photo: photo!, size: size, radius: radius)
              : Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    color: context.cs.surfaceContainer,
                    borderRadius: radius,
                    border: Border.all(color: context.cs.outlineVariant),
                  ),
                  child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                    Icon(Icons.add_a_photo_outlined, color: context.cs.primary, size: 30),
                    const SizedBox(height: 6),
                    Text(t.addPhoto,
                        textAlign: TextAlign.center,
                        style: context.tt.labelMedium?.copyWith(color: context.cs.primary)),
                  ]),
                ),
          if (has)
            Positioned(
              right: -4,
              bottom: -4,
              child: Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: context.cs.primary,
                  shape: BoxShape.circle,
                  border: Border.all(color: context.cs.surface, width: 3),
                ),
                child: Icon(Icons.edit_rounded, size: 16, color: context.cs.onPrimary),
              ),
            ),
        ]),
      ),
    );
  }
}

// ======================= Выбор клиента =======================

Future<int?> pickClient(BuildContext context) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (ctx) => const _ClientPickerSheet(),
  );
}

class _ClientPickerSheet extends StatefulWidget {
  const _ClientPickerSheet();

  @override
  State<_ClientPickerSheet> createState() => _ClientPickerSheetState();
}

class _ClientPickerSheetState extends State<_ClientPickerSheet> {
  String _q = '';

  @override
  Widget build(BuildContext context) {
    final q = _q.toLowerCase();
    final list = _store.clients.where((c) => c.name.toLowerCase().contains(q) || c.phone.contains(q)).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.78,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Align(alignment: Alignment.centerLeft, child: Text(t.chooseClient, style: context.tt.titleLarge)),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                autofocus: _store.clients.length > 8,
                decoration: _dec(t.search, icon: Icons.search_rounded),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: IconBadge(Icons.person_add_alt_1_rounded,
                  color: context.cs.primary, background: context.cs.primaryContainer.withValues(alpha: 0.6)),
              title: Text(_q.trim().isEmpty ? t.newClient : t.newClientNamed(_q.trim())),
              onTap: () async {
                final id = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(builder: (_) => ClientFormPage(initialName: _q.trim())),
                );
                if (id != null && id > 0 && context.mounted) Navigator.pop(context, id);
              },
            ),
            const Divider(),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final c = list[i];
                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    leading: Avatar(c.name, photo: c.photo, size: 40),
                    title: Text(c.name),
                    trailing: BalancePill(_store.balanceOf(c.id!)),
                    onTap: () => Navigator.pop(context, c.id),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ClientField extends StatelessWidget {
  final int? clientId;
  final ValueChanged<int> onChanged;
  final String? errorText;

  const _ClientField({required this.clientId, required this.onChanged, this.errorText});

  @override
  Widget build(BuildContext context) {
    final client = clientId == null ? null : _store.clientById(clientId!);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final id = await pickClient(context);
        if (id != null) onChanged(id);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: t.client,
          errorText: errorText,
          prefixIcon: client == null
              ? const Icon(Icons.person_outline_rounded)
              : Padding(padding: const EdgeInsets.all(10), child: Avatar(client.name, photo: client.photo, size: 28)),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          client?.name ?? t.chooseClient,
          style: client == null ? TextStyle(color: Theme.of(context).hintColor) : context.tt.titleSmall,
        ),
      ),
    );
  }
}

// ======================= Клиент =======================

class ClientFormPage extends StatefulWidget {
  final Client? client;
  final String initialName;

  const ClientFormPage({super.key, this.client, this.initialName = ''});

  @override
  State<ClientFormPage> createState() => _ClientFormPageState();
}

class _ClientFormPageState extends State<ClientFormPage> {
  final _key = GlobalKey<FormState>();
  late final _name = TextEditingController(text: widget.client?.name ?? widget.initialName);
  late final _phone = TextEditingController(text: widget.client?.phone ?? '');
  late final _note = TextEditingController(text: widget.client?.note ?? '');
  late String? _photo = widget.client?.photo;

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final id = await _store.saveClient(Client(
      id: widget.client?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      note: _note.text.trim(),
      photo: _photo,
    ));
    if (mounted) Navigator.pop(context, id);
  }

  Future<void> _delete() async {
    final c = widget.client!;
    final n = _store.ordersOf(c.id!).length + _store.paymentsOf(c.id!).length;
    final ok = await confirm(context, n == 0 ? t.deleteClientQ(c.name) : t.deleteClientWithQ(c.name, n));
    if (!ok) return;
    await _store.deleteClient(c.id!);
    if (mounted) Navigator.pop(context, -1);
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.client == null ? t.newClient : t.client,
      formKey: _key,
      onSave: _save,
      onDelete: widget.client == null ? null : _delete,
      children: [
        _PhotoPicker(photo: _photo, prefix: 'c', round: true, onChanged: (p) => setState(() => _photo = p)),
        const SizedBox(height: 18),
        TextFormField(
          controller: _name,
          autofocus: widget.client == null && widget.initialName.isEmpty,
          textCapitalization: TextCapitalization.words,
          decoration: _dec(t.name, icon: Icons.person_outline_rounded),
          validator: (v) => (v == null || v.trim().isEmpty) ? t.enterName : null,
        ),
        _gap,
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _dec(t.phone, icon: Icons.phone_outlined),
        ),
        _gap,
        TextFormField(
          controller: _note,
          maxLines: 3,
          decoration: _dec(t.note, icon: Icons.notes_rounded),
        ),
      ],
    );
  }
}

// ======================= Заказ =======================

class OrderFormPage extends StatefulWidget {
  final Order? order;
  final int? clientId;

  const OrderFormPage({super.key, this.order, this.clientId});

  @override
  State<OrderFormPage> createState() => _OrderFormPageState();
}

class _OrderFormPageState extends State<OrderFormPage> {
  final _key = GlobalKey<FormState>();
  late int? _clientId = widget.order?.clientId ?? widget.clientId;
  late String? _photo = widget.order?.photo;
  late final _desc = TextEditingController(text: widget.order?.description ?? '');
  late final _price = TextEditingController(
    text: widget.order == null ? '' : moneyInput(widget.order!.priceCents),
  );
  late final _deposit = TextEditingController(
    text: (widget.order?.depositCents ?? 0) == 0 ? '' : moneyInput(widget.order!.depositCents),
  );
  late final _note = TextEditingController(text: widget.order?.note ?? '');
  late DateTime _accepted = widget.order?.acceptedAt ?? today();
  late DateTime? _depositAt = widget.order?.depositAt;
  late DateTime? _due = widget.order?.dueAt;
  late DateTime? _done = widget.order?.doneAt;
  bool _clientError = false;

  @override
  void initState() {
    super.initState();
    _price.addListener(_refresh);
    _deposit.addListener(_refresh);
  }

  void _refresh() => setState(() {});

  @override
  void dispose() {
    for (final c in [_desc, _price, _deposit, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    final valid = _key.currentState!.validate();
    setState(() => _clientError = _clientId == null);
    if (!valid || _clientId == null) return;
    final deposit = parseMoney(_deposit.text) ?? 0;
    await _store.saveOrder(Order(
      id: widget.order?.id,
      clientId: _clientId!,
      description: _desc.text.trim(),
      photo: _photo,
      priceCents: parseMoney(_price.text)!,
      depositCents: deposit,
      // дату залога храним, только если она отличается от даты приёма
      depositAt: deposit == 0 || _depositAt == null || _depositAt == _accepted ? null : _depositAt,
      acceptedAt: _accepted,
      dueAt: _due,
      doneAt: _done,
      note: _note.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (!await confirm(context, t.deleteOrderQ)) return;
    await _store.deleteOrder(widget.order!.id!);
    if (mounted) Navigator.pop(context, -1);
  }

  @override
  Widget build(BuildContext context) {
    final s = _settings;
    final price = parseMoney(_price.text) ?? 0;
    final deposit = parseMoney(_deposit.text) ?? 0;
    final paidBefore = widget.order?.id == null ? 0 : _store.paidForOrder(widget.order!.id!);
    final remain = price - deposit - paidBefore;
    final c = context.colors;

    return _FormScaffold(
      title: widget.order == null ? t.newOrder : t.order,
      formKey: _key,
      onSave: _save,
      onDelete: widget.order == null ? null : _delete,
      children: [
        if (s.show(OrderField.photo)) ...[
          _PhotoPicker(photo: _photo, prefix: 'o', onChanged: (p) => setState(() => _photo = p)),
          const SizedBox(height: 18),
        ],
        _ClientField(
          clientId: _clientId,
          errorText: _clientError ? t.chooseClient : null,
          onChanged: (id) => setState(() {
            _clientId = id;
            _clientError = false;
          }),
        ),
        _gap,
        if (s.show(OrderField.description)) ...[
          TextFormField(
            controller: _desc,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec(t.workDescription, icon: Icons.handyman_outlined),
          ),
          _gap,
        ],

        // ----- Деньги -----
        SectionCard(children: [
          TextFormField(
            controller: _price,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _decimalOnly,
            style: amountStyle(22),
            decoration: _dec(t.workPrice, prefix: '\$ ', icon: Icons.sell_outlined),
            validator: (v) {
              final x = parseMoney(v ?? '');
              if (x == null) return t.enterAmount;
              if (x < 0) return t.negativeAmount;
              return null;
            },
          ),
          if (s.show(OrderField.deposit)) ...[
            _gap,
            TextFormField(
              controller: _deposit,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: _decimalOnly,
              style: amountStyle(18, color: c.income),
              decoration: _dec(t.deposit, prefix: '\$ ', icon: Icons.savings_outlined, helper: t.depositHint),
              validator: (v) {
                final d = parseMoney(v ?? '') ?? 0;
                final p = parseMoney(_price.text) ?? 0;
                if (d > p && p > 0) return t.depositTooBig;
                return null;
              },
            ),
            if (deposit > 0) ...[
              _gap,
              DateField(
                label: t.depositDate,
                value: _depositAt ?? _accepted,
                icon: Icons.event_available_outlined,
                onChanged: (d) => setState(() => _depositAt = d),
              ),
            ],
          ],
          if (price > 0) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: remain > 0 ? c.debtBg : c.incomeBg,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(children: [
                Icon(remain > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                    color: remain > 0 ? c.debt : c.income),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    remain > 0 ? t.willRemain : t.fullyPaid,
                    style: context.tt.titleSmall?.copyWith(color: remain > 0 ? c.debt : c.income),
                  ),
                ),
                if (remain > 0) Text(money(remain), style: amountStyle(20, color: c.debt)),
              ]),
            ),
          ],
        ]),
        _gap,

        // ----- Даты -----
        DateField(label: t.acceptDate, value: _accepted, onChanged: (d) => setState(() => _accepted = d)),
        if (s.show(OrderField.due)) ...[
          _gap,
          if (_due == null)
            OutlinedButton.icon(
              icon: const Icon(Icons.flag_outlined),
              label: Text(t.setDue),
              onPressed: () async {
                final d = await showDatePicker(
                  context: context,
                  initialDate: _accepted.add(const Duration(days: 7)),
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (d != null) setState(() => _due = d);
              },
            )
          else
            Row(children: [
              Expanded(
                child: DateField(
                  label: t.dueDate,
                  value: _due!,
                  icon: Icons.flag_outlined,
                  onChanged: (d) => setState(() => _due = d),
                ),
              ),
              IconButton(
                tooltip: t.noDue,
                icon: const Icon(Icons.close_rounded),
                onPressed: () => setState(() => _due = null),
              ),
            ]),
        ],
        if (s.show(OrderField.done)) ...[
          _gap,
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              title: Text(t.orderIsDone),
              subtitle: Text(_done == null ? t.inWorkCap : t.doneOn(dayLabel(_done!, withYear: true))),
              value: _done != null,
              onChanged: (v) => setState(() => _done = v ? today() : null),
            ),
          ),
          if (_done != null) ...[
            _gap,
            DateField(
              label: t.doneDateLabel,
              value: _done!,
              icon: Icons.task_alt_rounded,
              onChanged: (d) => setState(() => _done = d),
            ),
          ],
        ],
        if (s.show(OrderField.note)) ...[
          _gap,
          TextFormField(
            controller: _note,
            maxLines: 2,
            decoration: _dec(t.note, icon: Icons.notes_rounded),
          ),
        ],
      ],
    );
  }
}

// ======================= Оплата =======================

class PaymentFormPage extends StatefulWidget {
  final Payment? payment;
  final int? clientId;
  final int? orderId;

  const PaymentFormPage({super.key, this.payment, this.clientId, this.orderId});

  @override
  State<PaymentFormPage> createState() => _PaymentFormPageState();
}

class _PaymentFormPageState extends State<PaymentFormPage> {
  final _key = GlobalKey<FormState>();
  late int? _clientId = widget.payment?.clientId ?? widget.clientId;
  late int? _orderId = widget.payment?.orderId ?? widget.orderId;
  late final _amount = TextEditingController(
    text: widget.payment == null ? '' : moneyInput(widget.payment!.amountCents),
  );
  late final _note = TextEditingController(text: widget.payment?.note ?? '');
  late DateTime _date = widget.payment?.paidAt ?? today();
  bool _clientError = false;

  @override
  void initState() {
    super.initState();
    if (_clientId == null && widget.orderId != null) {
      _clientId = _store.orderById(widget.orderId!)?.clientId;
    }
  }

  Future<void> _save() async {
    final valid = _key.currentState!.validate();
    setState(() => _clientError = _clientId == null);
    if (!valid || _clientId == null) return;
    await _store.savePayment(Payment(
      id: widget.payment?.id,
      clientId: _clientId!,
      orderId: _orderId,
      amountCents: parseMoney(_amount.text)!,
      paidAt: _date,
      note: _note.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (!await confirm(context, t.deletePaymentQ)) return;
    await _store.deletePayment(widget.payment!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // Баланс без учёта редактируемой оплаты — чтобы кнопка «весь долг» работала и при правке.
    final edit = widget.payment;
    int? balance;
    if (_clientId != null) {
      balance = _store.balanceOf(_clientId!);
      if (edit != null && edit.clientId == _clientId) balance += edit.amountCents;
    }
    final clientOrders = _clientId == null ? <Order>[] : _store.ordersOf(_clientId!);
    if (_orderId != null && !clientOrders.any((o) => o.id == _orderId)) _orderId = null;
    final order = _orderId == null ? null : _store.orderById(_orderId!);
    int? orderRemain;
    if (order != null) {
      orderRemain = _store.remainingOf(order);
      if (edit != null && edit.orderId == order.id) orderRemain += edit.amountCents;
    }
    final c = context.colors;

    return _FormScaffold(
      title: edit == null ? t.paymentFromClient : t.payment,
      formKey: _key,
      onSave: _save,
      onDelete: edit == null ? null : _delete,
      children: [
        _ClientField(
          clientId: _clientId,
          errorText: _clientError ? t.chooseClient : null,
          onChanged: (id) => setState(() {
            _clientId = id;
            _clientError = false;
          }),
        ),
        if (balance != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.fromLTRB(14, 10, 8, 10),
            decoration: BoxDecoration(
              color: balance > 0 ? c.debtBg : (balance < 0 ? c.incomeBg : context.cs.surfaceContainer),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(children: [
              Icon(
                balance > 0 ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                color: balance > 0 ? c.debt : (balance < 0 ? c.income : c.muted),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  balance > 0
                      ? t.clientDebt(money(balance))
                      : (balance < 0 ? t.clientOverpaid(money(-balance)) : t.clientSettled),
                  style: context.tt.titleSmall?.copyWith(
                    color: balance > 0 ? c.debt : (balance < 0 ? c.income : c.muted),
                  ),
                ),
              ),
              if (balance > 0)
                TextButton(
                  onPressed: () => setState(() => _amount.text = moneyInput(balance!)),
                  child: Text(t.wholeDebt),
                ),
            ]),
          ),
        ],
        _gap,
        TextFormField(
          controller: _amount,
          autofocus: edit == null && _clientId != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _decimalOnly,
          style: amountStyle(26, color: c.income),
          decoration: _dec(t.howMuchGave, prefix: '\$ ', icon: Icons.south_west_rounded),
          validator: (v) {
            final x = parseMoney(v ?? '');
            if (x == null || x <= 0) return t.enterAmount;
            return null;
          },
        ),
        _gap,
        DateField(label: t.date, value: _date, onChanged: (d) => setState(() => _date = d)),
        _gap,
        if (clientOrders.isNotEmpty) ...[
          DropdownButtonFormField<int?>(
            key: ValueKey('orders-$_clientId'),
            initialValue: _orderId,
            isExpanded: true,
            borderRadius: BorderRadius.circular(16),
            decoration: _dec(t.forWhichOrder, icon: Icons.receipt_long_outlined),
            items: [
              DropdownMenuItem<int?>(value: null, child: Text(t.generalAccount)),
              for (final o in clientOrders)
                DropdownMenuItem<int?>(
                  value: o.id,
                  child: Text(
                    '${shortDay(o.acceptedAt)} · ${o.title} · ${money(o.priceCents)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _orderId = v),
          ),
          if (orderRemain != null && orderRemain > 0)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => setState(() => _amount.text = moneyInput(orderRemain!)),
                child: Text('${t.orderRemainder}: ${money(orderRemain)}'),
              ),
            ),
          _gap,
        ],
        TextFormField(
          controller: _note,
          maxLines: 2,
          decoration: _dec(t.note, icon: Icons.notes_rounded),
        ),
      ],
    );
  }
}

// ======================= Расход =======================

class ExpenseFormPage extends StatefulWidget {
  final Expense? expense;

  const ExpenseFormPage({super.key, this.expense});

  @override
  State<ExpenseFormPage> createState() => _ExpenseFormPageState();
}

class _ExpenseFormPageState extends State<ExpenseFormPage> {
  final _key = GlobalKey<FormState>();
  late final _category = TextEditingController(text: widget.expense?.category ?? '');
  late final _amount = TextEditingController(
    text: widget.expense == null ? '' : moneyInput(widget.expense!.amountCents),
  );
  late final _note = TextEditingController(text: widget.expense?.note ?? '');
  late DateTime _date = widget.expense?.spentAt ?? today();

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    await _store.saveExpense(Expense(
      id: widget.expense?.id,
      category: _category.text.trim(),
      amountCents: parseMoney(_amount.text)!,
      spentAt: _date,
      note: _note.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (!await confirm(context, t.deleteExpenseQ)) return;
    await _store.deleteExpense(widget.expense!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final c = context.colors;
    return _FormScaffold(
      title: widget.expense == null ? t.newExpense : t.expenseOne,
      formKey: _key,
      onSave: _save,
      onDelete: widget.expense == null ? null : _delete,
      children: [
        TextFormField(
          controller: _amount,
          autofocus: widget.expense == null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _decimalOnly,
          style: amountStyle(26, color: c.expense),
          decoration: _dec(t.amount, prefix: '\$ ', icon: Icons.north_east_rounded),
          validator: (v) {
            final x = parseMoney(v ?? '');
            if (x == null || x <= 0) return t.enterAmount;
            return null;
          },
        ),
        _gap,
        SectionCard(
          title: t.spentOn,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final cat in _store.categories)
                  ChoiceChip(
                    label: Text(cat),
                    selected: _category.text.trim() == cat,
                    onSelected: (_) => setState(() => _category.text = cat),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _category,
              textCapitalization: TextCapitalization.sentences,
              decoration: _dec(t.ownCategory, icon: Icons.edit_outlined),
              validator: (v) => (v == null || v.trim().isEmpty) ? t.enterCategory : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        _gap,
        DateField(label: t.date, value: _date, onChanged: (d) => setState(() => _date = d)),
        _gap,
        TextFormField(
          controller: _note,
          maxLines: 2,
          decoration: _dec(t.comment, icon: Icons.notes_rounded),
        ),
      ],
    );
  }
}
