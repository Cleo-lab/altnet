import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
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
  bool _isOffline = false;
  String? _userNickname;
  final _messageSubscription = <StreamSubscription>[];
  Timer? _cleanupTimer;

  @override
  void initState() {
    super.initState();
    _loadUserAndInitialize();
    _cleanupTimer =
        Timer.periodic(const Duration(minutes: 1), (_) => _cleanupOldMessages());
  }

  @override
  void dispose() {
    _cleanupTimer?.cancel();
    for (var sub in _messageSubscription) {
      sub.cancel();
    }
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _cleanupOldMessages() async {
    final now = DateTime.now();
    final messagesToRemove = <Message>[];

    for (final message in _messages) {
      final readTime = await StorageService.getLastMessageReadTime(message.id);
      if (readTime != null) {
        final difference = now.difference(readTime);
        if (difference.inHours >= 24) {
          messagesToRemove.add(message);
        }
      }
    }

    if (messagesToRemove.isNotEmpty) {
      setState(() {
        _messages.removeWhere((m) => messagesToRemove.contains(m));
      });
      _saveMessages();
    }
  }

  Future<void> _loadUserAndInitialize() async {
    setState(() => _isLoading = true);

    try {
      final user = await StorageService.getUser();
      if (user == null) {
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/login');
        }
        return;
      }

      setState(() {
        _userNickname = user['nickname'] as String;
      });

      await _loadLocalMessages();

      final isConnected = await ServerService.connect(
        user['nickname'] as String,
        user['deviceId'] as String,
      );

      setState(() {
        _isOffline = ServerService.isOfflineMode;
      });

      if (_isOffline) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Режим оффлайн. Сообщения будут сохранены локально.'),
            backgroundColor: Colors.orange,
          ),
        );
      }

      _messageSubscription.add(
        ServerService.messageStream.listen((message) {
          if (mounted) {
            setState(() {
              if (!_messages.any((m) => m.id == message.id)) {
                _messages.add(message);
                _saveMessages();
              }
            });
            _scrollToBottom();
          }
        }),
      );

      _messageSubscription.add(
        ServerService.errorStream.listen((error) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Ошибка: $error'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }),
      );
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

  Future<void> _loadLocalMessages() async {
    try {
      final messagesJson = await StorageService.getLocalMessages();
      if (messagesJson != null && messagesJson.isNotEmpty) {
        final List<dynamic> messagesList = json.decode(messagesJson);
        setState(() {
          _messages.addAll(
            messagesList.map((m) => Message.fromJson(m)).toList(),
          );
        });
        _scrollToBottom();
      }
    } catch (e) {
      debugPrint('Ошибка загрузки локальных сообщений: $e');
    }
  }

  Future<void> _saveMessages() async {
    try {
      final messagesJson = json.encode(
        _messages.map((m) => m.toJson()).toList(),
      );
      await StorageService.saveLocalMessages(messagesJson);
    } catch (e) {
      debugPrint('Ошибка сохранения сообщений: $e');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      });
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final message = Message(
      id: const Uuid().v4(),
      text: text,
      sender: _userNickname ?? 'Вы',
      timestamp: DateTime.now(),
      isLocal: _isOffline,
    );

    setState(() {
      _messages.add(message);
    });
    _saveMessages();
    _scrollToBottom();

    _messageController.clear();
    FocusScope.of(context).unfocus();

    try {
      if (!_isOffline) {
        await ServerService.sendMessage(text);
      } else {
        // Перезаписываем сообщение с isLocal = true
        final index = _messages.indexWhere((m) => m.id == message.id);
        if (index != -1) {
          setState(() {
            _messages[index] = message.copyWith(isLocal: true);
          });
          _saveMessages();
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Ошибка при отправке: $e. Сообщение сохранено локально.'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  Future<void> _showLogoutDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Выход из чата'),
        content: const Text('Вы уверены, что хотите выйти из чата?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Выйти'),
          ),
        ],
      ),
    );

    if (result == true) {
      await StorageService.clearAll();
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/');
      }
    }
  }

  Future<void> _markMessageAsRead(Message message) async {
    await StorageService.saveLastMessageReadTime(message.id, DateTime.now());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: _isOffline ? Colors.orange : Colors.purple,
        title: Row(
          children: [
            GestureDetector(
              onTap: _showLogoutDialog,
              child: Row(
                children: [
                  Text(_userNickname ?? 'Семейный чат'),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_drop_down, size: 20),
                ],
              ),
            ),
            if (_isOffline) ...[
              const SizedBox(width: 8),
              const Icon(Icons.wifi_off, size: 18),
              const SizedBox(width: 4),
              const Text('Оффлайн', style: TextStyle(fontSize: 14)),
            ],
          ],
        ),
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
                final isMe = message.sender == _userNickname;

                _markMessageAsRead(message);

                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment:
                    isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                    children: [
                      if (!isMe) ...[
                        CircleAvatar(
                          backgroundColor: Colors.purple.withOpacity(0.7),
                          radius: 16,
                          child: Text(
                            message.sender[0].toUpperCase(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                      ],
                      Flexible(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: isMe ? Colors.purple : Colors.white,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.1),
                                blurRadius: 2,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (!isMe)
                                Text(
                                  message.sender,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              if (!isMe) const SizedBox(height: 4),
                              Text(
                                message.text,
                                style: TextStyle(
                                  color: isMe ? Colors.white : Colors.black87,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                '${message.timestamp.hour.toString().padLeft(2, '0')}:${message.timestamp.minute.toString().padLeft(2, '0')}',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isMe ? Colors.white60 : Colors.black45,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const Divider(height: 1),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            color: Colors.white,
            child: SafeArea(
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _messageController,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Напишите сообщение...',
                        border: InputBorder.none,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.send),
                    color: Colors.purple,
                    onPressed: _sendMessage,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
