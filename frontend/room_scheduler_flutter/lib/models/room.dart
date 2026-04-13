class Room {
  final String roomNumber;
  final String roomType;
  final int capacity;
  final String building;

  const Room({
    required this.roomNumber,
    required this.roomType,
    required this.capacity,
    required this.building,
  });

  factory Room.fromJson(Map<String, dynamic> json) => Room(
        roomNumber: json['room_number'] ?? '',
        roomType: json['room_type'] ?? 'Classroom',
        capacity: json['capacity'] ?? 60,
        building: json['building'] ?? 'Main Block',
      );

  Map<String, dynamic> toJson() => {
        'room_number': roomNumber,
        'room_type': roomType,
        'capacity': capacity,
        'building': building,
      };
}

enum RoomStatus { free, busy, soon }

class RoomWithStatus {
  final Room room;
  final RoomStatus status;
  final TimetableEntry? currentClass;

  const RoomWithStatus({
    required this.room,
    required this.status,
    this.currentClass,
  });
}

class TimetableEntry {
  final String startTime;
  final String endTime;
  final String? subject;
  final String? year;
  final String? branch;
  final String? section;
  final String? facultyName;
  final String? facultyCode;
  final String day;

  const TimetableEntry({
    required this.startTime,
    required this.endTime,
    this.subject,
    this.year,
    this.branch,
    this.section,
    this.facultyName,
    this.facultyCode,
    required this.day,
  });

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        startTime: json['start_time'] ?? '',
        endTime: json['end_time'] ?? '',
        subject: json['subject'],
        year: json['year'],
        branch: json['branch'],
        section: json['section'],
        facultyName: json['faculty_name'],
        facultyCode: json['faculty_code'],
        day: json['day'] ?? '',
      );

  bool get isOccupied => subject != null && subject!.isNotEmpty;
}

class ScheduleSlot {
  final String time;
  final String endTime;
  final TimetableEntry? entry;

  const ScheduleSlot({
    required this.time,
    required this.endTime,
    this.entry,
  });
}
