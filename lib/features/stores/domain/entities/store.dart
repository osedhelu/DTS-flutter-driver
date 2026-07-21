class Store {
  const Store({
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

  bool get hasValidLocation =>
      latitude >= -90 &&
      latitude <= 90 &&
      longitude >= -180 &&
      longitude <= 180 &&
      !(latitude == 0 && longitude == 0);
}
