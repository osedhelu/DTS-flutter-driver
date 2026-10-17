import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/router/active_delivery_navigation.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_offer.dart';
import '../widgets/driver_offer_card.dart';
import 'driver_home_map_screen.dart';

class OffersScreen extends ConsumerStatefulWidget {
  const OffersScreen({super.key});

  @override
  ConsumerState<OffersScreen> createState() => _OffersScreenState();
}

class _OffersScreenState extends ConsumerState<OffersScreen> {
  List<DriverOffer> _offers = [];
  bool _isLoading = true;
  String? _error;
  int? _actionOrderId;
  bool _isOnline = false;
  bool _toggling = false;
  OfferFilter _filter = OfferFilter.all;

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
    await _loadOffers();
  }

  Future<void> _toggleOnline(bool value) async {
    setState(() => _toggling = true);
    try {
      final geo = ref.read(geolocatorServiceProvider);
      final granted =
          await geo.isPermissionGranted() || await geo.requestPermission();
      double? lat;
      double? lng;
      if (granted) {
        final pos = await geo.getCurrentPosition();
        lat = pos.latitude;
        lng = pos.longitude;
      }
      final result = await ref.read(toggleOnlineUseCaseProvider).call(
            isOnline: value,
            latitude: lat,
            longitude: lng,
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
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las ofertas';
        _isLoading = false;
      });
    }
  }

  Future<void> _accept(DriverOffer offer) async {
    setState(() => _actionOrderId = offer.orderId);
    try {
      if (offer.isRide) {
        await ref.read(acceptRideOfferUseCaseProvider).call(offer.orderId);
      } else {
        await ref.read(acceptDriverOfferUseCaseProvider).call(offer.orderId);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            offer.isRide
                ? 'Viaje #${offer.orderId} aceptado'
                : 'Pedido #${offer.orderId} aceptado',
          ),
        ),
      );
      if (offer.isRide) {
        navigateToActiveRide(GoRouter.of(context), offer.orderId);
      } else {
        navigateToActiveDelivery(GoRouter.of(context), offer.orderId);
      }
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inicio'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadOffers,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    DtsStatusDot(online: _isOnline),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isOnline ? 'En línea' : 'Desconectado',
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _isOnline
                                ? 'Recibiendo ofertas cercanas'
                                : 'Actívate para recibir pedidos',
                            style:
                                Theme.of(context).textTheme.bodySmall?.copyWith(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                    ),
                          ),
                        ],
                      ),
                    ),
                    if (_toggling)
                      const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2.5),
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
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: SegmentedButton<OfferFilter>(
              key: const Key('offer_filter'),
              showSelectedIcon: false,
              style: const ButtonStyle(visualDensity: VisualDensity.compact),
              segments: const [
                ButtonSegment(
                  value: OfferFilter.all,
                  label: Text('Todas'),
                ),
                ButtonSegment(
                  value: OfferFilter.delivery,
                  label: Text('Delivery'),
                ),
                ButtonSegment(
                  value: OfferFilter.ride,
                  label: Text('Viajes'),
                ),
              ],
              selected: {_filter},
              onSelectionChanged: (selection) {
                setState(() => _filter = selection.first);
              },
            ),
          ),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _loadOffers,
              child: _buildBody(context),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildEmptyState(
        icon: Icons.error_outline,
        message: _error!,
      );
    }
    if (_offers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.local_shipping_outlined,
        message:
            'Sin ofertas por ahora.\nMantente en línea para recibir pedidos.',
      );
    }

    final filteredOffers = _offers
        .where((o) => switch (_filter) {
              OfferFilter.all => true,
              OfferFilter.delivery => o.isDelivery,
              OfferFilter.ride => o.isRide,
            })
        .toList();

    if (filteredOffers.isEmpty) {
      return _buildEmptyState(
        icon: Icons.filter_alt_off_outlined,
        message: _filter == OfferFilter.ride
            ? 'No hay viajes disponibles con el filtro actual.'
            : 'No hay pedidos disponibles con el filtro actual.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(20),
      itemCount: filteredOffers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 16),
      itemBuilder: (context, index) {
        final offer = filteredOffers[index];
        return DriverOfferCard(
          offer: offer,
          isLoading: _actionOrderId == offer.orderId,
          onAccept: () => _accept(offer),
          onReject: () => _reject(offer),
        );
      },
    );
  }

  Widget _buildEmptyState({required IconData icon, required String message}) {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: SizedBox(
            height: constraints.maxHeight,
            child: Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      size: 56,
                      color: Theme.of(context).colorScheme.outline,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      message,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color:
                                Theme.of(context).colorScheme.onSurfaceVariant,
                          ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
