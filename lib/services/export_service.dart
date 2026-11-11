import 'dart:io';

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
import '../models.dart';
import '../store.dart';

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
    book.rename(defName, 'Итоги');

    bool inRange(DateTime d) => month == null || month.contains(d);

    // --- Итоги ---
    final sum = book['Итоги'];
    _widths(sum, [30, 16, 16, 16, 14, 16, 12]);
    if (month != null) {
      final s = _s.summary(month);
      _row(sum, ['Отчёт за ${month.label}'], bold: true);
      _row(sum, ['']);
      _row(sum, ['Пришло (оплаты), \$', _usd(s.incomeCents)]);
      _row(sum, ['Потрачено (расходы), \$', _usd(s.expenseCents)]);
      _row(sum, [s.profitCents >= 0 ? 'Прибыль, \$' : 'Убыток, \$', _usd(s.profitCents)], bold: true);
      _row(sum, ['']);
      _row(sum, ['Заказов принято', s.ordersCount]);
      _row(sum, ['Сумма заказов, \$', _usd(s.ordersCents)]);
      _row(sum, ['Вес, кг', s.weightKg]);
      _row(sum, ['']);
      _row(sum, ['Долг клиентов на сегодня, \$', _usd(_s.totalDebt)]);
      _row(sum, ['Авансы клиентов на сегодня, \$', _usd(_s.totalAdvance)]);
      if (s.expensesByCategory.isNotEmpty) {
        _row(sum, ['']);
        _row(sum, ['Расходы по категориям', '\$'], bold: true);
        for (final e in s.expensesByCategory.entries) {
          _row(sum, [e.key, _usd(e.value)]);
        }
      }
    } else {
      _row(sum, ['Месяц', 'Пришло \$', 'Потрачено \$', 'Прибыль \$', 'Заказов', 'Сумма заказов \$', 'Вес кг'],
          bold: true);
      var ti = 0, te = 0, to = 0, tc = 0;
      var tw = 0.0;
      for (final m in _s.months) {
        final s = _s.summary(m);
        ti += s.incomeCents;
        te += s.expenseCents;
        to += s.ordersCents;
        tc += s.ordersCount;
        tw += s.weightKg;
        _row(sum, [m.label, _usd(s.incomeCents), _usd(s.expenseCents), _usd(s.profitCents), s.ordersCount,
          _usd(s.ordersCents), s.weightKg]);
      }
      _row(sum, ['ИТОГО', _usd(ti), _usd(te), _usd(ti - te), tc, _usd(to), tw], bold: true);
      _row(sum, ['']);
      _row(sum, ['Долг клиентов на сегодня, \$', _usd(_s.totalDebt)]);
    }

    // --- Оплаты ---
    final pay = book['Оплаты'];
    _widths(pay, [12, 24, 12, 28, 30]);
    _row(pay, ['Дата', 'Клиент', 'Сумма \$', 'За заказ', 'Заметка'], bold: true);
    var payTotal = 0;
    for (final x in _s.payments.reversed.where((x) => inRange(x.paidAt))) {
      final o = x.orderId == null ? null : _s.orderById(x.orderId!);
      payTotal += x.amountCents;
      _row(pay, [dateStr(x.paidAt), _s.clientName(x.clientId), _usd(x.amountCents), o?.description ?? '', x.note]);
    }
    _row(pay, ['ИТОГО', '', _usd(payTotal)], bold: true);

    // --- Расходы ---
    final exp = book['Расходы'];
    _widths(exp, [12, 22, 12, 34]);
    _row(exp, ['Дата', 'Категория', 'Сумма \$', 'Комментарий'], bold: true);
    var expTotal = 0;
    for (final x in _s.expenses.reversed.where((x) => inRange(x.spentAt))) {
      expTotal += x.amountCents;
      _row(exp, [dateStr(x.spentAt), x.category, _usd(x.amountCents), x.note]);
    }
    _row(exp, ['ИТОГО', '', _usd(expTotal)], bold: true);

    // --- Заказы ---
    final ord = book['Заказы'];
    _widths(ord, [12, 22, 26, 10, 10, 12, 12, 26]);
    _row(ord, ['Принят', 'Клиент', 'Груз', 'Вес кг', 'Кол-во', 'Сумма \$', 'Выполнен', 'Заметка'], bold: true);
    var ordTotal = 0;
    var ordWeight = 0.0;
    for (final x in _s.orders.reversed.where((x) => inRange(x.acceptedAt))) {
      ordTotal += x.amountCents;
      ordWeight += x.weightKg ?? 0;
      _row(ord, [
        dateStr(x.acceptedAt),
        _s.clientName(x.clientId),
        x.description,
        x.weightKg,
        x.quantity,
        _usd(x.amountCents),
        x.doneAt == null ? '' : dateStr(x.doneAt!),
        x.note,
      ]);
    }
    _row(ord, ['ИТОГО', '', '', ordWeight, '', _usd(ordTotal)], bold: true);

    // --- Клиенты (балансы на сегодня) ---
    final cl = book['Клиенты'];
    _widths(cl, [24, 16, 16, 14, 16]);
    _row(cl, ['Клиент', 'Телефон', 'Заказов на \$', 'Оплачено \$', 'Долг (+) / аванс (−) \$'], bold: true);
    for (final c in _s.clients) {
      final o = _s.ordersOf(c.id!).fold(0, (a, x) => a + x.amountCents);
      final pd = _s.paymentsOf(c.id!).fold(0, (a, x) => a + x.amountCents);
      _row(cl, [c.name, c.phone, _usd(o), _usd(pd), _usd(_s.balanceOf(c.id!))]);
    }

    final bytes = book.encode();
    if (bytes == null) throw Exception('Не удалось создать Excel-файл');
    final name = month == null ? 'uchet_vse_${dateToDb(today())}.xlsx' : 'uchet_${month.fileLabel}.xlsx';
    final f = await _tempFile(name);
    await f.writeAsBytes(bytes, flush: true);
    await _share(f, month == null ? 'Учёт — все данные' : 'Учёт — ${month.label}');
  }

  // =========================== PDF ===========================

  static pw.ThemeData? _theme;

  static Future<pw.ThemeData> _pdfTheme() async {
    if (_theme != null) return _theme!;
    final reg = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Regular.ttf'));
    final bold = pw.Font.ttf(await rootBundle.load('assets/fonts/NotoSans-Bold.ttf'));
    return _theme = pw.ThemeData.withFont(base: reg, bold: bold);
  }

  static pw.Widget _h(String t) => pw.Padding(
        padding: const pw.EdgeInsets.only(top: 14, bottom: 6),
        child: pw.Text(t, style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
      );

  static pw.Widget _table(List<String> headers, List<List<String>> rows, {Set<int> right = const {}}) {
    if (rows.isEmpty) {
      return pw.Text('Нет записей', style: const pw.TextStyle(color: PdfColors.grey600));
    }
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
    final pays = _s.payments.reversed.where((x) => month.contains(x.paidAt)).toList();
    final exps = _s.expenses.reversed.where((x) => month.contains(x.spentAt)).toList();
    final ords = _s.orders.reversed.where((x) => month.contains(x.acceptedAt)).toList();
    final debtors = _s.clients.where((c) => _s.balanceOf(c.id!) != 0).toList()
      ..sort((a, b) => _s.balanceOf(b.id!).compareTo(_s.balanceOf(a.id!)));

    doc.addPage(pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(28),
      footer: (ctx) => pw.Align(
        alignment: pw.Alignment.centerRight,
        child: pw.Text('Стр. ${ctx.pageNumber} из ${ctx.pagesCount} · сформировано ${dateStr(today())}',
            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
      ),
      build: (ctx) => [
        pw.Text('Отчёт за ${month.label}', style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 10),
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey400)),
          child: pw.Column(children: [
            _kv('Пришло (оплаты)', money(s.incomeCents), color: PdfColors.green800),
            _kv('Потрачено (расходы)', money(s.expenseCents), color: PdfColors.red800),
            pw.Divider(),
            _kv(s.profitCents >= 0 ? 'Прибыль' : 'Убыток', money(s.profitCents),
                bold: true, color: s.profitCents >= 0 ? PdfColors.green800 : PdfColors.red800),
            pw.SizedBox(height: 6),
            _kv('Заказов принято', '${s.ordersCount} на ${money(s.ordersCents)}'),
            if (s.weightKg > 0) _kv('Вес', kg(s.weightKg)),
            _kv('Долг клиентов на сегодня', money(_s.totalDebt)),
          ]),
        ),
        if (s.expensesByCategory.isNotEmpty) ...[
          _h('Расходы по категориям'),
          _table(
            ['Категория', 'Сумма'],
            [for (final e in s.expensesByCategory.entries) [e.key, money(e.value)]],
            right: {1},
          ),
        ],
        _h('Оплаты (${pays.length})'),
        _table(
          ['Дата', 'Клиент', 'Сумма', 'Заметка'],
          [for (final x in pays) [dateStr(x.paidAt), _s.clientName(x.clientId), money(x.amountCents), x.note]],
          right: {2},
        ),
        _h('Расходы (${exps.length})'),
        _table(
          ['Дата', 'Категория', 'Сумма', 'Комментарий'],
          [for (final x in exps) [dateStr(x.spentAt), x.category, money(x.amountCents), x.note]],
          right: {2},
        ),
        _h('Заказы (${ords.length})'),
        _table(
          ['Принят', 'Клиент', 'Груз', 'Вес', 'Сумма', 'Выполнен'],
          [
            for (final x in ords)
              [
                dateStr(x.acceptedAt),
                _s.clientName(x.clientId),
                x.description,
                x.weightKg == null ? '' : kg(x.weightKg!),
                money(x.amountCents),
                x.doneAt == null ? 'в работе' : dateStr(x.doneAt!),
              ]
          ],
          right: {3, 4},
        ),
        _h('Расчёты с клиентами на сегодня'),
        _table(
          ['Клиент', 'Долг / аванс'],
          [
            for (final c in debtors)
              [
                c.name,
                _s.balanceOf(c.id!) > 0
                    ? 'долг ${money(_s.balanceOf(c.id!))}'
                    : 'аванс ${money(-_s.balanceOf(c.id!))}',
              ]
          ],
          right: {1},
        ),
      ],
    ));

    final f = await _tempFile('otchet_${month.fileLabel}.pdf');
    await f.writeAsBytes(await doc.save(), flush: true);
    await _share(f, 'Отчёт — ${month.label}');
  }

  // =========================== РЕЗЕРВНАЯ КОПИЯ ===========================

  static Future<void> shareBackup() async {
    final src = File(await _s.dbPath());
    final dst = await _tempFile('uchet_backup_${dateToDb(today())}.db');
    await src.copy(dst.path);
    await _share(dst, 'Резервная копия учёта');
  }

  /// Выбор файла копии. null — пользователь отменил; false — файл не подходит.
  static Future<String?> pickBackup() async {
    final file = await FilePicker.pickFile();
    if (file == null) return null;
    final bytes = await file.readAsBytes();
    final tmp = await _tempFile('restore_candidate.db');
    await tmp.writeAsBytes(bytes, flush: true);
    return tmp.path;
  }

  static Future<bool> restore(String path) async {
    if (!await AppDatabase.isValidBackup(path)) return false;
    await _s.replaceDatabase(path);
    return true;
  }
}
