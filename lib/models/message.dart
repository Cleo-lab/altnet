class Message {
  final String id;
  final String text;
  final String sender;
  final DateTime timestamp;
  final bool isLocal;
  DateTime? readTime;

  Message({
    required this.id,
    required this.text,
    required this.sender,
    required this.timestamp,
    required this.isLocal,
    this.readTime,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'sender': sender,
      'timestamp': timestamp.toIso8601String(),
      'isLocal': isLocal,
      'readTime': readTime?.toIso8601String(),
    };
  }

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['id'] as String,
      text: json['text'] as String,
      sender: json['sender'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      isLocal: json['isLocal'] as bool,
      readTime: json['readTime'] != null 
          ? DateTime.parse(json['readTime'] as String)
          : null,
    );
  }

  Message copyWith({
    String? id,
    String? text,
    String? sender,
    DateTime? timestamp,
    bool? isLocal,
    DateTime? readTime,
  }) {
    return Message(
      id: id ?? this.id,
      text: text ?? this.text,
      sender: sender ?? this.sender,
      timestamp: timestamp ?? this.timestamp,
      isLocal: isLocal ?? this.isLocal,
      readTime: readTime ?? this.readTime,
    );
  }
}
