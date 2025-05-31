class User {
  final String nickname;
  final String deviceId;
  final bool isAdmin;

  User({
    required this.nickname,
    required this.deviceId,
    this.isAdmin = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'nickname': nickname,
      'deviceId': deviceId,
      'isAdmin': isAdmin,
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      nickname: json['nickname'] as String,
      deviceId: json['deviceId'] as String,
      isAdmin: json['isAdmin'] as bool? ?? false,
    );
  }

  User copyWith({
    String? nickname,
    String? deviceId,
    bool? isAdmin,
  }) {
    return User(
      nickname: nickname ?? this.nickname,
      deviceId: deviceId ?? this.deviceId,
      isAdmin: isAdmin ?? this.isAdmin,
    );
  }
}
