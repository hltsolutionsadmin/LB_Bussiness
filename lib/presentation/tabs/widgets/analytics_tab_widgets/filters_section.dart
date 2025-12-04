import 'package:flutter/material.dart';

class FiltersSection extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final String type;
  final bool isLoading;
  final VoidCallback onPickDateRange;
  final ValueChanged<String?> onTypeChanged;
  final VoidCallback onLoadReport;

  const FiltersSection({
    super.key,
    required this.startDate,
    required this.endDate,
    required this.type,
    required this.isLoading,
    required this.onPickDateRange,
    required this.onTypeChanged,
    required this.onLoadReport,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Products Report Filters',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0xFF111827),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _DateRangeButton(
                  startDate: startDate,
                  endDate: endDate,
                  onPressed: onPickDateRange,
                ),
              ),
              const SizedBox(width: 12),
              _TypeDropdown(value: type, onChanged: onTypeChanged),
              const SizedBox(width: 12),
              _LoadButton(isLoading: isLoading, onPressed: onLoadReport),
            ],
          ),
        ],
      ),
    );
  }
}

class _DateRangeButton extends StatelessWidget {
  final DateTime? startDate;
  final DateTime? endDate;
  final VoidCallback onPressed;

  const _DateRangeButton({
    required this.startDate,
    required this.endDate,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: const Icon(Icons.date_range),
      label: Text(_getDateRangeText()),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      ),
    );
  }

  String _getDateRangeText() {
    if (startDate == null || endDate == null) {
      return 'Select Date Range';
    }
    return '${_formatDate(startDate!)} to ${_formatDate(endDate!)}';
  }

  String _formatDate(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

class _TypeDropdown extends StatelessWidget {
  final String value;
  final ValueChanged<String?> onChanged;

  const _TypeDropdown({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButton<String>(
        value: value,
        underline: const SizedBox(),
        items: const [DropdownMenuItem(value: 'online', child: Text('Online'))],
        onChanged: onChanged,
      ),
    );
  }
}

class _LoadButton extends StatelessWidget {
  final bool isLoading;
  final VoidCallback onPressed;

  const _LoadButton({required this.isLoading, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: isLoading ? null : onPressed,
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF2563EB),
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
      ),
      child: isLoading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.white,
              ),
            )
          : const Text('Load Report'),
    );
  }
}
