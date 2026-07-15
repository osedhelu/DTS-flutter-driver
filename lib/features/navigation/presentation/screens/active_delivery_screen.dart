import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';

class ActiveDeliveryScreen extends ConsumerStatefulWidget {
  const ActiveDeliveryScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<ActiveDeliveryScreen> createState() =>
      _ActiveDeliveryScreenState();
}

class _ActiveDeliveryScreenState extends ConsumerState<ActiveDeliveryScreen> {
  double? _lat;
  double? _lng;
  String? _status;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final orders = await ref.read(driverOrderRepositoryProvider).listOrders();
      final order = orders.where((o) => o.id == widget.orderId).firstOrNull;
      final geo = ref.read(geolocatorServiceProvider);
      final granted =
          await geo.isPermissionGranted() || await geo.requestPermission();
      if (granted) {
        final pos = await geo.getCurrentPosition();
        _lat = pos.latitude;
        _lng = pos.longitude;
      }
      ref.read(locationServiceProvider).start(isOnline: true);
      if (!mounted) return;
      setState(() {
        _status = order?.status;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _updateStatus(String status) async {
    try {
      await ref.read(driverOrderRepositoryProvider).updateStatus(
            orderId: widget.orderId,
            status: status,
          );
      if (!mounted) return;
      setState(() => _status = status);
      if (status == 'delivered') {
        ref.read(locationServiceProvider).stop();
        context.go('/orders');
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final pos = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : const LatLng(4.711, -74.072);

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
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                if (_error != null)
                  Padding(
                    padding: const EdgeInsets.all(12),
                    child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                  ),
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Estado: ${_status ?? '—'}',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: pos, zoom: 14),
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    markers: {
                      Marker(
                        markerId: const MarkerId('me'),
                        position: pos,
                        infoWindow: const InfoWindow(title: 'Tú'),
                      ),
                    },
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        if (_status == 'driver_assigned')
                          FilledButton(
                            onPressed: () => _updateStatus('picked_up'),
                            child: const Text('Confirmar recogida'),
                          ),
                        if (_status == 'picked_up')
                          FilledButton(
                            onPressed: () => _updateStatus('on_the_way'),
                            child: const Text('En camino'),
                          ),
                        if (_status == 'on_the_way')
                          FilledButton(
                            onPressed: () => _updateStatus('delivered'),
                            child: const Text('Marcar entregado'),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
