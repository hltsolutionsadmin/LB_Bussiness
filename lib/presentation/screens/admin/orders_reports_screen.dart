import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:intl/intl.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:local_basket_business/data/datasources/orders/orders_remote_data_source.dart';

class OrdersReportsScreen extends StatefulWidget {
  final int? initialBusinessId;
  final bool autoLoad;

  const OrdersReportsScreen({
    super.key,
    this.initialBusinessId,
    this.autoLoad = false,
  });

  @override
  State<OrdersReportsScreen> createState() => _OrdersReportsScreenState();
}

class _OrdersReportsScreenState extends State<OrdersReportsScreen>
    with SingleTickerProviderStateMixin {
  final _dateFmt = DateFormat('dd MMM yyyy');

  List<Map<String, dynamic>> _businesses = [];
  int? _selectedBusinessId;

  String _frequency = 'MONTHLY';
  String _status = 'PLACED';
  DateTime _from = DateTime.now().subtract(const Duration(days: 7));
  DateTime _to = DateTime.now();

  final int _page = 0;
  final int _size = 10;

  bool _loading = false;
  Map<String, dynamic>? _report;

  late AnimationController _animCtrl;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _fadeAnim = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    _loadBusinesses();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadBusinesses() async {
    try {
      final ds = GetIt.I<BusinessRemoteDataSource>();
      final list = await ds.listBusinesses();

      setState(() {
        _businesses = list;
        _selectedBusinessId =
            widget.initialBusinessId ?? (list.first['id'] as num?)?.toInt();
      });

      if (widget.autoLoad) _loadReport();
    } catch (_) {
      _showSnack('Failed to load restaurants');
    }
  }

  Future<void> _pickDate(bool isFrom) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: isFrom ? _from : _to,
      firstDate: DateTime(2023),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      setState(() => isFrom ? _from = picked : _to = picked);
    }
  }

  Future<void> _loadReport() async {
    if (_selectedBusinessId == null) return;

    setState(() => _loading = true);
    _animCtrl.reset();

    try {
      final ds = GetIt.I<OrdersRemoteDataSource>();
      final res = await ds.getOrdersReportView(
        frequency: _frequency,
        status: _status,
        businessId: _selectedBusinessId!,
        fromDate: DateFormat('yyyy-MM-dd').format(_from),
        toDate: DateFormat('yyyy-MM-dd').format(_to),
        page: _page,
        size: _size,
      );

      setState(() => _report = res);
      _animCtrl.forward();
    } catch (_) {
      _showSnack('Failed to load report');
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _downloadExcel() async {
    if (_selectedBusinessId == null) return;

    try {
      final ds = GetIt.I<OrdersRemoteDataSource>();
      await ds.downloadOrdersExcel(
        orderStatus: _status,
        fromDate: DateFormat('yyyy-MM-dd').format(_from),
        toDate: DateFormat('yyyy-MM-dd').format(_to),
        restaurantId: _selectedBusinessId!,
        page: _page,
        size: _size,
      );
      _showSnack('Excel downloaded successfully');
    } catch (_) {
      _showSnack('Download failed');
    }
  }

  void _showSnack(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
  }

  // ======================= UI =======================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text(
          'Orders Reports',
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _filtersCard(),
            const SizedBox(height: 20),
            Expanded(
              child: _loading
                  ? const Center(child: CircularProgressIndicator())
                  : FadeTransition(opacity: _fadeAnim, child: _ordersList()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filtersCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          _dropdownRow(),
          const SizedBox(height: 12),
          _dateRow(),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _primaryButton()),
              const SizedBox(width: 12),
              Expanded(child: _outlineButton()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _dropdownRow() {
    return Row(
      children: [
        Expanded(child: _businessDropdown()),
        const SizedBox(width: 12),
        Expanded(child: _frequencyDropdown()),
      ],
    );
  }

  Widget _dateRow() {
    return Row(
      children: [
        Expanded(child: _statusDropdown()),
        const SizedBox(width: 12),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _dateTile('From', _from, true)),
              const SizedBox(width: 8),
              Expanded(child: _dateTile('To', _to, false)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _ordersList() {
    List items = [];
    final data = _report;
    if (data is Map<String, dynamic>) {
      if (data['content'] is List) {
        items = data['content'] as List;
      } else if (data['data'] is Map<String, dynamic> &&
          (data['data'] as Map<String, dynamic>)['content'] is List) {
        items =
            (data['data'] as Map<String, dynamic>)['content'] as List<dynamic>;
      }
    }

    if (items.isEmpty) {
      return const Center(child: Text('No orders found'));
    }

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (_, i) {
        final m = items[i];
        return Container(
          decoration: _cardDecoration(),
          child: ListTile(
            title: Text(
              m['orderNumber'] ?? '',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            subtitle: Text(
              '₹${(m['total'] ?? m['totalAmount'] ?? '')} • ${(m['status'] ?? m['orderStatus'] ?? '')}',
              style: const TextStyle(color: Colors.grey),
            ),
            trailing: Text(
              (m['createdAt'] ?? m['createdDate'] ?? '')
                  .toString()
                  .split('T')
                  .first,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        );
      },
    );
  }

  // ================== Widgets ==================

  Widget _primaryButton() => ElevatedButton(
    onPressed: _loadReport,
    style: ElevatedButton.styleFrom(
      backgroundColor: Colors.black,
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: const Text('Load Report'),
  );

  Widget _outlineButton() => OutlinedButton(
    onPressed: _downloadExcel,
    style: OutlinedButton.styleFrom(
      padding: const EdgeInsets.symmetric(vertical: 14),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
    ),
    child: const Text('Download Excel'),
  );

  Widget _dateTile(String label, DateTime date, bool isFrom) {
    return InkWell(
      onTap: () => _pickDate(isFrom),
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: _cardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: const TextStyle(fontSize: 11)),
            const SizedBox(height: 4),
            Text(
              _dateFmt.format(date),
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ],
        ),
      ),
    );
  }

  // ================== Dropdowns ==================

  Widget _businessDropdown() => _dropdown<int>(
    label: 'Restaurant',
    value: _selectedBusinessId ?? 0,
    items: _businesses
        .map(
          (b) => DropdownMenuItem<int>(
            value: (b['id'] as num?)?.toInt() ?? 0,
            child: Text(b['businessName'] ?? ''),
          ),
        )
        .toList(),
    onChanged: (v) => setState(() => _selectedBusinessId = v),
    selectedItemBuilder: (context) => _businesses
        .map(
          (b) => Align(
            alignment: Alignment.centerLeft,
            child: Text(
              (b['businessName'] ?? '').toString(),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        )
        .toList(),
  );

  Widget _frequencyDropdown() => _dropdown<String>(
    label: 'Frequency',
    value: _frequency,
    items: [
      'DAILY',
      'WEEKLY',
      'MONTHLY',
    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: (v) => setState(() => _frequency = v!),
  );

  Widget _statusDropdown() => _dropdown<String>(
    label: 'Status',
    value: _status,
    items: [
      'PLACED',
      'ACCEPTED',
      'PREPARING',
      'READY',
      'DELIVERED',
      'CANCELLED',
    ].map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
    onChanged: (v) => setState(() => _status = v!),
  );

  Widget _dropdown<T>({
    required String label,
    required T value,
    required List<DropdownMenuItem<T>> items,
    required ValueChanged<T?> onChanged,
    List<Widget> Function(BuildContext context)? selectedItemBuilder,
  }) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
      ),
      items: items,
      onChanged: onChanged,
      isExpanded: true,
      selectedItemBuilder: selectedItemBuilder,
    );
  }

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: Colors.white,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.black.withOpacity(0.05),
        blurRadius: 12,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
