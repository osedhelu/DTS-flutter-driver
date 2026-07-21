import '../../domain/entities/store.dart';

class StoreDto {
  const StoreDto({
    required this.id,
    required this.name,
    required this.latitude,
    required this.longitude,
    this.address,
    this.phone,
    this.description,
    this.logoUrl,
    this.isOpen = true,
    this.status,
    this.vertical,
  });

  final int id;
  final String name;
  final double latitude;
  final double longitude;
  final String? address;
  final String? phone;
  final String? description;
  final String? logoUrl;
  final bool isOpen;
  final String? status;
  final String? vertical;

  factory StoreDto.fromJson(Map<String, dynamic> json) {
    return StoreDto(
      id: json['id'] as int,
      name: json['name'] as String,
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      address: json['address'] as String?,
      phone: json['phone'] as String?,
      description: json['description'] as String?,
      logoUrl: json['logo_url'] as String?,
      isOpen: json['is_open'] as bool? ?? true,
      status: json['status'] as String?,
      vertical: json['vertical'] as String?,
    );
  }

  Store toEntity() => Store(
        id: id,
        name: name,
        latitude: latitude,
        longitude: longitude,
        address: address,
        phone: phone,
        description: description,
        logoUrl: logoUrl,
        isOpen: isOpen,
        status: status,
        vertical: vertical,
      );
}
