import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../format.dart';
import '../models.dart';
import '../services/export_service.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

class SettingsScreen extends StatefulWidget {
  /// Сразу прокрутить к настройкам заказов.
  final bool focusOrders;

  const SettingsScreen({super.key, this.focusOrders = false});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  final _ordersKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    if (widget.focusOrders) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _ordersKey.currentContext;
        if (ctx != null) Scrollable.ensureVisible(ctx, duration: const Duration(milliseconds: 350));
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.I;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Настройки')),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            // ---------------- Оформление ----------------
            SectionCard(title: 'Оформление', children: [
              Text('Тема', style: context.tt.titleSmall),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: const [
                  ButtonSegment(value: ThemeMode.system, icon: Icon(Icons.brightness_auto_outlined), label: Text('Авто')),
                  ButtonSegment(value: ThemeMode.light, icon: Icon(Icons.light_mode_outlined), label: Text('Светлая')),
                  ButtonSegment(value: ThemeMode.dark, icon: Icon(Icons.dark_mode_outlined), label: Text('Тёмная')),
                ],
                selected: {s.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (v) => s.setThemeMode(v.first),
              ),
              const SizedBox(height: 18),
              Text('Цвет', style: context.tt.titleSmall),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (var i = 0; i < AppSettings.accents.length; i++)
                  _AccentDot(
                    option: AppSettings.accents[i],
                    selected: s.accentIndex == i,
                    onTap: () => s.setAccent(i),
                  ),
              ]),
            ]),
            const SizedBox(height: 12),

            // ---------------- Расчёт ----------------
            SectionCard(key: _ordersKey, title: 'Расчёт суммы заказа', children: [
              Text(
                'Как по умолчанию считать сумму нового заказа. В самом заказе способ можно поменять.',
                style: context.tt.bodySmall?.copyWith(color: context.colors.muted),
              ),
              const SizedBox(height: 12),
              SegmentedButton<Pricing>(
                segments: [
                  for (final p in s.availablePricing) ButtonSegment(value: p, label: Text(p.label)),
                ],
                selected: {s.effectiveDefaultPricing},
                showSelectedIcon: false,
                onSelectionChanged: (v) => s.setDefaultPricing(v.first),
              ),
              if (s.availablePricing.contains(Pricing.perKg))
                _RateTile(
                  icon: Icons.scale_outlined,
                  title: 'Обычная цена за кг',
                  subtitle: 'Для клиента можно задать свою цену в его карточке',
                  suffix: '/ кг',
                  value: s.defaultRateKgCents,
                  onChanged: s.setDefaultRateKg,
                ),
              if (s.availablePricing.contains(Pricing.perUnit))
                _RateTile(
                  icon: Icons.tag_rounded,
                  title: 'Обычная цена за штуку',
                  suffix: '/ шт',
                  value: s.defaultRateUnitCents,
                  onChanged: s.setDefaultRateUnit,
                ),
            ]),
            const SizedBox(height: 12),

            // ---------------- Поля заказа ----------------
            SectionCard(
              title: 'Поля заказа',
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              children: [
                Text(
                  'Ненужные поля можно скрыть — они пропадут из формы и списка заказов. '
                  'Уже введённые данные не удаляются.',
                  style: context.tt.bodySmall?.copyWith(color: context.colors.muted),
                ),
                const SizedBox(height: 12),
                Text('Так выглядит заказ в списке:', style: context.tt.labelLarge),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: context.cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: OrderTile(_sampleOrder(s), previewName: 'Али Валиев'),
                ),
                const SizedBox(height: 8),
                for (final f in OrderField.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(f.label),
                    subtitle: _fieldHint(f) == null ? null : Text(_fieldHint(f)!),
                    value: s.show(f),
                    onChanged: (v) => s.setFieldVisible(f, v),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ---------------- Данные ----------------
            SectionCard(
              title: 'Данные',
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
              children: [
                _ActionTile(
                  icon: Icons.cloud_upload_outlined,
                  title: 'Резервная копия',
                  subtitle: 'Отправьте файл себе в Telegram — так данные не потеряются',
                  onTap: () => _run(context, ExportService.shareBackup),
                ),
                _ActionTile(
                  icon: Icons.settings_backup_restore_rounded,
                  title: 'Восстановить из копии',
                  subtitle: 'Заменит все текущие данные данными из файла',
                  onTap: () => _restore(context),
                ),
                _ActionTile(
                  icon: Icons.table_view_outlined,
                  title: 'Excel за всё время',
                  subtitle: 'Все клиенты, заказы, оплаты и расходы',
                  onTap: () => _run(context, () => ExportService.excel()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('Учёт · версия 1.1', style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
            ),
          ],
        ),
      ),
    );
  }

  String? _fieldHint(OrderField f) => switch (f) {
        OrderField.pricing => 'Расчёт суммы по весу или количеству',
        OrderField.extra => 'Добавить к сумме по тарифу упаковку, доставку или скидку',
        OrderField.done => 'Отметка «выполнен» и фильтр «в работе»',
        OrderField.code => 'Номер отправления или внутренний код',
        _ => null,
      };

  Order _sampleOrder(AppSettings s) {
    final perKg = s.availablePricing.contains(Pricing.perKg);
    final rate = s.defaultRateKgCents ?? 350;
    return Order(
      clientId: -1,
      description: 'Одежда, 3 мешка',
      code: 'YT7845120',
      weightKg: 42.5,
      quantity: 3,
      pricing: perKg ? Pricing.perKg : Pricing.fixed,
      rateCents: perKg ? rate : null,
      amountCents: perKg ? (42.5 * rate).round() : 15000,
      acceptedAt: today(),
    );
  }

  Future<void> _run(BuildContext context, Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      if (context.mounted) toast(context, 'Ошибка: $e');
    }
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await confirm(
      context,
      'Восстановить данные из резервной копии?\n\nВСЕ текущие данные будут заменены данными из файла.',
      ok: 'Выбрать файл',
    );
    if (!ok) return;
    try {
      final path = await ExportService.pickBackup();
      if (path == null) return;
      final done = await ExportService.restore(path);
      if (context.mounted) toast(context, done ? 'Данные восстановлены' : 'Этот файл не является копией учёта');
    } catch (e) {
      if (context.mounted) toast(context, 'Ошибка: $e');
    }
  }
}

class _AccentDot extends StatelessWidget {
  final AccentOption option;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({required this.option, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: option.name,
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          width: 46,
          height: 46,
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: selected ? option.color : Colors.transparent, width: 2.5),
          ),
          child: Container(
            decoration: BoxDecoration(color: option.color, shape: BoxShape.circle),
            child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
          ),
        ),
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _ActionTile({required this.icon, required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconBadge(icon,
          size: 40, color: context.cs.primary, background: context.cs.primaryContainer.withValues(alpha: 0.6)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right_rounded),
      onTap: onTap,
    );
  }
}

class _RateTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String suffix;
  final int? value;
  final Future<void> Function(int?) onChanged;

  const _RateTile({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.suffix,
    required this.value,
    required this.onChanged,
  });

  Future<void> _edit(BuildContext context) async {
    final ctrl = TextEditingController(text: value == null ? '' : moneyInput(value!));
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(prefixText: '\$ ', suffixText: suffix, hintText: 'Не задана'),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Отмена')),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Сохранить'),
          ),
        ],
      ),
    );
    if (result == null) return;
    await onChanged(parseMoney(result));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 4),
        leading: Icon(icon, color: context.cs.primary),
        title: Text(title),
        subtitle: subtitle == null ? null : Text(subtitle!),
        trailing: Text(
          value == null ? 'не задана' : '${money(value!)} $suffix',
          style: value == null
              ? context.tt.bodyMedium?.copyWith(color: context.colors.muted)
              : amountStyle(15, color: context.cs.primary),
        ),
        onTap: () => _edit(context),
      ),
    );
  }
}
