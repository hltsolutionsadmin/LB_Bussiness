import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:local_basket_business/core/network/dio_client.dart';
import 'package:local_basket_business/core/storage/secure_storage.dart';
import 'package:local_basket_business/data/datasources/business/business_remote_data_source.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:local_basket_business/presentation/widgets/map_picker.dart';

class RestaurantOnboardingScreen extends StatefulWidget {
  final VoidCallback onBack;
  const RestaurantOnboardingScreen({super.key, required this.onBack});

  @override
  State<RestaurantOnboardingScreen> createState() =>
      _RestaurantOnboardingScreenState();
}

class _RestaurantOnboardingScreenState
    extends State<RestaurantOnboardingScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _ownerController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _gstController = TextEditingController();
  final _fssaiController = TextEditingController();
  final _cityController = TextEditingController();
  final _countryController = TextEditingController(text: 'india');
  final _postalController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  final _categoryIdController = TextEditingController(text: '1');
  final _loginTimeController = TextEditingController();
  final _logoutTimeController = TextEditingController();

  late final BusinessRemoteDataSource _remote;

  String _selectedCuisine = 'North Indian';
  bool _isLoading = false;

  final List<String> _cuisines = const [
    'North Indian',
    'South Indian',
    'Chinese',
    'Italian',
    'Japanese',
    'Mexican',
    'Continental',
    'Fast Food',
  ];

  @override
  void initState() {
    super.initState();
    _remote = BusinessRemoteDataSource(DioClient(Dio()), AppSecureStorage());
  }

  @override
  void dispose() {
    _nameController.dispose();
    _ownerController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _gstController.dispose();
    _fssaiController.dispose();
    _cityController.dispose();
    _countryController.dispose();
    _postalController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    _categoryIdController.dispose();
    _loginTimeController.dispose();
    _logoutTimeController.dispose();
    super.dispose();
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _remote.onboardBusiness(
        businessName: _nameController.text.trim(),
        categoryId: _categoryIdController.text.trim(),
        addressLine1: _addressController.text.trim(),
        city: _cityController.text.trim(),
        country: _countryController.text.trim(),
        postalCode: _postalController.text.trim(),
        latitude: _latitudeController.text.trim(),
        longitude: _longitudeController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        gstNumber: _gstController.text.trim().isEmpty
            ? null
            : _gstController.text.trim(),
        fssaiNumber: _fssaiController.text.trim().isEmpty
            ? null
            : _fssaiController.text.trim(),
        loginTime: _loginTimeController.text.trim().isEmpty
            ? null
            : _loginTimeController.text.trim(),
        logoutTime: _logoutTimeController.text.trim().isEmpty
            ? null
            : _logoutTimeController.text.trim(),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to add restaurant: $e'),
          backgroundColor: AppColors.error,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Restaurant added successfully!'),
        backgroundColor: AppColors.success,
      ),
    );
    widget.onBack();
    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: AppColors.glass),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  GlassCard(
                        child: Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.arrow_back),
                              onPressed: widget.onBack,
                              color: AppColors.textPrimary,
                            ),
                            const SizedBox(width: 8),
                            const Expanded(
                              child: Text(
                                'Add New Restaurant',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.textPrimary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(duration: 300.ms)
                      .slideX(begin: -0.2, end: 0, duration: 300.ms),
                  const SizedBox(height: 24),
                  GlassCard(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Restaurant Details',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            const SizedBox(height: 20),
                            _buildTextField(
                              controller: _nameController,
                              label: 'Restaurant Name',
                              icon: Icons.restaurant,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter restaurant name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _ownerController,
                              label: 'Owner Name',
                              icon: Icons.person,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter owner name'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _emailController,
                              label: 'Email',
                              icon: Icons.email,
                              keyboardType: TextInputType.emailAddress,
                              validator: (v) {
                                if (v == null || v.isEmpty) {
                                  return 'Please enter email';
                                }
                                if (!v.contains('@')) {
                                  return 'Please enter a valid email';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              icon: Icons.phone,
                              keyboardType: TextInputType.phone,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter phone number'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _addressController,
                              label: 'Address',
                              icon: Icons.location_on,
                              maxLines: 3,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter address'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _cityController,
                              label: 'City',
                              icon: Icons.location_city,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter city'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _countryController,
                              label: 'Country',
                              icon: Icons.flag,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter country'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _postalController,
                              label: 'Postal Code',
                              icon: Icons.markunread_mailbox,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter postal code'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _categoryIdController,
                              label: 'Category ID',
                              icon: Icons.category,
                              keyboardType: TextInputType.number,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter category id'
                                  : null,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _latitudeController,
                                    label: 'Latitude',
                                    icon: Icons.my_location,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Enter latitude'
                                        : null,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _longitudeController,
                                    label: 'Longitude',
                                    icon: Icons.explore,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                          decimal: true,
                                        ),
                                    validator: (v) => v == null || v.isEmpty
                                        ? 'Enter longitude'
                                        : null,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () async {
                                  final result = await Navigator.of(context)
                                      .push<LatLng?>(
                                        MaterialPageRoute(
                                          builder: (_) {
                                            final lat = double.tryParse(
                                              _latitudeController.text.trim(),
                                            );
                                            final lng = double.tryParse(
                                              _longitudeController.text.trim(),
                                            );
                                            final initial =
                                                (lat != null && lng != null)
                                                ? LatLng(lat, lng)
                                                : const LatLng(
                                                    17.686001,
                                                    83.008781,
                                                  );
                                            return MapPicker(initial: initial);
                                          },
                                        ),
                                      );
                                  if (result != null) {
                                    _latitudeController.text = result.latitude
                                        .toStringAsFixed(6);
                                    _longitudeController.text = result.longitude
                                        .toStringAsFixed(6);
                                    setState(() {});
                                  }
                                },
                                icon: const Icon(
                                  Icons.map,
                                  color: AppColors.orange600,
                                ),
                                label: const Text('Pick from Map'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            _buildDropdown(),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _gstController,
                              label: 'GST Number (Optional)',
                              icon: Icons.receipt,
                            ),
                            const SizedBox(height: 16),
                            _buildTextField(
                              controller: _fssaiController,
                              label: 'FSSAI Number (Optional)',
                              icon: Icons.shield,
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildTextField(
                                    controller: _loginTimeController,
                                    label: 'Login Time (HH:mm)',
                                    icon: Icons.login,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildTextField(
                                    controller: _logoutTimeController,
                                    label: 'Logout Time (HH:mm)',
                                    icon: Icons.logout,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms),
                  const SizedBox(height: 24),
                  GradientButton(
                        text: 'Add Restaurant',
                        onPressed: _submitForm,
                        isLoading: _isLoading,
                        isFullWidth: true,
                        icon: Icons.add,
                      )
                      .animate()
                      .fadeIn(delay: 200.ms, duration: 300.ms)
                      .slideY(begin: 0.1, end: 0, duration: 300.ms),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.orange600),
      ),
      keyboardType: keyboardType,
      maxLines: maxLines,
      validator: validator,
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }

  Widget _buildDropdown() {
    return DropdownButtonFormField<String>(
      initialValue: _selectedCuisine,
      decoration: const InputDecoration(
        labelText: 'Cuisine Type',
        prefixIcon: Icon(Icons.fastfood, color: AppColors.orange600),
      ),
      dropdownColor: AppColors.red900,
      items: _cuisines
          .map(
            (cuisine) => DropdownMenuItem(
              value: cuisine,
              child: Text(
                cuisine,
                style: const TextStyle(color: AppColors.textPrimary),
              ),
            ),
          )
          .toList(),
      onChanged: (value) {
        if (value != null) setState(() => _selectedCuisine = value);
      },
      style: const TextStyle(color: AppColors.textPrimary),
    );
  }
}

class GlassCard extends StatelessWidget {
  final Widget child;
  const GlassCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: AppColors.cardGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.glassBorder, width: 1),
      ),
      padding: const EdgeInsets.all(16),
      child: child,
    );
  }
}

class GradientButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;
  final bool isLoading;
  final bool isFullWidth;
  final IconData? icon;
  const GradientButton({
    super.key,
    required this.text,
    required this.onPressed,
    this.isLoading = false,
    this.isFullWidth = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final child = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
            ),
          )
        else ...[
          if (icon != null) ...[
            Icon(icon, color: Colors.white),
            const SizedBox(width: 8),
          ],
          Text(
            text,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ],
    );

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      height: 56,
      child: DecoratedBox(
        decoration: const BoxDecoration(
          gradient: AppColors.buttonGradient,
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            shadowColor: Colors.transparent,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
          onPressed: isLoading ? null : onPressed,
          child: child,
        ),
      ),
    );
  }
}
