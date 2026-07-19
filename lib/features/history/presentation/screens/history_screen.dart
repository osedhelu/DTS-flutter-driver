import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../../orders/domain/entities/driver_order.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  List<DriverOrder> _orders = [];
  bool _loading = true;
  String? _error;
  String _filter = 'all';

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
      final orders = await ref.read(driverOrderRepositoryProvider).listOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders.where((o) => o.isCompleted || o.isActive).toList();
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudo cargar el historial';
        _loading = false;
      });
    }
  }

  List<DriverOrder> get _filtered {
    return switch (_filter) {
      'delivered' => _orders.where((o) => o.status == 'delivered').toList(),
      'cancelled' => _orders.where((o) => o.status == 'cancelled').toList(),
      'active' => _orders.where((o) => o.isActive).toList(),
      _ => _orders,
    };
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Historial')),
      body: Column(
        children: [
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                for (final entry in [
                  ('all', 'Todos'),
                  ('active', 'Activos'),
                  ('delivered', 'Entregados'),
                  ('cancelled', 'Cancelados'),
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: FilterChip(
                      label: Text(entry.$2),
                      selected: _filter == entry.$1,
                      onSelected: (_) => setState(() => _filter = entry.$1),
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: _loading
                ? const DtsLoading()
                : _error != null
                    ? DtsErrorView(message: _error!, onRetry: _load)
                    : RefreshIndicator(
                        onRefresh: _load,
                        child: _filtered.isEmpty
                            ? ListView(
                                children: const [
                                  SizedBox(height: 80),
                                  DtsEmptyState(
                                    icon: Icons.history,
                                    title: 'Sin pedidos',
                                    message:
                                        'Aquí verás tus entregas completadas.',
                                  ),
                                ],
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.all(16),
                                itemCount: _filtered.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(height: 10),
                                itemBuilder: (context, i) {
                                  final order = _filtered[i];
                                  return Card(
                                    child: ListTile(
                                      title: Text(
                                        order.storeName.isNotEmpty
                                            ? order.storeName
                                            : 'Pedido #${order.id}',
                                      ),
                                      subtitle: Text(
                                        '${order.status} · \$${order.total}',
                                      ),
                                      trailing: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.end,
                                        children: [
                                          DtsStatusChip(
                                            label: order.status,
                                            tone: DtsStatusChip.toneForStatus(
                                              order.status,
                                            ),
                                          ),
                                          if (order.driverEarning.isNotEmpty)
                                            Text(
                                              '+\$${order.driverEarning}',
                                              style: theme.textTheme.labelLarge
                                                  ?.copyWith(
                                                color: theme.colorScheme.primary,
                                              ),
                                            ),
                                        ],
                                      ),
                                      onTap: () =>
                                          context.push('/orders/${order.id}'),
                                    ),
                                  );
                                },
                              ),
                      ),
          ),
        ],
      ),
    );
  }
}
