import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/driver_order.dart';
import '../../domain/entities/driver_earnings.dart';

class EarningsScreen extends ConsumerStatefulWidget {
  const EarningsScreen({super.key});

  @override
  ConsumerState<EarningsScreen> createState() => _EarningsScreenState();
}

class _EarningsScreenState extends ConsumerState<EarningsScreen> {
  String _period = 'today';
  DriverEarnings? _data;
  List<DriverOrder> _completedRides = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        ref.read(earningsRemoteDataSourceProvider).getEarnings(
              period: _period,
            ),
        ref.read(driverOrderRepositoryProvider).listOrders(),
      ]);
      if (!mounted) return;
      setState(() {
        _data = results[0] as DriverEarnings;
        _completedRides = (results[1] as List<DriverOrder>)
            .where((o) => o.isRide && o.status == 'ride_completed')
            .toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar las ganancias';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Ganancias')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: SegmentedButton<String>(
              segments: const [
                ButtonSegment(value: 'today', label: Text('Hoy')),
                ButtonSegment(value: 'week', label: Text('Semana')),
                ButtonSegment(value: 'month', label: Text('Mes')),
              ],
              selected: {_period},
              onSelectionChanged: (s) {
                setState(() => _period = s.first);
                _load();
              },
            ),
          ),
          Expanded(
            child: _loading
                ? const DtsLoading()
                : _error != null
                    ? DtsErrorView(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: ListView(
                          padding: const EdgeInsets.all(16),
                          children: [
                            Card(
                              child: Padding(
                                padding: const EdgeInsets.all(20),
                                child: Column(
                                  children: [
                                    Text(
                                      'Total',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                    Text(
                                      '\$${_data?.totalEarnings ?? '0'}',
                                      style: theme.textTheme.displaySmall
                                          ?.copyWith(
                                        color: theme.colorScheme.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    Text(
                                      '${_data?.deliveryCount ?? 0} entregas · ${_completedRides.length} viajes · ${_data?.currency ?? 'COP'}',
                                      style: theme.textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),
                            const DtsSectionHeader(title: 'Entregas'),
                            if (_data?.breakdown.isEmpty ?? true)
                              const DtsEmptyState(
                                icon: Icons.payments_outlined,
                                message:
                                    'Aún no hay ganancias en este periodo.',
                              )
                            else
                              ..._data!.breakdown.map(
                                (item) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text('Pedido #${item.orderId}'),
                                    subtitle: Text(item.completedAt),
                                    trailing: Text(
                                      '\$${item.earning}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            const SizedBox(height: 16),
                            const DtsSectionHeader(
                              title: 'Viajes de movilidad',
                              subtitle: 'Completados recientemente',
                            ),
                            if (_completedRides.isEmpty)
                              const DtsEmptyState(
                                icon: Icons.directions_car_outlined,
                                message:
                                    'Aún no hay viajes completados. Acepta un viaje para empezar.',
                              )
                            else
                              ..._completedRides.map(
                                (ride) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    leading: const Icon(
                                      Icons.directions_car_outlined,
                                    ),
                                    title: Text('Viaje #${ride.id}'),
                                    subtitle: Text(
                                      '${ride.pickupAddress.isEmpty ? 'Recogida' : ride.pickupAddress} → '
                                      '${ride.dropoffAddress.isEmpty ? 'Destino' : ride.dropoffAddress}',
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    trailing: Text(
                                      '\$${ride.total}',
                                      style:
                                          theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                ),
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
