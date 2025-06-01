import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SetupScreen extends StatefulWidget {
  @override
  _SetupScreenState createState() => _SetupScreenState();
}

class _SetupScreenState extends State<SetupScreen> {
  bool _initialized = false;
  bool _showFakeLogin = false;

  @override
  void initState() {
    super.initState();
    _initialize();
  }

  Future<void> _initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSetup = prefs.getBool('hasCompletedSetup') ?? false;
    final savedPIN = prefs.getString('userPIN');

    if (hasSetup && savedPIN != null) {
      setState(() {
        _showFakeLogin = true;
        _initialized = true;
      });
    } else {
      setState(() {
        _showFakeLogin = false;
        _initialized = true;
      });
    }
  }

  void _onFakeLoginPressed() async {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => FakePinEntryScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return Scaffold(
        backgroundColor: Colors.black,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_showFakeLogin) {
      return Scaffold(
        backgroundColor: Color(0xFF800080),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '欢迎来到 ChangMart',
                  style: TextStyle(fontSize: 26, color: Colors.white, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 20),
                Text(
                  '请输入中国电话号码进行注册',
                  style: TextStyle(fontSize: 18, color: Colors.white70),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _onFakeLoginPressed,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: Colors.black,
                      padding: EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text('下一步'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    } else {
      return Scaffold(
        backgroundColor: Color(0xFF800080),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  '创建或加入家庭圈',
                  style: TextStyle(fontSize: 24, color: Colors.white),
                ),
                SizedBox(height: 40),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FakeCreateCircleScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Создать семейный круг'),
                ),
                SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => FakeJoinCircleScreen()),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Text('Присоединиться к кругу'),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }
}

// ====== ЗАГЛУШКИ ЭКРАНОВ ВМЕСТО ОТДЕЛЬНЫХ ФАЙЛОВ ======

class FakePinEntryScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Ввод PIN')),
      body: Center(
        child: Text('Здесь будет экран ввода PIN-кода'),
      ),
    );
  }
}

class FakeCreateCircleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Создание круга')),
      body: Center(
        child: Text('Здесь будет экран создания семейного круга'),
      ),
    );
  }
}

class FakeJoinCircleScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Присоединиться')),
      body: Center(
        child: Text('Здесь будет экран присоединения к кругу'),
      ),
    );
  }
}
