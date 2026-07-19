import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_offer.dart';
import 'incoming_offer_screen.dart';

/// Home estilo Uber: mapa + sheet de ofertas + toggle online.
class DriverHomeMapScreen extends ConsumerStatefulWidget {
  const DriverHomeMapScreen({super.key});

  @override
  ConsumerState<DriverHomeMapScreen> createState() =>
      _DriverHomeMapScreenState();
}

class _DriverHomeMapScreenState extends ConsumerState<DriverHomeMapScreen> {
  List<DriverOffer> _offers = [];
  bool _isLoading = true;
  String? _error;
  bool _isOnline = false;
  bool _toggling = false;
  bool _gpsDenied = false;
  double? _lat;
  double? _lng;
  int? _actionOrderId;
  GoogleMapController? _mapController;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    try {
      final profile = await ref.read(getDriverProfileUseCaseProvider).call();
      if (mounted) setState(() => _isOnline = profile.isOnline);
    } catch (_) {}
    await _refreshLocation();
    await _loadOffers();
  }

  Future<void> _refreshLocation() async {
    final geo = ref.read(geolocatorServiceProvider);
    final granted =
        await geo.isPermissionGranted() || await geo.requestPermission();
    if (!granted) {
      if (mounted) setState(() => _gpsDenied = true);
      return;
    }
    try {
      final pos = await geo.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _gpsDenied = false;
        _lat = pos.latitude;
        _lng = pos.longitude;
      });
      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(pos.latitude, pos.longitude)),
      );
    } catch (_) {
      if (mounted) setState(() => _gpsDenied = true);
    }
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _toggling = true);
    try {
      await _refreshLocation();
      final result = await ref.read(toggleOnlineUseCaseProvider).call(
            isOnline: value,
            latitude: _lat,
            longitude: _lng,
          );
      if (!mounted) return;
      setState(() => _isOnline = result.isOnline);
      ref.read(locationServiceProvider).start(isOnline: value);
      await _loadOffers();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('No se pudo cambiar disponibilidad: $e')),
      );
    } finally {
      if (mounted) setState(() => _toggling = false);
    }
  }

  Future<void> _loadOffers() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final offers = await ref.read(listDriverOffersUseCaseProvider).call();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _isLoading = false;
      });
      if (offers.length == 1 && _isOnline) {
        // Auto-present first urgent offer when only one arrives
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las ofertas';
        _isLoading = false;
      });
    }
  }

  Future<void> _openOffer(DriverOffer offer) async {
    await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingOfferScreen(offer: offer),
      ),
    );
    await _loadOffers();
  }

  Future<void> _accept(DriverOffer offer) async {
    setState(() => _actionOrderId = offer.orderId);
    try {
      await ref.read(acceptDriverOfferUseCaseProvider).call(offer.orderId);
      if (!mounted) return;
      context.push('/active/${offer.orderId}');
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo aceptar la oferta')),
      );
    } finally {
      if (mounted) setState(() => _actionOrderId = null);
    }
  }

  Future<void> _reject(DriverOffer offer) async {
    setState(() => _actionOrderId = offer.orderId);
    try {
      await ref.read(rejectDriverOfferUseCaseProvider).call(offer.orderId);
      if (!mounted) return;
      setState(() {
        _offers = _offers.where((o) => o.orderId != offer.orderId).toList();
      });
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo rechazar la oferta')),
      );
    } finally {
      if (mounted) setState(() => _actionOrderId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final center = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : const LatLng(4.711, -74.072);

    final markers = <Marker>{
      if (_lat != null && _lng != null)
        Marker(
          markerId: const MarkerId('me'),
          position: LatLng(_lat!, _lng!),
          infoWindow: const InfoWindow(title: 'Tú'),
          icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueAzure),
        ),
      ..._offers.map(
        (o) => Marker(
          markerId: MarkerId('offer_${o.orderId}'),
          position: LatLng(o.storeLatitude, o.storeLongitude),
          infoWindow: InfoWindow(
            title: o.storeName.isEmpty ? 'Pedido #${o.orderId}' : o.storeName,
            snippet: '${o.distanceKm.toStringAsFixed(1)} km',
          ),
          onTap: () => _openOffer(o),
        ),
      ),
    };

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            onMapCreated: (c) => _mapController = c,
          ),
          SafeArea(
            child: Column(
              children: [
                if (_gpsDenied)
                  Material(
                    color: theme.colorScheme.errorContainer,
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(Icons.location_off,
                              color: theme.colorScheme.onErrorContainer),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Activa la ubicación para recibir pedidos',
                              style: TextStyle(
                                color: theme.colorScheme.onErrorContainer,
                              ),
                            ),
                          ),
                          TextButton(
                            onPressed: _refreshLocation,
                            child: const Text('Permitir'),
                          ),
                        ],
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 10,
                            height: 10,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: _isOnline
                                  ? Colors.green
                                  : theme.colorScheme.outline,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _isOnline ? 'En línea' : 'Desconectado',
                                  style: theme.textTheme.titleSmall,
                                ),
                                Text(
                                  _isOnline
                                      ? 'Recibiendo ofertas cercanas'
                                      : 'Actívate para ganar',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          if (_toggling)
                            const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          else
                            Switch(
                              key: const Key('availability_switch'),
                              value: _isOnline,
                              onChanged: _toggleOnline,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          DraggableScrollableSheet(
            initialChildSize: 0.34,
            minChildSize: 0.22,
            maxChildSize: 0.72,
            builder: (context, scrollController) {
              return Material(
                elevation: 8,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(20)),
                color: theme.colorScheme.surface,
                child: Column(
                  children: [
                    const SizedBox(height: 8),
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 8, 0),
                      child: DtsSectionHeader(
                        title: 'Ofertas',
                        subtitle: _isOnline
                            ? '${_offers.length} disponibles'
                            : 'Ponte en línea',
                        trailing: IconButton(
                          icon: const Icon(Icons.refresh),
                          onPressed: _isLoading ? null : _loadOffers,
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: _loadOffers,
                        child: _buildSheetBody(scrollController),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.small(
        onPressed: _refreshLocation,
        child: const Icon(Icons.my_location),
      ),
    );
  }

  Widget _buildSheetBody(ScrollController scrollController) {
    if (_isLoading) {
      return ListView(
        controller: scrollController,
        children: const [SizedBox(height: 80), DtsLoading()],
      );
    }
    if (_error != null) {
      return ListView(
        controller: scrollController,
        children: [
          SizedBox(
            height: 200,
            child: DtsErrorView(message: _error!, onRetry: _loadOffers),
          ),
        ],
      );
    }
    if (_offers.isEmpty) {
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          SizedBox(
            height: 220,
            child: DtsEmptyState(
              icon: Icons.local_shipping_outlined,
              title: 'Sin ofertas',
              message: _isOnline
                  ? 'Mantente cerca: te avisaremos cuando haya pedidos.'
                  : 'Activa el interruptor para empezar a recibir pedidos.',
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      controller: scrollController,
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      itemCount: _offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        final busy = _actionOrderId == offer.orderId;
        return Card(
          key: Key('offer_card_${offer.orderId}'),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () => _openOffer(offer),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor:
                            Theme.of(context).colorScheme.secondaryContainer,
                        child: const Icon(Icons.storefront),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              offer.storeName.isEmpty
                                  ? 'Pedido #${offer.orderId}'
                                  : offer.storeName,
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            Text(
                              '${offer.distanceKm.toStringAsFixed(1)} km · \$${offer.total}',
                            ),
                          ],
                        ),
                      ),
                      DtsStatusChip(
                        label: offer.status,
                        tone: DtsStatusChip.toneForStatus(offer.status),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (busy)
                    const LinearProgressIndicator()
                  else
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            key: Key('offer_reject_${offer.orderId}'),
                            onPressed: () => _reject(offer),
                            child: const Text('Rechazar'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FilledButton(
                            key: Key('offer_accept_${offer.orderId}'),
                            onPressed: () => _accept(offer),
                            child: const Text('Aceptar'),
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
