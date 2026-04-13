enum UserRole { admin, teacher, student }

class AppUser {
  final String id;
  final String name;
  final String email;
  final UserRole role;
  final String? department;

  AppUser({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.department,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'email': email,
    'role': role.name,
    'department': department,
  };

  factory AppUser.fromJson(Map<String, dynamic> json) => AppUser(
    id: json['id'],
    name: json['name'],
    email: json['email'],
    role: UserRole.values.firstWhere((r) => r.name == json['role']),
    department: json['department'],
  );

  bool get isAdmin => role == UserRole.admin;
  bool get isTeacher => role == UserRole.teacher;
  bool get isStudent => role == UserRole.student;

  String get roleLabel {
    switch (role) {
      case UserRole.admin: return 'Admin';
      case UserRole.teacher: return 'Teacher';
      case UserRole.student: return 'Student';
    }
  }
}
