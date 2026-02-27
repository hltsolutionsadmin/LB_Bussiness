import 'package:flutter/material.dart';
import 'package:dio/dio.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';

class MapPickerResult {
  const MapPickerResult({required this.location, required this.placemark});
  final LatLng location;
  final Placemark placemark;
}

class MapPicker extends StatefulWidget {
  const MapPicker({super.key, required this.initial});
  final LatLng initial;

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  LatLng? _selected;
  Placemark? _placemark;
  String _address = 'Fetching address...';
  bool _isLoading = false;

  final MapController _controller = MapController();

  final Dio _searchDio = Dio(
    BaseOptions(
      headers: {
        'User-Agent': 'local_basket_business (Flutter; OSM Nominatim search)',
      },
    ),
  );

  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
    _fetchCurrentLocation();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchCurrentLocation() async {
    setState(() => _isLoading = true);
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Location services are disabled')),
        );
        return;
      }

      var perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.deniedForever) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permissions are permanently denied'),
          ),
        );
        return;
      }

      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm != LocationPermission.whileInUse &&
            perm != LocationPermission.always) {
          return;
        }
      }

      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      final current = LatLng(pos.latitude, pos.longitude);
      _controller.move(current, 15);
      setState(() => _selected = current);
      await _getAddressFromLatLng(current);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error getting location: $e')));
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _getAddressFromLatLng(LatLng latLng) async {
    setState(() {
      _address = 'Fetching address...';
      _isLoading = true;
    });
    try {
      final places = await placemarkFromCoordinates(
        latLng.latitude,
        latLng.longitude,
      );
      if (places.isEmpty) {
        setState(() => _address = 'No address found');
        return;
      }

      final p = places.first;
      final parts =
          <String?>[
                p.street,
                p.subLocality,
                p.locality,
                p.administrativeArea,
                p.postalCode,
                p.country,
              ]
              .whereType<String>()
              .map((e) => e.trim())
              .where((e) => e.isNotEmpty)
              .toList();

      setState(() {
        _placemark = p;
        _address = parts.isEmpty ? 'No address found' : parts.join(', ');
      });
    } catch (_) {
      setState(() => _address = 'Failed to fetch address');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _onMapTap(LatLng point) {
    setState(() {
      _selected = point;
      _placemark = null;
      _address = 'Fetching address...';
    });
    _getAddressFromLatLng(point);
  }

  Future<List<_SearchResult>> _nominatimSearch(String query) async {
    final res = await _searchDio.get(
      'https://nominatim.openstreetmap.org/search',
      queryParameters: {'format': 'json', 'q': query, 'limit': 8},
    );
    final data = res.data;
    if (data is! List) return const [];
    return data
        .whereType<Map>()
        .map((e) => _SearchResult.fromJson(Map<String, dynamic>.from(e)))
        .where((e) => e.lat != null && e.lon != null)
        .toList();
  }

  Future<void> _searchPlace() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    try {
      final results = await _nominatimSearch(query);
      if (!mounted) return;
      if (results.isEmpty) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('No results found')));
        return;
      }

      final picked = await showModalBottomSheet<_SearchResult>(
        context: context,
        showDragHandle: true,
        builder: (ctx) {
          return SafeArea(
            child: ListView.separated(
              itemCount: results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (_, i) {
                final r = results[i];
                return ListTile(
                  leading: const Icon(Icons.place_outlined),
                  title: Text(r.displayName ?? ''),
                  onTap: () => Navigator.of(ctx).pop(r),
                );
              },
            ),
          );
        },
      );

      if (picked == null || picked.lat == null || picked.lon == null) return;
      final ll = LatLng(picked.lat!, picked.lon!);
      _controller.move(ll, 16);
      setState(() => _selected = ll);
      await _getAddressFromLatLng(ll);
    } catch (_) {
      // ignore
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          IconButton(
            tooltip: 'Search',
            icon: const Icon(Icons.search),
            onPressed: () async {
              final q = await showDialog<String>(
                context: context,
                builder: (ctx) {
                  final controller = TextEditingController(
                    text: _searchController.text,
                  );
                  return AlertDialog(
                    title: const Text('Search location'),
                    content: TextField(
                      controller: controller,
                      autofocus: true,
                      decoration: const InputDecoration(
                        hintText: 'Enter area / address',
                      ),
                      textInputAction: TextInputAction.search,
                      onSubmitted: (v) => Navigator.of(ctx).pop(v),
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: const Text('Cancel'),
                      ),
                      ElevatedButton(
                        onPressed: () =>
                            Navigator.of(ctx).pop(controller.text.trim()),
                        child: const Text('Search'),
                      ),
                    ],
                  );
                },
              );
              if (q == null || q.trim().isEmpty) return;
              _searchController.text = q.trim();
              await _searchPlace();
            },
          ),
          TextButton(
            onPressed: () {
              if (_selected == null || _placemark == null) return;
              Navigator.of(context).pop(
                MapPickerResult(location: _selected!, placemark: _placemark!),
              );
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: Stack(
        children: [
          FlutterMap(
            mapController: _controller,
            options: MapOptions(
              initialCenter: _selected ?? widget.initial,
              initialZoom: 15,
              onTap: (_, p) => _onMapTap(p),
            ),
            children: [
              TileLayer(
                urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                userAgentPackageName: 'local_basket_business',
              ),
              if (_selected != null)
                MarkerLayer(
                  markers: [
                    Marker(
                      point: _selected!,
                      width: 80,
                      height: 80,
                      child: const Icon(
                        Icons.location_pin,
                        size: 40,
                        color: Colors.red,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
          if (_selected != null && !_isLoading)
            Positioned(
              bottom: 20,
              left: 20,
              right: 20,
              child: Card(
                elevation: 2,
                color: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.location_pin, color: Colors.red, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'Selected Location',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _detailRow(
                              'Latitude:',
                              _selected!.latitude.toStringAsFixed(6),
                            ),
                            const SizedBox(height: 6),
                            _detailRow(
                              'Longitude:',
                              _selected!.longitude.toStringAsFixed(6),
                            ),
                            const SizedBox(height: 8),
                            const Divider(height: 1),
                            const SizedBox(height: 8),
                            Text(
                              'Address:',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.grey.shade700,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              _address,
                              style: const TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (_selected != null && _placemark != null)
                              ? () {
                                  Navigator.of(context).pop(
                                    MapPickerResult(
                                      location: _selected!,
                                      placemark: _placemark!,
                                    ),
                                  );
                                }
                              : null,
                          child: const Text('Use This Location'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: 'my_location',
            onPressed: _fetchCurrentLocation,
            child: const Icon(Icons.my_location),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: 'center',
            onPressed: () {
              _controller.move(_selected ?? widget.initial, 16);
              setState(() => _selected = _selected ?? widget.initial);
            },
            child: const Icon(Icons.center_focus_strong),
          ),
        ],
      ),
    );
  }
}

Widget _detailRow(String label, String value) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        label,
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.grey.shade700,
          fontSize: 14,
        ),
      ),
      const SizedBox(width: 8),
      Expanded(child: Text(value, style: const TextStyle(fontSize: 14))),
    ],
  );
}

class _SearchResult {
  const _SearchResult({this.displayName, this.lat, this.lon});

  final String? displayName;
  final double? lat;
  final double? lon;

  factory _SearchResult.fromJson(Map<String, dynamic> json) {
    double? parseNum(dynamic v) {
      if (v == null) return null;
      return double.tryParse(v.toString());
    }

    return _SearchResult(
      displayName: json['display_name']?.toString(),
      lat: parseNum(json['lat']),
      lon: parseNum(json['lon']),
    );
  }
}
