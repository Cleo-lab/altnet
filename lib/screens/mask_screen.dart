import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';
import 'dart:math';

class MaskScreen extends StatefulWidget {
  const MaskScreen({Key? key}) : super(key: key);

  @override
  State<MaskScreen> createState() => _MaskScreenState();
}

class _MaskScreenState extends State<MaskScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showError = false;
  final List<String> _chineseTexts = [
    '欢迎来到昌马特', // Добро пожаловать в ChangMart
    '中国最大的购物平台', // Крупнейшая платформа для покупок в Китае
    '请输入您的手机号码', // Пожалуйста, введите номер телефона
    '注册新账户', // Регистрация нового аккаунта
    '登录现有账户', // Вход в существующий аккаунт
    '仅限中国用户', // Только для пользователей из Китая
    '验证您的身份', // Подтвердите свою личность
    '安全购物', // Безопасные покупки
    '快速配送', // Быстрая доставка
    '优质服务', // Качественный сервис
  ];

  @override
  void initState() {
    super.initState();
    _setupStatusBar();
    _checkFirstTime();
  }

  void _setupStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.purple,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _checkFirstTime() async {
    final isFirstTime = await StorageService.isFirstTime();
    if (isFirstTime) {
      // Если это первый запуск, показываем экран создания семейного круга
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    }
  }

  Future<void> _handleLogin() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _showError = false;
    });

    try {
      final input = _phoneController.text;
      
      // Проверяем, является ли ввод мастер-паролем
      final circleInfo = await StorageService.getCircleInfo();
      if (circleInfo != null && input == circleInfo['masterPassword']) {
        // Если введен мастер-пароль, переходим к настройке
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/setup');
        }
        return;
      }

      // Проверяем PIN-код
      final pin = await StorageService.getPin();
      if (pin == null) {
        // Если PIN не установлен, сохраняем его
        await StorageService.savePin(input);
        await StorageService.saveUser('User', false);
        var deviceId = await StorageService.getDeviceId();
        if (deviceId == null) {
          deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
          await StorageService.saveDeviceId(deviceId);
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (pin == input) {
        // Валидный PIN
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // Неверный PIN - показываем фейковую ошибку
        setState(() => _showError = true);
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _showError = false);
      }
    } catch (e) {
      setState(() => _showError = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _showError = false);
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  String _getRandomChineseText() {
    return _chineseTexts[Random().nextInt(_chineseTexts.length)];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 40),
                  // Логотип
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                      ),
                      Column(
                        children: const [
                          Text(
                            '家', // Семья
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            '亲', // Родственники
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 60,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  // Заголовок
                  Text(
                    'Welcome to ChangMart',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      shadows: [
                        Shadow(
                          color: Colors.black.withOpacity(0.3),
                          offset: const Offset(1, 1),
                          blurRadius: 2,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Случайный китайский текст
                  Text(
                    _getRandomChineseText(),
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Поле ввода
                  TextFormField(
                    controller: _phoneController,
                    keyboardType: TextInputType.number,
                    obscureText: true,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      letterSpacing: 4,
                    ),
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      labelText: '手机号码', // Номер телефона
                      labelStyle: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(
                          color: Colors.white.withOpacity(0.5),
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderSide: const BorderSide(color: Colors.red),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 16,
                        horizontal: 8,
                      ),
                      errorText: _showError ? '仅限中国用户' : null, // Только для пользователей из Китая
                    ),
                    maxLength: 6,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入您的手机号码'; // Пожалуйста, введите номер телефона
                      }
                      if (value.length < 4) {
                        return '请输入有效的手机号码'; // Пожалуйста, введите действительный номер телефона
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  // Кнопка входа
                  ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 32,
                        vertical: 16,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                            ),
                          )
                        : const Text(
                            '登录', // Вход
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                  const SizedBox(height: 16),
                  // Дополнительный китайский текст
                  Text(
                    '安全购物 • 快速配送 • 优质服务', // Безопасные покупки • Быстрая доставка • Качественный сервис
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
