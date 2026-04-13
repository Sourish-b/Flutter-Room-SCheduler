class TimeSlot {
  final String startTime; // "09:00"
  final String endTime;   // "10:00"
  final String subject;
  final String teacher;

  TimeSlot({
    required this.startTime,
    required this.endTime,
    required this.subject,
    required this.teacher,
  });

  Map<String, dynamic> toJson() => {
    'startTime': startTime,
    'endTime': endTime,
    'subject': subject,
    'teacher': teacher,
  };

  factory TimeSlot.fromJson(Map<String, dynamic> json) => TimeSlot(
    startTime: json['startTime'],
    endTime: json['endTime'],
    subject: json['subject'],
    teacher: json['teacher'],
  );

  /// Returns true if the given time (HH:mm) falls within this slot
  bool isActiveAt(String currentTime) {
    return currentTime.compareTo(startTime) >= 0 &&
        currentTime.compareTo(endTime) < 0;
  }
}

class DaySchedule {
  final String day; // "Monday", "Tuesday", etc.
  final List<TimeSlot> slots;

  DaySchedule({required this.day, required this.slots});

  Map<String, dynamic> toJson() => {
    'day': day,
    'slots': slots.map((s) => s.toJson()).toList(),
  };

  factory DaySchedule.fromJson(Map<String, dynamic> json) => DaySchedule(
    day: json['day'],
    slots: (json['slots'] as List).map((s) => TimeSlot.fromJson(s)).toList(),
  );

  TimeSlot? getActiveSlot(String currentTime) {
    for (final slot in slots) {
      if (slot.isActiveAt(currentTime)) return slot;
    }
    return null;
  }
}

class Room {
  final String id;
  final String name;         // "CS-101"
  final String building;     // "Block A"
  final int floor;
  final int capacity;
  final String type;         // "Lecture Hall", "Lab", "Seminar Room"
  final Map<String, DaySchedule> schedule; // day -> schedule

  Room({
    required this.id,
    required this.name,
    required this.building,
    required this.floor,
    required this.capacity,
    required this.type,
    required this.schedule,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'building': building,
    'floor': floor,
    'capacity': capacity,
    'type': type,
    'schedule': schedule.map((k, v) => MapEntry(k, v.toJson())),
  };

  factory Room.fromJson(Map<String, dynamic> json) => Room(
    id: json['id'],
    name: json['name'],
    building: json['building'],
    floor: json['floor'],
    capacity: json['capacity'],
    type: json['type'],
    schedule: (json['schedule'] as Map<String, dynamic>).map(
      (k, v) => MapEntry(k, DaySchedule.fromJson(v)),
    ),
  );

  /// Check if room is free at a given day and time
  bool isFreeAt(String day, String time) {
    final daySchedule = schedule[day];
    if (daySchedule == null) return true;
    return daySchedule.getActiveSlot(time) == null;
  }

  TimeSlot? currentSlot(String day, String time) {
    return schedule[day]?.getActiveSlot(time);
  }

  /// Get next available slot for today
  String? nextFreeTime(String day, String currentTime) {
    final daySchedule = schedule[day];
    if (daySchedule == null) return 'Free all day';
    
    final sortedSlots = daySchedule.slots
      ..sort((a, b) => a.startTime.compareTo(b.startTime));
    
    for (final slot in sortedSlots) {
      if (slot.endTime.compareTo(currentTime) > 0 &&
          slot.startTime.compareTo(currentTime) > 0) {
        return 'Busy from ${slot.startTime}';
      }
      if (slot.isActiveAt(currentTime)) {
        return 'Free after ${slot.endTime}';
      }
    }
    return 'Free now';
  }
}
