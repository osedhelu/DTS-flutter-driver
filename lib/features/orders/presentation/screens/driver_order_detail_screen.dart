import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/di/providers.dart';
import '../../domain/entities/driver_order.dart';
import '../../domain/value_objects/order_status.dart';

class DriverOrderDetailScreen extends ConsumerStatefulWidget {
  const DriverOrderDetailScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<DriverOrderDetailScreen> createState() =>
      _DriverOrderDetailScreenState();
}

class _DriverOrderDetailScreenState
    extends ConsumerState<DriverOrderDetailScreen> {
  DriverOrder? _order;
  bool _isLoading = true;
  String? _error;
  bool _actionLoading = false;

  @override
  void initState() {
    super.initState();
    _loadOrder();
  }

  Future<void> _loadOrder() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final orders =
          await ref.read(driverOrderRepositoryProvider).listOrders();
      final order = orders.firstWhere((o) => o.id == widget.orderId);
      if (!mounted) return;
      setState(() {
        _order = order;
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _error = 'Pedido no encontrado';
        _isLoading = false;
      });
    }
  }

  Future<void> _runAction(Future<void> Function() action) async {
    setState(() => _actionLoading = true);
    try {
      await action();
      await _loadOrder();
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'No se pudo actualizar el pedido');
      }
    } finally {
      if (mounted) setState(() => _actionLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final order = _order;

    return Scaffold(
      appBar: AppBar(title: Text('Pedido #${widget.orderId}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : order == null
              ? Center(child: Text(_error ?? 'Pedido no encontrado'))
              : Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Estado: ${order.status}',
                          style: Theme.of(context).textTheme.titleLarge),
                      Text('Total: \$${order.total}'),
                      Text('Artículos: ${order.itemCount}'),
                      const SizedBox(height: 24),
                      if (order.status == OrderStatusValues.driverAssigned)
                        FilledButton(
                          key: const Key('accept_order_button'),
                          onPressed: _actionLoading
                              ? null
                              : () => _runAction(
                                    () => ref
                                        .read(acceptOrderUseCaseProvider)
                                        .call(order.id),
                                  ),
                          child: const Text('Aceptar pedido'),
                        ),
                      if (order.status == OrderStatusValues.pickedUp)
                        FilledButton(
                          key: const Key('confirm_pickup_button'),
                          onPressed: _actionLoading
                              ? null
                              : () => _runAction(
                                    () => ref
                                        .read(confirmPickupUseCaseProvider)
                                        .call(order.id),
                                  ),
                          child: const Text('Confirmar recogida'),
                        ),
                      if (order.status == OrderStatusValues.onTheWay)
                        FilledButton(
                          key: const Key('confirm_delivery_button'),
                          onPressed: _actionLoading
                              ? null
                              : () => _runAction(
                                    () => ref
                                        .read(confirmDeliveryUseCaseProvider)
                                        .call(order.id),
                                  ),
                          child: const Text('Confirmar entrega'),
                        ),
                      if (_actionLoading)
                        const Padding(
                          padding: EdgeInsets.only(top: 16),
                          child: LinearProgressIndicator(),
                        ),
                      if (_error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          _error!,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.error,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
    );
  }
}
