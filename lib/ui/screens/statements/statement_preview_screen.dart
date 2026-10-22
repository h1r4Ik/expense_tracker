import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../data/services/pdf_export_service.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/transaction_provider.dart';

class StatementPreviewScreen extends StatefulWidget {
  final DateTime from;
  final DateTime to;

  const StatementPreviewScreen({
    super.key,
    required this.from,
    required this.to,
  });

  @override
  State<StatementPreviewScreen> createState() => _StatementPreviewScreenState();
}

class _StatementPreviewScreenState extends State<StatementPreviewScreen> {
  final PdfExportService _pdfService = PdfExportService();
  Uint8List? _generatedBytes;

  Future<Uint8List> _buildPdf() async {
    final auth = context.read<AuthProvider>();
    final txProvider = context.read<TransactionProvider>();

    final accountName = auth.activeAccount?.nameOrDefault ?? 'Primary Account';
    final allTx = txProvider.allTransactions;

    final filteredTx = allTx.where((tx) {
      return (tx.date.isAfter(widget.from.subtract(const Duration(seconds: 1))) &&
          tx.date.isBefore(widget.to.add(const Duration(seconds: 1))));
    }).toList();

    final totalIncome = filteredTx
        .where((tx) => tx.isIncome)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final totalExpense = filteredTx
        .where((tx) => tx.isExpense)
        .fold<double>(0.0, (sum, tx) => sum + tx.amount);

    final bytes = await _pdfService.generateStatement(
      accountName: accountName,
      from: widget.from,
      to: widget.to,
      transactions: filteredTx,
      totalIncome: totalIncome,
      totalExpense: totalExpense,
    );

    _generatedBytes = bytes;
    return bytes;
  }

  Future<void> _handlePrint() async {
    if (_generatedBytes != null) {
      await _pdfService.printStatement(_generatedBytes!);
    } else {
      final bytes = await _buildPdf();
      await _pdfService.printStatement(bytes);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Statement Preview'),
        actions: [
          IconButton(
            tooltip: 'Print Statement',
            icon: const Icon(LucideIcons.printer, size: 20),
            onPressed: _handlePrint,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: PdfPreview(
        build: (format) => _buildPdf(),
        canChangeOrientation: false,
        canChangePageFormat: false,
        canDebug: false,
        allowPrinting: true,
        allowSharing: true,
        loadingWidget: Center(
          child: CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(
              isDark ? Colors.white : Colors.black,
            ),
          ),
        ),
        pdfPreviewPageDecoration: BoxDecoration(
          color: theme.colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
      ),
    );
  }
}
