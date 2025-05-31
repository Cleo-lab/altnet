class FamilyCircle {
  final String name;
  final String masterPassword;
  final String id;
  final List<String> memberDeviceIds;

  FamilyCircle({
    required this.name,
    required this.masterPassword,
    required this.id,
    this.memberDeviceIds = const [],
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'masterPassword': masterPassword,
      'id': id,
      'memberDeviceIds': memberDeviceIds,
    };
  }

  factory FamilyCircle.fromJson(Map<String, dynamic> json) {
    return FamilyCircle(
      name: json['name'] as String,
      masterPassword: json['masterPassword'] as String,
      id: json['id'] as String,
      memberDeviceIds: List<String>.from(json['memberDeviceIds'] as List<dynamic>),
    );
  }

  FamilyCircle copyWith({
    String? name,
    String? masterPassword,
    String? id,
    List<String>? memberDeviceIds,
  }) {
    return FamilyCircle(
      name: name ?? this.name,
      masterPassword: masterPassword ?? this.masterPassword,
      id: id ?? this.id,
      memberDeviceIds: memberDeviceIds ?? this.memberDeviceIds,
    );
  }
}
