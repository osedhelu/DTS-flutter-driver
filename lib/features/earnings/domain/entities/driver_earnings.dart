import 'package:equatable/equatable.dart';

class DriverEarningItem extends Equatable {
  const DriverEarningItem({
    required this.orderId,
    required this.completedAt,
    required this.orderTotal,
    required this.earning,
  });

  final int orderId;
  final String completedAt;
  final String orderTotal;
  final String earning;

  @override
  List<Object?> get props => [orderId, completedAt, orderTotal, earning];
}

class DriverEarnings extends Equatable {
  const DriverEarnings({
    required this.period,
    required this.deliveryCount,
    required this.totalEarnings,
    required this.currency,
    required this.breakdown,
  });

  final String period;
  final int deliveryCount;
  final String totalEarnings;
  final String currency;
  final List<DriverEarningItem> breakdown;

  @override
  List<Object?> get props =>
      [period, deliveryCount, totalEarnings, currency, breakdown];
}
