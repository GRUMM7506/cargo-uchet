import 'package:flutter/material.dart';

import '../format.dart';
import '../forms.dart';
import '../models.dart';
import '../settings.dart';
import '../store.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';
import 'month_report_screen.dart';
import 'settings_screen.dart';

class HomeScreen extends StatefulWidget {
  final VoidCallback onOpenClients;

  const HomeScreen({super.key, required this.onOpenClients});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  YearMonth _month = YearMonth.now();

  void _open(Widget page) => Navigator.push(context, MaterialPageRoute(builder: (_) => page));

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    return ListenableBuilder(
      listenable: Listenable.merge([store, AppSettings.I]),
      builder: (context, _) {
        final s = store.summary(_month);
        final ops = <(DateTime, Widget)>[
          for (final p in store.payments)
            if (_month.contains(p.paidAt)) (p.paidAt, PaymentTile(p)),
          for (final e in store.expenses)
            if (_month.contains(e.spentAt)) (e.spentAt, ExpenseTile(e)),
        ];

        return Scaffold(
          appBar: AppBar(
            title: const Text('Учёт'),
            actions: [
              IconButton(
                tooltip: 'Отчёт за месяц',
                icon: const Icon(Icons.insert_chart_outlined_rounded),
                onPressed: () => _open(MonthReportScreen(month: _month)),
              ),
              IconButton(
                tooltip: 'Настройки',
                icon: const Icon(Icons.tune_rounded),
                onPressed: () => _open(const SettingsScreen()),
              ),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.only(bottom: 32),
            children: [
              Center(child: MonthSwitcher(month: _month, onChanged: (m) => setState(() => _month = m))),
              const SizedBox(height: 14),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _HeroCard(summary: s),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DebtCard(onTap: widget.onOpenClients),
              ),
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _QuickAction(
                    icon: Icons.south_west_rounded,
                    label: 'Оплата',
                    color: context.colors.income,
                    background: context.colors.incomeBg,
                    onTap: () => _open(const PaymentFormPage()),
                  ),
                  _QuickAction(
                    icon: Icons.north_east_rounded,
                    label: 'Расход',
                    color: context.colors.expense,
                    background: context.colors.expenseBg,
                    onTap: () => _open(const ExpenseFormPage()),
                  ),
                  _QuickAction(
                    icon: Icons.local_shipping_outlined,
                    label: 'Заказ',
                    color: context.cs.primary,
                    background: context.cs.primaryContainer.withValues(alpha: 0.6),
                    onTap: () => _open(const OrderFormPage()),
                  ),
                  _QuickAction(
                    icon: Icons.person_add_alt_1_outlined,
                    label: 'Клиент',
                    color: context.cs.tertiary,
                    background: context.cs.tertiaryContainer.withValues(alpha: 0.6),
                    onTap: () => _open(const ClientFormPage()),
                  ),
                ]),
              ),
              if (s.ordersCount > 0) ...[
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: _OrdersStrip(summary: s),
                ),
              ],
              SectionHeader('Движение денег', padding: const EdgeInsets.fromLTRB(20, 24, 12, 0)),
              if (ops.isEmpty)
                const EmptyState(
                  icon: Icons.receipt_long_outlined,
                  title: 'Пока пусто',
                  text: 'Оплаты и расходы этого месяца появятся здесь',
                )
              else
                DayGroupedList(items: ops),
            ],
          ),
        );
      },
    );
  }
}

class _HeroCard extends StatelessWidget {
  final MonthSummary summary;

  const _HeroCard({required this.summary});

  @override
  Widget build(BuildContext context) {
    final cs = context.cs;
    final dark = context.isDark;
    final fg = dark ? cs.onPrimaryContainer : cs.onPrimary;
    final s = summary;
    final profit = s.profitCents;
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: dark
              ? [cs.primaryContainer, Color.lerp(cs.primaryContainer, cs.tertiaryContainer, 0.7)!]
              : [cs.primary, Color.lerp(cs.primary, cs.tertiary, 0.55)!],
        ),
        boxShadow: dark
            ? null
            : [BoxShadow(color: cs.primary.withValues(alpha: 0.28), blurRadius: 24, offset: const Offset(0, 10))],
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Text(
            profit >= 0 ? 'Прибыль за ${s.month.name.toLowerCase()}' : 'Убыток за ${s.month.name.toLowerCase()}',
            style: TextStyle(color: fg.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Icon(profit >= 0 ? Icons.trending_up_rounded : Icons.trending_down_rounded, color: fg.withValues(alpha: 0.85)),
        ]),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(money(profit), style: amountStyle(38, color: fg)),
        ),
        const SizedBox(height: 16),
        Row(children: [
          Expanded(child: _HeroStat(label: 'Пришло', value: money(s.incomeCents), icon: Icons.south_west_rounded, fg: fg)),
          const SizedBox(width: 10),
          Expanded(
              child: _HeroStat(label: 'Потрачено', value: money(s.expenseCents), icon: Icons.north_east_rounded, fg: fg)),
        ]),
      ]),
    );
  }
}

class _HeroStat extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color fg;

  const _HeroStat({required this.label, required this.value, required this.icon, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: fg.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(color: fg.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, size: 17, color: fg),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(label, style: TextStyle(fontSize: 12, color: fg.withValues(alpha: 0.8))),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: amountStyle(16, color: fg)),
            ),
          ]),
        ),
      ]),
    );
  }
}

class _DebtCard extends StatelessWidget {
  final VoidCallback onTap;

  const _DebtCard({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final store = AppStore.I;
    final c = context.colors;
    final debtors = store.clients.where((x) => store.balanceOf(x.id!) > 0).length;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(children: [
            IconBadge(Icons.account_balance_wallet_outlined, color: c.debt, background: c.debtBg),
            const SizedBox(width: 14),
            Expanded(
              child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text('Клиенты должны', style: context.tt.titleSmall),
                const SizedBox(height: 2),
                Text(
                  [
                    debtors == 0 ? 'никто не должен' : '$debtors ${_plural(debtors, 'клиент', 'клиента', 'клиентов')}',
                    if (store.totalAdvance > 0) 'авансы ${money(store.totalAdvance)}',
                  ].join(' · '),
                  style: context.tt.bodySmall?.copyWith(color: c.muted),
                ),
              ]),
            ),
            Text(money(store.totalDebt), style: amountStyle(20, color: store.totalDebt > 0 ? c.debt : c.muted)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ]),
        ),
      ),
    );
  }
}

String _plural(int n, String one, String few, String many) {
  final m10 = n % 10, m100 = n % 100;
  if (m10 == 1 && m100 != 11) return one;
  if (m10 >= 2 && m10 <= 4 && (m100 < 12 || m100 > 14)) return few;
  return many;
}

class _QuickAction extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _QuickAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(children: [
            Container(
              width: 58,
              height: 58,
              decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(20)),
              child: Stack(alignment: Alignment.center, children: [
                Icon(icon, color: color, size: 26),
                Positioned(
                  right: 9,
                  top: 9,
                  child: Icon(Icons.add_rounded, size: 13, color: color),
                ),
              ]),
            ),
            const SizedBox(height: 7),
            Text(label, style: context.tt.labelLarge?.copyWith(fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}

class _OrdersStrip extends StatelessWidget {
  final MonthSummary summary;

  const _OrdersStrip({required this.summary});

  @override
  Widget build(BuildContext context) {
    final s = summary;
    final set = AppSettings.I;
    final items = <(String, String)>[
      ('Заказов', '${s.ordersCount}'),
      ('На сумму', money(s.ordersCents)),
      if (set.show(OrderField.weight) && s.weightKg > 0) ('Вес', kg(s.weightKg)),
      if (set.show(OrderField.weight) && s.avgPerKgCents != null) ('Ср. за кг', money(s.avgPerKgCents!)),
    ];
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
        child: Row(children: [
          for (var i = 0; i < items.length; i++) ...[
            if (i > 0) Container(width: 1, height: 30, color: context.cs.outlineVariant.withValues(alpha: 0.5)),
            Expanded(
              child: Column(children: [
                Text(items[i].$1, style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
                const SizedBox(height: 2),
                FittedBox(fit: BoxFit.scaleDown, child: Text(items[i].$2, style: amountStyle(15))),
              ]),
            ),
          ],
        ]),
      ),
    );
  }
}
