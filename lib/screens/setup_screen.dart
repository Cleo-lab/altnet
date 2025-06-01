import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';
import 'dart:math';

class SetupScreen extends StatefulWidget {
  const SetupScreen({Key? key}) : super(key: key);

  @override
  State<SetupScreen> createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _circleNameController = TextEditingController();
  final _masterPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _pinController = TextEditingController();
  bool _isLoading = false;
  bool _isJoining = false;
  bool _showMasterPassword = false;
  bool _showPin = false;

  @override
  void initState() {
    super.initState();
    _checkExistingCircle();
  }

  Future<void> _checkExistingCircle() async {
    final hasCircle = await StorageService.hasCircle();
    if (hasCircle) {
      setState(() => _isJoining = true);
    }
  }

  Future<void> _handleSetup() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      if (_isJoining) {
        // Присоединение к существующему кругу
        final circleInfo = await StorageService.getCircleInfo();
        if (circleInfo == null) {
          throw Exception('Круг не найден');
        }

        if (_masterPasswordController.text != circleInfo['masterPassword']) {
          throw Exception('Неверный мастер-пароль');
        }

        // Сохраняем пользовательские данные
        await StorageService.savePin(_pinController.text);
        await StorageService.saveUser(_nicknameController.text, false);
        var deviceId = await StorageService.getDeviceId();
        if (deviceId == null) {
          deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
          await StorageService.saveDeviceId(deviceId);
        }

        await StorageService.setFirstTimeDone();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // Создание нового круга
        final circleId = 'circle_${DateTime.now().millisecondsSinceEpoch}';
        await StorageService.saveCircleInfo(
          circleId: circleId,
          circleName: _circleNameController.text,
          masterPassword: _masterPasswordController.text,
        );

        // Сохраняем пользовательские данные
        await StorageService.savePin(_pinController.text);
        await StorageService.saveUser(_nicknameController.text, true);
        var deviceId = await StorageService.getDeviceId();
        if (deviceId == null) {
          deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
          await StorageService.saveDeviceId(deviceId);
        }

        await StorageService.setFirstTimeDone();
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _isJoining ? 'Присоединиться к кругу' : 'Создать семейный круг',
          style: const TextStyle(color: Colors.white),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!_isJoining) ...[
                  // Поле для имени круга (только при создании)
                  TextFormField(
                    controller: _circleNameController,
                    style: const TextStyle(color: Colors.white),
                    decoration: const InputDecoration(
                      labelText: 'Имя семейного круга',
                      labelStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white54),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Пожалуйста, введите имя круга';
                      }
                      if (value.length < 3) {
                        return 'Имя должно содержать минимум 3 символа';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                // Поле для мастер-пароля
                TextFormField(
                  controller: _masterPasswordController,
                  obscureText: !_showMasterPassword,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: _isJoining ? 'Мастер-пароль' : 'Придумайте мастер-пароль',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showMasterPassword ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() => _showMasterPassword = !_showMasterPassword);
                      },
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите мастер-пароль';
                    }
                    if (value.length < 6) {
                      return 'Пароль должен содержать минимум 6 символов';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Поле для никнейма
                TextFormField(
                  controller: _nicknameController,
                  style: const TextStyle(color: Colors.white),
                  decoration: const InputDecoration(
                    labelText: 'Ваш никнейм',
                    labelStyle: TextStyle(color: Colors.white70),
                    enabledBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите никнейм';
                    }
                    if (value.length < 2) {
                      return 'Никнейм должен содержать минимум 2 символа';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Поле для PIN-кода
                TextFormField(
                  controller: _pinController,
                  obscureText: !_showPin,
                  keyboardType: TextInputType.number,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'PIN-код (4-6 цифр)',
                    labelStyle: const TextStyle(color: Colors.white70),
                    enabledBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white54),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderSide: BorderSide(color: Colors.white),
                    ),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _showPin ? Icons.visibility_off : Icons.visibility,
                        color: Colors.white70,
                      ),
                      onPressed: () {
                        setState(() => _showPin = !_showPin);
                      },
                    ),
                  ),
                  maxLength: 6,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Пожалуйста, введите PIN-код';
                    }
                    if (value.length < 4 || value.length > 6) {
                      return 'PIN-код должен содержать от 4 до 6 цифр';
                    }
                    if (!RegExp(r'^\d+$').hasMatch(value)) {
                      return 'PIN-код должен содержать только цифры';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                // Кнопка подтверждения
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleSetup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.purple,
                    padding: const EdgeInsets.symmetric(vertical: 16),
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
                      : Text(
                          _isJoining ? 'Присоединиться' : 'Создать круг',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
                if (!_isJoining) ...[
                  const SizedBox(height: 16),
                  const Text(
                    'Важно: Сохраните мастер-пароль в надежном месте. Он потребуется для добавления новых членов семьи.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _circleNameController.dispose();
    _masterPasswordController.dispose();
    _nicknameController.dispose();
    _pinController.dispose();
    super.dispose();
  }
} 