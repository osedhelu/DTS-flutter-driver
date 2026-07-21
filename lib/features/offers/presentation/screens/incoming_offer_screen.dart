import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/providers.dart';
import '../../../../core/notifications/offer_ringtone_service.dart';
import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/driver_offer.dart';

/// Modal fullscreen de oferta entrante con countdown.
class IncomingOfferScreen extends ConsumerStatefulWidget {
  const IncomingOfferScreen({super.key, required this.offer});

  final DriverOffer offer;

  @override
  ConsumerState<IncomingOfferScreen> createState() =>
      _IncomingOfferScreenState();
}

class _IncomingOfferScreenState extends ConsumerState<IncomingOfferScreen> {
  static const _seconds = 45;
  int _remaining = _seconds;
  bool _busy = false;
  final _ringtone = OfferRingtoneService();

  @override
  void initState() {
    super.initState();
    HapticFeedback.heavyImpact();
    unawaited(_ringtone.start());
    _tick();
  }

  @override
  void dispose() {
    unawaited(_ringtone.dispose());
    super.dispose();
  }

  void _tick() async {
    while (mounted && _remaining > 0 && !_busy) {
      await Future<void>.delayed(const Duration(seconds: 1));
      if (!mounted || _busy) return;
      setState(() => _remaining--);
    }
    if (mounted && _remaining == 0 && !_busy) {
      await _reject(auto: true);
    }
  }

  Future<void> _accept() async {
    setState(() => _busy = true);
    await _ringtone.stop();
    try {
      await ref
          .read(acceptDriverOfferUseCaseProvider)
          .call(widget.offer.orderId);
      if (!mounted) return;
      // Cerrar el MaterialPageRoute antes de tocar go_router.
      Navigator.of(context).pop(true);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo aceptar la oferta')),
      );
      setState(() => _busy = false);
      unawaited(_ringtone.start());
    }
  }

  Future<void> _reject({bool auto = false}) async {
    setState(() => _busy = true);
    await _ringtone.stop();
    try {
      await ref
          .read(rejectDriverOfferUseCaseProvider)
          .call(widget.offer.orderId);
    } catch (_) {}
    if (!mounted) return;
    if (auto) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Oferta expirada')),
      );
    }
    Navigator.of(context).pop(false);
  }

  @override
  Widget build(BuildContext context) {
    final offer = widget.offer;
    final theme = Theme.of(context);
    final storePos = LatLng(offer.storeLatitude, offer.storeLongitude);
    final progress = _remaining / _seconds;

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  Text(
                    'Nueva oferta',
                    style: theme.textTheme.titleLarge,
                  ),
                  const Spacer(),
                  DtsStatusChip(
                    label: '${_remaining}s',
                    tone: _remaining <= 10
                        ? DtsChipTone.danger
                        : DtsChipTone.warning,
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 6,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: GoogleMap(
                    initialCameraPosition:
                        CameraPosition(target: storePos, zoom: 14),
                    markers: {
                      Marker(
                        markerId: const MarkerId('store'),
                        position: storePos,
                        infoWindow: InfoWindow(
                          title: offer.storeName.isEmpty
                              ? 'Comercio'
                              : offer.storeName,
                        ),
                      ),
                    },
                    myLocationEnabled: true,
                    zoomControlsEnabled: false,
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.storeName.isEmpty
                            ? 'Pedido #${offer.orderId}'
                            : offer.storeName,
                        style: theme.textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.near_me,
                              size: 18,
                              color: theme.colorScheme.primary),
                          const SizedBox(width: 6),
                          Text(
                            '${offer.distanceKm.toStringAsFixed(1)} km',
                            style: theme.textTheme.titleMedium,
                          ),
                          const Spacer(),
                          Text(
                            '\$${offer.total}',
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: theme.colorScheme.primary,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _reject(),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: DtsPrimaryButton(
                      label: 'Aceptar pedido',
                      isLoading: _busy,
                      onPressed: _accept,
                      icon: Icons.check,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
