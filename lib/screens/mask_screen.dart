import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/storage_service.dart';

class MaskScreen extends StatefulWidget {
  const MaskScreen({Key? key}) : super(key: key);

  @override
  State<MaskScreen> createState() => _MaskScreenState();
}

class _MaskScreenState extends State<MaskScreen> {
  final _inputController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  bool _showError = false;

  @override
  void initState() {
    super.initState();
    _setupStatusBar();
    _checkFirstTime();
  }

  // Set status bar style to match purple background
  void _setupStatusBar() {
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.purple,
        statusBarBrightness: Brightness.light,
      ),
    );
  }

  // Check if this is the first app launch to redirect to setup
  Future<void> _checkFirstTime() async {
    final isFirstTime = await StorageService.isFirstTime();
    if (isFirstTime) {
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/setup');
      }
    }
  }

  // Validate input against Chinese phone number pattern
  bool _validateChinesePhone(String input) {
    // Pattern: optional +86 followed by 1 and 10 digits
    final phoneReg = RegExp(r'^(\+86)?1\d{10}$');
    return phoneReg.hasMatch(input);
  }

  // Handle submit button pressed
  Future<void> _onSubmit() async {
    if (_isLoading) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _showError = false;
    });

    final enteredPassword = _inputController.text;

    try {
      // Check master password (if any)
      final circleInfo = await StorageService.getCircleInfo();
      if (circleInfo != null && enteredPassword == circleInfo['masterPassword']) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/setup');
        }
        return;
      }

      // Retrieve saved PIN (our "secret chat" password)
      final savedPin = await StorageService.getPin();
      if (savedPin == null) {
        // First-time setup: save entered password as PIN
        await StorageService.savePin(enteredPassword);
        await StorageService.saveUser('User', false);
        var deviceId = await StorageService.getDeviceId();
        if (deviceId == null) {
          deviceId = 'device_${DateTime.now().millisecondsSinceEpoch}';
          await StorageService.saveDeviceId(deviceId);
        }
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else if (enteredPassword == savedPin) {
        // Correct password entered: go to chat/login
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
      } else {
        // Wrong password — show fake error message "仅限中国用户" (Only Chinese users)
        setState(() => _showError = true);
        await Future.delayed(const Duration(seconds: 2));
        setState(() => _showError = false);
      }
    } catch (e) {
      setState(() => _showError = true);
      await Future.delayed(const Duration(seconds: 2));
      setState(() => _showError = false);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Large single character "家" (family)
                  const Text(
                    '家',
                    style: TextStyle(
                      fontSize: 100,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Welcome text
                  const Text(
                    'Welcome to ChangMart',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          color: Colors.black38,
                          offset: Offset(1, 1),
                          blurRadius: 3,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 50),

                  // Input field - looks like phone input but actually password input (visible)
                  TextFormField(
                    controller: _inputController,
                    keyboardType: TextInputType.phone,
                    obscureText: false, // show characters to user
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      letterSpacing: 1.8,
                    ),
                    textAlign: TextAlign.center,
                    maxLength: 13, // max length to fit +86 and 11 digits
                    decoration: InputDecoration(
                      labelText: '请输入您的手机号码', // Please enter your phone number
                      labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: Colors.white.withOpacity(0.5)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.white),
                      ),
                      errorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      focusedErrorBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Colors.red),
                      ),
                      errorText: _showError ? '仅限中国用户' : null, // Only for Chinese users
                      counterText: '',
                      contentPadding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入您的手机号码'; // Please enter your phone number
                      }
                      if (!_validateChinesePhone(value)) {
                        return '请输入有效的手机号码'; // Please enter a valid phone number
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 40),

                  // Submit button
                  ElevatedButton(
                    onPressed: _isLoading ? null : _onSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.purple,
                      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 48),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 5,
                    ),
                    child: _isLoading
                        ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.purple),
                      ),
                    )
                        : const Text(
                      '登录', // Login
                      style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
    _inputController.dispose();
    super.dispose();
  }
}
