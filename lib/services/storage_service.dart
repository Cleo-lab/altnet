import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static late SharedPreferences _prefs;
  
  // Local storage keys
  static const _localMessagesKey = 'local_messages';

  static Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // Ключи
  static const _pinKey = 'pin_code';
  static const _deviceIdKey = 'device_id';
  static const _nicknameKey = 'user_nickname';
  static const _isAdminKey = 'is_admin';
  static const _circleIdKey = 'circle_id';
  static const _masterPasswordKey = 'master_password';
  static const _circleNameKey = 'circle_name';
  static const _isFirstTimeKey = 'is_first_time';
  static const _lastMessageReadKey = 'last_message_read';

  // Первый запуск
  static Future<bool> isFirstTime() async {
    return _prefs.getBool(_isFirstTimeKey) ?? true;
  }

  static Future<void> setFirstTimeDone() async {
    await _prefs.setBool(_isFirstTimeKey, false);
  }

  // PIN-код
  static Future<void> savePin(String pin) async {
    await _storage.write(key: _pinKey, value: pin);
  }

  static Future<String?> getPin() async {
    return await _storage.read(key: _pinKey);
  }

  // Device ID
  static Future<void> saveDeviceId(String deviceId) async {
    await _storage.write(key: _deviceIdKey, value: deviceId);
  }

  static Future<String?> getDeviceId() async {
    return await _storage.read(key: _deviceIdKey);
  }

  // Пользовательские данные
  static Future<void> saveUser(String nickname, bool isAdmin) async {
    await _storage.write(key: _nicknameKey, value: nickname);
    await _storage.write(key: _isAdminKey, value: isAdmin.toString());
  }

  static Future<Map<String, dynamic>?> getUser() async {
    final nickname = await _storage.read(key: _nicknameKey);
    final isAdminStr = await _storage.read(key: _isAdminKey);

    if (nickname == null || isAdminStr == null) return null;

    return {
      'nickname': nickname,
      'isAdmin': isAdminStr == 'true',
    };
  }

  // Семейный круг
  static Future<void> saveCircleInfo({
    required String circleId,
    required String circleName,
    required String masterPassword,
  }) async {
    await _storage.write(key: _circleIdKey, value: circleId);
    await _storage.write(key: _circleNameKey, value: circleName);
    await _storage.write(key: _masterPasswordKey, value: masterPassword);
  }

  static Future<Map<String, String>?> getCircleInfo() async {
    final circleId = await _storage.read(key: _circleIdKey);
    final circleName = await _storage.read(key: _circleNameKey);
    final masterPassword = await _storage.read(key: _masterPasswordKey);

    if (circleId == null || circleName == null || masterPassword == null) {
      return null;
    }

    return {
      'circleId': circleId,
      'circleName': circleName,
      'masterPassword': masterPassword,
    };
  }

  static Future<bool> verifyMasterPassword(String password) async {
    final storedPassword = await _storage.read(key: _masterPasswordKey);
    return storedPassword == password;
  }

  // Время последнего прочтения сообщения
  static Future<void> saveLastMessageReadTime(String messageId, DateTime time) async {
    await _prefs.setString('${_lastMessageReadKey}_$messageId', time.toIso8601String());
  }

  static Future<DateTime?> getLastMessageReadTime(String messageId) async {
    final timeStr = _prefs.getString('${_lastMessageReadKey}_$messageId');
    if (timeStr == null) return null;
    return DateTime.parse(timeStr);
  }

  // Local messages storage
  static Future<void> saveLocalMessages(String messagesJson) async {
    await _prefs.setString(_localMessagesKey, messagesJson);
  }

  static Future<String?> getLocalMessages() async {
    return _prefs.getString(_localMessagesKey);
  }

  static Future<void> clearLocalMessages() async {
    await _prefs.remove(_localMessagesKey);
  }

  // Очистка данных при выходе
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    await _prefs.clear();
  }

  // Проверка существования семейного круга
  static Future<bool> hasCircle() async {
    final circleInfo = await getCircleInfo();
    return circleInfo != null;
  }
  // Отдельное сохранение только circleId
  static Future<void> saveCircleId(String circleId) async {
    await _storage.write(key: _circleIdKey, value: circleId);
  }

  static Future<String?> getCircleId() async {
    return await _storage.read(key: _circleIdKey);
  }

  // Проверка является ли пользователь администратором
  static Future<bool> isAdmin() async {
    final user = await getUser();
    return user?['isAdmin'] ?? false;
  }
}
