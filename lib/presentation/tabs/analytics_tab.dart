import 'package:flutter/material.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:excel/excel.dart' as xlsx;
import 'package:pdf/widgets.dart' as pw;
import 'package:pdf/pdf.dart' as pdf;
import 'package:local_basket_business/core/utils/responsive.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:local_basket_business/domain/repositories/products/product_repository.dart';
import 'widgets/analytics_tab_widgets/export_button.dart';
import 'widgets/analytics_tab_widgets/filters_section.dart';
import 'widgets/analytics_tab_widgets/products_chart.dart';
import 'widgets/analytics_tab_widgets/products_table.dart';

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  DateTime? _startDate;
  DateTime? _endDate;
  String _type = 'online';
  bool _loadingReport = false;
  List<Map<String, dynamic>> _reportItems = [];

  // Constants
  static const int _defaultPageSize = 50;
  static const int _maxChartItems = 6;

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final start = await showDatePicker(
      context: context,
      initialDate: _startDate ?? DateTime(now.year, now.month, 1),
      firstDate: DateTime(now.year - 2),
      lastDate: now,
    );
    if (start == null) return;
    final end = await showDatePicker(
      context: context,
      initialDate: _endDate ?? now,
      firstDate: start,
      lastDate: now,
    );
    if (end == null) return;
    setState(() {
      _startDate = start;
      _endDate = end;
    });
  }

  // Helper methods
  int? _getBusinessId() {
    final sess = sl<SessionStore>().user;
    return (sess != null && sess['b2bUnit'] is Map<String, dynamic>)
        ? (sess['b2bUnit']['id'] as int?)
        : null;
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  bool _validateDateRange() {
    if (_startDate == null || _endDate == null) {
      _showSnackBar('Select date range first');
      return false;
    }
    return true;
  }

  Future<void> _fetchReport({int page = 0, int? size}) async {
    size ??= _defaultPageSize;

    final businessId = _getBusinessId();
    if (businessId == null) {
      _showSnackBar('Business ID not found');
      return;
    }

    if (!_validateDateRange()) return;

    setState(() => _loadingReport = true);

    try {
      final repo = sl<ProductRepository>();
      final pageData = await repo.getProductsReportPaged(
        startDate: _startDate!,
        endDate: _endDate!,
        businessId: businessId,
        type: _type,
        page: page,
        size: size,
      );

      setState(() => _reportItems = pageData.items);

      // Debug logging
      if (pageData.items.isNotEmpty) {
        debugPrint('Analytics: Loaded ${pageData.items.length} items');
        debugPrint('First item: ${pageData.items.first}');
      }
    } catch (e) {
      _showSnackBar('Failed to load report: $e');
    } finally {
      if (mounted) setState(() => _loadingReport = false);
    }
  }

  Future<void> _exportExcel() async {
    final businessId = _getBusinessId();
    if (businessId == null) {
      _showSnackBar('Business ID not found');
      return;
    }

    try {
      final now = DateTime.now();
      final start = await showDatePicker(
        context: context,
        initialDate: DateTime(now.year, now.month, 1),
        firstDate: DateTime(now.year - 2),
        lastDate: now,
      );
      if (start == null) return;
      final end = await showDatePicker(
        context: context,
        initialDate: now,
        firstDate: start,
        lastDate: now,
      );
      if (end == null) return;

      String? selectedType = await showDialog<String>(
        context: context,
        builder: (ctx) => SimpleDialog(
          title: const Text('Select type'),
          children: [
            SimpleDialogOption(
              onPressed: () => Navigator.pop(ctx, 'online'),
              child: const Text('online'),
            ),
          ],
        ),
      );
      selectedType ??= 'online';

      final repo = sl<ProductRepository>();
      final bytes = await repo.downloadProductsExcel(
        startDate: start,
        endDate: end,
        businessId: businessId,
        type: selectedType,
      );

      // Save original Excel
      final dir = await getApplicationDocumentsDirectory();
      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
      final xlsxFile = File(
        '${dir.path}/products_${fmt(start)}_${fmt(end)}_$selectedType.xlsx',
      );
      await xlsxFile.writeAsBytes(bytes, flush: true);

      // Convert to PDF (first sheet)
      final excel = xlsx.Excel.decodeBytes(bytes);
      final sheetName = excel.tables.keys.isNotEmpty
          ? excel.tables.keys.first
          : null;
      if (sheetName == null) {
        if (!mounted) return;
        _showSnackBar('No data found in Excel');
        return;
      }
      final sheet = excel.tables[sheetName]!;
      final List<List<String>> rows = [];
      for (final row in sheet.rows) {
        final cells = row.map((c) => (c?.value)?.toString() ?? '').toList();
        rows.add(cells);
      }
      final maxCols = rows.isNotEmpty
          ? rows.map((r) => r.length).reduce((a, b) => a > b ? a : b)
          : 0;
      final truncated = rows
          .map((r) => r.take(maxCols.clamp(0, 12)).toList())
          .toList();

      final doc = pw.Document();
      doc.addPage(
        pw.MultiPage(
          build: (context) => [
            pw.Text(
              'Products Report (${fmt(start)} to ${fmt(end)} - $selectedType)',
              style: pw.TextStyle(fontSize: 16),
            ),
            pw.SizedBox(height: 12),
            if (truncated.isNotEmpty)
              pw.Table.fromTextArray(
                data: truncated,
                cellStyle: const pw.TextStyle(fontSize: 9),
                headerStyle: pw.TextStyle(
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                ),
                headerDecoration: pw.BoxDecoration(
                  color: pdf.PdfColors.grey300,
                ),
                border: null,
                cellAlignment: pw.Alignment.centerLeft,
              )
            else
              pw.Text('No rows'),
          ],
        ),
      );

      final pdfFile = File(
        '${dir.path}/products_${fmt(start)}_${fmt(end)}_$selectedType.pdf',
      );
      await pdfFile.writeAsBytes(await doc.save(), flush: true);

      if (!mounted) return;
      _showSnackBar('Saved PDF: ${pdfFile.path.split('/').last}');
      await OpenFilex.open(pdfFile.path);
    } catch (e) {
      if (!mounted) return;
      _showSnackBar('Export failed: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(Responsive.horizontalPadding(context)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExportButton(onPressed: _exportExcel),
          const SizedBox(height: 20),
          FiltersSection(
            startDate: _startDate,
            endDate: _endDate,
            type: _type,
            isLoading: _loadingReport,
            onPickDateRange: _pickDateRange,
            onTypeChanged: (value) => setState(() => _type = value ?? 'online'),
            onLoadReport: _fetchReport,
          ),
          const SizedBox(height: 20),
          ProductsChart(reportItems: _reportItems, maxItems: _maxChartItems),
          if (_reportItems.isNotEmpty) const SizedBox(height: 20),
          ProductsTable(reportItems: _reportItems),
        ],
      ),
    );
  }
}
