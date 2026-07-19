import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/driver_order.dart';

class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  const ActiveDeliveryScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ActiveDeliveryScreen> createState() =>
      _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  DriverOrder? _order;
  double? _lat;
  double? _lng;
  bool _loading = true;
  String? _error;
  bool _updating = false;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final order =
          await ref.read(driverOrderRepositoryProvider).getOrder(widget.orderId);
      final geo = ref.read(geolocatorServiceProvider);
      final granted =
          await geo.isPermissionGranted() || await geo.requestPermission();
      if (granted) {
        final pos = await geo.getCurrentPosition();
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
      ref.read(locationServiceProvider).start(isOnline: true);
      unawaited(ref.read(localNotificationServiceProvider).showTrackingActive());
      if (!mounted) return;
      setState(() {
        _order = order;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el pedido';
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    setState(() => _updating = true);
    try {
      final updated = await ref.read(driverOrderRepositoryProvider).updateStatus(
            orderId: widget.orderId,
            status: status,
          );
      if (!mounted) return;
      setState(() => _order = updated);
      if (status == 'delivered') {
        ref.read(locationServiceProvider).stop();
        unawaited(ref.read(localNotificationServiceProvider).cancelTracking());
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

  Future<void> _openMaps({required double lat, required double lng}) async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=$lat,$lng&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone(String phone) async {
    final uri = Uri.parse('tel:$phone');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;
    final theme = Theme.of(context);
    final me = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : const LatLng(4.711, -74.072);

    final pickup = (order?.storeLatitude != null && order?.storeLongitude != null)
        ? LatLng(order!.storeLatitude!, order.storeLongitude!)
        : null;
    final dropoff =
        (order?.deliveryLatitude != null && order?.deliveryLongitude != null)
            ? LatLng(order!.deliveryLatitude!, order.deliveryLongitude!)
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
          infoWindow: InfoWindow(
            title: 'Recoger',
            snippet: order?.storeName ?? '',
          ),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueOrange),
        ),
      if (dropoff != null)
        Marker(
          markerId: const MarkerId('dropoff'),
          position: dropoff,
          infoWindow: const InfoWindow(title: 'Entregar'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueGreen),
        ),
    };

    final polylines = <Polyline>{};
    if (pickup != null && dropoff != null) {
      polylines.add(
        Polyline(
          polylineId: const PolylineId('route'),
          points: [if (_lat != null) me, pickup, dropoff],
          color: theme.colorScheme.primary,
          width: 4,
        ),
      );
    }

    final navTarget =
        (order?.status == 'driver_assigned' || order?.status == 'picked_up')
            ? pickup
            : dropoff;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido #${widget.orderId}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.chat_bubble_outline),
            onPressed: () => context.push('/orders/${widget.orderId}/chat'),
          ),
        ],
      ),
      body: _loading
          ? const DtsLoading()
          : _error != null
              ? DtsErrorView(message: _error!, onRetry: _bootstrap)
              : Column(
                  children: [
                    if (order != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                        child: Row(
                          children: [
                            DtsStatusChip(
                              label: order.status,
                              tone: DtsStatusChip.toneForStatus(order.status),
                            ),
                            const Spacer(),
                            if (order.driverEarning.isNotEmpty)
                              Text(
                                'Ganas \$${order.driverEarning}',
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
                              Text(
                                order?.storeName.isNotEmpty == true
                                    ? order!.storeName
                                    : 'Comercio',
                                style: theme.textTheme.titleMedium,
                              ),
                              if (order?.deliveryAddress.isNotEmpty == true)
                                Text(
                                  order!.deliveryAddress,
                                  style: theme.textTheme.bodySmall,
                                ),
                              if (order?.customerNotes.isNotEmpty == true)
                                Text(
                                  'Nota: ${order!.customerNotes}',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    fontStyle: FontStyle.italic,
                                  ),
                                ),
                              if (order?.items.isNotEmpty == true) ...[
                                const SizedBox(height: 6),
                                Text(
                                  order!.items
                                      .map((i) =>
                                          '${i.quantity}× ${i.productName}')
                                      .join(' · '),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                              const SizedBox(height: 12),
                              Row(
                                children: [
                                  if (navTarget != null)
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () => _openMaps(
                                          lat: navTarget.latitude,
                                          lng: navTarget.longitude,
                                        ),
                                        icon: const Icon(Icons.navigation),
                                        label: const Text('Maps'),
                                      ),
                                    ),
                                  if (order?.customerPhone.isNotEmpty ==
                                      true) ...[
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: OutlinedButton.icon(
                                        onPressed: () =>
                                            _callPhone(order!.customerPhone),
                                        icon: const Icon(Icons.phone),
                                        label: const Text('Llamar'),
                                      ),
                                    ),
                                  ],
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: OutlinedButton.icon(
                                      onPressed: () => context.push(
                                        '/orders/${widget.orderId}/chat',
                                      ),
                                      icon: const Icon(Icons.chat),
                                      label: const Text('Chat'),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 10),
                              if (_updating)
                                const LinearProgressIndicator()
                              else if (order?.status == 'driver_assigned')
                                DtsPrimaryButton(
                                  label: 'Confirmar recogida',
                                  onPressed: () => _updateStatus('picked_up'),
                                )
                              else if (order?.status == 'picked_up')
                                DtsPrimaryButton(
                                  label: 'En camino al cliente',
                                  onPressed: () => _updateStatus('on_the_way'),
                                )
                              else if (order?.status == 'on_the_way')
                                DtsPrimaryButton(
                                  label: 'Marcar entregado',
                                  onPressed: () => _updateStatus('delivered'),
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
