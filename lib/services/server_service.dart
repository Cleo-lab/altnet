import 'dart:async';
import 'dart:convert';
import 'package:web_socket_channel/web_socket_channel.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/family_circle.dart';

class ServerService {
  static WebSocketChannel? _channel;
  static final StreamController<Message> _messageController =
  StreamController<Message>.broadcast();
  static final StreamController<String> _errorController =
  StreamController<String>.broadcast();

  static Stream<Message> get messageStream => _messageController.stream;
  static Stream<String> get errorStream => _errorController.stream;

  static bool _isOfflineMode = false;

  static bool get isOfflineMode => _isOfflineMode;

  static Future<bool> connect(String nickname, String deviceId) async {
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
          const Duration(seconds: 5),
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
                  final message = Message.fromJson(decoded);
                  _messageController.add(message);
                } else if (decoded['type'] == 'error') {
                  _errorController.add(decoded['message']);
                }
              }
            } catch (e) {
              _errorController.add('Ошибка при обработке сообщения: $e');
            }
          },
          onError: (error) {
            _errorController.add('WebSocket ошибка: $error');
            _isOfflineMode = true;
          },
          onDone: () {
            _errorController.add('Соединение закрыто');
            _isOfflineMode = true;
          },
        );

        return true;
      } catch (e) {
        _isOfflineMode = true;
        _errorController.add('Сервер недоступен. Режим оффлайн активирован.');
        return true; // Return true to allow offline mode
      }
    } catch (e) {
      _isOfflineMode = true;
      _errorController.add('Ошибка подключения: $e. Режим оффлайн активирован.');
      return true; // Return true to allow offline mode
    }
  }

  static Future<void> disconnect() async {
    try {
      if (_channel != null) {
        await _channel!.sink.close();
        _channel = null;
      }
    } catch (e) {
      _errorController.add('Ошибка при отключении: $e');
    } finally {
      _channel = null;
      _messageController.close();
    }
  }

  static Future<void> sendMessage(String text) async {
    if (_isOfflineMode) {
      // In offline mode, just broadcast the message locally
      final message = Message(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        text: text,
        sender: 'You',
        timestamp: DateTime.now(),
        isLocal: true, // <-- Добавлено обязательное поле
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
        'text': text,
        'timestamp': DateTime.now().toIso8601String(),
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
