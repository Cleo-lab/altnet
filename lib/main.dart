import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'screens/mask_screen.dart';
import 'screens/login_screen.dart';
import 'screens/chat_screen.dart';
import 'screens/setup_screen.dart';

import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService.initialize();
  await StorageService.init();

  // Установка статус бара в фиолетовый цвет
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.purple,
      statusBarBrightness: Brightness.light,
    ),
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ChangMart',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.purple,
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      initialRoute: '/',
      routes: {
        '/': (context) => const MaskScreen(),       // Экран ввода номера/пароля
        '/setup': (context) => SetupScreen(), // Создание семейного круга
        '/login': (context) => const LoginScreen(), // Вход по PIN
        '/chat': (context) => const ChatScreen(),   // Семейный чат
      },
    );
  }
}
