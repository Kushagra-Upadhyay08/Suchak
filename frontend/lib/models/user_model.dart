class User {
  final String id;
  final String name;
  final String role;
  final String? employeeId;

  User({required this.id, required this.name, required this.role, this.employeeId});

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'] ?? json['_id'],
      name: json['name'] ?? 'Unknown',
      role: json['role'] ?? 'engineer',
      employeeId: json['employeeId'],
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'role': role,
    'employeeId': employeeId,
  };
}
