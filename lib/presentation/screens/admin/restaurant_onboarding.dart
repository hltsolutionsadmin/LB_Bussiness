import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:local_basket_business/theme/app_colors.dart';
import 'package:dio/dio.dart';
import 'package:local_basket_business/core/env/env.dart';
import 'package:local_basket_business/di/locator.dart';
import 'package:local_basket_business/domain/repositories/business/business_repository.dart';
import 'package:local_basket_business/core/session/session_store.dart';
import 'package:geocoding/geocoding.dart';
import 'package:latlong2/latlong.dart';
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
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _countryController = TextEditingController(text: 'india');
  final _postalController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();

  late final BusinessRepository _repo;

  final Dio _placesDio = Dio();
  Timer? _placesDebounce;
  bool _isPlacesLoading = false;
  List<_PlacesPrediction> _placesPredictions = const [];

  bool _isReverseGeocoding = false;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _repo = sl<BusinessRepository>();
    _addressController.addListener(_onAddressChanged);
  }

  void _fillFromPlacemark(Placemark p) {
    final parts = <String?>[
      p.street,
      p.subLocality,
      p.locality,
      p.administrativeArea,
      p.postalCode,
      p.country,
    ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty);
    final formatted = parts.join(', ');

    if (formatted.isNotEmpty) {
      _addressController.text = formatted;
      _addressController.selection = TextSelection.fromPosition(
        TextPosition(offset: _addressController.text.length),
      );
      setState(() {
        _placesPredictions = const [];
        _isPlacesLoading = false;
      });
    }

    final city = (p.locality ?? '').trim();
    final state = (p.administrativeArea ?? '').trim();
    final country = (p.country ?? '').trim();
    final postal = (p.postalCode ?? '').trim();

    if (city.isNotEmpty) _cityController.text = city;
    if (state.isNotEmpty) _stateController.text = state;
    if (country.isNotEmpty) _countryController.text = country;
    if (postal.isNotEmpty) _postalController.text = postal;
  }

  Future<void> _reverseGeocode(double lat, double lng) async {
    setState(() => _isReverseGeocoding = true);
    try {
      final places = await placemarkFromCoordinates(lat, lng);
      if (places.isEmpty) return;
      final p = places.first;

      final parts = <String?>[
        p.street,
        p.subLocality,
        p.locality,
        p.administrativeArea,
        p.postalCode,
        p.country,
      ].whereType<String>().map((e) => e.trim()).where((e) => e.isNotEmpty);
      final formatted = parts.join(', ');

      final city = (p.locality ?? '').trim();
      final state = (p.administrativeArea ?? '').trim();
      final country = (p.country ?? '').trim();
      final postal = (p.postalCode ?? '').trim();

      if (!mounted) return;
      if (formatted.isNotEmpty) {
        _addressController.text = formatted;
        _addressController.selection = TextSelection.fromPosition(
          TextPosition(offset: _addressController.text.length),
        );
        setState(() {
          _placesPredictions = const [];
          _isPlacesLoading = false;
        });
      }
      if (city.isNotEmpty) _cityController.text = city;
      if (state.isNotEmpty) _stateController.text = state;
      if (country.isNotEmpty) _countryController.text = country;
      if (postal.isNotEmpty) _postalController.text = postal;
    } catch (_) {
      // ignore
    } finally {
      if (mounted) {
        setState(() => _isReverseGeocoding = false);
      }
    }
  }

  @override
  void dispose() {
    _placesDebounce?.cancel();
    _addressController.removeListener(_onAddressChanged);
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _countryController.dispose();
    _postalController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  void _onAddressChanged() {
    final input = _addressController.text.trim();
    _placesDebounce?.cancel();
    _placesDebounce = Timer(const Duration(milliseconds: 350), () {
      if (!mounted) return;
      if (input.isEmpty) {
        setState(() {
          _placesPredictions = const [];
          _isPlacesLoading = false;
        });
        return;
      }
      _fetchPlaceAutocomplete(input);
    });
  }

  Future<void> _fetchPlaceAutocomplete(String input) async {
    final apiKey = EnvConfig.googleMapsApiKey;
    if (apiKey.isEmpty) {
      setState(() {
        _placesPredictions = const [];
        _isPlacesLoading = false;
      });
      return;
    }

    setState(() => _isPlacesLoading = true);
    try {
      final res = await _placesDio.get(
        'https://maps.googleapis.com/maps/api/place/autocomplete/json',
        queryParameters: {'input': input, 'key': apiKey},
      );

      final data = res.data;
      final preds = (data is Map<String, dynamic>)
          ? (data['predictions'] as List?)
          : null;

      final parsed = (preds ?? const [])
          .whereType<Map>()
          .map((e) => _PlacesPrediction.fromJson(Map<String, dynamic>.from(e)))
          .toList();

      if (!mounted) return;
      setState(() {
        _placesPredictions = parsed;
        _isPlacesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _placesPredictions = const [];
        _isPlacesLoading = false;
      });
    }
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final businessId = await _repo.onboardBusiness(
        businessName: _nameController.text.trim(),
        addressLine1: _addressController.text.trim(),
        city: _cityController.text.trim(),
        state: _stateController.text.trim(),
        country: _countryController.text.trim(),
        postalCode: _postalController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        latitude: _latitudeController.text.trim(),
        longitude: _longitudeController.text.trim(),
      );

      final roles = sl<SessionStore>().roleNames;
      final isSuperAdmin = roles.contains('ROLE_SUPER_ADMIN');
      if (isSuperAdmin && businessId != null && businessId > 0) {
        await _repo.approveBusiness(businessId: businessId);
      }
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
                            if (_isPlacesLoading)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            if (_isReverseGeocoding)
                              const Padding(
                                padding: EdgeInsets.only(top: 8),
                                child: LinearProgressIndicator(minHeight: 2),
                              ),
                            if (_placesPredictions.isNotEmpty)
                              Container(
                                margin: const EdgeInsets.only(top: 8),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: AppColors.glassBorder,
                                  ),
                                ),
                                child: ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: _placesPredictions.length,
                                  separatorBuilder: (_, __) => Divider(
                                    height: 1,
                                    color: AppColors.glassBorder,
                                  ),
                                  itemBuilder: (context, index) {
                                    final p = _placesPredictions[index];
                                    return ListTile(
                                      dense: true,
                                      leading: const Icon(
                                        Icons.place,
                                        color: AppColors.orange600,
                                      ),
                                      title: Text(
                                        p.description,
                                        style: const TextStyle(
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                      onTap: () {
                                        _addressController.text = p.description;
                                        _addressController.selection =
                                            TextSelection.fromPosition(
                                              TextPosition(
                                                offset: _addressController
                                                    .text
                                                    .length,
                                              ),
                                            );
                                        setState(() {
                                          _placesPredictions = const [];
                                          _isPlacesLoading = false;
                                        });
                                        FocusScope.of(context).unfocus();
                                      },
                                    );
                                  },
                                ),
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
                              controller: _stateController,
                              label: 'State',
                              icon: Icons.map_outlined,
                              validator: (v) => v == null || v.isEmpty
                                  ? 'Please enter state'
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
                                      .push(
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
                                  final MapPickerResult? picked =
                                      result is MapPickerResult ? result : null;
                                  if (picked == null) return;

                                  _latitudeController.text = picked
                                      .location
                                      .latitude
                                      .toStringAsFixed(6);
                                  _longitudeController.text = picked
                                      .location
                                      .longitude
                                      .toStringAsFixed(6);

                                  _fillFromPlacemark(picked.placemark);
                                  if (_addressController.text.trim().isEmpty) {
                                    await _reverseGeocode(
                                      picked.location.latitude,
                                      picked.location.longitude,
                                    );
                                  }

                                  setState(() {});
                                },
                                icon: const Icon(
                                  Icons.map,
                                  color: AppColors.orange600,
                                ),
                                label: const Text('Pick from Map'),
                              ),
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
}

class _PlacesPrediction {
  const _PlacesPrediction({required this.description, required this.placeId});

  final String description;
  final String placeId;

  factory _PlacesPrediction.fromJson(Map<String, dynamic> json) {
    return _PlacesPrediction(
      description: (json['description'] ?? '').toString(),
      placeId: (json['place_id'] ?? '').toString(),
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
