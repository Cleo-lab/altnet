class Message {
  final String text;
  final String sender;
  final DateTime timestamp;
  final String? id;

  Message({
    required this.text,
    required this.sender,
    required this.timestamp,
    this.id,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String?,
      text: json['text'] as String,
      sender: json['sender'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
    );
  }

  Message copyWith({
    String? text,
    String? sender,
    DateTime? timestamp,
    String? id,
  }) {
    return Message(
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      id: id ?? this.id,
    );
  }
}
