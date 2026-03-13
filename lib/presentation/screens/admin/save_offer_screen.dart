import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/data/datasources/offers/offers_remote_data_source.dart';
import 'package:local_basket_business/data/models/offers/offer_models.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:local_basket_business/widgets/glass_card.dart';

class SaveOfferScreen extends StatefulWidget {
  final int businessId;
  const SaveOfferScreen({super.key, required this.businessId});

  @override
  State<SaveOfferScreen> createState() => _SaveOfferScreenState();
}

class _SaveOfferScreenState extends State<SaveOfferScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameCtrl = TextEditingController();
  final _minOrderCtrl = TextEditingController(text: '1');
  final _couponCtrl = TextEditingController();
  final _descCtrl = TextEditingController(text: '');
  final _targetTypeCtrl = TextEditingController(text: 'LUCKY_ONE_RUPEE');
  final _windowMinutesCtrl = TextEditingController(text: '10');
  final _maxClaimsCtrl = TextEditingController(text: '1');

  bool _active = true;
  DateTime _start = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  );
  DateTime _end = DateTime(
    DateTime.now().year,
    DateTime.now().month,
    DateTime.now().day,
  ).add(const Duration(days: 14));

  bool _saving = false;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _minOrderCtrl.dispose();
    _couponCtrl.dispose();
    _descCtrl.dispose();
    _targetTypeCtrl.dispose();
    _windowMinutesCtrl.dispose();
    _maxClaimsCtrl.dispose();
    super.dispose();
  }

  InputDecoration _dec({required String label, IconData? icon, String? hint}) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon == null ? null : Icon(icon),
      filled: true,
      fillColor: const Color(0xFFF4F6FA),
      border: InputBorder.none,
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    );
  }

  String _dateLabel(DateTime d) {
    String two(int v) => v < 10 ? '0$v' : '$v';
    return '${d.year}-${two(d.month)}-${two(d.day)} ${two(d.hour)}:${two(d.minute)}';
  }

  Future<DateTime?> _pickDateTime({required DateTime initial}) async {
    final pickedDate = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: initial,
    );
    if (pickedDate == null) return null;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: initial.hour, minute: initial.minute),
      builder: (context, child) {
        final media = MediaQuery.of(context);
        return MediaQuery(
          data: media.copyWith(alwaysUse24HourFormat: true),
          child: child!,
        );
      },
    );
    if (pickedTime == null) return null;

    return DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
  }

  Future<void> _pickStart() async {
    final picked = await _pickDateTime(initial: _start);
    if (picked == null) return;
    setState(() {
      _start = picked;
      if (_end.isBefore(_start)) {
        _end = _start;
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await _pickDateTime(initial: _end);
    if (picked == null) return;
    setState(() {
      _end = picked;
      if (_end.isBefore(_start)) {
        _start = DateTime(_end.year, _end.month, _end.day);
      }
    });
  }

  Future<void> _save() async {
    if (_saving) return;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final minOrder = double.tryParse(_minOrderCtrl.text.trim()) ?? 0;
    if (minOrder <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Min order value must be greater than 0')),
      );
      return;
    }

    final windowMinutes = int.tryParse(_windowMinutesCtrl.text.trim()) ?? 0;
    if (windowMinutes <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Window minutes must be greater than 0')),
      );
      return;
    }

    final maxClaims = int.tryParse(_maxClaimsCtrl.text.trim()) ?? 0;
    if (maxClaims <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Max claims per window must be greater than 0'),
        ),
      );
      return;
    }

    const categoryIds = <int>[5];

    setState(() => _saving = true);
    try {
      final req = SaveOfferRequest(
        name: _nameCtrl.text.trim(),
        offerType: 'FLAT',
        value: 50.00,
        minOrderValue: minOrder,
        couponCode: _couponCtrl.text.trim(),
        startDate: _start,
        endDate: _end,
        businessId: widget.businessId,
        active: _active,
        description: _descCtrl.text.trim(),
        targetType: _targetTypeCtrl.text.trim(),
        windowMinutes: windowMinutes,
        maxClaimsPerWindow: maxClaims,
        productIds: const [],
        categoryIds: categoryIds,
      );

      await GetIt.I<OffersRemoteDataSource>().saveOffer(req);

      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Offer saved successfully')));
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Failed to save offer')));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GlassCard(
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back),
                        onPressed: () => Navigator.of(context).pop(false),
                        color: AppColors.textPrimary,
                      ),
                      const SizedBox(width: 8),
                      const Expanded(
                        child: Text(
                          'Create Offer',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.glass,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: AppColors.glassBorder),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              'Active',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Switch.adaptive(
                              value: _active,
                              onChanged: (v) => setState(() => _active = v),
                              activeColor: AppColors.orange600,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                GlassCard(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Offer Details',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _nameCtrl,
                            decoration: _dec(
                              label: 'Name',
                              icon: Icons.badge_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Name is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _minOrderCtrl,
                            keyboardType: TextInputType.number,
                            decoration: _dec(
                              label: 'Min Order Value',
                              icon: Icons.currency_rupee,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Min order value is required';
                              }
                              final parsed = double.tryParse(v.trim());
                              if (parsed == null) return 'Invalid number';
                              if (parsed <= 0) return 'Must be > 0';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _couponCtrl,
                            decoration: _dec(
                              label: 'Coupon Code',
                              icon: Icons.discount_outlined,
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Coupon code is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _targetTypeCtrl,
                            decoration: _dec(
                              label: 'Target Type',
                              icon: Icons.bolt_outlined,
                              hint: 'e.g. LUCKY_ONE_RUPEE',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Target type is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _windowMinutesCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec(
                                    label: 'Window Minutes',
                                    icon: Icons.timer_outlined,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = int.tryParse(v.trim());
                                    if (parsed == null) return 'Invalid';
                                    if (parsed <= 0) return 'Must be > 0';
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
                                  controller: _maxClaimsCtrl,
                                  keyboardType: TextInputType.number,
                                  decoration: _dec(
                                    label: 'Max Claims / Window',
                                    icon: Icons.groups_outlined,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Required';
                                    }
                                    final parsed = int.tryParse(v.trim());
                                    if (parsed == null) return 'Invalid';
                                    if (parsed <= 0) return 'Must be > 0';
                                    return null;
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: _DateField(
                                  label: 'Start Date',
                                  value: _dateLabel(_start),
                                  onTap: _pickStart,
                                  decoration: _dec(
                                    label: 'Start Date',
                                    icon: Icons.calendar_month,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _DateField(
                                  label: 'End Date',
                                  value: _dateLabel(_end),
                                  onTap: _pickEnd,
                                  decoration: _dec(
                                    label: 'End Date',
                                    icon: Icons.event,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          TextFormField(
                            controller: _descCtrl,
                            maxLines: 3,
                            decoration: _dec(
                              label: 'Description',
                              icon: Icons.notes_outlined,
                            ),
                          ),
                          const SizedBox(height: 16),
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: ElevatedButton(
                              onPressed: _saving ? null : _save,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.orange600,
                                foregroundColor: Colors.white,
                              ),
                              child: _saving
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2.5,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      'Save Offer',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _DateField extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;
  final InputDecoration decoration;

  const _DateField({
    required this.label,
    required this.value,
    required this.onTap,
    required this.decoration,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: InputDecorator(
        decoration: decoration,
        child: Text(
          value,
          style: const TextStyle(
            color: AppColors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}
