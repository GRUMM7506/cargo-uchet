import 'package:flutter/material.dart';

import '../l10n.dart';
import '../models.dart';
import '../services/export_service.dart';
import '../settings.dart';
import '../theme.dart';
import '../widgets/common.dart';
import '../widgets/tiles.dart';

class SettingsScreen extends StatefulWidget {
  /// Сразу прокрутить к полям заказа.
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

  String _fieldLabel(OrderField f) => switch (f) {
        OrderField.photo => t.fieldPhoto,
        OrderField.description => t.fieldDescription,
        OrderField.deposit => t.fieldDeposit,
        OrderField.due => t.fieldDue,
        OrderField.done => t.fieldDone,
        OrderField.note => t.fieldNote,
      };

  IconData _fieldIcon(OrderField f) => switch (f) {
        OrderField.photo => Icons.photo_camera_outlined,
        OrderField.description => Icons.handyman_outlined,
        OrderField.deposit => Icons.savings_outlined,
        OrderField.due => Icons.flag_outlined,
        OrderField.done => Icons.task_alt_rounded,
        OrderField.note => Icons.notes_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final s = AppSettings.I;
    return ListenableBuilder(
      listenable: s,
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: Text(t.settings)),
        body: ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
          children: [
            // ---------------- Язык ----------------
            SectionCard(title: t.language, children: [
              SegmentedButton<String>(
                segments: [
                  for (final e in AppSettings.languages.entries) ButtonSegment(value: e.key, label: Text(e.value)),
                ],
                selected: {s.lang},
                showSelectedIcon: false,
                onSelectionChanged: (v) => s.setLang(v.first),
              ),
            ]),
            const SizedBox(height: 12),

            // ---------------- Оформление ----------------
            SectionCard(title: t.appearance, children: [
              Text(t.theme, style: context.tt.titleSmall),
              const SizedBox(height: 10),
              SegmentedButton<ThemeMode>(
                segments: [
                  ButtonSegment(
                      value: ThemeMode.system, icon: const Icon(Icons.brightness_auto_outlined), label: Text(t.themeAuto)),
                  ButtonSegment(
                      value: ThemeMode.light, icon: const Icon(Icons.light_mode_outlined), label: Text(t.themeLight)),
                  ButtonSegment(
                      value: ThemeMode.dark, icon: const Icon(Icons.dark_mode_outlined), label: Text(t.themeDark)),
                ],
                selected: {s.themeMode},
                showSelectedIcon: false,
                onSelectionChanged: (v) => s.setThemeMode(v.first),
              ),
              const SizedBox(height: 18),
              Text(t.color, style: context.tt.titleSmall),
              const SizedBox(height: 12),
              Wrap(spacing: 12, runSpacing: 12, children: [
                for (var i = 0; i < AppSettings.accents.length; i++)
                  _AccentDot(color: AppSettings.accents[i], selected: s.accentIndex == i, onTap: () => s.setAccent(i)),
              ]),
            ]),
            const SizedBox(height: 12),

            // ---------------- Поля заказа ----------------
            SectionCard(
              key: _ordersKey,
              title: t.orderFields,
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
              children: [
                Text(t.orderFieldsHint, style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
                const SizedBox(height: 12),
                Text(t.previewLabel, style: context.tt.labelLarge),
                const SizedBox(height: 8),
                Container(
                  decoration: BoxDecoration(
                    color: context.cs.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.cs.outlineVariant.withValues(alpha: 0.5)),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: OrderTile(
                    Order(
                      clientId: -1,
                      description: t.sampleWork,
                      priceCents: 45000,
                      depositCents: 15000,
                      acceptedAt: today(),
                      dueAt: today().add(const Duration(days: 5)),
                    ),
                    previewName: t.sampleClient,
                  ),
                ),
                const SizedBox(height: 8),
                for (final f in OrderField.values)
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    secondary: Icon(_fieldIcon(f), color: context.cs.primary),
                    title: Text(_fieldLabel(f)),
                    value: s.show(f),
                    onChanged: (v) => s.setFieldVisible(f, v),
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // ---------------- Данные ----------------
            SectionCard(
              title: t.data,
              padding: const EdgeInsets.fromLTRB(8, 14, 8, 8),
              children: [
                _ActionTile(
                  icon: Icons.cloud_upload_outlined,
                  title: t.backup,
                  subtitle: t.backupHint,
                  onTap: () => _run(context, ExportService.shareBackup),
                ),
                _ActionTile(
                  icon: Icons.settings_backup_restore_rounded,
                  title: t.restore,
                  subtitle: t.restoreHint,
                  onTap: () => _restore(context),
                ),
                _ActionTile(
                  icon: Icons.table_view_outlined,
                  title: t.excelAll,
                  subtitle: t.excelAllHint,
                  onTap: () => _run(context, () => ExportService.excel()),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Center(
              child: Text('${t.appTitle} · ${t.versionLabel} 2.0',
                  style: context.tt.bodySmall?.copyWith(color: context.colors.muted)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _run(BuildContext context, Future<void> Function() job) async {
    try {
      await job();
    } catch (e) {
      if (context.mounted) toast(context, t.error(e));
    }
  }

  Future<void> _restore(BuildContext context) async {
    final ok = await confirm(context, t.restoreQ, ok: t.chooseFile);
    if (!ok) return;
    try {
      final path = await ExportService.pickBackup();
      if (path == null) return;
      final done = await ExportService.restore(path);
      if (context.mounted) toast(context, done ? t.restored : t.notBackup);
    } catch (e) {
      if (context.mounted) toast(context, t.error(e));
    }
  }
}

class _AccentDot extends StatelessWidget {
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  const _AccentDot({required this.color, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 46,
        height: 46,
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: selected ? color : Colors.transparent, width: 2.5),
        ),
        child: Container(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: selected ? const Icon(Icons.check_rounded, color: Colors.white, size: 20) : null,
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
