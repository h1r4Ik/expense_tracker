import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:printing/printing.dart';
import 'package:provider/provider.dart';
import '../../../data/services/pdf_export_service.dart';
import '../../../logic/providers/auth_provider.dart';
import '../../../logic/providers/transaction_provider.dart';
import '../../widgets/common/frosted_header_bar.dart';
import '../../widgets/common/glass_container.dart';

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

    // Force always light mode theme for printing & preview canvas
    final lightThemeData = ThemeData.light(useMaterial3: true).copyWith(
      scaffoldBackgroundColor: const Color(0xFFF3F4F6),
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF111827),
        onPrimary: Colors.white,
        secondary: Color(0xFF4B5563),
        onSecondary: Colors.white,
        surface: Colors.white,
        onSurface: Color(0xFF111827),
        error: Color(0xFFB91C1C),
        onError: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Color(0xFF111827)),
    );

    return Scaffold(
      appBar: FrostedHeaderBar(
        leading: GlassContainer(
          shape: BoxShape.circle,
          padding: const EdgeInsets.all(10),
          onTap: () => Navigator.of(context).maybePop(),
          child: Icon(
            LucideIcons.chevronLeft,
            size: 20,
            color: isDark ? Colors.white : Colors.black,
          ),
        ),
        title: GlassContainer(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
          borderRadius: 20,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                LucideIcons.fileSpreadsheet,
                size: 20,
                color: isDark ? Colors.white : Colors.black,
              ),
              const SizedBox(width: 8),
              Text(
                'Statement Preview',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : Colors.black,
                ),
              ),
            ],
          ),
        ),
        actions: [
          GlassContainer(
            shape: BoxShape.circle,
            padding: const EdgeInsets.all(10),
            onTap: _handlePrint,
            child: Icon(
              LucideIcons.printer,
              size: 20,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
      body: Theme(
        data: lightThemeData,
        child: PdfPreview(
          build: (format) => _buildPdf(),
          maxPageWidth: MediaQuery.sizeOf(context).width - 24,
          canChangeOrientation: false,
          canChangePageFormat: false,
          canDebug: false,
          scrollViewDecoration:  BoxDecoration(
            color: isDark ? Color.fromARGB(255, 0, 0, 0) : Color(0xFFF3F4F6),
          ),
          previewPageMargin: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: 12,
          ),
          actionBarTheme:PdfActionBarTheme(
            backgroundColor: Color(0xFFE5E7EB),
            iconColor: Color(0xFF111827),
            elevation: 2,
            height: 64,
          ),
          loadingWidget: const Center(
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
            ),
          ),
          pdfPreviewPageDecoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(4),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.12),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
