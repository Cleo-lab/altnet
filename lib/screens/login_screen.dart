import 'package:flutter/material.dart';

// This screen masquerades as a Chinese shopping app login
// but actually is a secret family chat login using a password disguised as phone input.

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();

  // Regex for Chinese phone number validation starting with +86 and 11 digits after
  final RegExp _chinaPhoneRegex = RegExp(r'^\+86\d{11}$');

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final password = _passwordController.text;
      // Here you would check the password and navigate to secret chat screen
      // For demonstration, just show a success snackbar

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('登录成功！密码：$password')), // "Login success! Password: ..."
      );

      // TODO: Navigate to secret chat screen
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF800080), // Purple background (#800080)
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Big Chinese character "家" (family)
                  const Text(
                    '家',
                    style: TextStyle(
                      fontSize: 120,
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Welcome text "Welcome to ChangMart" in Chinese
                  const Text(
                    '欢迎来到长马特',
                    style: TextStyle(
                      fontSize: 24,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Input field that looks like Chinese phone number input
                  TextFormField(
                    controller: _passwordController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: Colors.white),
                    cursorColor: Colors.white,
                    decoration: InputDecoration(
                      prefixText: '+86 ',
                      prefixStyle: const TextStyle(color: Colors.white),
                      hintText: '请输入手机号', // "Please enter phone number"
                      hintStyle: TextStyle(color: Colors.white70),
                      enabledBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white70),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderSide: BorderSide(color: Colors.white),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      // This disguises the input as phone number input, but text is visible
                    ),
                    obscureText: false, // show input (password disguised as phone)
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return '请输入手机号'; // "Please enter phone number"
                      }
                      // Validate format: must start with 1 and 11 digits total after +86 prefix
                      if (!_chinaPhoneRegex.hasMatch('+86$value')) {
                        return '手机号格式错误，需以 +86 开头，后跟11位数字';
                        // "Phone number format error, must start with +86 and 11 digits"
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: const Color(0xFF800080),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: const Text(
                        '登录', // "Login"
                        style: TextStyle(fontSize: 18),
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),
                  // Bottom branding text in white
                  const Text(
                    '长马特 © 2025',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
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
}
