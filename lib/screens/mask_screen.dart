import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/encryption_service.dart';

class MaskScreen extends StatefulWidget {
  const MaskScreen({Key? key}) : super(key: key);

  @override
  State<MaskScreen> createState() => _MaskScreenState();
}

class _MaskScreenState extends State<MaskScreen> {
  final _phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _setupStatusBar();
  }

  void _setupStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.purple,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  Future<void> _simulateLogin() async {
    if (_isLoading) return;

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      // Симулируем проверку PIN-кода
      final pin = _phoneController.text;
      final isValid = await StorageService.getPin() == pin;

      if (isValid) {
        // Переходим к экрану чата
        Navigator.pushReplacementNamed(context, '/chat');
      } else {
        // Показываем фейковую ошибку
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Неверный номер телефона'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ошибка при входе'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  '家', // Семья
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Text(
                  '亲', // Родственники
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 100,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                const Text(
                  '欢迎来到ChangMart', // Добро пожаловать в ChangMart
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '请输入手机号码', // Введите номер телефона
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  '注册 | 登录', // Регистрация | Вход
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    filled: true,
                    fillColor: Colors.purple[800],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                    hintText: '+86 123 456 7890',
                    hintStyle: const TextStyle(color: Colors.white70),
                    prefixIcon: const Icon(Icons.phone, color: Colors.white70),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите номер телефона';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isLoading ? null : _simulateLogin,
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
                      : const Text('Войти в ChangMart'),
                ),
              ],
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
