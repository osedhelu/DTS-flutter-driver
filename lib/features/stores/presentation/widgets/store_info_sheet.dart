import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/widgets/widgets.dart';
import '../../domain/entities/store.dart';

class StoreInfoSheet extends StatelessWidget {
  const StoreInfoSheet({super.key, required this.store});

  final Store store;

  static Future<void> show(BuildContext context, Store store) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => StoreInfoSheet(store: store),
    );
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/dir/?api=1&destination=${store.latitude},${store.longitude}&travelmode=driving',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  Future<void> _callPhone() async {
    final phone = store.phone?.trim();
    if (phone == null || phone.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: phone);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.paddingOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 0, 20, 16 + bottomInset),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _StoreLogo(logoUrl: store.logoUrl),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      store.name,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 8),
                    DtsStatusChip(
                      label: store.isOpen ? 'Abierto' : 'Cerrado',
                      tone: store.isOpen
                          ? DtsChipTone.success
                          : DtsChipTone.neutral,
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (store.address != null && store.address!.trim().isNotEmpty) ...[
            const SizedBox(height: 16),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.place_outlined, color: theme.colorScheme.outline),
                const SizedBox(width: 8),
                Expanded(child: Text(store.address!)),
              ],
            ),
          ],
          if (store.phone != null && store.phone!.trim().isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              onTap: _callPhone,
              borderRadius: BorderRadius.circular(8),
              child: Row(
                children: [
                  Icon(Icons.phone_outlined, color: theme.colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      store.phone!,
                      style: TextStyle(color: theme.colorScheme.primary),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          DtsPrimaryButton(
            label: 'Cómo llegar',
            icon: Icons.directions,
            onPressed: _openMaps,
          ),
        ],
      ),
    );
  }
}

class _StoreLogo extends StatelessWidget {
  const _StoreLogo({this.logoUrl});

  final String? logoUrl;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (logoUrl == null || logoUrl!.trim().isEmpty) {
      return CircleAvatar(
        radius: 28,
        backgroundColor: theme.colorScheme.secondaryContainer,
        child: Icon(Icons.storefront, color: theme.colorScheme.onSecondaryContainer),
      );
    }
    return CircleAvatar(
      radius: 28,
      backgroundColor: theme.colorScheme.surfaceContainerHighest,
      backgroundImage: NetworkImage(logoUrl!),
    );
  }
}
