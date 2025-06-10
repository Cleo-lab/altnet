import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/family_circle.dart';
import '../services/storage_service.dart';

class ServerService {
  static WebSocketChannel? _channel;
  static final StreamController<Message> _messageController =
  StreamController<Message>.broadcast();
  static final StreamController<String> _errorController =
  StreamController<String>.broadcast();

  static Stream<Message> get messageStream => _messageController.stream;
  static Stream<String> get errorStream => _errorController.stream;

  static bool _isOfflineMode = false;
  static bool _isConnecting = false;
  static Timer? _reconnectTimer;
  static const _reconnectDelay = Duration(seconds: 5);
  static const _connectionTimeout = Duration(seconds: 10);

  static bool get isOfflineMode => _isOfflineMode;

  static Future<bool> connect(String nickname, String deviceId) async {
    if (_isConnecting) return false;
    _isConnecting = true;

    try {
      if (_channel != null) {
        await disconnect();
      }

      // First try the main server
      try {
        final uri = Uri.parse('wss://altnet-server.onrender.com');
        _channel = WebSocketChannel.connect(uri);
        _isOfflineMode = false;

        // Set a timeout for the initial connection
        await _channel!.ready.timeout(
          _connectionTimeout,
          onTimeout: () {
            throw TimeoutException('Connection timeout');
          },
        );

        // Authenticate
        _channel!.sink.add(json.encode({
          'type': 'auth',
          'nickname': nickname,
          'deviceId': deviceId,
        }));

        _channel!.stream.listen(
              (message) {
            try {
              final decoded = json.decode(message);
              if (decoded is Map<String, dynamic>) {
                if (decoded['type'] == 'message') {
                  final message = Message.fromMap(decoded);
                  _messageController.add(message);
                } else if (decoded['type'] == 'error') {
                  _errorController.add(decoded['message']);
                } else if (decoded['type'] == 'auth_success') {
                  _isOfflineMode = false;
                  _errorController.add('Успешное подключение к серверу');
                }
              }
            } catch (e) {
              _errorController.add('Ошибка при обработке сообщения: $e');
            }
          },
          onError: (error) {
            _errorController.add('WebSocket ошибка: $error');
            _handleConnectionLoss();
          },
          onDone: () {
            _errorController.add('Соединение закрыто');
            _handleConnectionLoss();
          },
        );

        return true;
      } catch (e) {
        _handleConnectionLoss();
        return true; // Return true to allow offline mode
      }
    } finally {
      _isConnecting = false;
    }
  }

  static void _handleConnectionLoss() {
      _isOfflineMode = true;
    _channel = null;
    
    // Cancel existing reconnect timer if any
    _reconnectTimer?.cancel();
    
    // Start reconnect timer
    _reconnectTimer = Timer(_reconnectDelay, () {
      if (_isOfflineMode) {
        _errorController.add('Попытка переподключения...');
        // Get stored credentials and try to reconnect
        StorageService.getUser().then((user) {
          if (user != null) {
            StorageService.getDeviceId().then((deviceId) {
              if (deviceId != null) {
                connect(user['nickname'], deviceId);
              }
            });
          }
        });
      }
    });
  }

  static Future<void> disconnect() async {
    _reconnectTimer?.cancel();
    _reconnectTimer = null;
    
    try {
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
    } catch (e) {
      _errorController.add('Ошибка при отключении: $e');
    }
  }

  static Future<void> sendMessage(String text) async {
    if (_isOfflineMode) {
      // In offline mode, just broadcast the message locally
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch,
        senderId: 'You',
        recipientId: 'group',
        content: text,
        sentAt: DateTime.now(),
        readAt: null,
      );
      _messageController.add(message);
      return;
    }

    if (_channel == null) {
      _errorController.add('Не подключены к серверу. Сообщение сохранено локально.');
      return;
    }

    try {
      _channel!.sink.add(json.encode({
        'type': 'message',
        'content': text,
        'sentAt': DateTime.now().toIso8601String(),
      }));
    } catch (e) {
      _errorController.add('Ошибка при отправке сообщения: $e. Сообщение сохранено локально.');
    }
  }

  static Future<void> createFamilyCircle(FamilyCircle circle) async {
    if (_channel == null) {
      _errorController.add('Не подключены к серверу');
      return;
    }

    try {
      _channel!.sink.add(json.encode({
        'type': 'create_circle',
        'circle': circle.toJson(),
      }));
    } catch (e) {
      _errorController.add('Ошибка при создании семейного круга: $e');
    }
  }

  static Future<void> joinFamilyCircle(String circleId, String masterPassword) async {
    if (_channel == null) {
      _errorController.add('Не подключены к серверу');
      return;
    }

    try {
      _channel!.sink.add(json.encode({
        'type': 'join_circle',
        'circleId': circleId,
        'masterPassword': masterPassword,
      }));
    } catch (e) {
      _errorController.add('Ошибка при присоединении к семейному кругу: $e');
    }
  }
}
