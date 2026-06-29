import 'package:flutter_test/flutter_test.dart';

import 'package:dts_driver/core/firebase/firebase_messaging_service.dart';
import 'package:dts_driver/features/notifications/domain/handlers/new_order_notification_handler.dart';

void main() {
  test('new_order_notification_handler_test', () {
    final handler = NewOrderNotificationHandler();
    int? capturedOrderId;

    handler.handleMessage(
      const RemotePushMessage(
        data: {'type': 'READY_FOR_PICKUP', 'order_id': '99'},
      ),
      (orderId) => capturedOrderId = orderId,
    );

    expect(capturedOrderId, 99);
  });

  test('ignores non READY_FOR_PICKUP messages', () {
    final handler = NewOrderNotificationHandler();
    var called = false;

    handler.handleMessage(
      const RemotePushMessage(data: {'type': 'ON_THE_WAY', 'order_id': '1'}),
      (_) => called = true,
    );

    expect(called, isFalse);
  });
}
