import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'format.dart';
import 'models.dart';
import 'settings.dart';
import 'store.dart';
import 'theme.dart';
import 'widgets/common.dart';

final _store = AppStore.I;
final _settings = AppSettings.I;

const _gap = SizedBox(height: 12);

final _decimalOnly = [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))];
final _signedDecimal = [FilteringTextInputFormatter.allow(RegExp(r'[-−0-9.,\s]'))];

InputDecoration _dec(String label, {String? hint, String? suffix, String? prefix, IconData? icon, String? helper}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      suffixText: suffix,
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
              tooltip: 'Удалить',
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
              child: Row(children: [
                Expanded(child: Text('Выберите клиента', style: context.tt.titleLarge)),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: TextField(
                autofocus: _store.clients.length > 8,
                decoration: _dec('Поиск', icon: Icons.search_rounded),
                onChanged: (v) => setState(() => _q = v),
              ),
            ),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16),
              leading: IconBadge(Icons.person_add_alt_1_rounded,
                  color: context.cs.primary, background: context.cs.primaryContainer.withValues(alpha: 0.6)),
              title: Text(_q.trim().isEmpty ? 'Новый клиент' : 'Новый клиент «${_q.trim()}»'),
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
                    leading: Avatar(c.name, size: 40),
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
    final name = clientId == null ? null : _store.clientName(clientId!);
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final id = await pickClient(context);
        if (id != null) onChanged(id);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: 'Клиент',
          errorText: errorText,
          prefixIcon: name == null
              ? const Icon(Icons.person_outline_rounded)
              : Padding(padding: const EdgeInsets.all(10), child: Avatar(name, size: 28)),
          suffixIcon: const Icon(Icons.expand_more_rounded),
        ),
        child: Text(
          name ?? 'Выберите клиента',
          style: name == null ? TextStyle(color: Theme.of(context).hintColor) : context.tt.titleSmall,
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
  late final _rate = TextEditingController(
    text: widget.client?.rateKgCents == null ? '' : moneyInput(widget.client!.rateKgCents!),
  );

  bool get _showRate => _settings.show(OrderField.pricing) && _settings.show(OrderField.weight);

  Future<void> _save() async {
    if (!_key.currentState!.validate()) return;
    final id = await _store.saveClient(Client(
      id: widget.client?.id,
      name: _name.text.trim(),
      phone: _phone.text.trim(),
      note: _note.text.trim(),
      rateKgCents: parseMoney(_rate.text),
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
    final def = _settings.defaultRateKgCents;
    return _FormScaffold(
      title: widget.client == null ? 'Новый клиент' : 'Клиент',
      formKey: _key,
      onSave: _save,
      onDelete: widget.client == null ? null : _delete,
      children: [
        TextFormField(
          controller: _name,
          autofocus: widget.client == null && widget.initialName.isEmpty,
          textCapitalization: TextCapitalization.words,
          decoration: _dec('Имя', icon: Icons.person_outline_rounded),
          validator: (v) => (v == null || v.trim().isEmpty) ? 'Введите имя' : null,
        ),
        _gap,
        TextFormField(
          controller: _phone,
          keyboardType: TextInputType.phone,
          decoration: _dec('Телефон', icon: Icons.phone_outlined),
        ),
        if (_showRate) ...[
          _gap,
          TextFormField(
            controller: _rate,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: _decimalOnly,
            decoration: _dec(
              'Своя цена за кг',
              prefix: '\$ ',
              suffix: '/ кг',
              icon: Icons.scale_outlined,
              helper: def == null
                  ? 'Если пусто — цена из настроек'
                  : 'Если пусто — обычная цена ${money(def)}/кг',
            ),
          ),
        ],
        _gap,
        TextFormField(
          controller: _note,
          maxLines: 3,
          decoration: _dec('Заметка', icon: Icons.notes_rounded),
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
  late final _code = TextEditingController(text: widget.order?.code ?? '');
  late final _weight = TextEditingController(text: numInput(widget.order?.weightKg));
  late final _qty = TextEditingController(text: widget.order?.quantity?.toString() ?? '');
  late final _amount = TextEditingController(
    text: widget.order == null ? '' : moneyInput(widget.order!.amountCents),
  );
  late final _rate = TextEditingController();
  late final _extra = TextEditingController(
    text: (widget.order?.extraCents ?? 0) == 0 ? '' : moneyInput(widget.order!.extraCents),
  );
  late final _note = TextEditingController(text: widget.order?.note ?? '');
  late DateTime _accepted = widget.order?.acceptedAt ?? today();
  late DateTime? _done = widget.order?.doneAt;
  late Pricing _pricing;
  bool _rateTouched = false;
  bool _clientError = false;

  @override
  void initState() {
    super.initState();
    final o = widget.order;
    final available = _settings.availablePricing;
    if (o != null) {
      _pricing = available.contains(o.pricing) ? o.pricing : Pricing.fixed;
      if (o.rateCents != null && _pricing != Pricing.fixed) {
        _rate.text = moneyInput(o.rateCents!);
        _rateTouched = true;
      }
    } else {
      _pricing = _settings.effectiveDefaultPricing;
      _fillDefaultRate();
    }
    for (final c in [_weight, _qty, _rate, _extra]) {
      c.addListener(_onChanged);
    }
  }

  void _onChanged() => setState(() {});

  @override
  void dispose() {
    for (final c in [_desc, _code, _weight, _qty, _amount, _rate, _extra, _note]) {
      c.dispose();
    }
    super.dispose();
  }

  int? _defaultRate(Pricing p) {
    switch (p) {
      case Pricing.fixed:
        return null;
      case Pricing.perKg:
        final client = _clientId == null ? null : _store.clientById(_clientId!);
        return client?.rateKgCents ?? _settings.defaultRateKgCents;
      case Pricing.perUnit:
        return _settings.defaultRateUnitCents;
    }
  }

  void _fillDefaultRate() {
    if (_rateTouched) return;
    final r = _defaultRate(_pricing);
    _rate.text = r == null ? '' : moneyInput(r);
  }

  int? get _computed => computeOrderAmount(
        pricing: _pricing,
        rateCents: parseMoney(_rate.text),
        weightKg: parseNum(_weight.text),
        quantity: int.tryParse(_qty.text.trim()),
        extraCents: _settings.show(OrderField.extra) ? (parseMoney(_extra.text.replaceAll('−', '-')) ?? 0) : 0,
      );

  Future<void> _save() async {
    final valid = _key.currentState!.validate();
    setState(() => _clientError = _clientId == null);
    if (!valid || _clientId == null) return;
    final tariff = _pricing != Pricing.fixed;
    final amount = tariff ? _computed : parseMoney(_amount.text);
    if (amount == null) return;
    await _store.saveOrder(Order(
      id: widget.order?.id,
      clientId: _clientId!,
      description: _desc.text.trim(),
      code: _code.text.trim(),
      weightKg: parseNum(_weight.text),
      quantity: int.tryParse(_qty.text.trim()),
      pricing: _pricing,
      rateCents: tariff ? parseMoney(_rate.text) : null,
      extraCents: tariff && _settings.show(OrderField.extra) ? (parseMoney(_extra.text.replaceAll('−', '-')) ?? 0) : 0,
      amountCents: amount,
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
    final s = _settings;
    final available = s.availablePricing;
    final tariff = _pricing != Pricing.fixed;
    final showWeight = s.show(OrderField.weight);
    final showQty = s.show(OrderField.quantity);

    final weightField = TextFormField(
      controller: _weight,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: _decimalOnly,
      decoration: _dec('Вес', suffix: 'кг', icon: Icons.scale_outlined),
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isNotEmpty && parseNum(t) == null) return 'Число';
        if (_pricing == Pricing.perKg && (parseNum(t) ?? 0) <= 0) return 'Укажите вес';
        return null;
      },
    );
    final qtyField = TextFormField(
      controller: _qty,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _dec('Кол-во', suffix: 'шт', icon: Icons.tag_rounded),
      validator: (v) {
        if (_pricing == Pricing.perUnit && (int.tryParse(v?.trim() ?? '') ?? 0) <= 0) return 'Укажите кол-во';
        return null;
      },
    );

    return _FormScaffold(
      title: widget.order == null ? 'Новый заказ' : 'Заказ',
      formKey: _key,
      onSave: _save,
      onDelete: widget.order == null ? null : _delete,
      children: [
        _ClientField(
          clientId: _clientId,
          errorText: _clientError ? 'Выберите клиента' : null,
          onChanged: (id) {
            _clientId = id;
            _clientError = false;
            _fillDefaultRate();
            setState(() {});
          },
        ),
        _gap,
        if (s.show(OrderField.description)) ...[
          TextFormField(
            controller: _desc,
            textCapitalization: TextCapitalization.sentences,
            decoration: _dec('Что за груз / товар', icon: Icons.inventory_2_outlined),
          ),
          _gap,
        ],
        if (s.show(OrderField.code)) ...[
          TextFormField(
            controller: _code,
            decoration: _dec('Трек-номер / код', icon: Icons.qr_code_2_rounded),
          ),
          _gap,
        ],
        if (showWeight && showQty)
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(child: weightField),
            const SizedBox(width: 10),
            Expanded(child: qtyField),
          ])
        else if (showWeight)
          weightField
        else if (showQty)
          qtyField,
        if (showWeight || showQty) _gap,

        // ----- Сумма -----
        SectionCard(
          title: 'Сумма заказа',
          children: [
            if (available.length > 1) ...[
              SegmentedButton<Pricing>(
                segments: [
                  for (final p in available)
                    ButtonSegment(
                      value: p,
                      label: Text(p.label),
                      icon: Icon(switch (p) {
                        Pricing.fixed => Icons.attach_money_rounded,
                        Pricing.perKg => Icons.scale_outlined,
                        Pricing.perUnit => Icons.tag_rounded,
                      }),
                    ),
                ],
                selected: {_pricing},
                showSelectedIcon: false,
                onSelectionChanged: (sel) {
                  final before = _computed;
                  _pricing = sel.first;
                  _rateTouched = false;
                  _fillDefaultRate();
                  if (_pricing == Pricing.fixed && _amount.text.isEmpty && before != null) {
                    _amount.text = moneyInput(before);
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 14),
            ],
            if (!tariff)
              TextFormField(
                controller: _amount,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimalOnly,
                style: amountStyle(22),
                decoration: _dec('Сумма', prefix: '\$ ', icon: Icons.payments_outlined),
                validator: (v) {
                  final c = parseMoney(v ?? '');
                  if (c == null) return 'Введите сумму';
                  if (c < 0) return 'Сумма не может быть отрицательной';
                  return null;
                },
              )
            else ...[
              TextFormField(
                controller: _rate,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: _decimalOnly,
                onChanged: (_) => _rateTouched = true,
                decoration: _dec(
                  _pricing == Pricing.perKg ? 'Цена за кг' : 'Цена за штуку',
                  prefix: '\$ ',
                  suffix: _pricing == Pricing.perKg ? '/ кг' : '/ шт',
                  icon: Icons.sell_outlined,
                  helper: _rateHelper(),
                ),
                validator: (v) => (parseMoney(v ?? '') ?? 0) <= 0 ? 'Укажите цену' : null,
              ),
              if (s.show(OrderField.extra)) ...[
                _gap,
                TextFormField(
                  controller: _extra,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
                  inputFormatters: _signedDecimal,
                  decoration: _dec(
                    'Доплата / скидка',
                    prefix: '\$ ',
                    icon: Icons.add_circle_outline_rounded,
                    helper: 'Упаковка, доставка по городу… Скидка — с минусом',
                  ),
                ),
              ],
              const SizedBox(height: 14),
              _TariffSummary(
                pricing: _pricing,
                weight: parseNum(_weight.text),
                qty: int.tryParse(_qty.text.trim()),
                rate: parseMoney(_rate.text),
                extra: s.show(OrderField.extra) ? (parseMoney(_extra.text.replaceAll('−', '-')) ?? 0) : 0,
                total: _computed,
              ),
            ],
          ],
        ),
        _gap,

        // ----- Даты -----
        DateField(label: 'Дата приёма', value: _accepted, onChanged: (d) => setState(() => _accepted = d)),
        if (s.show(OrderField.done)) ...[
          _gap,
          Card(
            child: SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              title: const Text('Заказ выполнен'),
              subtitle: Text(_done == null ? 'В работе' : 'Выполнен ${dayLabel(_done!, withYear: true)}'),
              value: _done != null,
              onChanged: (v) => setState(() => _done = v ? today() : null),
            ),
          ),
          if (_done != null) ...[
            _gap,
            DateField(
              label: 'Дата выполнения',
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
            decoration: _dec('Заметка', icon: Icons.notes_rounded),
          ),
        ],
      ],
    );
  }

  String? _rateHelper() {
    if (_pricing != Pricing.perKg) return null;
    final client = _clientId == null ? null : _store.clientById(_clientId!);
    if (client?.rateKgCents != null) return 'Цена клиента: ${money(client!.rateKgCents!)}/кг';
    if (_settings.defaultRateKgCents != null) return 'Обычная цена: ${money(_settings.defaultRateKgCents!)}/кг';
    return 'Обычную цену можно задать в настройках';
  }
}

class _TariffSummary extends StatelessWidget {
  final Pricing pricing;
  final double? weight;
  final int? qty;
  final int? rate;
  final int extra;
  final int? total;

  const _TariffSummary({
    required this.pricing,
    required this.weight,
    required this.qty,
    required this.rate,
    required this.extra,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final base = pricing == Pricing.perKg
        ? (weight == null ? '? кг' : kg(weight!))
        : (qty == null ? '? шт' : '$qty шт');
    final formula = '$base × ${rate == null ? '\$?' : money(rate!)}'
        '${extra == 0 ? '' : (extra > 0 ? ' + ${money(extra)}' : ' − ${money(-extra)}')}';
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.cs.primaryContainer.withValues(alpha: context.isDark ? 0.35 : 0.55),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Итого к оплате', style: context.tt.labelMedium?.copyWith(color: context.cs.onPrimaryContainer)),
            const SizedBox(height: 2),
            Text(formula, style: context.tt.bodySmall?.copyWith(color: context.cs.onPrimaryContainer)),
          ]),
        ),
        Text(
          total == null ? '—' : money(total!),
          style: amountStyle(24, color: context.cs.onPrimaryContainer),
        ),
      ]),
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
    final c = context.colors;

    return _FormScaffold(
      title: widget.payment == null ? 'Оплата от клиента' : 'Оплата',
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
                      ? 'Долг клиента: ${money(balance)}'
                      : (balance < 0 ? 'Аванс клиента: ${money(-balance)}' : 'Клиент полностью рассчитан'),
                  style: context.tt.titleSmall?.copyWith(
                    color: balance > 0 ? c.debt : (balance < 0 ? c.income : c.muted),
                  ),
                ),
              ),
              if (balance > 0)
                TextButton(
                  onPressed: () => setState(() => _amount.text = moneyInput(balance!)),
                  child: const Text('Весь долг'),
                ),
            ]),
          ),
        ],
        _gap,
        TextFormField(
          controller: _amount,
          autofocus: widget.payment == null && _clientId != null,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: _decimalOnly,
          style: amountStyle(26, color: c.income),
          decoration: _dec('Сколько дал', prefix: '\$ ', icon: Icons.south_west_rounded),
          validator: (v) {
            final x = parseMoney(v ?? '');
            if (x == null || x <= 0) return 'Введите сумму';
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
            borderRadius: BorderRadius.circular(16),
            decoration: _dec('За какой заказ (необязательно)', icon: Icons.receipt_long_outlined),
            items: [
              const DropdownMenuItem<int?>(value: null, child: Text('Общий счёт клиента')),
              for (final o in clientOrders)
                DropdownMenuItem<int?>(
                  value: o.id,
                  child: Text(
                    '${shortDay(o.acceptedAt)} · ${o.title} · ${money(o.amountCents)}',
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
          decoration: _dec('Заметка', icon: Icons.notes_rounded),
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
    final c = context.colors;
    return _FormScaffold(
      title: widget.expense == null ? 'Новый расход' : 'Расход',
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
          decoration: _dec('Сумма', prefix: '\$ ', icon: Icons.north_east_rounded),
          validator: (v) {
            final x = parseMoney(v ?? '');
            if (x == null || x <= 0) return 'Введите сумму';
            return null;
          },
        ),
        _gap,
        SectionCard(
          title: 'На что',
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
              decoration: _dec('Или своя категория', icon: Icons.edit_outlined),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Укажите, на что потратили' : null,
              onChanged: (_) => setState(() {}),
            ),
          ],
        ),
        _gap,
        DateField(label: 'Дата', value: _date, onChanged: (d) => setState(() => _date = d)),
        _gap,
        TextFormField(
          controller: _note,
          maxLines: 2,
          decoration: _dec('Комментарий', icon: Icons.notes_rounded),
        ),
      ],
    );
  }
}
