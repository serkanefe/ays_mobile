class User {
  final int? id;
  final String fullName;
  final String email;
  final String role;
  final bool isActive;

  User({
    this.id,
    required this.fullName,
    required this.email,
    required this.role,
    this.isActive = true,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      fullName: json['full_name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'OWNER',
      isActive: json['is_active'] ?? true,
    );
  }
}
