import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/constants/location_radius_constants.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/router/active_delivery_navigation.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../settings/presentation/widgets/open_driver_work_zone_picker.dart';
import '../../../orders/domain/entities/driver_order.dart';
import '../../../stores/domain/entities/store.dart';
import '../../../stores/presentation/widgets/store_info_sheet.dart';
import '../../domain/entities/driver_offer.dart';
import '../utils/driver_home_map_markers.dart';
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
  List<DriverOrder> _activeOrders = [];
  List<Store> _stores = [];
  bool _isLoading = true;
  bool _storesLoading = true;
  String? _error;
  bool _isOnline = false;
  bool _toggling = false;
  bool _gpsDenied = false;
  bool _showStores = true;
  double? _lat;
  double? _lng;
  double? _workCenterLat;
  double? _workCenterLng;
  double _workRadiusKm = defaultRadiusKm;
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
      if (mounted) {
        setState(() {
          _isOnline = profile.isOnline;
          _workCenterLat = profile.workCenterLatitude;
          _workCenterLng = profile.workCenterLongitude;
          _workRadiusKm = profile.workRadiusKm;
        });
        ref.read(locationServiceProvider).start(isOnline: profile.isOnline);
      }
    } catch (_) {}
    await _refreshLocation();
    await Future.wait([_loadOffers(), _loadStores(), _loadActiveOrders()]);
  }

  Future<void> _openWorkZonePicker() async {
    final updated = await openDriverWorkZonePicker(context, ref);
    if (updated == null || !mounted) return;
    setState(() {
      _workCenterLat = updated.workCenterLatitude;
      _workCenterLng = updated.workCenterLongitude;
      _workRadiusKm = updated.workRadiusKm;
    });
    await _loadOffers();
  }

  Future<void> _loadActiveOrders() async {
    try {
      final orders = await ref.read(driverOrderRepositoryProvider).listOrders();
      if (!mounted) return;
      setState(() {
        _activeOrders = orders.where((order) => order.isActive).toList();
      });
    } catch (_) {}
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
    final previous = _isOnline;
    setState(() => _toggling = true);
    try {
      if (value) {
        await _refreshLocation();
      }
      final result = await ref.read(toggleOnlineUseCaseProvider).call(
            isOnline: value,
            latitude: value ? _lat : null,
            longitude: value ? _lng : null,
          );
      if (!mounted) return;
      setState(() => _isOnline = result.isOnline);
      ref.read(locationServiceProvider).start(isOnline: result.isOnline);
      if (result.isOnline) {
        await Future.wait([_loadOffers(), _loadActiveOrders()]);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _isOnline = previous);
      ref.read(locationServiceProvider).start(isOnline: previous);
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

  Future<void> _loadStores() async {
    setState(() {
      _storesLoading = true;
    });
    try {
      final stores = await ref.read(getStoresUseCaseProvider).call();
      if (!mounted) return;
      setState(() {
        _stores = stores.where((s) => s.hasValidLocation).toList();
        _storesLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _storesLoading = false;
      });
    }
  }

  void _showStoreSheet(Store store) {
    StoreInfoSheet.show(context, store);
  }

  Future<void> _openOffer(DriverOffer offer) async {
    final accepted = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        fullscreenDialog: true,
        builder: (_) => IncomingOfferScreen(offer: offer),
      ),
    );
    if (!mounted) return;
    if (accepted == true) {
      navigateToActiveDelivery(GoRouter.of(context), offer.orderId);
    }
    await Future.wait([_loadOffers(), _loadActiveOrders()]);
  }

  Future<void> _accept(DriverOffer offer) async {
    setState(() => _actionOrderId = offer.orderId);
    try {
      await ref.read(acceptDriverOfferUseCaseProvider).call(offer.orderId);
      if (!mounted) return;
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
    final theme = Theme.of(context);
    final center = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : const LatLng(4.711, -74.072);

    final markers = buildDriverHomeMapMarkers(
      driverLat: _lat,
      driverLng: _lng,
      stores: _stores,
      offers: _offers,
      showStores: _showStores,
      onStoreTap: _showStoreSheet,
      onOfferTap: _openOffer,
    );

    final circles = (_workCenterLat != null && _workCenterLng != null)
        ? {
            Circle(
              circleId: const CircleId('work_zone'),
              center: LatLng(_workCenterLat!, _workCenterLng!),
              radius: radiusKmToMeters(_workRadiusKm),
              fillColor: theme.colorScheme.primary.withValues(alpha: 0.10),
              strokeColor: theme.colorScheme.primary,
              strokeWidth: 2,
            ),
          }
        : const <Circle>{};

    final workZoneLabel =
        'Zona: ${normalizeRadiusPreset(_workRadiusKm).toStringAsFixed(0)} km';

    return Scaffold(
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: CameraPosition(target: center, zoom: 13),
            myLocationEnabled: true,
            myLocationButtonEnabled: false,
            zoomControlsEnabled: false,
            markers: markers,
            circles: circles,
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
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: ActionChip(
                      key: const Key('driver_work_zone_chip'),
                      avatar: const Icon(Icons.radar_outlined, size: 18),
                      label: Text(workZoneLabel),
                      onPressed: _openWorkZonePicker,
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
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
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
                                  child:
                                      CircularProgressIndicator(strokeWidth: 2),
                                )
                              else
                                Switch(
                                  key: const Key('availability_switch'),
                                  value: _isOnline,
                                  onChanged: _toggleOnline,
                                ),
                            ],
                          ),
                          const Divider(height: 16),
                          Row(
                            children: [
                              Icon(
                                Icons.storefront_outlined,
                                size: 18,
                                color: theme.colorScheme.outline,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  _storesLoading
                                      ? 'Cargando comercios…'
                                      : '${_stores.length} comercios en el mapa',
                                  style: theme.textTheme.bodySmall,
                                ),
                              ),
                              Text(
                                'Mostrar',
                                style: theme.textTheme.bodySmall,
                              ),
                              Switch(
                                key: const Key('show_stores_switch'),
                                value: _showStores,
                                onChanged: (value) =>
                                    setState(() => _showStores = value),
                              ),
                            ],
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
                          onPressed: _isLoading
                              ? null
                              : () async {
                                  await Future.wait([
                                    _loadOffers(),
                                    _loadActiveOrders(),
                                  ]);
                                },
                        ),
                      ),
                    ),
                    Expanded(
                      child: RefreshIndicator(
                        onRefresh: () async {
                          await Future.wait([
                            _loadOffers(),
                            _loadActiveOrders(),
                          ]);
                        },
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

    final children = <Widget>[];

    if (_activeOrders.isNotEmpty) {
      children.addAll([
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: DtsSectionHeader(
            title: 'Entregas activas',
            subtitle: '${_activeOrders.length} en curso',
          ),
        ),
        ..._activeOrders.map(
          (order) => Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Card(
              child: ListTile(
                leading: const Icon(Icons.local_shipping_outlined),
                title: Text('Pedido #${order.id}'),
                subtitle: Text(
                  order.storeName.isNotEmpty
                      ? order.storeName
                      : 'Tienda #${order.storeId}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () =>
                    navigateToActiveDelivery(GoRouter.of(context), order.id),
              ),
            ),
          ),
        ),
        const Divider(height: 24),
      ]);
    }

    if (_offers.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: DtsEmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'Sin ofertas nuevas',
            message: _isOnline
                ? _gpsDenied
                    ? 'Activa el permiso de ubicación para ver pedidos cercanos.'
                    : 'Aparecen cuando el comercio busca conductor. Revisa Mis pedidos.'
                : 'Activa el interruptor para empezar a recibir pedidos.',
          ),
        ),
      );
      return ListView(
        controller: scrollController,
        physics: const AlwaysScrollableScrollPhysics(),
        children: children,
      );
    }

    children.addAll(
      _offers.asMap().entries.map(
        (entry) => Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: _buildOfferCard(entry.value),
        ),
      ),
    );

    return ListView(
      controller: scrollController,
      padding: const EdgeInsets.only(bottom: 24),
      children: children,
    );
  }

  Widget _buildOfferCard(DriverOffer offer) {
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
  }
}
