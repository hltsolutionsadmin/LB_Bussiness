import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:local_basket_business/core/session/session_store.dart';
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
  final _fullNameController = TextEditingController();
  final _displayNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _maxAssignmentsController = TextEditingController(text: '1');
  final _specializationsController = TextEditingController();
  final _sessionModeController = TextEditingController();

  String _vehicleType = 'Two wheeler';
  bool _submitting = false;

  @override
  void dispose() {
    _vehicleController.dispose();
    _mobileController.dispose();
    _fullNameController.dispose();
    _displayNameController.dispose();
    _bioController.dispose();
    _maxAssignmentsController.dispose();
    _specializationsController.dispose();
    _sessionModeController.dispose();
    super.dispose();
  }

  String _extractAgentId(dynamic data) {
    if (data is Map<String, dynamic>) {
      final direct = data['id'] ?? data['agentId'] ?? data['deliveryPartnerId'];
      final directText = direct?.toString() ?? '';
      if (directText.isNotEmpty) return directText;

      final nested = data['data'];
      if (nested != null) {
        final nestedId = _extractAgentId(nested);
        if (nestedId.isNotEmpty) return nestedId;
      }

      final agent = data['agent'];
      if (agent != null) {
        final agentId = _extractAgentId(agent);
        if (agentId.isNotEmpty) return agentId;
      }
    }
    return '';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _submitting = true);
    try {
      final ds = GetIt.I<DeliveryRemoteDataSource>();
      final session = GetIt.I<SessionStore>();

      final resolvedB2BUnitId = session.b2bUnitId;
      if (resolvedB2BUnitId.isEmpty) {
        throw StateError('B2B unit ID not found');
      }

      final res = await ds.addPartner(
        vehicleNumber: _vehicleController.text.trim(),
        mobileNumber: _mobileController.text.trim(),
        fullName: _fullNameController.text.trim(),
        b2bUnitId: resolvedB2BUnitId,
        displayName: _displayNameController.text.trim().isEmpty
            ? _fullNameController.text.trim()
            : _displayNameController.text.trim(),
        bio: _bioController.text.trim(),
        maxConcurrentAssignments:
            int.tryParse(_maxAssignmentsController.text.trim()) ?? 1,
        vehicleType: _vehicleType,
        specializations: _specializationsController.text.trim(),
        sessionMode: _sessionModeController.text.trim(),
      );
      final agentId = _extractAgentId(res);
      if (agentId.isEmpty) {
        throw StateError('Delivery partner ID not found for verification');
      }

      final verified = await ds.verifyAgent(agentId: agentId);
      if (!mounted) return;
      Navigator.of(context).pop(verified);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Failed to add and activate partner'),
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
                        'Partner Details',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _mobileController,
                        keyboardType: TextInputType.phone,
                        maxLength: 10,
                        decoration: InputDecoration(
                          labelText: 'Mobile Number',
                          hintText: '0000000000',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.phone_android),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          counterText: "", // This removes 10/10 counter
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Mobile number is required';
                          if (t.length != 10) {
                            return 'Enter a valid 10 digit mobile number';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _fullNameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name',
                          hintText: 'Full Name',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.person),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          final t = v?.trim() ?? '';
                          if (t.isEmpty) return 'Full name is required';
                          if (t.length < 2) {
                            return 'Enter a valid full name';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _displayNameController,
                        decoration: InputDecoration(
                          labelText: 'Display Name',
                          hintText: 'rahulk',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.badge_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _bioController,
                        decoration: InputDecoration(
                          labelText: 'Bio',
                          hintText: 'nothing',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.notes_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 20),
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
                          labelText: 'Vehicle Registration',
                          hintText: '12-20-21',
                          hintStyle: const TextStyle(color: Colors.grey),
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
                          if (t.isEmpty) {
                            return 'Vehicle registration is required';
                          }
                          if (t.length < 4) {
                            return 'Enter a valid vehicle registration';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: _vehicleType,
                        decoration: InputDecoration(
                          labelText: 'Vehicle Type',
                          prefixIcon: const Icon(Icons.two_wheeler_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'Two wheeler',
                            child: Text('Two wheeler'),
                          ),
                          DropdownMenuItem(
                            value: 'Three wheeler',
                            child: Text('Three wheeler'),
                          ),
                          DropdownMenuItem(
                            value: 'Four wheeler',
                            child: Text('Four wheeler'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value == null) return;
                          setState(() => _vehicleType = value);
                        },
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _maxAssignmentsController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          labelText: 'Max Concurrent Assignments',
                          hintText: '1',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.format_list_numbered),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                        validator: (v) {
                          final value = int.tryParse(v?.trim() ?? '');
                          if (value == null || value < 1) {
                            return 'Enter at least 1 assignment';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _specializationsController,
                        decoration: InputDecoration(
                          labelText: 'Specializations',
                          hintText: 'Optional',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.star_border_rounded),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _sessionModeController,
                        decoration: InputDecoration(
                          labelText: 'Session Mode',
                          hintText: 'Optional',
                          hintStyle: const TextStyle(color: Colors.grey),
                          prefixIcon: const Icon(Icons.schedule_outlined),
                          filled: true,
                          fillColor: const Color(0xFFF4F6FA),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

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
                              color: Colors.black,
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
