import 'dart:async';

abstract class PushMessage {
  const PushMessage({required this.data});

  final Map<String, dynamic> data;

  String? get type => data['type'] as String?;
  int? get orderId {
    final raw = data['order_id'];
    if (raw == null) return null;
    return raw is int ? raw : int.tryParse('$raw');
  }
}

class RemotePushMessage extends PushMessage {
  const RemotePushMessage({required super.data});
}

abstract class FirebaseMessagingService {
  Stream<PushMessage> get onMessage;
  Future<void> initialize();
}

class MockFirebaseMessagingService implements FirebaseMessagingService {
  MockFirebaseMessagingService();

  final StreamController<PushMessage> _messageController =
      StreamController<PushMessage>.broadcast();

  @override
  Stream<PushMessage> get onMessage => _messageController.stream;

  @override
  Future<void> initialize() async {}

  void emit(PushMessage message) {
    _messageController.add(message);
  }

  void dispose() {
    _messageController.close();
  }
}
