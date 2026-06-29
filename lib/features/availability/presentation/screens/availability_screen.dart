import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/providers.dart';

class AvailabilityScreen extends ConsumerStatefulWidget {
  const AvailabilityScreen({super.key});

  @override
  ConsumerState<AvailabilityScreen> createState() => _AvailabilityScreenState();
}

class _AvailabilityScreenState extends ConsumerState<AvailabilityScreen> {
  bool _isOnline = false;
  bool _isLoading = false;
  String? _error;
  double? _latitude;
  double? _longitude;

  @override
  void initState() {
    super.initState();
    _loadInitialPosition();
  }

  Future<void> _loadInitialPosition() async {
    final geolocator = ref.read(geolocatorServiceProvider);
    final granted = await geolocator.isPermissionGranted() ||
        await geolocator.requestPermission();
    if (!granted || !mounted) return;

    try {
      final position = await geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (_) {
      // GPS opcional al cargar; el switch pedirá permiso al activarse.
    }
  }

  Future<void> _onToggle(bool value) async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      if (value) {
        final geolocator = ref.read(geolocatorServiceProvider);
        final granted = await geolocator.isPermissionGranted() ||
            await geolocator.requestPermission();
        if (!granted) {
          throw Exception('Permiso de ubicación denegado');
        }
        final position = await geolocator.getCurrentPosition();
        _latitude = position.latitude;
        _longitude = position.longitude;
      }

      final availability = await ref.read(toggleOnlineUseCaseProvider).call(
            isOnline: value,
            latitude: _latitude,
            longitude: _longitude,
          );

      if (!mounted) return;
      setState(() {
        _isOnline = availability.isOnline;
        _latitude = availability.latitude ?? _latitude;
        _longitude = availability.longitude ?? _longitude;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Disponibilidad'),
        actions: [
          IconButton(
            key: const Key('go_orders'),
            icon: const Icon(Icons.list_alt),
            onPressed: () => context.go('/orders'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SwitchListTile(
              key: const Key('availability_switch'),
              title: const Text('En línea'),
              subtitle: Text(_isOnline ? 'Recibiendo pedidos' : 'Fuera de línea'),
              value: _isOnline,
              onChanged: _isLoading ? null : _onToggle,
            ),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.only(top: 16),
                child: LinearProgressIndicator(),
              ),
            if (_latitude != null && _longitude != null) ...[
              const SizedBox(height: 16),
              Text('Ubicación: $_latitude, $_longitude'),
            ],
            if (_error != null) ...[
              const SizedBox(height: 16),
              Text(
                _error!,
                style: TextStyle(color: Theme.of(context).colorScheme.error),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
