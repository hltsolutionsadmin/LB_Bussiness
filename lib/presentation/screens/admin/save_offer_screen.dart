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
  final _offerTypeCtrl = TextEditingController(text: 'LUCKY_ONE_RUPEE');
  final _valueCtrl = TextEditingController(text: '1');
  final _minOrderCtrl = TextEditingController(text: '1');
  final _couponCtrl = TextEditingController();
  final _descCtrl = TextEditingController(text: '');

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
    _offerTypeCtrl.dispose();
    _valueCtrl.dispose();
    _minOrderCtrl.dispose();
    _couponCtrl.dispose();
    _descCtrl.dispose();
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
    return '${d.year}-${two(d.month)}-${two(d.day)}';
  }

  Future<void> _pickStart() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _start,
    );
    if (picked == null) return;
    setState(() {
      _start = DateTime(picked.year, picked.month, picked.day);
      if (_end.isBefore(_start)) {
        _end = _start;
      }
    });
  }

  Future<void> _pickEnd() async {
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      initialDate: _end,
    );
    if (picked == null) return;
    setState(() {
      _end = DateTime(picked.year, picked.month, picked.day, 23, 59, 59);
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

    setState(() => _saving = true);
    try {
      final req = SaveOfferRequest(
        name: _nameCtrl.text.trim(),
        offerType: _offerTypeCtrl.text.trim(),
        value: _valueCtrl.text.trim(),
        minOrderValue: minOrder,
        couponCode: _couponCtrl.text.trim(),
        startDate: _start,
        endDate: _end,
        businessId: widget.businessId,
        active: _active,
        description: _descCtrl.text.trim(),
        productIds: const [],
        categoryIds: const [],
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
                            controller: _offerTypeCtrl,
                            decoration: _dec(
                              label: 'Offer Type',
                              icon: Icons.category_outlined,
                              hint: 'e.g. LUCKY_ONE_RUPEE',
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Offer type is required';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: TextFormField(
                                  controller: _valueCtrl,
                                  decoration: _dec(
                                    label: 'Value',
                                    icon: Icons.confirmation_number_outlined,
                                  ),
                                  validator: (v) {
                                    if (v == null || v.trim().isEmpty) {
                                      return 'Value is required';
                                    }
                                    return null;
                                  },
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: TextFormField(
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
                              ),
                            ],
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
