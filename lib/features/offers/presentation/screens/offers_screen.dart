import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/router/active_delivery_navigation.dart';
import '../../domain/entities/driver_offer.dart';

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
      await ref.read(acceptDriverOfferUseCaseProvider).call(offer.orderId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Pedido #${offer.orderId} aceptado')),
      );
      navigateToActiveDelivery(GoRouter.of(context), offer.orderId);
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
          SwitchListTile(
            key: const Key('availability_switch'),
            title: const Text('En línea'),
            subtitle: Text(
              _isOnline
                  ? 'Recibiendo ofertas cercanas'
                  : 'Actívate para recibir pedidos',
            ),
            value: _isOnline,
            onChanged: _toggling ? null : _toggleOnline,
          ),
          const Divider(height: 1),
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
        message: 'Sin ofertas por ahora.\nMantente en línea para recibir pedidos.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: _offers.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final offer = _offers[index];
        return _OfferCard(
          key: Key('offer_card_${offer.orderId}'),
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
                            color: Theme.of(context).colorScheme.onSurfaceVariant,
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

class _OfferCard extends StatelessWidget {
  const _OfferCard({
    super.key,
    required this.offer,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
  });

  final DriverOffer offer;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: theme.colorScheme.secondaryContainer,
                  child: Icon(
                    Icons.storefront,
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
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
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '${offer.distanceKm.toStringAsFixed(1)} km · \$${offer.total}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Chip(label: Text(offer.status)),
              ],
            ),
            const SizedBox(height: 16),
            if (isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: LinearProgressIndicator(),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      key: Key('offer_reject_${offer.orderId}'),
                      onPressed: onReject,
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      key: Key('offer_accept_${offer.orderId}'),
                      onPressed: onAccept,
                      child: const Text('Aceptar'),
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
