import 'dart:async';
import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart' hide RouteData;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/location/geolocator_service.dart';
import '../../../../core/utils/polyline_decoder.dart';
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
  BitmapDescriptor? _vehicleIcon;
  GoogleMapController? _mapController;
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
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    try {
      final ride = await ref.read(getRideUseCaseProvider).call(widget.rideId);
      // Genera el icono de vehículo sin bloquear la carga del viaje
      // (best-effort: si la rasterización falla, se usa el pin por defecto).
      unawaited(_loadVehicleIcon());
      final trackingActive =
          RideStatusValues.liveTrackingStatuses.contains(ride.status);
      if (trackingActive) {
        final geo = ref.read(geolocatorServiceProvider);
        final granted =
            await geo.isPermissionGranted() || await geo.requestPermission();
        if (granted) {
          final pos = await geo.getCurrentPosition();
          _lat = pos.latitude;
          _lng = pos.longitude;
          await _sendTrackingPoint(
            latitude: pos.latitude,
            longitude: pos.longitude,
          );
          _gpsSub = geo.getPositionStream().listen((position) {
            if (!mounted) return;
            setState(() {
              _lat = position.latitude;
              _lng = position.longitude;
            });
            // Envía la posición por WS/REST para que el cliente vea el
            // movimiento del conductor en tiempo real.
            unawaited(
              _sendTrackingPoint(
                latitude: position.latitude,
                longitude: position.longitude,
              ),
            );
            // Sigue al conductor suavizando el movimiento de la cámara.
            unawaited(
              _mapController?.animateCamera(
                CameraUpdate.newLatLng(
                  LatLng(position.latitude, position.longitude),
                ),
              ),
            );
          });
        }
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

  /// Envía la posición actual del conductor al backend (WS con fallback REST).
  Future<void> _sendTrackingPoint({
    required double latitude,
    required double longitude,
  }) async {
    try {
      await ref.read(locationTrackingRepositoryProvider).sendTrackingPoint(
            orderId: widget.rideId,
            latitude: latitude,
            longitude: longitude,
          );
    } catch (_) {
      // Errores puntuales de red: el background tracking reintenta.
    }
  }

  /// Genera el icono de vehículo sin bloquear el bootstrap y actualiza el
  /// marcador cuando está listo (best-effort en entornos/plataformas donde la
  /// rasterización de imagen no está disponible, p. ej. tests de widgets).
  Future<void> _loadVehicleIcon() async {
    final icon = await _buildVehicleMarkerIcon();
    if (!mounted || icon == null) return;
    setState(() => _vehicleIcon = icon);
  }

  /// Pinta un marcador circular con el icono de vehículo (bits PNG).
  Future<BitmapDescriptor?> _buildVehicleMarkerIcon() async {
    try {
      final recorder = ui.PictureRecorder();
      final canvas = Canvas(recorder);
      const size = 48.0;
      const center = Offset(size / 2, size / 2);
      canvas.drawCircle(
        center,
        size / 2,
        Paint()..color = const Color(0xFF0B3D2E),
      );
      canvas.drawCircle(
        center,
        size / 2 - 2,
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5,
      );
      const iconSize = size * 0.62;
      final painter = TextPainter(
        text: TextSpan(
          text: String.fromCharCode(Icons.directions_car.codePoint),
          style: TextStyle(
            fontSize: iconSize,
            fontFamily: Icons.directions_car.fontFamily,
            color: Colors.white,
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();
      painter.paint(
        canvas,
        Offset(
          (size - painter.width) / 2,
          (size - painter.height) / 2,
        ),
      );
      final image =
          await recorder.endRecording().toImage(size.toInt(), size.toInt());
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) return null;
      return BitmapDescriptor.bytes(
        bytes.buffer.asUint8List(),
        width: size,
        height: size,
      );
    } catch (_) {
      return null;
    }
  }

  /// Resuelve la dirección a mostrar para un punto del viaje.
  ///
  /// Cuando el cliente usa "mi ubicación actual" o toca el mapa, el backend
  /// entrega textos genéricos ("Mi ubicación actual", "Punto en el mapa").
  /// En esos casos (o si la dirección está vacía), se muestra como fallback
  /// las coordenadas formateadas; si tampoco hay coordenadas, "Sin dirección".
  String _displayAddress({
    required String address,
    double? latitude,
    double? longitude,
  }) {
    final trimmed = address.trim().toLowerCase();
    const generic = {
      '',
      'mi ubicación actual',
      'mi ubicacion actual',
      'punto en el mapa',
      'sin dirección',
      'sin direccion',
    };
    if (generic.contains(trimmed) && latitude != null && longitude != null) {
      return '${latitude.toStringAsFixed(5)}, ${longitude.toStringAsFixed(5)}';
    }
    return address.trim().isEmpty ? 'Sin dirección' : address.trim();
  }

  /// Encuadra la cámara sobre la ruta real del viaje (si el backend la calculó).
  Future<void> _fitRouteToCamera() async {
    final controller = _mapController;
    final routePoints = _ride?.routePoints ?? const <LatLng>[];
    if (controller == null || routePoints.length < 2) return;
    final bounds = boundsOf(routePoints);
    if (bounds == null) return;
    // Espera el primer layout para que `animateCamera` tenga el tamaño real.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.animateCamera(CameraUpdate.newLatLngBounds(bounds, 90));
    });
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
        icon: _vehicleIcon ??
            BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
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
    final status = ride?.status;
    // Ruta real sobre calles (Pickup → Dropoff) calculada por el backend.
    // Cuando existe, se pinta siguiendo la malla vial en lugar de las líneas
    // rectas punto a punto (antes: [me, pickup] y [pickup, dropoff]).
    final realRoute = (ride?.routePoints.length ?? 0) >= 2
        ? ride!.routePoints
        : const <LatLng>[];
    // Etapa del viaje:
    // - Antes de recoger: el conductor va al punto de recogida.
    // - Viaje en curso: la ruta es Recogida → Destino final.
    final headingToPickup = status == RideStatusValues.driverAccepted ||
        status == RideStatusValues.driverEnRouteToPickup ||
        status == RideStatusValues.driverAtPickup;

    if (realRoute.isNotEmpty) {
      // Con geometría real se evitan las líneas rectas: se pinta la ruta del
      // trayecto sobre calles en cualquier etapa activa.
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_route'),
          points: realRoute,
          color: theme.colorScheme.primary,
          width: 5,
        ),
      );
    } else if (headingToPickup && pickup != null) {
      // Fallback sin proveedor de rutas (p. ej. CI): conductor → Recogida.
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_to_pickup'),
          points: [me, pickup],
          color: theme.colorScheme.primary,
          width: 4,
        ),
      );
    } else if (status == RideStatusValues.rideInProgress &&
        pickup != null &&
        dropoff != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('ride_route'),
          points: [pickup, dropoff],
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
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                        child: Row(
                          children: [
                            DtsStatusChip(
                              label: RideStatusValues.label(ride.status),
                              tone: DtsStatusChip.toneForStatus(ride.status),
                            ),
                            const Spacer(),
                            if (ride.estimatedDurationMinutes != null) ...[
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: theme.colorScheme.primaryContainer,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.schedule,
                                      size: 16,
                                      color:
                                          theme.colorScheme.onPrimaryContainer,
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      '~ ${ride.estimatedDurationMinutes} min',
                                      style:
                                          theme.textTheme.labelMedium?.copyWith(
                                        color: theme
                                            .colorScheme.onPrimaryContainer,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                            ],
                            Text(
                              '\$${ride.total}',
                              style: theme.textTheme.titleLarge?.copyWith(
                                color: theme.colorScheme.primary,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ],
                        ),
                      ),
                    Expanded(
                      child: GoogleMap(
                        initialCameraPosition:
                            CameraPosition(target: me, zoom: 13.5),
                        onMapCreated: (controller) {
                          _mapController = controller;
                          _fitRouteToCamera();
                        },
                        myLocationEnabled: true,
                        myLocationButtonEnabled: true,
                        markers: markers,
                        polylines: polylines,
                      ),
                    ),
                    Material(
                      color: theme.colorScheme.surface,
                      elevation: 12,
                      shadowColor: Colors.black.withValues(alpha: 0.14),
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(24),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: SafeArea(
                        top: false,
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Padding(
                                padding:
                                    const EdgeInsets.fromLTRB(16, 8, 16, 4),
                                child: Container(
                                  width: 44,
                                  height: 5,
                                  decoration: BoxDecoration(
                                    color: theme.colorScheme.outlineVariant,
                                    borderRadius: BorderRadius.circular(3),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 12),
                              _RideRouteTile(
                                icon: Icons.trip_origin,
                                color: theme.colorScheme.primary,
                                label: 'Recogida',
                                address: _displayAddress(
                                  address: ride?.pickupAddress ?? '',
                                  latitude: ride?.pickupLatitude,
                                  longitude: ride?.pickupLongitude,
                                ),
                              ),
                              const SizedBox(height: 12),
                              _RideRouteTile(
                                icon: Icons.place_outlined,
                                color: Colors.green,
                                label: 'Destino',
                                address: _displayAddress(
                                  address: ride?.dropoffAddress ?? '',
                                  latitude: ride?.dropoffLatitude,
                                  longitude: ride?.dropoffLongitude,
                                ),
                              ),
                              if (ride?.estimatedDistanceKm != null) ...[
                                const SizedBox(height: 10),
                                Row(
                                  children: [
                                    Icon(
                                      Icons.route_outlined,
                                      size: 16,
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${ride!.estimatedDistanceKm!.toStringAsFixed(1)} km estimados',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 16),
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
                              const SizedBox(height: 12),
                              if (_updating)
                                const LinearProgressIndicator(minHeight: 4)
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
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(13),
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: theme.textTheme.labelSmall?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                address.isEmpty ? 'Sin dirección' : address,
                style: theme.textTheme.bodyLarge?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
