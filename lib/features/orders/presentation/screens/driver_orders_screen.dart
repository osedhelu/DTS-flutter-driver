import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_order.dart';

class DriverOrdersScreen extends ConsumerStatefulWidget {
  const DriverOrdersScreen({super.key});

  @override
  ConsumerState<DriverOrdersScreen> createState() => _DriverOrdersScreenState();
}

class _DriverOrdersScreenState extends ConsumerState<DriverOrdersScreen> {
  List<DriverOrder> _orders = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders = await ref.read(driverOrderRepositoryProvider).listOrders();
      if (!mounted) return;
      setState(() {
        _orders = orders;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'No se pudieron cargar los pedidos';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.history),
            onPressed: () => context.push('/history'),
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const DtsLoading()
          : _error != null
              ? DtsErrorView(message: _error!, onRetry: _loadOrders)
              : RefreshIndicator(
                  onRefresh: _loadOrders,
                  child: _orders.isEmpty
                      ? ListView(
                          children: const [
                            SizedBox(height: 100),
                            DtsEmptyState(
                              icon: Icons.list_alt,
                              title: 'Sin pedidos',
                              message:
                                  'Cuando aceptes una oferta, aparecerá aquí.',
                            ),
                          ],
                        )
                      : ListView.separated(
                          padding: const EdgeInsets.all(16),
                          itemCount: _orders.length,
                          separatorBuilder: (_, __) =>
                              const SizedBox(height: 10),
                          itemBuilder: (context, index) {
                            final order = _orders[index];
                            return Card(
                              key: Key('order_tile_${order.id}'),
                              child: ListTile(
                                title: Text(
                                  order.storeName.isNotEmpty
                                      ? order.storeName
                                      : 'Pedido #${order.id}',
                                ),
                                subtitle: Text(
                                  '${order.status} · \$${order.total} · ${order.itemCount} ítems',
                                ),
                                trailing: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    DtsStatusChip(
                                      label: order.status,
                                      tone: DtsStatusChip.toneForStatus(
                                        order.status,
                                      ),
                                    ),
                                    const Icon(Icons.chevron_right),
                                  ],
                                ),
                                onTap: () {
                                  if (order.isActive) {
                                    context.push('/active/${order.id}');
                                  } else {
                                    context.go('/orders/${order.id}');
                                  }
                                },
                              ),
                            );
                          },
                        ),
                ),
    );
  }
}
