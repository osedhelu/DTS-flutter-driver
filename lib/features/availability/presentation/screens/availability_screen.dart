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
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    try {
      final profile = await ref.read(getDriverProfileUseCaseProvider).call();
      if (!mounted) return;
      setState(() => _isOnline = profile.isOnline);
      ref.read(locationServiceProvider).start(isOnline: profile.isOnline);
    } catch (_) {
      // Perfil no disponible; el switch arranca en offline.
    }
    await _loadInitialPosition();
  }

  Future<void> _loadInitialPosition() async {
    final geolocator = ref.read(geolocatorServiceProvider);

    try {
      final alreadyGranted = await geolocator.isPermissionGranted();
      final granted =
          alreadyGranted || await geolocator.requestPermission();
      if (!granted || !mounted) return;

      final position = await geolocator.getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _latitude = position.latitude;
        _longitude = position.longitude;
      });
    } catch (e) {
      // GPS opcional al cargar; el switch pedirá permiso al activarse.
    }
  }

  Future<void> _onToggle(bool value) async {
    final previous = _isOnline;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      double? latitude = _latitude;
      double? longitude = _longitude;

      if (value) {
        final geolocator = ref.read(geolocatorServiceProvider);
        final granted = await geolocator.isPermissionGranted() ||
            await geolocator.requestPermission();
        if (!granted) {
          throw Exception('Permiso de ubicación denegado');
        }
        final position = await geolocator.getCurrentPosition();
        latitude = position.latitude;
        longitude = position.longitude;
      }

      final availability = await ref.read(toggleOnlineUseCaseProvider).call(
            isOnline: value,
            latitude: value ? latitude : null,
            longitude: value ? longitude : null,
          );

      if (!mounted) return;
      setState(() {
        _isOnline = availability.isOnline;
        _latitude = availability.latitude ?? latitude;
        _longitude = availability.longitude ?? longitude;
        _isLoading = false;
      });
      ref.read(locationServiceProvider).start(isOnline: availability.isOnline);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOnline = previous;
        _error = e.toString();
        _isLoading = false;
      });
      ref.read(locationServiceProvider).start(isOnline: previous);
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
