import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';

/// Reproduce el tono de oferta entrante (loop corto) mientras el modal está abierto.
class OfferRingtoneService {
  OfferRingtoneService({AudioPlayer? player})
      : _player = player ?? AudioPlayer();

  final AudioPlayer _player;
  bool _playing = false;

  Future<void> start() async {
    if (_playing) return;
    try {
      await _player.setReleaseMode(ReleaseMode.loop);
      await _player.setVolume(1.0);
      await _player.play(AssetSource('sounds/new_order.wav'));
      _playing = true;
    } catch (e) {
      if (kDebugMode) debugPrint('OfferRingtone start failed: $e');
    }
  }

  Future<void> stop() async {
    if (!_playing) {
      try {
        await _player.stop();
      } catch (_) {}
      return;
    }
    try {
      await _player.stop();
    } catch (_) {}
    _playing = false;
  }

  Future<void> dispose() async {
    await stop();
    await _player.dispose();
  }
}
