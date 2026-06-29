import '../../../../core/firebase/firebase_messaging_service.dart';

typedef NewOrderCallback = void Function(int orderId);

class NewOrderNotificationHandler {
  const NewOrderNotificationHandler();

  static const readyForPickupType = 'READY_FOR_PICKUP';

  void handleMessage(PushMessage message, NewOrderCallback onNewOrder) {
    if (message.type != readyForPickupType) return;
    final orderId = message.orderId;
    if (orderId == null) return;
    onNewOrder(orderId);
  }
}
