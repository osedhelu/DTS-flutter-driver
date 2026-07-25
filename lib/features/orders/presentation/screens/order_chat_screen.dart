import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import '../../../../core/config/env.dart';
import '../../../../core/di/providers.dart';
import '../../../../core/widgets/widgets.dart';

class OrderChatScreen extends ConsumerStatefulWidget {
  const OrderChatScreen({super.key, required this.orderId});

  final int orderId;

  @override
  ConsumerState<OrderChatScreen> createState() => _OrderChatScreenState();
}

class _OrderChatScreenState extends ConsumerState<OrderChatScreen> {
  final _controller = TextEditingController();
  final _scroll = ScrollController();
  final _messages = <Map<String, dynamic>>[];
  bool _loading = true;
  bool _sending = false;
  bool _chatClosed = false;
  WebSocketChannel? _channel;
  StreamSubscription? _sub;
  Timer? _poll;

  bool _sameId(dynamic a, dynamic b) {
    if (a == null || b == null) return false;
    return a.toString() == b.toString();
  }

  void _upsert(Map<String, dynamic> msg) {
    final id = msg['id'];
    final idx = _messages.indexWhere((m) => _sameId(m['id'], id));
    if (idx >= 0) {
      _messages[idx] = msg;
    } else {
      _messages.add(msg);
    }
  }

  List<dynamic> _extractMessages(dynamic data) {
    if (data is List) return data;
    if (data is Map && data['messages'] is List) {
      return data['messages'] as List;
    }
    return const [];
  }

  bool _extractClosed(dynamic data) {
    if (data is Map && data['chat_closed'] == true) return true;
    return false;
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
    _poll = Timer.periodic(const Duration(seconds: 8), (_) {
      if (mounted) unawaited(_loadHistory(silent: true));
    });
  }

  @override
  void dispose() {
    _poll?.cancel();
    _sub?.cancel();
    _channel?.sink.close();
    _controller.dispose();
    _scroll.dispose();
    super.dispose();
  }

  Future<void> _bootstrap() async {
    await _loadHistory();
    await _connectWs();
  }

  Future<void> _loadHistory({bool silent = false}) async {
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.get('/orders/${widget.orderId}/messages/');
      final list = _extractMessages(res.data);
      final closed = _extractClosed(res.data);
      if (!mounted) return;
      setState(() {
        if (!silent) _messages.clear();
        for (final e in list) {
          _upsert(Map<String, dynamic>.from(e as Map));
        }
        _chatClosed = closed;
        _loading = false;
      });
      if (!silent) _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      if (!silent) setState(() => _loading = false);
    }
  }

  Future<void> _connectWs() async {
    try {
      final token = await ref.read(tokenStorageProvider).getAccessToken();
      if (token == null || token.isEmpty) return;
      final uri = EnvConfig.buildWsUri(
        '/ws/orders/${widget.orderId}/chat/'
        '?token=${Uri.encodeQueryComponent(token)}',
      );
      final channel = WebSocketChannel.connect(uri);
      await channel.ready;
      if (!mounted) {
        await channel.sink.close();
        return;
      }
      _channel = channel;
      _sub = channel.stream.listen(
        (event) {
          try {
            final data = jsonDecode(event as String) as Map<String, dynamic>;
            if (data['type'] == 'chat.closed') {
              if (!mounted) return;
              setState(() => _chatClosed = true);
              return;
            }
            if (data['type'] == 'message' ||
                data.containsKey('body') ||
                data['message_type'] == 'image') {
              if (!mounted) return;
              setState(() => _upsert(data));
              _scrollToEnd();
            }
          } catch (_) {}
        },
        onError: (_) {},
        cancelOnError: true,
      );
    } catch (_) {}
  }

  void _scrollToEnd() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scroll.hasClients) return;
      _scroll.animateTo(
        _scroll.position.maxScrollExtent + 80,
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty || _sending || _chatClosed) return;
    setState(() => _sending = true);
    try {
      final dio = ref.read(apiClientProvider).dio;
      final res = await dio.post(
        '/orders/${widget.orderId}/messages/',
        data: {'body': text},
      );
      _controller.clear();
      if (!mounted) return;
      final msg = Map<String, dynamic>.from(res.data as Map);
      setState(() => _upsert(msg));
      _scrollToEnd();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo enviar el mensaje')),
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Widget _bubble(Map<String, dynamic> m) {
    final mine = m['sender_role'] == 'driver';
    final imageUrl = m['image_url']?.toString() ?? '';
    final isImage =
        m['message_type']?.toString() == 'image' && imageUrl.isNotEmpty;
    final body = m['body']?.toString() ?? '';
    final created = m['created_at']?.toString();
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine
              ? Theme.of(context).colorScheme.primaryContainer
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  imageUrl,
                  width: 220,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const Text('Foto no disponible'),
                ),
              ),
            if (body.isNotEmpty) ...[
              if (isImage) const SizedBox(height: 6),
              Text(body),
            ],
            if (created != null && created.isNotEmpty)
              Text(
                created.length > 16 ? created.substring(11, 16) : created,
                style: Theme.of(context).textTheme.labelSmall,
              ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Chat #${widget.orderId}')),
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? const DtsLoading()
                : _messages.isEmpty
                    ? const DtsEmptyState(
                        icon: Icons.chat_bubble_outline,
                        title: 'Sin mensajes',
                        message: 'Escribe al cliente o al comercio.',
                      )
                    : ListView.builder(
                        controller: _scroll,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) => _bubble(_messages[i]),
                      ),
          ),
          if (_chatClosed)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                child: Text(
                  'Chat cerrado — pedido entregado',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _controller,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _send(),
                        decoration: const InputDecoration(
                          hintText: 'Escribe al cliente…',
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: _send,
                      icon: const Icon(Icons.send),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
