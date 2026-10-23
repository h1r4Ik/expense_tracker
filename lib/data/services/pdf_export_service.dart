import 'dart:io';
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';

/// PDF statement generator producing professional monochrome statements.
class PdfExportService {
  final DateFormat _dateFormat = DateFormat('dd MMM yyyy');
  final DateFormat _timeFormat = DateFormat('dd MMM yyyy, hh:mm a');
  final NumberFormat _currencyFormat = NumberFormat('#,##,##0.00');

  String _formatAmount(double amount) => 'INR ${_currencyFormat.format(amount)}';

  /// Generates a PDF statement byte array.
  Future<Uint8List> generateStatement({
    required String accountName,
    required DateTime from,
    required DateTime to,
    required List<ExpenseTransaction> transactions,
    required double totalIncome,
    required double totalExpense,
  }) async {
    final pdf = pw.Document();

    final netBalance = totalIncome - totalExpense;
    final sortedTxns = List<ExpenseTransaction>.from(transactions)
      ..sort((a, b) => a.date.compareTo(b.date));

    // Precalculate running balances
    double currentBal = 0.0;
    final List<Map<String, dynamic>> rows = [];
    for (final tx in sortedTxns) {
      if (tx.isIncome) {
        currentBal += tx.amount;
      } else {
        currentBal -= tx.amount;
      }
      rows.add({
        'date': _dateFormat.format(tx.date),
        'title': tx.title,
        'category': tx.category,
        'debit': tx.isExpense ? _formatAmount(tx.amount) : '-',
        'credit': tx.isIncome ? _formatAmount(tx.amount) : '-',
        'balance': _formatAmount(currentBal),
      });
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        header: (context) => _buildHeader(accountName, from, to),
        footer: (context) => _buildFooter(context),
        build: (context) => [
          pw.SizedBox(height: 12),
          _buildSummarySection(totalIncome, totalExpense, netBalance, sortedTxns.length),
          pw.SizedBox(height: 16),
          pw.Text(
            'TRANSACTION DETAILS',
            style: pw.TextStyle(
              fontSize: 10,
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.grey700,
              letterSpacing: 1.0,
            ),
          ),
          pw.SizedBox(height: 8),
          _buildTransactionTable(rows),
        ],
      ),
    );

    return pdf.save();
  }

  pw.Widget _buildHeader(String accountName, DateTime from, DateTime to) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColors.grey400, width: 1.0),
        ),
      ),
      padding: const pw.EdgeInsets.only(bottom: 12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.end,
        children: [
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
             
              pw.Text(
                'Account Statement :- $accountName',
                style: const pw.TextStyle(
                  fontSize: 16,
                  color: PdfColors.black,
                ),
              ),
            ],
          ),
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              pw.Text(
                'STATEMENT PERIOD',
                style: pw.TextStyle(
                  fontSize: 8,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.grey600,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                '${_dateFormat.format(from)} - ${_dateFormat.format(to)}',
                style: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _buildSummarySection(
    double totalIncome,
    double totalExpense,
    double netBalance,
    int count,
  ) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.grey100,
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
        border: pw.Border.all(color: PdfColors.grey300, width: 0.8),
      ),
      padding: const pw.EdgeInsets.all(12),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceAround,
        children: [
          _buildSummaryBox('TOTAL INCOME', _formatAmount(totalIncome)),
          pw.Container(width: 1, height: 32, color: PdfColors.grey300),
          _buildSummaryBox('TOTAL EXPENSE', _formatAmount(totalExpense)),
          pw.Container(width: 1, height: 32, color: PdfColors.grey300),
          _buildSummaryBox('NET BALANCE', _formatAmount(netBalance)),
          pw.Container(width: 1, height: 32, color: PdfColors.grey300),
          _buildSummaryBox('TRANSACTIONS', count.toString()),
        ],
      ),
    );
  }

  pw.Widget _buildSummaryBox(String label, String value) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.center,
      children: [
        pw.Text(
          label,
          style: pw.TextStyle(
            fontSize: 7.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColors.grey600,
          ),
        ),
        pw.SizedBox(height: 4),
        pw.Text(
          value,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
          ),
        ),
      ],
    );
  }

  pw.Widget _buildTransactionTable(List<Map<String, dynamic>> rows) {
    if (rows.isEmpty) {
      return pw.Container(
        padding: const pw.EdgeInsets.symmetric(vertical: 24),
        alignment: pw.Alignment.center,
        child: pw.Text(
          'No transactions found for the selected period.',
          style: const pw.TextStyle(
            fontSize: 10,
            color: PdfColors.grey600,
          ),
        ),
      );
    }

    return pw.Table(
      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
      columnWidths: const {
        0: pw.FlexColumnWidth(2.0), // Date
        1: pw.FlexColumnWidth(3.5), // Description
        2: pw.FlexColumnWidth(2.5), // Category
        3: pw.FlexColumnWidth(2.2), // Debit
        4: pw.FlexColumnWidth(2.2), // Credit
        5: pw.FlexColumnWidth(2.4), // Balance
      },
      children: [
        // Header
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: PdfColors.grey200),
          children: [
            _tableHeaderCell('Date'),
            _tableHeaderCell('Description'),
            _tableHeaderCell('Category'),
            _tableHeaderCell('Debit (Dr)', alignRight: true),
            _tableHeaderCell('Credit (Cr)', alignRight: true),
            _tableHeaderCell('Balance', alignRight: true),
          ],
        ),
        // Rows
        for (int i = 0; i < rows.length; i++)
          pw.TableRow(
            decoration: pw.BoxDecoration(
              color: i % 2 == 0 ? PdfColors.white : PdfColors.grey50,
            ),
            children: [
              _tableBodyCell(rows[i]['date'] as String),
              _tableBodyCell(rows[i]['title'] as String),
              _tableBodyCell(rows[i]['category'] as String),
              _tableBodyCell(rows[i]['debit'] as String, alignRight: true),
              _tableBodyCell(rows[i]['credit'] as String, alignRight: true),
              _tableBodyCell(rows[i]['balance'] as String, alignRight: true),
            ],
          ),
      ],
    );
  }

  pw.Widget _tableHeaderCell(String text, {bool alignRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _tableBodyCell(String text, {bool alignRight = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      alignment: alignRight ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
      child: pw.Text(
        text,
        style: const pw.TextStyle(
          fontSize: 8,
          color: PdfColors.black,
        ),
      ),
    );
  }

  pw.Widget _buildFooter(pw.Context context) {
    return pw.Container(
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColors.grey300, width: 0.8),
        ),
      ),
      padding: const pw.EdgeInsets.only(top: 8),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generated on ${_timeFormat.format(DateTime.now())}',
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey600,
            ),
          ),
          pw.Text(
            'Page ${context.pageNumber} of ${context.pagesCount}',
            style: const pw.TextStyle(
              fontSize: 7.5,
              color: PdfColors.grey600,
            ),
          ),
        ],
      ),
    );
  }

  /// Sends the PDF to the system print dialog.
  Future<void> printStatement(Uint8List pdfBytes) async {
    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdfBytes,
      name: 'Expense_Statement_${DateFormat('yyyyMMdd').format(DateTime.now())}.pdf',
    );
  }

  /// Saves the PDF to local device storage.
  Future<File> saveToFile(Uint8List pdfBytes, String fileName) async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(pdfBytes, flush: true);
    return file;
  }
}
