import 'package:flutter/material.dart';

import '../../../../core/widgets/dts_status_chip.dart';
import '../../domain/entities/driver_offer.dart';

/// Tarjeta de oferta unificada (delivery / ride) con lenguaje visual moderno.
///
/// Jerarquía clara: tipo + título → ruta (viajes) → precio destacado → acciones.
/// Mantiene las `Key`s que usan los tests de widget:
/// - `offer_card_<orderId>`
/// - `offer_reject_<orderId>`
/// - `offer_accept_<orderId>`
class DriverOfferCard extends StatelessWidget {
  const DriverOfferCard({
    super.key,
    required this.offer,
    required this.isLoading,
    required this.onAccept,
    required this.onReject,
    this.onTap,
  });

  final DriverOffer offer;
  final bool isLoading;
  final VoidCallback onAccept;
  final VoidCallback onReject;

  /// Abre el modal de detalle (solo en el home mapa).
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isRide = offer.isRide;

    final avatarBg = isRide
        ? theme.colorScheme.secondaryContainer
        : theme.colorScheme.primaryContainer;
    final avatarIcon =
        isRide ? Icons.directions_car_outlined : Icons.storefront_outlined;

    return Card(
      key: Key('offer_card_${offer.orderId}'),
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: avatarBg,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Icon(
                      avatarIcon,
                      size: 28,
                      color: isRide
                          ? theme.colorScheme.onSecondaryContainer
                          : theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRide
                              ? 'Viaje #${offer.orderId}'
                              : offer.storeName.isEmpty
                                  ? 'Pedido #${offer.orderId}'
                                  : offer.storeName,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            height: 1.2,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${offer.distanceKm.toStringAsFixed(1)} km de distancia',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  DtsStatusChip(
                    label: offer.status,
                    tone: DtsStatusChip.toneForStatus(offer.status),
                  ),
                ],
              ),
              if (isRide) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(
                      alpha: 0.55,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _OfferRouteLine(
                        icon: Icons.trip_origin,
                        color: theme.colorScheme.primary,
                        text: offer.pickupAddress.isEmpty
                            ? 'Recogida sin dirección'
                            : offer.pickupAddress,
                      ),
                      const SizedBox(height: 8),
                      _OfferRouteLine(
                        icon: Icons.place_outlined,
                        color: Colors.green,
                        text: offer.dropoffAddress.isEmpty
                            ? 'Destino sin dirección'
                            : offer.dropoffAddress,
                      ),
                      if (offer.estimatedDurationMinutes != null) ...[
                        const SizedBox(height: 10),
                        Text(
                          '~ ${offer.estimatedDurationMinutes} min estimados',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isRide ? 'Viaje' : 'Total a pagar',
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${offer.total}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            height: 1.1,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isLoading)
                    const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                ],
              ),
              const SizedBox(height: 18),
              if (isLoading)
                const LinearProgressIndicator(minHeight: 4)
              else
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        key: Key('offer_reject_${offer.orderId}'),
                        onPressed: onReject,
                        icon: const Icon(Icons.close, size: 20),
                        label: const Text('Rechazar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        key: Key('offer_accept_${offer.orderId}'),
                        onPressed: onAccept,
                        icon: Icon(
                          isRide ? Icons.directions_car_outlined : Icons.check,
                          size: 20,
                        ),
                        label: Text(isRide ? 'Aceptar viaje' : 'Aceptar'),
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

class _OfferRouteLine extends StatelessWidget {
  const _OfferRouteLine({
    required this.icon,
    required this.color,
    required this.text,
  });

  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurface,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
