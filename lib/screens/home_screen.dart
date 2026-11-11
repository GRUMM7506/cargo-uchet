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
import 'clients_screen.dart';
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
          for (final o in store.orders)
            if (o.depositCents > 0 && _month.contains(o.depositDate)) (o.depositDate, DepositTile(o)),
          for (final p in store.payments)
            if (_month.contains(p.paidAt)) (p.paidAt, PaymentTile(p)),
          for (final e in store.expenses)
            if (_month.contains(e.spentAt)) (e.spentAt, ExpenseTile(e)),
        ];
        final debtors = store.debtors;

        return Scaffold(
          appBar: AppBar(
            title: Text(t.appTitle),
            actions: [
              CurrencyButton(value: AppSettings.I.currency, onChanged: AppSettings.I.setCurrency),
              IconButton(
                tooltip: t.monthReport,
                icon: const Icon(Icons.insert_chart_outlined_rounded),
                onPressed: () => _open(MonthReportScreen(month: _month)),
              ),
              IconButton(
                tooltip: t.settings,
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
              const SizedBox(height: 18),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(children: [
                  _QuickAction(
                    icon: Icons.south_west_rounded,
                    label: t.payment,
                    color: context.colors.income,
                    background: context.colors.incomeBg,
                    onTap: () => _open(const PaymentFormPage()),
                  ),
                  _QuickAction(
                    icon: Icons.handyman_outlined,
                    label: t.order,
                    color: context.cs.primary,
                    background: context.cs.primaryContainer.withValues(alpha: 0.6),
                    onTap: () => _open(const OrderFormPage()),
                  ),
                  _QuickAction(
                    icon: Icons.north_east_rounded,
                    label: t.expenseOne,
                    color: context.colors.expense,
                    background: context.colors.expenseBg,
                    onTap: () => _open(const ExpenseFormPage()),
                  ),
                  _QuickAction(
                    icon: Icons.person_add_alt_1_outlined,
                    label: t.client,
                    color: context.cs.tertiary,
                    background: context.cs.tertiaryContainer.withValues(alpha: 0.6),
                    onTap: () => _open(const ClientFormPage()),
                  ),
                ]),
              ),
              const SizedBox(height: 18),

              // ----- Должники -----
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: _DebtCard(onTap: widget.onOpenClients),
              ),
              if (debtors.isNotEmpty) ...[
                SectionHeader(
                  t.debtors,
                  padding: const EdgeInsets.fromLTRB(20, 20, 8, 6),
                  trailing: debtors.length > 5
                      ? TextButton(onPressed: widget.onOpenClients, child: Text('${t.seeAll} · ${debtors.length}'))
                      : null,
                ),
                GroupCard(children: [
                  for (final c in debtors.take(5))
                    ClientTile(
                      c,
                      onTap: () => _open(ClientDetailScreen(clientId: c.id!)),
                    ),
                ]),
              ],

              // ----- Деньги за месяц -----
              SectionHeader(t.moneyFlow, padding: const EdgeInsets.fromLTRB(20, 24, 12, 0)),
              if (ops.isEmpty)
                EmptyState(icon: Icons.receipt_long_outlined, title: t.emptyTitle, text: t.emptyMoneyFlow)
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
          Expanded(
            child: Text(
              profit >= 0 ? t.profitFor(s.month.name) : t.lossFor(s.month.name),
              style: TextStyle(color: fg.withValues(alpha: 0.85), fontWeight: FontWeight.w600),
            ),
          ),
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
          Expanded(child: _HeroStat(label: t.income, value: money(s.incomeCents), icon: Icons.south_west_rounded, fg: fg)),
          const SizedBox(width: 10),
          Expanded(
              child: _HeroStat(label: t.expense, value: money(s.expenseCents), icon: Icons.north_east_rounded, fg: fg)),
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
      decoration: BoxDecoration(color: fg.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(16)),
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
    final n = store.debtors.length;
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
                Text(t.clientsOwe, style: context.tt.titleSmall),
                const SizedBox(height: 2),
                Text(
                  [
                    n == 0 ? t.nobodyOwes : t.clientsCount(n),
                    if (store.totalOverpaid > 0) t.overpaidTotal(money(store.totalOverpaid)),
                  ].join(' · '),
                  style: context.tt.bodySmall?.copyWith(color: c.muted),
                ),
              ]),
            ),
            Text(money(store.totalDebt), style: amountStyle(22, color: store.totalDebt > 0 ? c.debt : c.muted)),
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, color: c.muted),
          ]),
        ),
      ),
    );
  }
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
                Positioned(right: 9, top: 9, child: Icon(Icons.add_rounded, size: 13, color: color)),
              ]),
            ),
            const SizedBox(height: 7),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.tt.labelLarge?.copyWith(fontSize: 13)),
          ]),
        ),
      ),
    );
  }
}
