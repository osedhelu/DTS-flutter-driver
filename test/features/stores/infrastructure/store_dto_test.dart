import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/features/stores/infrastructure/models/store_dto.dart';

void main() {
  group('StoreDto.fromJson', () {
    test('parsea latitude y longitude', () {
      final dto = StoreDto.fromJson({
        'id': 1,
        'name': 'Tienda Demo',
        'latitude': 4.711,
        'longitude': -74.0721,
        'address': 'Calle 100',
        'phone': '+573001234567',
        'logo_url': 'https://cdn.example/logo.png',
        'is_open': true,
        'status': 'open',
        'vertical': 'restaurant',
      });

      expect(dto.id, 1);
      expect(dto.name, 'Tienda Demo');
      expect(dto.latitude, 4.711);
      expect(dto.longitude, -74.0721);
      expect(dto.address, 'Calle 100');
      expect(dto.phone, '+573001234567');
      expect(dto.isOpen, isTrue);

      final entity = dto.toEntity();
      expect(entity.latitude, dto.latitude);
      expect(entity.longitude, dto.longitude);
      expect(entity.hasValidLocation, isTrue);
    });

    test('is_open default true cuando falta en JSON', () {
      final dto = StoreDto.fromJson({
        'id': 2,
        'name': 'Otra tienda',
        'latitude': 4.65,
        'longitude': -74.08,
      });

      expect(dto.isOpen, isTrue);
    });
  });
}
