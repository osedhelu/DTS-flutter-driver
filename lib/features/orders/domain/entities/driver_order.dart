import 'package:equatable/equatable.dart';

class DriverOrder extends Equatable {
  const DriverOrder({
    required this.id,
    required this.storeId,
    required this.status,
    required this.total,
    required this.itemCount,
  });

  final int id;
  final int storeId;
  final String status;
  final String total;
  final int itemCount;

  @override
  List<Object?> get props => [id, storeId, status, total, itemCount];
}
