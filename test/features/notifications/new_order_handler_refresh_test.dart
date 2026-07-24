import 'package:dts_driver/core/firebase/firebase_messaging_service.dart';
import 'package:dts_driver/features/notifications/domain/handlers/new_order_notification_handler.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('A5 readyTypes incluye searching_driver y dispara callback', () {
    final handler = NewOrderNotificationHandler();
    int? received;
    handler.handleMessage(
      const RemotePushMessage(
        data: {
          'type': 'searching_driver',
          'order_id': '99',
        },
      ),
      (id) => received = id,
    );
    expect(received, 99);
  });
}
