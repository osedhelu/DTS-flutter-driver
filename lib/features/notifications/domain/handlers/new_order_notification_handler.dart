import '../../../../core/firebase/firebase_messaging_service.dart';

typedef NewOrderCallback = void Function(int orderId);

class NewOrderNotificationHandler {
  const NewOrderNotificationHandler();

  static const readyTypes = {
    'READY_FOR_PICKUP',
    'ready_for_pickup',
    'searching_driver',
    'SEARCHING_DRIVER',
  };

  void handleMessage(PushMessage message, NewOrderCallback onNewOrder) {
    final type = message.type;
    if (type == null || !readyTypes.contains(type)) return;
    final orderId = message.orderId;
    if (orderId == null) return;
    onNewOrder(orderId);
  }
}
