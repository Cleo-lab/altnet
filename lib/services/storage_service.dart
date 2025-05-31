import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static const _storage = FlutterSecureStorage();
  static const _prefs = SharedPreferences.getInstance();

  // PIN-код
  static const _pinKey = 'pin_code';
  static const _deviceIdKey = 'device_id';
  static const _nicknameKey = 'user_nickname';
  static const _isAdminKey = 'is_admin';
  static const _circleIdKey = 'circle_id';

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
  static Future<void> saveCircleId(String circleId) async {
    await _storage.write(key: _circleIdKey, value: circleId);
  }

  static Future<String?> getCircleId() async {
    return await _storage.read(key: _circleIdKey);
  }

  // Очистка данных при выходе
  static Future<void> clearAll() async {
    await _storage.deleteAll();
    await _prefs.then((prefs) => prefs.clear());
  }
}
