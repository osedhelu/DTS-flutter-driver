import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/notifications/offer_ringtone_service.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/polyline_decoder.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_offer.dart';

/// Modal fullscreen de oferta entrante con countdown.
///
/// Soporta el feed unificado: entrega muestra la tienda; viaje muestra el
/// trayecto del pasajero (Pickup → Dropoff) y acepta vía `AcceptRideOfferUseCase`.
class IncomingOfferScreen extends ConsumerStatefulWidget {
  const IncomingOfferScreen({super.key, required this.offer});

  final DriverOffer offer;

  @override
  ConsumerState<IncomingOfferScreen> createState() =>
      _IncomingOfferScreenState();
}

class _IncomingOfferScreenState extends ConsumerState<IncomingOfferScreen> {
  static const _seconds = 45;
  int _remaining = _seconds;
  bool _busy = false;
  final _ringtone = OfferRingtoneService();
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    unawaited(_ringtone.start());
    _tick();
  }

  @override
  void dispose() {
    unawaited(_ringtone.dispose());
    _mapController?.dispose();
    super.dispose();
  }

  void _tick() async {
    while (mounted && _remaining > 0 && !_busy) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || _busy) return;
      setState(() => _remaining--);
    }
    if (mounted && _remaining == 0 && !_busy) {
      await _reject(auto: true);
    }
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    await _ringtone.stop();
    try {
      final offer = widget.offer;
      if (offer.isRide) {
        await ref.read(acceptRideOfferUseCaseProvider).call(offer.orderId);
      } else {
        await ref.read(acceptDriverOfferUseCaseProvider).call(offer.orderId);
      }
      if (!mounted) return;
      // Cerrar el MaterialPageRoute antes de tocar go_router.
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      final offer = widget.offer;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(offer.isRide
              ? 'No se pudo aceptar el viaje'
              : 'No se pudo aceptar la oferta'),
        ),
      );
      setState(() => _busy = false);
      unawaited(_ringtone.start());
    }
  }

  Future<void> _reject({bool auto = false}) async {
    setState(() => _busy = true);
    await _ringtone.stop();
    try {
      await ref
          .read(rejectDriverOfferUseCaseProvider)
          .call(widget.offer.orderId);
    } catch (_) {}
    if (!mounted) return;
    if (auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta expirada')),
      );
    }
    Navigator.of(context).pop(false);
  }

  Future<void> _fitRouteToCamera(List<LatLng> routePoints) async {
    final controller = _mapController;
    final bounds = boundsOf(routePoints);
    if (controller == null || bounds == null) return;
    // Espera el primer layout para que `animateCamera` tenga el tamaño real.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      controller.animateCamera(
        CameraUpdate.newLatLngBounds(bounds, 90),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final theme = Theme.of(context);
    final isRide = offer.isRide;

    final targetPos = isRide
        ? (offer.hasMapPosition
            ? LatLng(offer.pickupLatitude!, offer.pickupLongitude!)
            : null)
        : LatLng(offer.storeLatitude ?? 0, offer.storeLongitude ?? 0);
    final dropoffPos = isRide &&
            offer.dropoffLatitude != null &&
            offer.dropoffLongitude != null
        ? LatLng(offer.dropoffLatitude!, offer.dropoffLongitude!)
        : null;

    final markers = <Marker>{
      if (targetPos != null)
        Marker(
          markerId: const MarkerId('pickup'),
          position: targetPos,
          infoWindow: InfoWindow(
            title: isRide ? 'Recoger pasajero' : 'Comercio',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(
            isRide ? BitmapDescriptor.hueAzure : BitmapDescriptor.hueRed,
          ),
        ),
      if (dropoffPos != null)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoffPos,
          infoWindow: const InfoWindow(title: 'Destino'),
          icon:
              BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    // Ruta real sobre calles de la oferta de viaje (si el backend la calculó).
    final routePoints = isRide && offer.routePoints.length >= 2
        ? offer.routePoints
        : const <LatLng>[];
    final route = routePoints.isEmpty
        ? const <Polyline>{}
        : <Polyline>{
            Polyline(
              polylineId: const PolylineId('offer_route'),
              points: routePoints,
              color: theme.colorScheme.primary,
              width: 5,
            ),
          };

    final progress = _remaining / _seconds;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isRide ? 'Nuevo viaje' : 'Nueva oferta',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isRide
                            ? 'Viaje #${offer.orderId}'
                            : offer.storeName.isEmpty
                                ? 'Pedido #${offer.orderId}'
                                : offer.storeName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  DtsStatusChip(
                    label: '${_remaining}s',
                    tone: _remaining <= 10
                        ? DtsChipTone.danger
                        : DtsChipTone.warning,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(
                      target: targetPos ?? const LatLng(4.711, -74.072),
                      zoom: 14,
                    ),
                    markers: markers,
                    polylines: route,
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (routePoints.length >= 2) {
                        _fitRouteToCamera(routePoints);
                      }
                    },
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (isRide) ...[
                        _OfferRouteLine(
                          icon: Icons.trip_origin,
                          color: theme.colorScheme.primary,
                          text: offer.pickupAddress.isEmpty
                              ? 'Recogida sin dirección'
                              : offer.pickupAddress,
                        ),
                        const SizedBox(height: 8),
                        _OfferRouteLine(
                          icon: Icons.place_outlined,
                          color: Colors.green,
                          text: offer.dropoffAddress.isEmpty
                              ? 'Destino sin dirección'
                              : offer.dropoffAddress,
                        ),
                        if (offer.estimatedDurationMinutes != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            '~ ${offer.estimatedDurationMinutes} min estimados',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                        const SizedBox(height: 14),
                        const Divider(height: 1),
                        const SizedBox(height: 14),
                      ],
                      Row(
                        children: [
                          Icon(Icons.near_me,
                              size: 18, color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${offer.distanceKm.toStringAsFixed(1)} km',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const Spacer(),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                'Pago estimado',
                                style: theme.textTheme.labelMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                '\$${offer.total}',
                                style: theme.textTheme.headlineMedium?.copyWith(
                                  color: theme.colorScheme.primary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _reject(),
                      icon: const Icon(Icons.close),
                      label: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DtsPrimaryButton(
                      label: isRide ? 'Aceptar viaje' : 'Aceptar pedido',
                      isLoading: _busy,
                      onPressed: _accept,
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OfferRouteLine extends StatelessWidget {
  const _OfferRouteLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
        ),
      ],
    );
  }
}
