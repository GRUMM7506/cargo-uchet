import 'dart:io';

import 'package:archive/archive.dart';
import 'package:excel/excel.dart' as xl;
import 'package:file_picker/file_picker.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../db.dart';
import '../format.dart';
import '../l10n.dart';
import '../models.dart';
import '../store.dart';
import '../settings.dart';
import '../widgets/tiles.dart' show bucketsText;
import 'photos.dart';
import 'rates.dart';

class ExportService {
  static final _s = AppStore.I;

  static Future<File> _tempFile(String name) async {
    final dir = await getTemporaryDirectory();
    return File(p.join(dir.path, name));
  }

  static Future<void> _share(File f, String subject) async {
    await SharePlus.instance.share(ShareParams(files: [XFile(f.path)], subject: subject));
  }

  // =========================== EXCEL ===========================

  static xl.CellValue? _cell(Object? v) {
    if (v == null) return null;
    if (v is int) return xl.IntCellValue(v);
    if (v is double) return xl.DoubleCellValue(v);
    return xl.TextCellValue(v.toString());
  }

  static double _usd(int cents) => cents / 100;

  static void _row(xl.Sheet s, List<Object?> cells, {bool bold = false}) {
    s.appendRow(cells.map(_cell).toList());
    if (bold) {
      final r = s.maxRows - 1;
      for (var i = 0; i < cells.length; i++) {
        s.cell(xl.CellIndex.indexByColumnRow(columnIndex: i, rowIndex: r)).cellStyle = xl.CellStyle(bold: true);
      }
    }
  }

  static void _widths(xl.Sheet s, List<double> w) {
    for (var i = 0; i < w.length; i++) {
      s.setColumnWidth(i, w[i]);
    }
  }

  /// [month] == null — выгрузка за всё время.
  static Future<void> excel({YearMonth? month}) async {
    final book = xl.Excel.createExcel();
    final defName = book.getDefaultSheet() ?? 'Sheet1';
    book.rename(defName, t.sheetSummary);

    bool inRange(DateTime d) => month == null || month.contains(d);
    final main = AppSettings.I.currency;
    final fx = Fx.I;

    // --- Итоги ---
    final sum = book[t.sheetSummary];
    _widths(sum, [34, 16, 16, 16, 14, 16, 16]);
    if (month != null) {
      final s = _s.summary(month);
      _row(sum, [t.reportFor(month.label)], bold: true);
      _row(sum, ['']);
      _row(sum, ['${t.incomeFull}, $main', _usd(s.incomeCents)]);
      _row(sum, ['  ${t.deposits}, $main', _usd(s.depositsCents)]);
      _row(sum, ['  ${t.paymentsLabel}, $main', _usd(s.paymentsCents)]);
      _row(sum, ['${t.expenseFull}, $main', _usd(s.expenseCents)]);
      _row(sum, ['${s.profitCents >= 0 ? t.profit : t.loss}, $main', _usd(s.profitCents)], bold: true);
      _row(sum, ['']);
      _row(sum, [t.ordersAccepted, s.ordersCount]);
      _row(sum, ['${t.onSum}, $main', _usd(s.ordersCents)]);
      _row(sum, ['']);
      _row(sum, ['${t.debtNow}, $main', _usd(_s.totalDebt)]);
      if (s.expensesByCategory.isNotEmpty) {
        _row(sum, ['']);
        _row(sum, [t.byCategory, main], bold: true);
        for (final e in s.expensesByCategory.entries) {
          _row(sum, [e.key, _usd(e.value)]);
        }
      }
    } else {
      _row(sum, [t.monthCol, '${t.income} $main', '${t.expense} $main', '${t.profit} $main', t.ordersCountLabel,
        '${t.onSum} $main', '${t.deposits} $main'], bold: true);
      var ti = 0, te = 0, to = 0, tc = 0, td = 0;
      for (final m in _s.months) {
        final s = _s.summary(m);
        ti += s.incomeCents;
        te += s.expenseCents;
        to += s.ordersCents;
        tc += s.ordersCount;
        td += s.depositsCents;
        _row(sum, [m.label, _usd(s.incomeCents), _usd(s.expenseCents), _usd(s.profitCents), s.ordersCount,
          _usd(s.ordersCents), _usd(s.depositsCents)]);
      }
      _row(sum, [t.total, _usd(ti), _usd(te), _usd(ti - te), tc, _usd(to), _usd(td)], bold: true);
      _row(sum, ['']);
      _row(sum, ['${t.debtNow}, $main', _usd(_s.totalDebt)]);
    }

    // --- Заказы ---
    final ord = book[t.sheetOrders];
    _widths(ord, [12, 22, 28, 8, 12, 12, 12, 12, 14, 12, 12, 26]);
    _row(ord, [t.accepted, t.client, t.work, t.currencyCol, t.price, t.deposit, t.paid, t.remaining,
      '${t.remaining}, $main', t.due, t.doneDate, t.note], bold: true);
    var oRemMain = 0;
    for (final x in _s.orders.reversed.where((x) => inRange(x.acceptedAt))) {
      final paid = _s.paidForOrder(x.id!);
      final rem = _s.remainingOf(x);
      final remMain = fx.convert(rem, x.currency, main);
      oRemMain += remMain;
      _row(ord, [
        dateStr(x.acceptedAt),
        _s.clientName(x.clientId),
        x.description,
        x.currency,
        _usd(x.priceCents),
        _usd(x.depositCents),
        _usd(paid),
        _usd(rem),
        _usd(remMain),
        x.dueAt == null ? '' : dateStr(x.dueAt!),
        x.doneAt == null ? '' : dateStr(x.doneAt!),
        x.note,
      ]);
    }
    _row(ord, [t.total, '', '', '', '', '', '', '', _usd(oRemMain)], bold: true);

    // --- Поступления (залоги + оплаты) ---
    final pay = book[t.sheetPayments];
    _widths(pay, [12, 22, 14, 12, 8, 14, 28, 30]);
    _row(pay, [t.date, t.client, t.typeCol, t.amount, t.currencyCol, '${t.amount}, $main', t.work, t.note], bold: true);
    final rows = <(DateTime, List<Object?>, int)>[
      for (final o in _s.orders)
        if (o.depositCents > 0 && inRange(o.depositDate))
          (
            o.depositDate,
            [
              dateStr(o.depositDate),
              _s.clientName(o.clientId),
              t.deposit,
              _usd(o.depositCents),
              o.currency,
              _usd(fx.convert(o.depositCents, o.currency, main, o.depositDate)),
              o.description,
              '',
            ],
            fx.convert(o.depositCents, o.currency, main, o.depositDate)
          ),
      for (final x in _s.payments)
        if (inRange(x.paidAt))
          (
            x.paidAt,
            [
              dateStr(x.paidAt),
              _s.clientName(x.clientId),
              t.payment,
              _usd(x.amountCents),
              x.currency,
              _usd(fx.convert(x.amountCents, x.currency, main, x.paidAt)),
              x.orderId == null ? '' : (_s.orderById(x.orderId!)?.description ?? ''),
              x.note,
            ],
            fx.convert(x.amountCents, x.currency, main, x.paidAt)
          ),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    var payTotal = 0;
    for (final r in rows) {
      payTotal += r.$3;
      _row(pay, r.$2);
    }
    _row(pay, [t.total, '', '', '', '', _usd(payTotal)], bold: true);

    // --- Расходы ---
    final exp = book[t.sheetExpenses];
    _widths(exp, [12, 22, 12, 8, 14, 34]);
    _row(exp, [t.date, t.category, t.amount, t.currencyCol, '${t.amount}, $main', t.comment], bold: true);
    var expTotal = 0;
    for (final x in _s.expenses.reversed.where((x) => inRange(x.spentAt))) {
      final v = fx.convert(x.amountCents, x.currency, main, x.spentAt);
      expTotal += v;
      _row(exp, [dateStr(x.spentAt), x.category, _usd(x.amountCents), x.currency, _usd(v), x.note]);
    }
    _row(exp, [t.total, '', '', '', _usd(expTotal)], bold: true);

    // --- Клиенты (долги на сегодня) ---
    final cl = book[t.sheetClients];
    _widths(cl, [24, 16, 30, 20]);
    _row(cl, [t.client, t.phone, t.byCurrencies, '${t.balanceCol}, $main'], bold: true);
    for (final c in _s.clients) {
      final b = _s.bucketsOf(c.id!);
      _row(cl, [
        c.name,
        c.phone,
        b.entries.map((e) => '${e.value < 0 ? '−' : ''}${money(e.value.abs(), cur: e.key)}').join('; '),
        _usd(_s.balanceOf(c.id!)),
      ]);
    }

    final bytes = book.encode();
    if (bytes == null) throw Exception('Excel');
    final name = month == null ? 'uchet_${dateToDb(today())}.xlsx' : 'uchet_${month.fileLabel}.xlsx';
    final f = await _tempFile(name);
    await f.writeAsBytes(bytes, flush: true);
    await _share(f, month == null ? t.shareAll : t.shareMonth(month.label));
  }

  // =========================== PDF ===========================

  static pw.ThemeData? _theme;

  static Future<pw.ThemeData> _pdfTheme() async {
    if (_theme != null) return _theme!;
    final reg = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    return _theme = pw.ThemeData.withFont(base: reg, bold: bold);
  }

  static pw.Widget _h(String text) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(text, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _table(List<String> headers, List<List<String>> rows, {Set<int> right = const {}}) {
    if (rows.isEmpty) return pw.Text(t.noRecords, style: const pw.TextStyle(color: PdfColors.grey600));
    return pw.TableHelper.fromTextArray(
      headers: headers,
      data: rows,
      headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
      cellStyle: const pw.TextStyle(fontSize: 9),
      headerDecoration: const pw.BoxDecoration(color: PdfColors.grey200),
      cellAlignments: {for (final i in right) i: pw.Alignment.centerRight},
      cellPadding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 3),
    );
  }

  static pw.Widget _kv(String k, String v, {bool bold = false, PdfColor? color}) => pw.Padding(
        padding: const pw.EdgeInsets.symmetric(vertical: 2),
        child: pw.Row(children: [
          pw.Expanded(child: pw.Text(k)),
          pw.Text(v, style: pw.TextStyle(fontWeight: bold ? pw.FontWeight.bold : null, color: color)),
        ]),
      );

  static Future<void> pdf(YearMonth month) async {
    final s = _s.summary(month);
    final doc = pw.Document(theme: await _pdfTheme());
    final logo = pw.MemoryImage((await rootBundle.load('assets/images/logo.png')).buffer.asUint8List());
    final ords = _s.orders.reversed.where((x) => month.contains(x.acceptedAt)).toList();
    final exps = _s.expenses.reversed.where((x) => month.contains(x.spentAt)).toList();
    final incomes = <(DateTime, List<String>)>[
      for (final o in _s.orders)
        if (o.depositCents > 0 && month.contains(o.depositDate))
          (o.depositDate, [dateStr(o.depositDate), _s.clientName(o.clientId), t.deposit, money(o.depositCents, cur: o.currency)]),
      for (final x in _s.payments)
        if (month.contains(x.paidAt))
          (x.paidAt, [dateStr(x.paidAt), _s.clientName(x.clientId), t.payment, money(x.amountCents, cur: x.currency)]),
    ]..sort((a, b) => a.$1.compareTo(b.$1));
    final debtors = _s.debtors;

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text(t.pageFooter(ctx.pageNumber, ctx.pagesCount, dateStr(today())),
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Row(children: [
          pw.Image(logo, width: 34, height: 34),
          pw.SizedBox(width: 10),
          pw.Expanded(
            child: pw.Text(t.reportFor(month.label), style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
          ),
          pw.Text(AppSettings.I.currency, style: const pw.TextStyle(fontSize: 11, color: PdfColors.grey700)),
        ]),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Column(children: [
            _kv(t.incomeFull, money(s.incomeCents), color: PdfColors.green800),
            _kv(t.expenseFull, money(s.expenseCents), color: PdfColors.red800),
            pw.Divider(),
            _kv(s.profitCents >= 0 ? t.profit : t.loss, money(s.profitCents),
                bold: true, color: s.profitCents >= 0 ? PdfColors.green800 : PdfColors.red800),
            pw.SizedBox(height: 6),
            _kv(t.ordersAccepted, '${s.ordersCount} · ${money(s.ordersCents)}'),
            _kv(t.depositsReceived, money(s.depositsCents)),
            _kv(t.debtNow, money(_s.totalDebt), bold: true),
          ]),
        ),
        _h('${t.tabOrders} (${ords.length})'),
        _table(
          [t.accepted, t.client, t.work, t.price, t.deposit, t.remaining, t.due],
          [
            for (final x in ords)
              [
                dateStr(x.acceptedAt),
                _s.clientName(x.clientId),
                x.description,
                money(x.priceCents, cur: x.currency),
                money(x.depositCents, cur: x.currency),
                money(_s.remainingOf(x), cur: x.currency),
                x.isDone ? t.done : (x.dueAt == null ? '' : dateStr(x.dueAt!)),
              ]
          ],
          right: {3, 4, 5},
        ),
        _h('${t.incomeFull} (${incomes.length})'),
        _table([t.date, t.client, t.typeCol, t.amount], [for (final r in incomes) r.$2], right: {3}),
        _h('${t.tabExpenses} (${exps.length})'),
        _table(
          [t.date, t.category, t.amount, t.comment],
          [for (final x in exps) [dateStr(x.spentAt), x.category, money(x.amountCents, cur: x.currency), x.note]],
          right: {2},
        ),
        if (s.expensesByCategory.isNotEmpty) ...[
          _h(t.byCategory),
          _table([t.category, t.amount], [for (final e in s.expensesByCategory.entries) [e.key, money(e.value)]],
              right: {1}),
        ],
        _h(t.debtorsToday),
        _table(
          [t.client, t.phone, t.debt],
          [
            for (final c in debtors)
              [c.name, c.phone, _s.bucketsOf(c.id!).length == 1 ? bucketsText(_s.bucketsOf(c.id!)) : '≈ ${money(_s.balanceOf(c.id!))}']
          ],
          right: {2},
        ),
      ],
    ));

    final f = await _tempFile('otchet_${month.fileLabel}.pdf');
    await f.writeAsBytes(await doc.save(), flush: true);
    await _share(f, t.shareMonth(month.label));
  }

  // =========================== РЕЗЕРВНАЯ КОПИЯ ===========================
  // Копия — zip: база + папка photos/. Старые копии (.db) тоже восстанавливаются.

  static const _dbEntry = 'uchet.db';

  static Future<void> shareBackup() async {
    final archive = Archive();
    final dbBytes = await File(await _s.dbPath()).readAsBytes();
    archive.addFile(ArchiveFile(_dbEntry, dbBytes.length, dbBytes));
    final dir = Directory(Photos.dir);
    if (await dir.exists()) {
      await for (final e in dir.list()) {
        if (e is File) {
          final b = await e.readAsBytes();
          archive.addFile(ArchiveFile('photos/${p.basename(e.path)}', b.length, b));
        }
      }
    }
    final List<int>? zip = ZipEncoder().encode(archive);
    if (zip == null) throw Exception('zip');
    final dst = await _tempFile('uchet_backup_${dateToDb(today())}.zip');
    await dst.writeAsBytes(zip, flush: true);
    await _share(dst, t.backupSubject);
    await AppSettings.I.markBackupDone();
  }

  /// Выбор файла копии. null — пользователь отменил.
  static Future<String?> pickBackup() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final tmp = await _tempFile('restore_candidate.bin');
    await tmp.writeAsBytes(bytes, flush: true);
    return tmp.path;
  }

  static Future<bool> restore(String path) async {
    final bytes = await File(path).readAsBytes();
    final isZip = bytes.length > 4 && bytes[0] == 0x50 && bytes[1] == 0x4B;
    if (!isZip) {
      // старая копия — просто файл базы
      if (!await AppDatabase.isValidBackup(path)) return false;
      await _s.replaceDatabase(path);
      return true;
    }

    final archive = ZipDecoder().decodeBytes(bytes);
    ArchiveFile? dbFile;
    for (final f in archive.files) {
      if (f.isFile && f.name == _dbEntry) dbFile = f;
    }
    if (dbFile == null) return false;
    final dbTmp = await _tempFile('restore_db.db');
    await dbTmp.writeAsBytes(dbFile.content as List<int>, flush: true);
    if (!await AppDatabase.isValidBackup(dbTmp.path)) return false;

    // фото: очищаем папку и распаковываем
    final dir = Directory(Photos.dir);
    if (await dir.exists()) await dir.delete(recursive: true);
    await dir.create(recursive: true);
    for (final f in archive.files) {
      if (f.isFile && f.name.startsWith('photos/')) {
        final name = p.basename(f.name);
        if (name.isEmpty) continue;
        await Photos.file(name).writeAsBytes(f.content as List<int>, flush: true);
      }
    }
    await _s.replaceDatabase(dbTmp.path);
    return true;
  }
}
