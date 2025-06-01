// lib/models/message.dart

class Message {
  final int? id;
  final String senderId;
  final String recipientId;
  final String content;
  final DateTime sentAt;
  final DateTime? readAt;

  Message({
    this.id,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.sentAt,
    this.readAt,
  });

  // Создание объекта из Map (например, из JSON)
  factory Message.fromMap(Map<String, dynamic> map) => Message(
    id: map['id'] is int
        ? map['id']
        : int.tryParse(map['id']?.toString() ?? ''),
    senderId: map['senderId'] as String,
    recipientId: map['recipientId'] as String,
    content: map['content'] as String,
    sentAt: DateTime.parse(map['sentAt'] as String),
    readAt: map['readAt'] != null ? DateTime.parse(map['readAt'] as String) : null,
  );

  // Чтобы исправить ошибку "fromJson" добавляем синоним
  factory Message.fromJson(Map<String, dynamic> json) => Message.fromMap(json);

  // Преобразование объекта в Map для JSON сериализации
  Map<String, dynamic> toMap() => {
    'id': id,
    'senderId': senderId,
    'recipientId': recipientId,
    'content': content,
    'sentAt': sentAt.toIso8601String(),
    'readAt': readAt?.toIso8601String(),
  };

  // Синоним для toMap
  Map<String, dynamic> toJson() => toMap();
}
