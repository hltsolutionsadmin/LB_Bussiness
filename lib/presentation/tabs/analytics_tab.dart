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
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
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

      final dir = await getApplicationDocumentsDirectory();

      String fmt(DateTime d) =>
          '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

      final xlsxFile = File(
        '${dir.path}/products_${fmt(start)}_${fmt(end)}_$selectedType.xlsx',
      );
      await xlsxFile.writeAsBytes(bytes, flush: true);

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
    final horizontal = Responsive.horizontalPadding(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SingleChildScrollView(
      padding: EdgeInsets.symmetric(horizontal: horizontal, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTopHeader(theme),
          const SizedBox(height: 18),

          _buildSectionCard(
            context: context,
            title: 'Export Report',
            subtitle: 'Download products analytics report in PDF format',
            icon: Icons.file_download_outlined,
            child: ExportButton(onPressed: _exportExcel),
          ),

          const SizedBox(height: 18),

          _buildSectionCard(
            context: context,
            title: 'Filters',
            subtitle: 'Choose date range and report type',
            icon: Icons.tune_rounded,
            child: FiltersSection(
              startDate: _startDate,
              endDate: _endDate,
              type: _type,
              isLoading: _loadingReport,
              onPickDateRange: _pickDateRange,
              onTypeChanged: (value) =>
                  setState(() => _type = value ?? 'online'),
              onLoadReport: _fetchReport,
            ),
          ),

          const SizedBox(height: 18),

          _buildSectionCard(
            context: context,
            title: 'Products Overview',
            subtitle: _reportItems.isEmpty
                ? 'Load report to see analytics'
                : '${_reportItems.length} items loaded',
            icon: Icons.bar_chart_rounded,
            child: _loadingReport
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 30),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _reportItems.isEmpty
                ? _buildEmptyState(theme)
                : Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark
                              ? theme.colorScheme.surfaceContainerHighest
                              : theme.colorScheme.primary.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.primary.withOpacity(0.12),
                          ),
                        ),
                        child: ProductsChart(
                          reportItems: _reportItems,
                          maxItems: _maxChartItems,
                        ),
                      ),
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.cardColor,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.grey.withOpacity(0.12),
                          ),
                        ),
                        child: ProductsTable(reportItems: _reportItems),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopHeader(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary,
            theme.colorScheme.primary.withOpacity(0.75),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withOpacity(0.18),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            height: 54,
            width: 54,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const Icon(
              Icons.insights_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Analytics Dashboard',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Track product performance, export reports, and review trends easily.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.92),
                    fontSize: 12.5,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Widget child,
  }) {
    final theme = Theme.of(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.cardColor,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
        border: Border.all(color: Colors.grey.withOpacity(0.10)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                height: 42,
                width: 42,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: Colors.orange.shade700, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.withOpacity(0.12)),
      ),
      child: Column(
        children: [
          Container(
            height: 64,
            width: 64,
            decoration: BoxDecoration(
              color: theme.colorScheme.primary.withOpacity(0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.analytics_outlined,
              size: 30,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'No analytics data yet',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 6),
          Text(
            'Select date range and load the report to view product analytics.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey.shade600,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
