import 'dart:async';

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
import '../widgets/driver_offer_card.dart';
import 'incoming_offer_screen.dart';

/// Home estilo Uber: mapa + sheet de ofertas + toggle online.
class DriverHomeMapScreen extends ConsumerStatefulWidget {
  const DriverHomeMapScreen({super.key});

  @override
  ConsumerState<DriverHomeMapScreen> createState() =>
      _DriverHomeMapScreenState();
}

/// Filtro del feed unificado por tipo de oferta.
enum OfferFilter { all, delivery, ride }

class _DriverHomeMapScreenState extends ConsumerState<DriverHomeMapScreen>
    with WidgetsBindingObserver {
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
  OfferFilter _filter = OfferFilter.all;
  GoogleMapController? _mapController;
  Timer? _offersPoll;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _bootstrap();
    _offersPoll = Timer.periodic(const Duration(seconds: 10), (_) {
      if (_isOnline && mounted) {
        unawaited(_loadOffers(silent: true));
      }
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _offersPoll?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && _isOnline) {
      unawaited(_loadOffers(silent: true));
    }
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

  Future<void> _loadOffers({bool silent = false}) async {
    if (!silent) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final offers = await ref.read(listDriverOffersUseCaseProvider).call();
      if (!mounted) return;
      setState(() {
        _offers = offers;
        _isLoading = false;
        _error = null;
      });
    } catch (_) {
      if (!mounted) return;
      if (!silent) {
        setState(() {
          _error = 'No se pudieron cargar las ofertas';
          _isLoading = false;
        });
      }
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
      if (offer.isRide) {
        navigateToActiveRide(GoRouter.of(context), offer.orderId);
      } else {
        navigateToActiveDelivery(GoRouter.of(context), offer.orderId);
      }
    }
    await Future.wait([_loadOffers(), _loadActiveOrders()]);
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
      if (offer.isRide) {
        navigateToActiveRide(GoRouter.of(context), offer.orderId);
      } else {
        navigateToActiveDelivery(GoRouter.of(context), offer.orderId);
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(offer.isRide
              ? 'No se pudo aceptar el viaje'
              : 'No se pudo aceptar la oferta'),
        ),
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
    ref.listen<int>(offersRefreshTickProvider, (prev, next) {
      if (prev != next && _isOnline) {
        unawaited(_loadOffers(silent: true));
      }
    });
    final theme = Theme.of(context);
    final center = (_lat != null && _lng != null)
        ? LatLng(_lat!, _lng!)
        : const LatLng(4.711, -74.072);

    final filteredOffers = _offers
        .where((o) => switch (_filter) {
              OfferFilter.all => true,
              OfferFilter.delivery => o.isDelivery,
              OfferFilter.ride => o.isRide,
            })
        .toList();

    final markers = buildDriverHomeMapMarkers(
      driverLat: _lat,
      driverLng: _lng,
      stores: _stores,
      offers: filteredOffers,
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
                      label: Text(
                        workZoneLabel,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                      onPressed: _openWorkZonePicker,
                      backgroundColor:
                          theme.colorScheme.surface.withValues(alpha: 0.92),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant,
                      ),
                      elevation: 1,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 10,
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Row(
                            children: [
                              DtsStatusDot(online: _isOnline),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _isOnline ? 'En línea' : 'Desconectado',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _isOnline
                                          ? 'Recibiendo ofertas cercanas'
                                          : 'Actívate para ganar',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (_toggling)
                                const SizedBox(
                                  width: 28,
                                  height: 28,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                  ),
                                )
                              else
                                Switch(
                                  key: const Key('availability_switch'),
                                  value: _isOnline,
                                  onChanged: _toggleOnline,
                                ),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 14),
                            child: Divider(height: 1),
                          ),
                          Row(
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: theme
                                      .colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.6),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  Icons.storefront_outlined,
                                  size: 20,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  _storesLoading
                                      ? 'Cargando comercios…'
                                      : '${_stores.length} comercios en el mapa',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              Text(
                                'Mostrar',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
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
                elevation: 12,
                shadowColor: Colors.black.withValues(alpha: 0.16),
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(24),
                ),
                color: theme.colorScheme.surface,
                clipBehavior: Clip.antiAlias,
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 44,
                      height: 5,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.outlineVariant,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 16, 12, 0),
                      child: DtsSectionHeader(
                        title: 'Ofertas',
                        subtitle: _isOnline
                            ? '${filteredOffers.length} disponibles cerca'
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
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
                      child: SegmentedButton<OfferFilter>(
                        key: const Key('offer_filter'),
                        showSelectedIcon: false,
                        style: const ButtonStyle(
                          visualDensity: VisualDensity.compact,
                        ),
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
    final theme = Theme.of(context);
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

    final filteredOffers = _offers
        .where((o) => switch (_filter) {
              OfferFilter.all => true,
              OfferFilter.delivery => o.isDelivery,
              OfferFilter.ride => o.isRide,
            })
        .toList();

    final children = <Widget>[];

    if (_activeOrders.isNotEmpty) {
      children.addAll([
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
          child: DtsSectionHeader(
            title: 'Entregas activas',
            subtitle: '${_activeOrders.length} en curso',
          ),
        ),
        ..._activeOrders.map(
          (order) => Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
            child: Card(
              child: ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                leading: Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primaryContainer
                        .withValues(alpha: 0.55),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    order.isRide
                        ? Icons.directions_car_outlined
                        : Icons.local_shipping_outlined,
                    size: 22,
                    color: theme.colorScheme.onPrimaryContainer,
                  ),
                ),
                title: Text(
                  order.isRide ? 'Viaje #${order.id}' : 'Pedido #${order.id}',
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
                subtitle: Text(
                  order.isRide
                      ? '${order.status} · \$${order.total}'
                      : order.storeName.isNotEmpty
                          ? order.storeName
                          : 'Tienda #${order.storeId ?? ''}',
                ),
                trailing: const Icon(Icons.chevron_right),
                onTap: () {
                  if (order.isRide) {
                    navigateToActiveRide(GoRouter.of(context), order.id);
                  } else {
                    navigateToActiveDelivery(GoRouter.of(context), order.id);
                  }
                },
              ),
            ),
          ),
        ),
        const Divider(height: 28),
      ]);
    }

    if (filteredOffers.isEmpty) {
      children.add(
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
          child: DtsEmptyState(
            icon: Icons.local_shipping_outlined,
            title: 'Sin ofertas nuevas',
            message: _isOnline
                ? _gpsDenied
                    ? 'Activa el permiso de ubicación para ver pedidos cercanos.'
                    : switch (_filter) {
                        OfferFilter.delivery =>
                          'No hay pedidos de tiendas cercanos por ahora.',
                        OfferFilter.ride =>
                          'No hay viajes de pasajeros cercanos por ahora.',
                        OfferFilter.all =>
                          'Aparecen cuando el comercio busca conductor. Revisa Mis pedidos.',
                      }
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
      filteredOffers.asMap().entries.map(
            (entry) => Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
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
    return DriverOfferCard(
      offer: offer,
      isLoading: _actionOrderId == offer.orderId,
      onTap: () => _openOffer(offer),
      onAccept: () => _accept(offer),
      onReject: () => _reject(offer),
    );
  }
}
