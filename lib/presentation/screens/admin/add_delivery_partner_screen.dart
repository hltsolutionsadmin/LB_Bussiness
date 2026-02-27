import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/data/datasources/delivery/delivery_remote_data_source.dart';

class AddDeliveryPartnerScreen extends StatefulWidget {
  const AddDeliveryPartnerScreen({super.key});

  @override
  State<AddDeliveryPartnerScreen> createState() =>
      _AddDeliveryPartnerScreenState();
}

class _AddDeliveryPartnerScreenState extends State<AddDeliveryPartnerScreen> {
  final _formKey = GlobalKey<FormState>();
  final _vehicleController = TextEditingController();
  final _mobileController = TextEditingController();

  bool _available = true;
  bool _submitting = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _mobileController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final ds = GetIt.I<DeliveryRemoteDataSource>();
      final res = await ds.addPartner(
        vehicleNumber: _vehicleController.text.trim(),
        available: _available,
        mobileNumber: _mobileController.text.trim(),
      );
      if (!mounted) return;
      Navigator.of(context).pop(res);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add partner'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      appBar: AppBar(
        title: const Text('Add Delivery Partner'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Vehicle Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _vehicleController,
                        textCapitalization: TextCapitalization.characters,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Number',
                          hintText: 'KA 05 AB 1234',
                          prefixIcon: const Icon(Icons.directions_bike),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Vehicle number is required';
                          if (t.length < 4) {
                            return 'Enter a valid vehicle number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),

                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '9295012126',
                          prefixIcon: const Icon(Icons.phone_android),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Mobile number is required';
                          if (t.length < 10) {
                            return 'Enter a valid mobile number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Available'),
                        subtitle: const Text('Ready for delivery'),
                        value: _available,
                        onChanged: (v) => setState(() => _available = v),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                /// 🔥 Premium Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,

                    style: ElevatedButton.styleFrom(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      backgroundColor: Colors.white,
                    ),
                    child: _submitting
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text(
                            'Add Partner',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: Colors.black,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
