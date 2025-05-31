import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/storage_service.dart';
import '../services/notification_service.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../services/server_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final List<Message> _messages = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUserAndInitialize();
  }

  Future<void> _loadUserAndInitialize() async {
    setState(() => _isLoading = true);

    try {
      final user = await StorageService.getUser();
      if (user == null) {
        Navigator.pushReplacementNamed(context, '/login');
        return;
      }

      // Подключаемся к серверу
      final isConnected = await ServerService.connect(
        user['nickname'] as String,
        user['deviceId'] as String,
      );

      if (!isConnected) {
        throw Exception('Не удалось подключиться к серверу');
      }

      // Подписываемся на сообщения
      ServerService.messageStream.listen((message) {
        setState(() {
          _messages.add(message);
        });
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });

      ServerService.errorStream.listen((error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $error')),
        );
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Ошибка: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _sendMessage() async {
    if (_messageController.text.isEmpty) return;

    try {
      await ServerService.sendMessage(_messageController.text);
      _messageController.clear();
      FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка при отправке сообщения: $e')),
        );
      }
    }
  }

  void _logout() async {
    await StorageService.clearAll();
    Navigator.pushReplacementNamed(context, '/');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.white,
        title: const Text('Семейный чат'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(8),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final message = _messages[index];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: message.sender == 'Cleopatra' 
                        ? MainAxisAlignment.end 
                        : MainAxisAlignment.start,
                    children: [
                      if (message.sender != 'Cleopatra') ...[
                        const CircleAvatar(
                          child: Icon(Icons.person),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: message.sender == 'Cleopatra' 
                              ? Colors.purple[100] 
                              : Colors.grey[300],
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              message.sender,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(message.text),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_isLoading) ...[
            const LinearProgressIndicator(),
            const SizedBox(height: 8),
          ],
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (value) => _sendMessage(),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _sendMessage,
                  child: const Icon(Icons.send),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }
}
