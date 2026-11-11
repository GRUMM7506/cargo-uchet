import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../currency.dart';
import '../format.dart';
import '../l10n.dart';
import '../services/rates.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';

/// Курсы валют: обновление, ручной ввод, конвертер.
class RatesScreen extends StatefulWidget {
  const RatesScreen({super.key});

  @override
  State<RatesScreen> createState() => _RatesScreenState();
}

class _RatesScreenState extends State<RatesScreen> {
  final _amount = TextEditingController(text: '100');
  late String _from = AppSettings.I.currency == 'USD' ? 'USD' : AppSettings.I.currency;

  @override
  void dispose() {
    _amount.dispose();
    super.dispose();
  }

  Future<void> _update() async {
    final ok = await Fx.I.update();
    if (mounted) toast(context, ok ? t.ratesOk : t.ratesError);
  }

  Future<void> _edit(String code, String main) async {
    final fx = Fx.I;
    final ctrl = TextEditingController(text: rateStr(fx.cross(code, main)).replaceAll(' ', ''));
    final r = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('${currencyOf(code).flag}  ${currencyOf(code).name(AppSettings.I.lang)}'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]'))],
          decoration: InputDecoration(
            prefixText: '1 ${currencySymbol(code)} = ',
            suffixText: currencySymbol(main),
          ),
          onSubmitted: (v) => Navigator.pop(ctx, v),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(
            style: FilledButton.styleFrom(minimumSize: const Size(64, 44)),
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: Text(t.save),
          ),
        ],
      ),
    );
    final v = r == null ? null : parseNum(r);
    if (v == null || v <= 0) return;
    // 1 code = v main
    if (code == 'USD') {
      await fx.setManual(main, v);
    } else {
      await fx.setManual(code, fx.perUsd(main) / v);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([Fx.I, AppSettings.I]),
      builder: (context, _) {
        final fx = Fx.I;
        final set = AppSettings.I;
        final main = set.currency;
        final codes = set.currencyChoices();
        final others = codes.where((c) => c != main).toList();
        final amount = parseMoney(_amount.text) ?? 0;
        final c = context.colors;
        final last = fx.lastUpdate;

        return Scaffold(
          appBar: AppBar(
            title: Text(t.rates),
            actions: [
              fx.updating
                  ? const Padding(
                      padding: EdgeInsets.all(14),
                      child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
                    )
                  : IconButton(tooltip: t.updateRates, icon: const Icon(Icons.refresh_rounded), onPressed: _update),
              const SizedBox(width: 4),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: last == null ? c.debtBg : context.cs.surfaceContainer,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(children: [
                  Icon(last == null ? Icons.info_outline_rounded : Icons.cloud_done_outlined,
                      color: last == null ? c.debt : context.cs.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      last == null
                          ? t.ratesNever
                          : t.updatedAt('${dayLabel(last)}, ${two(last.hour)}:${two(last.minute)}'),
                      style: context.tt.bodyMedium,
                    ),
                  ),
                ]),
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(t.ratesHint, style: context.tt.bodySmall?.copyWith(color: c.muted)),
              ),
              const SizedBox(height: 12),
              Card(
                clipBehavior: Clip.antiAlias,
                child: Column(children: [
                  for (var i = 0; i < others.length; i++) ...[
                    if (i > 0) const Divider(indent: 64),
                    ListTile(
                      leading: Text(currencyOf(others[i]).flag, style: const TextStyle(fontSize: 26)),
                      title: Text(currencyOf(others[i]).name(set.lang)),
                      subtitle: Text(
                        [
                          if (fx.isManualToday(others[i]) || (others[i] == 'USD' && fx.isManualToday(main))) t.manualMark,
                          if (fx.isApprox(others[i]) || (others[i] == 'USD' && fx.isApprox(main))) t.approxMark,
                        ].join(' · '),
                        style: TextStyle(color: c.debt),
                      ),
                      trailing: Text(
                        '1 ${currencySymbol(others[i])} = ${rateStr(fx.cross(others[i], main))} ${currencySymbol(main)}',
                        style: amountStyle(15),
                      ),
                      onTap: () => _edit(others[i], main),
                    ),
                  ],
                ]),
              ),
              const SizedBox(height: 12),
              FilledButton.tonalIcon(
                icon: const Icon(Icons.refresh_rounded),
                label: Text(t.updateRates),
                onPressed: fx.updating ? null : _update,
              ),
              SectionHeader(t.converter, padding: const EdgeInsets.fromLTRB(4, 24, 4, 10)),
              SectionCard(children: [
                TextField(
                  controller: _amount,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,\s]'))],
                  style: amountStyle(22),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(Icons.currency_exchange_rounded),
                    suffixIcon: CurrencyButton(value: _from, onChanged: (v) => setState(() => _from = v)),
                  ),
                  onChanged: (_) => setState(() {}),
                ),
                const SizedBox(height: 8),
                for (final code in codes.where((x) => x != _from))
                  KeyValue('${currencyOf(code).flag}  $code', money(fx.convert(amount, _from, code), cur: code)),
              ]),
              const SizedBox(height: 16),
              Text(t.ratesSource, textAlign: TextAlign.center, style: context.tt.bodySmall?.copyWith(color: c.muted)),
            ],
          ),
        );
      },
    );
  }
}
