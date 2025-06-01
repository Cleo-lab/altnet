import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/server_service.dart';
import '../models/user.dart';
import '../models/family_circle.dart';
import 'package:uuid/uuid.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _circleNameController = TextEditingController();
  final _circleIdController = TextEditingController();
  final _masterPasswordController = TextEditingController();
  final _nicknameController = TextEditingController();
  bool _isCreatingCircle = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _checkExistingUser();
  }

  Future<void> _checkExistingUser() async {
    final user = await StorageService.getUser();
    if (user != null) {
      Navigator.pushReplacementNamed(context, '/chat');
    }
  }

  Future<void> _createFamilyCircle() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      var deviceId = await StorageService.getDeviceId();
      if (deviceId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await StorageService.saveDeviceId(deviceId);
      }

      final circleId = const Uuid().v4();

      await StorageService.saveUser(
        _nicknameController.text,
        true,
      );
      await StorageService.saveCircleId(circleId);

      final isConnected = await ServerService.connect(
        _nicknameController.text,
        deviceId,
      );

      if (!ServerService.isOfflineMode) {
        final circle = FamilyCircle(
          name: _circleNameController.text,
          masterPassword: _masterPasswordController.text,
          id: circleId,
          memberDeviceIds: [deviceId],
        );
        await ServerService.createFamilyCircle(circle);
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
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

  Future<void> _joinFamilyCircle() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      var deviceId = await StorageService.getDeviceId();
      if (deviceId == null) {
        deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
        await StorageService.saveDeviceId(deviceId);
      }

      await StorageService.saveUser(
        _nicknameController.text,
        false,
      );

      final isConnected = await ServerService.connect(
        _nicknameController.text,
        deviceId,
      );

      final circleId = _circleIdController.text;
      if (circleId.isEmpty) {
        throw Exception('Введите ID семейного круга');
      }
      await StorageService.saveCircleId(circleId);

      if (!ServerService.isOfflineMode) {
        await ServerService.joinFamilyCircle(
          circleId,
          _masterPasswordController.text,
        );
      }

      if (mounted) {
        Navigator.pushReplacementNamed(context, '/chat');
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
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Spacer(),
                const Text(
                  'Создание или присоединение к семейному кругу',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 32),
                if (_isCreatingCircle)
                  TextFormField(
                    controller: _circleNameController,
                    decoration: const InputDecoration(
                      labelText: 'Название семейного круга',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (_isCreatingCircle && (value == null || value.isEmpty)) {
                        return 'Введите название';
                      }
                      return null;
                    },
                  ),
                if (_isCreatingCircle) const SizedBox(height: 16),
                if (!_isCreatingCircle)
                  TextFormField(
                    controller: _circleIdController,
                    decoration: const InputDecoration(
                      labelText: 'ID семейного круга',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (!_isCreatingCircle && (value == null || value.isEmpty)) {
                        return 'Введите ID семейного круга';
                      }
                      return null;
                    },
                  ),
                if (!_isCreatingCircle) const SizedBox(height: 16),
                TextFormField(
                  controller: _masterPasswordController,
                  decoration: const InputDecoration(
                    labelText: 'Мастер-пароль семейного круга',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите мастер-пароль';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _nicknameController,
                  decoration: const InputDecoration(
                    labelText: 'Ваш никнейм',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Введите никнейм';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _isCreatingCircle ? _createFamilyCircle : _joinFamilyCircle,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                    ),
                  )
                      : Text(
                    _isCreatingCircle ? 'Создать семейный круг' : 'Присоединиться',
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
                const SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isCreatingCircle = !_isCreatingCircle;
                      _formKey.currentState?.reset();
                      _circleNameController.clear();
                      _circleIdController.clear();
                      _masterPasswordController.clear();
                      _nicknameController.clear();
                    });
                  },
                  child: Text(
                    _isCreatingCircle
                        ? 'Уже есть семейный круг?'
                        : 'Создать новый семейный круг',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
                const Spacer(),
                const Text(
                  'Altnet',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 48,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey,
                  ),
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
    _circleNameController.dispose();
    _circleIdController.dispose();
    _masterPasswordController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }
}
