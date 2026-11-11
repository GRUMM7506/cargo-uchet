import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'models.dart';
import 'store.dart';
import 'widgets/common.dart';

final _store = AppStore.I;

const _gap = SizedBox(height: 14);

final _moneyInputFormatters = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))];

InputDecoration _dec(String label, {String? hint, String? suffix, IconData? icon}) => InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
      prefixIcon: icon == null ? null : Icon(icon),
      border: const OutlineInputBorder(),
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
            IconButton(icon: const Icon(Icons.delete_outline), tooltip: 'Удалить', onPressed: onDelete),
        ],
      ),
      body: Form(
        key: formKey,
        child: ListView(padding: const EdgeInsets.all(16), children: children),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: FilledButton.icon(
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
            icon: const Icon(Icons.check),
            label: const Text('Сохранить', style: TextStyle(fontSize: 16)),
            onPressed: onSave,
          ),
        ),
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
    final list = _store.clients.where((c) => c.name.toLowerCase().contains(_q.toLowerCase())).toList();
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: TextField(
                autofocus: _store.clients.length > 8,
                decoration: _dec('Поиск клиента', icon: Icons.search),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            ListTile(
              leading: const CircleAvatar(child: Icon(Icons.person_add)),
              title: const Text('Новый клиент'),
              onTap: () async {
                final id = await Navigator.push<int>(
                  context,
                  MaterialPageRoute(builder: (_) => ClientFormPage(initialName: _q.trim())),
                );
                if (id != null && context.mounted) Navigator.pop(context, id);
              },
            ),
            const Divider(height: 1),
            Expanded(
              child: ListView.builder(
                itemCount: list.length,
                itemBuilder: (ctx, i) {
                  final c = list[i];
                  return ListTile(
                    title: Text(c.name),
                    subtitle: BalanceText(_store.balanceOf(c.id!)),
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
    return InkWell(
      onTap: () async {
        final id = await pickClient(context);
        if (id != null) onChanged(id);
      },
      child: InputDecorator(
        decoration: _dec('Клиент', icon: Icons.person).copyWith(
          errorText: errorText,
          suffixIcon: const Icon(Icons.arrow_drop_down),
        ),
        child: Text(
          clientId == null ? 'Выберите клиента' : _store.clientName(clientId!),
          style: clientId == null ? TextStyle(color: Theme.of(context).hintColor) : null,
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

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final id = await _store.saveClient(Client(
      id: widget.client?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      note: _note.text.trim(),
    ));
    if (mounted) Navigator.pop(context, id);
  }

  Future<void> _delete() async {
    final c = widget.client!;
    final n = _store.ordersOf(c.id!).length + _store.paymentsOf(c.id!).length;
    final ok = await confirm(
      context,
      n == 0
          ? 'Удалить клиента «${c.name}»?'
          : 'Удалить клиента «${c.name}» вместе со всеми его заказами и оплатами ($n записей)?',
    );
    if (!ok) return;
    await _store.deleteClient(c.id!);
    if (mounted) Navigator.pop(context, -1);
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.client == null ? 'Новый клиент' : 'Клиент',
      formKey: _key,
      onSave: _save,
      onDelete: widget.client == null ? null : _delete,
      children: [
        TextFormField(
          controller: _name,
          autofocus: widget.client == null,
          textCapitalization: TextCapitalization.words,
          decoration: _dec('Имя', icon: Icons.person),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
        ),
        _gap,
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _dec('Телефон', icon: Icons.phone),
        ),
        _gap,
        TextFormField(
          controller: _note,
          maxLines: 3,
          decoration: _dec('Заметка', icon: Icons.notes),
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
  late final _desc = TextEditingController(text: widget.order?.description ?? '');
  late final _weight = TextEditingController(text: numInput(widget.order?.weightKg));
  late final _qty = TextEditingController(text: widget.order?.quantity?.toString() ?? '');
  late final _amount = TextEditingController(
    text: widget.order == null ? '' : moneyInput(widget.order!.amountCents),
  );
  late final _note = TextEditingController(text: widget.order?.note ?? '');
  late DateTime _accepted = widget.order?.acceptedAt ?? today();
  late DateTime? _done = widget.order?.doneAt;
  bool _clientError = false;

  Future<void> _save() async {
    final valid = _key.currentState!.validate();
    setState(() => _clientError = _clientId == null);
    if (!valid || _clientId == null) return;
    await _store.saveOrder(Order(
      id: widget.order?.id,
      clientId: _clientId!,
      description: _desc.text.trim(),
      weightKg: parseNum(_weight.text),
      quantity: int.tryParse(_qty.text.trim()),
      amountCents: parseMoney(_amount.text)!,
      acceptedAt: _accepted,
      doneAt: _done,
      note: _note.text.trim(),
    ));
    if (mounted) Navigator.pop(context, true);
  }

  Future<void> _delete() async {
    if (!await confirm(context, 'Удалить этот заказ?')) return;
    await _store.deleteOrder(widget.order!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.order == null ? 'Новый заказ' : 'Заказ',
      formKey: _key,
      onSave: _save,
      onDelete: widget.order == null ? null : _delete,
      children: [
        _ClientField(
          clientId: _clientId,
          errorText: _clientError ? 'Выберите клиента' : null,
          onChanged: (id) => setState(() {
            _clientId = id;
            _clientError = false;
          }),
        ),
        _gap,
        TextFormField(
          controller: _desc,
          textCapitalization: TextCapitalization.sentences,
          decoration: _dec('Что за груз / товар', icon: Icons.inventory_2_outlined),
        ),
        _gap,
        Row(children: [
          Expanded(
            child: TextFormField(
              controller: _weight,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: _moneyInputFormatters,
              decoration: _dec('Вес', suffix: 'кг'),
              validator: (v) => (v != null && v.trim().isNotEmpty && parseNum(v) == null) ? 'Число' : null,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextFormField(
              controller: _qty,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: _dec('Кол-во', suffix: 'шт'),
            ),
          ),
        ]),
        _gap,
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _moneyInputFormatters,
          decoration: _dec('Сумма заказа', suffix: '\$', icon: Icons.attach_money),
          validator: (v) {
            final c = parseMoney(v ?? '');
            if (c == null) return 'Введите сумму';
            if (c < 0) return 'Сумма не может быть отрицательной';
            return null;
          },
        ),
        _gap,
        DateField(label: 'Дата приёма', value: _accepted, onChanged: (d) => setState(() => _accepted = d)),
        _gap,
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          title: const Text('Выполнен'),
          value: _done != null,
          onChanged: (v) => setState(() => _done = v ? today() : null),
        ),
        if (_done != null) ...[
          DateField(label: 'Дата выполнения', value: _done!, onChanged: (d) => setState(() => _done = d)),
          _gap,
        ],
        TextFormField(
          controller: _note,
          maxLines: 2,
          decoration: _dec('Заметка', icon: Icons.notes),
        ),
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
    if (!await confirm(context, 'Удалить эту оплату?')) return;
    await _store.deletePayment(widget.payment!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    // Баланс без учёта редактируемой оплаты — чтобы кнопка «весь долг» работала и при правке.
    int? balance;
    if (_clientId != null) {
      balance = _store.balanceOf(_clientId!);
      if (widget.payment != null && widget.payment!.clientId == _clientId) {
        balance += widget.payment!.amountCents;
      }
    }
    final clientOrders = _clientId == null ? <Order>[] : _store.ordersOf(_clientId!);
    if (_orderId != null && !clientOrders.any((o) => o.id == _orderId)) _orderId = null;

    return _FormScaffold(
      title: widget.payment == null ? 'Новая оплата' : 'Оплата',
      formKey: _key,
      onSave: _save,
      onDelete: widget.payment == null ? null : _delete,
      children: [
        _ClientField(
          clientId: _clientId,
          errorText: _clientError ? 'Выберите клиента' : null,
          onChanged: (id) => setState(() {
            _clientId = id;
            _clientError = false;
          }),
        ),
        if (balance != null)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 4),
            child: Row(children: [
              BalanceText(balance),
              const Spacer(),
              if (balance > 0)
                TextButton(
                  onPressed: () => setState(() => _amount.text = moneyInput(balance!)),
                  child: const Text('Весь долг'),
                ),
            ]),
          ),
        _gap,
        TextFormField(
          controller: _amount,
          autofocus: widget.payment == null && _clientId != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _moneyInputFormatters,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          decoration: _dec('Сколько дал', suffix: '\$', icon: Icons.payments_outlined),
          validator: (v) {
            final c = parseMoney(v ?? '');
            if (c == null || c <= 0) return 'Введите сумму';
            return null;
          },
        ),
        _gap,
        DateField(label: 'Дата', value: _date, onChanged: (d) => setState(() => _date = d)),
        _gap,
        if (clientOrders.isNotEmpty) ...[
          DropdownButtonFormField<int?>(
            key: ValueKey('orders-$_clientId'),
            initialValue: _orderId,
            isExpanded: true,
            decoration: _dec('За какой заказ (необязательно)', icon: Icons.receipt_long_outlined),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('— общий счёт клиента —')),
              for (final o in clientOrders)
                DropdownMenuItem<int?>(
                  value: o.id,
                  child: Text(
                    '${dateStr(o.acceptedAt)} · ${o.description.isEmpty ? 'Заказ' : o.description} · ${money(o.amountCents)}',
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
            ],
            onChanged: (v) => setState(() => _orderId = v),
          ),
          _gap,
        ],
        TextFormField(
          controller: _note,
          maxLines: 2,
          decoration: _dec('Заметка', icon: Icons.notes),
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
    if (!await confirm(context, 'Удалить этот расход?')) return;
    await _store.deleteExpense(widget.expense!.id!);
    if (mounted) Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return _FormScaffold(
      title: widget.expense == null ? 'Новый расход' : 'Расход',
      formKey: _key,
      onSave: _save,
      onDelete: widget.expense == null ? null : _delete,
      children: [
        TextFormField(
          controller: _category,
          textCapitalization: TextCapitalization.sentences,
          decoration: _dec('На что', icon: Icons.category_outlined),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите, на что потратили' : null,
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            for (final c in _store.categories)
              ChoiceChip(
                label: Text(c),
                selected: _category.text.trim() == c,
                onSelected: (_) => setState(() => _category.text = c),
              ),
          ],
        ),
        _gap,
        TextFormField(
          controller: _amount,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _moneyInputFormatters,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w600),
          decoration: _dec('Сумма', suffix: '\$', icon: Icons.attach_money),
          validator: (v) {
            final c = parseMoney(v ?? '');
            if (c == null || c <= 0) return 'Введите сумму';
            return null;
          },
        ),
        _gap,
        DateField(label: 'Дата', value: _date, onChanged: (d) => setState(() => _date = d)),
        _gap,
        TextFormField(
          controller: _note,
          maxLines: 2,
          decoration: _dec('Комментарий', icon: Icons.notes),
        ),
      ],
    );
  }
}
