import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../features/offers/domain/entities/driver_offer.dart';
import '../../features/offers/presentation/screens/incoming_offer_screen.dart';
import '../di/providers.dart';
import 'app_router.dart';

/// Abre el modal fullscreen de oferta para [orderId] (fetch + retry corto).
Future<void> presentIncomingOfferForOrder(
  WidgetRef ref,
  int orderId, {
  bool goHomeFirst = true,
}) async {
  if (goHomeFirst) {
    ref.read(appRouterProvider).go('/home');
  }

  DriverOffer? offer = await _findOffer(ref, orderId);
  if (offer == null) {
    await Future<void>.delayed(const Duration(milliseconds: 800));
    offer = await _findOffer(ref, orderId);
  }
  if (offer == null) return;

  final nav = rootNavigatorKey.currentState;
  if (nav == null) return;

  await nav.push(
    MaterialPageRoute<bool>(
      settings: RouteSettings(name: 'incoming_offer_$orderId'),
      builder: (_) => IncomingOfferScreen(offer: offer!),
    ),
  );
}

Future<DriverOffer?> _findOffer(WidgetRef ref, int orderId) async {
  try {
    final offers = await ref.read(listDriverOffersUseCaseProvider).call();
    for (final o in offers) {
      if (o.orderId == orderId) return o;
    }
  } catch (_) {}
  return null;
}
