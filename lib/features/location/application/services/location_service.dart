import 'dart:async';

import '../../../../core/location/geolocator_service.dart';
import '../../domain/usecases/send_location_usecase.dart';

typedef PeriodicTimerFactory = Timer Function(
  Duration duration,
  void Function(Timer timer) callback,
);

class LocationService {
  LocationService({
    required SendLocationUseCase sendLocationUseCase,
    required GeolocatorService geolocatorService,
    PeriodicTimerFactory? timerFactory,
    this.interval = const Duration(seconds: 10),
  })  : _sendLocationUseCase = sendLocationUseCase,
        _geolocatorService = geolocatorService,
        _timerFactory = timerFactory ?? Timer.periodic;

  final SendLocationUseCase _sendLocationUseCase;
  final GeolocatorService _geolocatorService;
  final PeriodicTimerFactory _timerFactory;
  final Duration interval;

  Timer? _timer;
  bool _isOnline = false;

  bool get isRunning => _timer != null;

  void start({required bool isOnline}) {
    _isOnline = isOnline;
    stop();
    if (!isOnline) return;

    _timer = _timerFactory(interval, (_) => _tick());
    unawaited(_tick());
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    try {
      final granted = await _geolocatorService.isPermissionGranted();
      if (!granted) return;

      final position = await _geolocatorService.getCurrentPosition();
      await _sendLocationUseCase.call(
        isOnline: _isOnline,
        latitude: position.latitude,
        longitude: position.longitude,
      );
    } catch (_) {
      // Ignorar errores puntuales de GPS/red en background.
    }
  }
}
