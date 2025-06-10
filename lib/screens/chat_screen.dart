import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/message_database.dart';
import '../models/message.dart';
import '../services/server_service.dart';
import '../services/storage_service.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  List<Message> _messages = [];
  StreamSubscription<Message>? _messageSubscription;
  StreamSubscription<String>? _errorSubscription;
  String? _currentUserId;
  String? _currentNickname;

  @override
  void initState() {
    super.initState();
    _initializeChat();
  }

  Future<void> _initializeChat() async {
    // Load user info
    final user = await StorageService.getUser();
    if (user != null) {
      setState(() {
        _currentUserId = user['nickname'];
        _currentNickname = user['nickname'];
      });
    }

    // Get device ID and connect to server
    final deviceId = await StorageService.getDeviceId();
    if (deviceId != null && _currentNickname != null) {
      await ServerService.connect(_currentNickname!, deviceId);
    }

    // Subscribe to messages and errors
    _messageSubscription = ServerService.messageStream.listen(_handleNewMessage);
    _errorSubscription = ServerService.errorStream.listen(_handleError);

    // Load local messages
    await _loadMessages();
  }

  void _handleNewMessage(Message message) async {
    // Save message to local database
    await MessageDatabase.instance.insertMessage(message);
    await _loadMessages();
  }

  void _handleError(String error) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(error)),
    );
  }

  Future<void> _loadMessages() async {
    final all = await MessageDatabase.instance.getAllMessages();
    final now = DateTime.now();

    // Filter out expired messages
    final filtered = all.where((msg) {
      if (msg.readAt == null) return true;
      return msg.readAt!.add(const Duration(hours: 24)).isAfter(now);
    }).toList();

    setState(() {
      _messages = filtered;
    });

    // Delete expired messages from database
    await MessageDatabase.instance.deleteExpiredMessages();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    if (ServerService.isOfflineMode) {
      // Save message locally if offline
    final msg = Message(
        senderId: _currentUserId ?? 'unknown',
      recipientId: 'group',
      content: text,
      sentAt: DateTime.now(),
    );
    await MessageDatabase.instance.insertMessage(msg);
    } else {
      // Send message through server
      await ServerService.sendMessage(text);
    }

    _controller.clear();
    await _loadMessages();
  }

  @override
  void dispose() {
    _messageSubscription?.cancel();
    _errorSubscription?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _markAsRead(Message msg) async {
    if (msg.readAt != null) return;

    await MessageDatabase.instance.markMessageAsRead(msg.id!, DateTime.now());
    await _loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('AltNet Chat')),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (_, index) {
                final msg = _messages[index];
                final isMe = msg.senderId == _currentUserId;

                return ListTile(
                  title: Text(msg.content),
                  subtitle: Text(
                    DateFormat('HH:mm dd.MM').format(msg.sentAt) +
                        (msg.readAt != null ? ' ✅' : ''),
                  ),
                  trailing: isMe
                      ? null
                      : IconButton(
                    icon: const Icon(Icons.check),
                    onPressed: () => _markAsRead(msg),
                  ),
                );
              },
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: const InputDecoration(
                      hintText: 'Введите сообщение...',
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.send),
                  onPressed: _sendMessage,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
