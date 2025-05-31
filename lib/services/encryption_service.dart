import 'dart:math';

import 'package:encrypt/encrypt.dart';

class EncryptionService {
  static final _encrypter = Encrypter(AES(Key.fromUtf8('altnet_secret_key_1234567890')));

  static String encrypt(String text) {
    final encrypted = _encrypter.encrypt(text, iv: IV.fromLength(16));
    return encrypted.base64;
  }

  static String decrypt(String encryptedText) {
    final decrypted = _encrypter.decrypt64(encryptedText, iv: IV.fromLength(16));
    return decrypted;
  }

  static String generateChineseMask(String text) {
    // Генерируем случайные китайские иероглифы для маскировки
    final chineseChars = '一二三四五六七八九十百千万亿';
    final random = Random();
    
    return String.fromCharCodes(
      List.generate(text.length * 2, (_) => 
        chineseChars.codeUnitAt(random.nextInt(chineseChars.length))
      )
    );
  }
}
