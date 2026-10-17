import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' hide RouteData;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/location/geolocator_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../location/infrastructure/background/background_tracking_service.dart';
import '../../domain/entities/ride.dart';

/// Pantalla del viaje activo (pasajero).
///
/// Ciclo de vida: `driver_accepted` → `driver_en_route_to_pickup` →
/// `driver_at_pickup` → `ride_in_progress` → `ride_completed`.
///
/// A diferencia del delivery, **no** solicita foto de prueba de entrega:
/// el viaje solo requiere transiciones de estado.
class ActiveRideScreen extends ConsumerStatefulWidget {
  const ActiveRideScreen({super.key, required this.rideId});

  final int rideId;

  @override
  ConsumerState<ActiveRideScreen> createState() => _ActiveRideScreenState();
}

class _ActiveRideScreenState extends ConsumerState<ActiveRideScreen> {
  Ride? _ride;
  double? _lat;
  double? _lng;
  bool _loading = true;
  String? _error;
  bool _updating = false;
  StreamSubscription<GeoPosition>? _gpsSub;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  @override
  void dispose() {
    _gpsSub?.cancel();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final ride = await ref.read(getRideUseCaseProvider).call(widget.rideId);
      final geo = ref.read(geolocatorServiceProvider);
      final granted =
          await geo.isPermissionGranted() || await geo.requestPermission();
      if (granted) {
        final pos = await geo.getCurrentPosition();
        _lat = pos.latitude;
        _lng = pos.longitude;
        _gpsSub = geo.getPositionStream().listen((position) {
          if (!mounted) return;
          setState(() {
            _lat = position.latitude;
            _lng = position.longitude;
          });
        });
      }
      ref.read(locationServiceProvider).start(isOnline: true);
      unawaited(
          ref.read(localNotificationServiceProvider).showTrackingActive());
      try {
        await startBackgroundTracking(orderId: widget.rideId)
            .timeout(const Duration(seconds: 5));
      } catch (_) {
        // Degradación graciosa: el FGS no es imprescindible para el viaje.
      }
      if (!mounted) return;
      setState(() {
        _ride = ride;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el viaje';
        _loading = false;
      });
    }
  }

  Future<void> _finishRideTracking() async {
    unawaited(ref.read(localNotificationServiceProvider).cancelTracking());
    try {
      await stopBackgroundTracking().timeout(const Duration(seconds: 5));
    } catch (_) {}
    try {
      final profile = await ref.read(getDriverProfileUseCaseProvider).call();
      ref.read(locationServiceProvider).start(isOnline: profile.isOnline);
    } catch (_) {
      ref.read(locationServiceProvider).stop();
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      final updated = await ref.read(updateRideStatusUseCaseProvider).call(
            rideId: widget.rideId,
            status: status,
          );
      if (!mounted) return;
      setState(() => _ride = updated);
      if (status == RideStatusValues.rideCompleted) {
        await _finishRideTracking();
        if (!mounted) return;
        context.go('/orders');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _updating = false);
    }
  }

  /// Abre el selector de navegación GPS externa (Google Maps / Waze / Apple).
  Future<void> _openNavOptions(LatLng destination) async {
    final app = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.navigation_outlined),
              title: const Text('Google Maps'),
              onTap: () => Navigator.of(sheetContext).pop('google'),
            ),
            ListTile(
              leading: const Icon(Icons.directions_car_outlined),
              title: const Text('Waze'),
              onTap: () => Navigator.of(sheetContext).pop('waze'),
            ),
            if (defaultTargetPlatform == TargetPlatform.iOS ||
                defaultTargetPlatform == TargetPlatform.macOS)
              ListTile(
                leading: const Icon(Icons.map_outlined),
                title: const Text('Apple Maps'),
                onTap: () => Navigator.of(sheetContext).pop('apple'),
              ),
          ],
        ),
      ),
    );
    if (app == null || !mounted) return;
    await _launchNavApp(app, destination);
  }

  Future<void> _launchNavApp(String app, LatLng destination) async {
    final Uri uri = switch (app) {
      'waze' => Uri.parse(
          'https://waze.com/ul?ll=${destination.latitude},'
          '${destination.longitude}&navigate=yes',
        ),
      'apple' => Uri.parse(
          'https://maps.apple.com/?daddr=${destination.latitude},'
          '${destination.longitude}',
        ),
      _ => Uri.parse(
          'https://www.google.com/maps/dir/?api=1&destination='
          '${destination.latitude},${destination.longitude}&travelmode=driving',
        ),
    };
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ride = _ride;
    final theme = Theme.of(context);
    final me = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : const LatLng(4.711, -74.072);

    final pickup = ride?.hasPickupPosition == true
        ? LatLng(ride!.pickupLatitude!, ride.pickupLongitude!)
        : null;
    final dropoff = ride?.hasDropoffPosition == true
        ? LatLng(ride!.dropoffLatitude!, ride.dropoffLongitude!)
        : null;

    final markers = <Marker>{
      Marker(
        markerId: const MarkerId('me'),
        position: me,
        infoWindow: const InfoWindow(title: 'Tú'),
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
      ),
      if (pickup != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: pickup,
          infoWindow: const InfoWindow(title: 'Recoger pasajero'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      if (dropoff != null)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          infoWindow: const InfoWindow(title: 'Destino'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    final polylines = <Polyline>{};
    if (pickup != null && dropoff != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_route'),
          points: [if (_lat != null) me, pickup, dropoff],
          color: theme.colorScheme.primary,
          width: 4,
        ),
      );
    }

    // Hasta llegar al pickup se navega al pickup; luego, al destino.
    final navTarget = (ride?.status == RideStatusValues.driverAccepted ||
            ride?.status == RideStatusValues.driverEnRouteToPickup ||
            ride?.status == RideStatusValues.driverAtPickup)
        ? pickup
        : dropoff;

    return Scaffold(
      appBar: AppBar(
        title: Text(
            ride == null ? 'Viaje #${widget.rideId}' : 'Viaje #${ride.id}'),
      ),
      body: _loading
          ? const DtsLoading()
          : _error != null
              ? DtsErrorView(message: _error!, onRetry: _bootstrap)
              : Column(
                  children: [
                    if (ride != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            DtsStatusChip(
                              label: ride.status,
                              tone: DtsStatusChip.toneForStatus(ride.status),
                            ),
                            const Spacer(),
                            if (ride.estimatedDurationMinutes != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '~ ${ride.estimatedDurationMinutes} min',
                                  style: theme.textTheme.labelMedium?.copyWith(
                                    color: theme.colorScheme.onPrimaryContainer,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '\$${ride.total}',
                              style: theme.textTheme.titleSmall?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition:
                            CameraPosition(target: me, zoom: 13.5),
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: markers,
                        polylines: polylines,
                      ),
                    ),
                    Material(
                      elevation: 8,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _RideRouteTile(
                                icon: Icons.trip_origin,
                                color: theme.colorScheme.primary,
                                label: 'Recogida',
                                address: ride?.pickupAddress ?? '',
                              ),
                              const SizedBox(height: 8),
                              _RideRouteTile(
                                icon: Icons.place_outlined,
                                color: Colors.green,
                                label: 'Destino',
                                address: ride?.dropoffAddress ?? '',
                              ),
                              if (ride?.estimatedDistanceKm != null) ...[
                                const SizedBox(height: 8),
                                Text(
                                  '${ride!.estimatedDistanceKm!.toStringAsFixed(1)} km estimados',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (navTarget != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        key: const Key('ride_nav_button'),
                                        onPressed: () =>
                                            _openNavOptions(navTarget),
                                        icon: const Icon(Icons.navigation),
                                        label: const Text('GPS'),
                                      ),
                                    ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_updating)
                                const LinearProgressIndicator()
                              else if (ride?.status ==
                                  RideStatusValues.driverAccepted)
                                DtsPrimaryButton(
                                  key: const Key('ride_en_route_button'),
                                  label: 'En camino al punto de recogida',
                                  onPressed: () => _updateStatus(
                                    RideStatusValues.driverEnRouteToPickup,
                                  ),
                                )
                              else if (ride?.status ==
                                  RideStatusValues.driverEnRouteToPickup)
                                DtsPrimaryButton(
                                  key: const Key('ride_at_pickup_button'),
                                  label: 'Llegué al punto de recogida',
                                  onPressed: () => _updateStatus(
                                    RideStatusValues.driverAtPickup,
                                  ),
                                )
                              else if (ride?.status ==
                                  RideStatusValues.driverAtPickup)
                                DtsPrimaryButton(
                                  key: const Key('ride_start_button'),
                                  label: 'Iniciar viaje',
                                  onPressed: () => _updateStatus(
                                    RideStatusValues.rideInProgress,
                                  ),
                                )
                              else if (ride?.status ==
                                  RideStatusValues.rideInProgress)
                                DtsPrimaryButton(
                                  key: const Key('ride_complete_button'),
                                  label: 'Completar viaje',
                                  onPressed: () => _updateStatus(
                                    RideStatusValues.rideCompleted,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
    );
  }
}

class _RideRouteTile extends StatelessWidget {
  const _RideRouteTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.address,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String address;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: theme.textTheme.labelSmall),
              Text(
                address.isEmpty ? 'Sin dirección' : address,
                style: theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
