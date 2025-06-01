import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../db/message_database.dart';
import '../models/message.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _controller = TextEditingController();
  List<Message> _messages = [];

  final String _currentUserId = 'me'; // можно заменить на ID пользователя

  @override
  void initState() {
    super.initState();
    _loadMessages();
  }

  Future<void> _loadMessages() async {
    final all = await MessageDatabase.instance.getAllMessages();
    final now = DateTime.now();

    // отфильтруем удаляемые сообщения вручную
    final filtered = all.where((msg) {
      if (msg.readAt == null) return true;
      return msg.readAt!.add(const Duration(hours: 24)).isAfter(now);
    }).toList();

    setState(() {
      _messages = filtered;
    });

    // автоудаление из базы
    await MessageDatabase.instance.deleteExpiredMessages();
  }

  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    final msg = Message(
      senderId: _currentUserId,
      recipientId: 'group',
      content: text,
      sentAt: DateTime.now(),
    );

    await MessageDatabase.instance.insertMessage(msg);
    _controller.clear();
    await _loadMessages();
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
