import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

class MapPicker extends StatefulWidget {
  const MapPicker({super.key, required this.initial});
  final LatLng initial;

  @override
  State<MapPicker> createState() => _MapPickerState();
}

class _MapPickerState extends State<MapPicker> {
  LatLng? _selected;
  GoogleMapController? _controller;

  @override
  void initState() {
    super.initState();
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pick Location'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop<LatLng?>(_selected);
            },
            child: const Text('Done'),
          ),
        ],
      ),
      body: GoogleMap(
        initialCameraPosition: CameraPosition(target: widget.initial, zoom: 16),
        markers: {
          if (_selected != null)
            Marker(markerId: const MarkerId('sel'), position: _selected!),
        },
        onMapCreated: (c) => _controller = c,
        onTap: (pos) {
          setState(() => _selected = pos);
        },
        myLocationEnabled: true,
        myLocationButtonEnabled: true,
        compassEnabled: true,
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          if (_controller != null) {
            _controller!.animateCamera(
              CameraUpdate.newLatLng(_selected ?? widget.initial),
            );
          }
        },
        icon: const Icon(Icons.center_focus_strong),
        label: const Text('Center'),
      ),
    );
  }
}
