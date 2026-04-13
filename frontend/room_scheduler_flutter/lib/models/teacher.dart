class Teacher {
  final int? id;
  final String employeeId;
  final String name;
  final String facultyCode;
  final String department;

  const Teacher({
    this.id,
    required this.employeeId,
    required this.name,
    required this.facultyCode,
    required this.department,
  });

  factory Teacher.fromJson(Map<String, dynamic> json) => Teacher(
        id: json['id'],
        employeeId: json['employee_id'] ?? '',
        name: json['name'] ?? '',
        facultyCode: json['faculty_code'] ?? '',
        department: json['department'] ?? 'CSE',
      );

  String get initials {
    final parts = name.split(' ').where((p) => p.isNotEmpty).toList();
    if (parts.length >= 2) {
      return '${parts[parts.length - 2][0]}${parts[parts.length - 1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }
}
