import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _notifications = 
      FlutterLocalNotificationsPlugin();

  static Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    
    await _notifications.initialize(settings);
  }

  static Future<void> showNotification(String title, String body) async {
    const androidDetails = AndroidNotificationDetails(
      'altnet_channel',
      'Altnet Notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    
    const iosDetails = DarwinNotificationDetails();
    
    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );
    
    await _notifications.show(
      0,
      title,
      body,
      details,
    );
  }

  static Future<void> showEncryptedNotification(String encryptedText) async {
    await showNotification(
      'New Message',
      encryptedText,
    );
  }
}
