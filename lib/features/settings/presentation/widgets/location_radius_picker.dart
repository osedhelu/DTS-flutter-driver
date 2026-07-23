import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/location_radius_constants.dart';
import '../../../../core/widgets/widgets.dart';

class LocationRadiusResult {
  const LocationRadiusResult({
    required this.latitude,
    required this.longitude,
    required this.radiusKm,
  });

  final double latitude;
  final double longitude;
  final double radiusKm;
}

/// Mapa + dropdown de radio + botón Aplicar ("Cambiar ubicación").
class LocationRadiusPicker extends StatefulWidget {
  const LocationRadiusPicker({
    super.key,
    this.initialLatitude,
    this.initialLongitude,
    this.initialRadiusKm = defaultRadiusKm,
  });

  final double? initialLatitude;
  final double? initialLongitude;
  final double initialRadiusKm;

  static Future<LocationRadiusResult?> show(
    BuildContext context, {
    double? initialLatitude,
    double? initialLongitude,
    double initialRadiusKm = defaultRadiusKm,
  }) {
    return Navigator.of(context).push<LocationRadiusResult>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => LocationRadiusPicker(
          initialLatitude: initialLatitude,
          initialLongitude: initialLongitude,
          initialRadiusKm: initialRadiusKm,
        ),
      ),
    );
  }

  @override
  State<LocationRadiusPicker> createState() => _LocationRadiusPickerState();
}

class _LocationRadiusPickerState extends State<LocationRadiusPicker> {
  static const _defaultCenter = LatLng(4.711, -74.072);

  late LatLng _center;
  late double _radiusKm;
  bool _loading = true;
  bool _myLocationEnabled = false;
  String? _locationHint;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _radiusKm = normalizeRadiusPreset(widget.initialRadiusKm);
    _center = LatLng(
      widget.initialLatitude ?? _defaultCenter.latitude,
      widget.initialLongitude ?? _defaultCenter.longitude,
    );
    _initCenter();
  }

  Future<void> _initCenter() async {
    if (widget.initialLatitude != null && widget.initialLongitude != null) {
      setState(() {
        _loading = false;
        _myLocationEnabled = true;
      });
      return;
    }
    await _moveToGps(updateState: true);
  }

  Future<void> _moveToGps({required bool updateState}) async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (!mounted) return;
        if (updateState) {
          setState(() {
            _loading = false;
            _locationHint =
                'Activa el GPS para centrar el mapa en tu ubicación.';
          });
        }
        return;
      }

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        if (!mounted) return;
        if (updateState) {
          setState(() {
            _loading = false;
            _locationHint =
                'Sin permiso de ubicación: toca el mapa para elegir el centro.';
          });
        }
        return;
      }

      final pos = await Geolocator.getCurrentPosition();
      if (!mounted) return;
      final target = LatLng(pos.latitude, pos.longitude);
      if (updateState) {
        setState(() {
          _center = target;
          _loading = false;
          _myLocationEnabled = true;
          _locationHint = null;
        });
      } else {
        setState(() {
          _center = target;
          _myLocationEnabled = true;
          _locationHint = null;
        });
      }
      await _mapController?.animateCamera(
        CameraUpdate.newLatLng(target),
      );
    } catch (_) {
      if (!mounted) return;
      if (updateState) {
        setState(() {
          _loading = false;
          _locationHint = 'No se pudo obtener GPS. Usa el mapa.';
        });
      }
    }
  }

  void _apply() {
    Navigator.of(context).pop(
      LocationRadiusResult(
        latitude: _center.latitude,
        longitude: _center.longitude,
        radiusKm: _radiusKm,
      ),
    );
  }

  Set<Circle> get _circles => {
        Circle(
          circleId: const CircleId('radius'),
          center: _center,
          radius: radiusKmToMeters(_radiusKm),
          fillColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
          strokeColor: Theme.of(context).colorScheme.primary,
          strokeWidth: 2,
        ),
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cambiar ubicación'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Radio de búsqueda',
                border: OutlineInputBorder(),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<double>(
                  key: const Key('location_radius_dropdown'),
                  isExpanded: true,
                  value: _radiusKm,
                  items: radiusPresetsKm
                      .map(
                        (km) => DropdownMenuItem(
                          value: km,
                          child: Text('$km km'),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) return;
                    setState(() => _radiusKm = value);
                  },
                ),
              ),
            ),
          ),
          if (_locationHint != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                _locationHint!,
                style: theme.textTheme.bodySmall,
              ),
            ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: _loading
                    ? const Center(child: CircularProgressIndicator())
                    : Stack(
                        children: [
                          GoogleMap(
                            initialCameraPosition: CameraPosition(
                              target: _center,
                              zoom: _zoomForRadius(_radiusKm),
                            ),
                            circles: _circles,
                            markers: {
                              Marker(
                                markerId: const MarkerId('center'),
                                position: _center,
                              ),
                            },
                            myLocationEnabled: _myLocationEnabled,
                            myLocationButtonEnabled: false,
                            zoomControlsEnabled: false,
                            onMapCreated: (controller) =>
                                _mapController = controller,
                            onTap: (point) => setState(() => _center = point),
                          ),
                          Positioned(
                            right: 12,
                            bottom: 12,
                            child: FloatingActionButton.small(
                              key: const Key('location_radius_my_location'),
                              onPressed: () => _moveToGps(updateState: false),
                              child: const Icon(Icons.my_location),
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: DtsPrimaryButton(
                key: const Key('location_radius_apply'),
                label: 'Aplicar',
                onPressed: _loading ? null : _apply,
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _zoomForRadius(double radiusKm) {
    if (radiusKm <= 2) return 14;
    if (radiusKm <= 10) return 12;
    if (radiusKm <= 40) return 10;
    if (radiusKm <= 100) return 8;
    return 6;
  }
}
