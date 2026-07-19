import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';
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
      final order =
          await ref.read(driverOrderRepositoryProvider).getOrder(widget.orderId);
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
    final theme = Theme.of(context);

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
      body: _isLoading
          ? const DtsLoading()
          : order == null
              ? DtsErrorView(
                  message: _error ?? 'Pedido no encontrado',
                  onRetry: _loadOrder,
                )
              : ListView(
                  padding: const EdgeInsets.all(24),
                  children: [
                    Row(
                      children: [
                        DtsStatusChip(
                          label: order.status,
                          tone: DtsStatusChip.toneForStatus(order.status),
                        ),
                        const Spacer(),
                        if (order.isActive)
                          TextButton(
                            onPressed: () =>
                                context.push('/active/${order.id}'),
                            child: const Text('Abrir mapa'),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      order.storeName.isNotEmpty
                          ? order.storeName
                          : 'Comercio #${order.storeId}',
                      style: theme.textTheme.headlineSmall,
                    ),
                    Text('Total: \$${order.total}'),
                    if (order.driverEarning.isNotEmpty)
                      Text(
                        'Tu ganancia: \$${order.driverEarning}',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    if (order.deliveryAddress.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text('Entrega: ${order.deliveryAddress}'),
                    ],
                    if (order.customerNotes.isNotEmpty)
                      Text('Notas: ${order.customerNotes}'),
                    if (order.items.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const DtsSectionHeader(title: 'Artículos'),
                      ...order.items.map(
                        (i) => ListTile(
                          contentPadding: EdgeInsets.zero,
                          title: Text(i.productName),
                          subtitle: Text('${i.quantity} × \$${i.unitPrice}'),
                          trailing: Text('\$${i.subtotal}'),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    if (order.status == OrderStatusValues.driverAssigned)
                      DtsPrimaryButton(
                        key: const Key('accept_order_button'),
                        label: 'Aceptar / Abrir entrega',
                        isLoading: _actionLoading,
                        onPressed: () => _runAction(
                          () async {
                            await ref
                                .read(acceptOrderUseCaseProvider)
                                .call(order.id);
                            if (context.mounted) {
                              context.push('/active/${order.id}');
                            }
                          },
                        ),
                      ),
                    if (order.status == OrderStatusValues.pickedUp)
                      DtsPrimaryButton(
                        key: const Key('confirm_pickup_button'),
                        label: 'Confirmar recogida / En camino',
                        isLoading: _actionLoading,
                        onPressed: () => _runAction(
                          () => ref
                              .read(confirmPickupUseCaseProvider)
                              .call(order.id),
                        ),
                      ),
                    if (order.status == OrderStatusValues.onTheWay)
                      DtsPrimaryButton(
                        key: const Key('confirm_delivery_button'),
                        label: 'Confirmar entrega',
                        isLoading: _actionLoading,
                        onPressed: () => _runAction(
                          () => ref
                              .read(confirmDeliveryUseCaseProvider)
                              .call(order.id),
                        ),
                      ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Text(
                        _error!,
                        style: TextStyle(color: theme.colorScheme.error),
                      ),
                    ],
                  ],
                ),
    );
  }
}
