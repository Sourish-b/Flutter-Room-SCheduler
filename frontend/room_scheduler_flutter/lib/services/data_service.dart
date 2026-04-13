import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/room.dart';
import '../models/booking.dart';
import '../models/teacher.dart';

/// Local data service — works completely offline.
/// Swap `_useMock = false` and set [baseUrl] to connect a real Flask backend.
class DataService {
  static const bool _useMock = false;
  static const String baseUrl = 'http://127.0.0.1:5000'; // Localhost

  static final http.Client _httpClient = http.Client();

  static Uri _apiUri(String endpoint, [Map<String, String?>? queryParameters]) {
    final base = Uri.parse(baseUrl);
    final path = endpoint.startsWith('/') ? endpoint : '/$endpoint';
    return base.replace(
        path: path,
        queryParameters: queryParameters
          ?..removeWhere((_, value) => value == null));
  }

  static Future<dynamic> _getJson(Uri uri) async {
    final response =
        await _httpClient.get(uri, headers: {'Accept': 'application/json'});
    return _decodeJsonResponse(response);
  }

  static Future<dynamic> _postJson(Uri uri, Object body) async {
    final response = await _httpClient.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode(body),
    );
    return _decodeJsonResponse(response);
  }

  static dynamic _decodeJsonResponse(http.Response response) {
    final body = response.body.isNotEmpty
        ? jsonDecode(response.body)
        : <String, dynamic>{};
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    throw Exception(
        'HTTP ${response.statusCode}: ${body is Map<String, dynamic> ? body['message'] ?? response.reasonPhrase : response.reasonPhrase}');
  }

  static RoomStatus _parseRoomStatus(String status) {
    final value = status.toLowerCase();
    if (value == 'busy') return RoomStatus.busy;
    if (value == 'soon') return RoomStatus.soon;
    return RoomStatus.free;
  }

  // Helper to parse branch and section from combined string (e.g., "CSE-A" -> branch: CSE, section: A)
  static Map<String, String?> _parseSectionInfo(String? sectionStr) {
    if (sectionStr == null || sectionStr.isEmpty) return {'branch': null, 'section': null};
    final parts = sectionStr.split('-');
    return {
      'branch': parts.isNotEmpty ? parts[0] : null,
      'section': parts.length > 1 ? parts[1] : null,
    };
  }

  static TimetableEntry? _entryFromJson(Map<String, dynamic>? json,
      {String? defaultDay}) {
    if (json == null) return null;
    return TimetableEntry(
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      subject: json['subject'],
      year: json['year'],
      branch: json['branch'],
      section: json['section'],
      facultyName: json['faculty_name'],
      facultyCode: json['faculty_code'],
      day: json['day'] ?? defaultDay ?? '',
    );
  }

  static RoomWithStatus _roomWithStatusFromJson(
      Map<String, dynamic> json, String day) {
    return RoomWithStatus(
      room: Room.fromJson(json),
      status: _parseRoomStatus(json['status']?.toString() ?? 'free'),
      currentClass: _entryFromJson(
          json['current_class'] as Map<String, dynamic>?,
          defaultDay: day),
    );
  }

  // ─────────────────── MOCK DATA ───────────────────

  static final List<Teacher> _teachers = [
    const Teacher(
        id: 1,
        employeeId: 'AP001',
        name: 'Dr. Ashutosh Pandey',
        facultyCode: 'AP',
        department: 'CSE'),
    const Teacher(
        id: 2,
        employeeId: 'UK002',
        name: 'Dr. Umesh Kumar',
        facultyCode: 'UK',
        department: 'CSE'),
    const Teacher(
        id: 3,
        employeeId: 'VJ003',
        name: 'Prof. Vikas Jain',
        facultyCode: 'VJ',
        department: 'ECE'),
    const Teacher(
        id: 4,
        employeeId: 'SM004',
        name: 'Dr. Shweta Mishra',
        facultyCode: 'SM',
        department: 'CSE'),
    const Teacher(
        id: 5,
        employeeId: 'RK005',
        name: 'Prof. Rakesh Kumar',
        facultyCode: 'RK',
        department: 'ECE'),
    const Teacher(
        id: 6,
        employeeId: 'TG006',
        name: 'Prof. Tanvi Gupta',
        facultyCode: 'TG',
        department: 'CSE'),
  ];

  static final List<Room> _rooms = [
    const Room(
        roomNumber: '203', roomType: 'Lab', capacity: 40, building: 'Block A'),
    const Room(
        roomNumber: '204',
        roomType: 'Classroom',
        capacity: 60,
        building: 'Block A'),
    const Room(
        roomNumber: '211',
        roomType: 'Classroom',
        capacity: 60,
        building: 'Block A'),
    const Room(
        roomNumber: '212', roomType: 'Lab', capacity: 30, building: 'Block A'),
    const Room(
        roomNumber: '216', roomType: 'Lab', capacity: 35, building: 'Block A'),
    const Room(
        roomNumber: '312', roomType: 'Lab', capacity: 30, building: 'Block B'),
    const Room(
        roomNumber: '314',
        roomType: 'Classroom',
        capacity: 60,
        building: 'Block B'),
    const Room(
        roomNumber: '315',
        roomType: 'Classroom',
        capacity: 60,
        building: 'Block B'),
    const Room(
        roomNumber: '101',
        roomType: 'Seminar Hall',
        capacity: 100,
        building: 'Block C'),
  ];

  // schedule: roomNumber -> list of {day, start, end, subject, faculty, section}
  static final Map<String, List<Map<String, String>>> _schedule = {
    '203': [
      {
        'day': 'Monday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'CVFD Lab',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'CSE-A'
      },
      {
        'day': 'Monday',
        'start': '11:00',
        'end': '12:00',
        'subject': 'Data Structures',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'CSE-B'
      },
      {
        'day': 'Monday',
        'start': '13:00',
        'end': '14:00',
        'subject': 'Web Dev',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'CSE-A'
      },
      {
        'day': 'Monday',
        'start': '15:00',
        'end': '16:00',
        'subject': 'Lab Session',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'ECE-B'
      },
      {
        'day': 'Tuesday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'DBMS Lab',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'CSE-A'
      },
      {
        'day': 'Tuesday',
        'start': '14:00',
        'end': '16:00',
        'subject': 'OS Lab',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'CSE-B'
      },
      {
        'day': 'Wednesday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'CVFD Lab',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'ECE-A'
      },
      {
        'day': 'Wednesday',
        'start': '12:00',
        'end': '13:00',
        'subject': 'Algorithms',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'CSE-A'
      },
      {
        'day': 'Thursday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'Data Structures',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'ECE-B'
      },
      {
        'day': 'Thursday',
        'start': '14:00',
        'end': '15:00',
        'subject': 'Web Dev',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'CSE-B'
      },
      {
        'day': 'Friday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'CVFD Lab',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'CSE-A'
      },
      {
        'day': 'Friday',
        'start': '11:00',
        'end': '13:00',
        'subject': 'Project Lab',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'CSE-A'
      },
    ],
    '204': [
      {
        'day': 'Monday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'Mathematics',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'CSE-A'
      },
      {
        'day': 'Monday',
        'start': '12:00',
        'end': '13:00',
        'subject': 'Physics',
        'faculty': 'Prof. Rakesh Kumar',
        'code': 'RK',
        'section': 'ECE-A'
      },
      {
        'day': 'Monday',
        'start': '14:00',
        'end': '15:00',
        'subject': 'English',
        'faculty': 'Prof. Tanvi Gupta',
        'code': 'TG',
        'section': 'CSE-B'
      },
      {
        'day': 'Tuesday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'Mathematics',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'ECE-A'
      },
      {
        'day': 'Tuesday',
        'start': '11:00',
        'end': '12:00',
        'subject': 'Communication',
        'faculty': 'Prof. Tanvi Gupta',
        'code': 'TG',
        'section': 'CSE-A'
      },
      {
        'day': 'Wednesday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'Physics',
        'faculty': 'Prof. Rakesh Kumar',
        'code': 'RK',
        'section': 'ECE-B'
      },
      {
        'day': 'Thursday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'Mathematics',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'CSE-B'
      },
      {
        'day': 'Friday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'English',
        'faculty': 'Prof. Tanvi Gupta',
        'code': 'TG',
        'section': 'ECE-A'
      },
      {
        'day': 'Friday',
        'start': '13:00',
        'end': '14:00',
        'subject': 'Physics',
        'faculty': 'Prof. Rakesh Kumar',
        'code': 'RK',
        'section': 'CSE-A'
      },
    ],
    '211': [
      {
        'day': 'Monday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'OS Theory',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'CSE-B'
      },
      {
        'day': 'Monday',
        'start': '12:00',
        'end': '13:00',
        'subject': 'DBMS',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'CSE-A'
      },
      {
        'day': 'Monday',
        'start': '14:00',
        'end': '15:00',
        'subject': 'Algorithms',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'CSE-B'
      },
      {
        'day': 'Tuesday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'OS Theory',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'ECE-A'
      },
      {
        'day': 'Wednesday',
        'start': '11:00',
        'end': '12:00',
        'subject': 'DBMS',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'CSE-B'
      },
      {
        'day': 'Thursday',
        'start': '13:00',
        'end': '14:00',
        'subject': 'Algorithms',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'ECE-B'
      },
      {
        'day': 'Friday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'OS Theory',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'CSE-A'
      },
    ],
    '212': [
      {
        'day': 'Monday',
        'start': '09:00',
        'end': '11:00',
        'subject': 'EW Lab',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'ECE-A'
      },
      {
        'day': 'Monday',
        'start': '13:00',
        'end': '14:00',
        'subject': 'Circuit Lab',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'ECE-B'
      },
      {
        'day': 'Tuesday',
        'start': '10:00',
        'end': '12:00',
        'subject': 'EW Lab',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'ECE-B'
      },
      {
        'day': 'Thursday',
        'start': '09:00',
        'end': '11:00',
        'subject': 'EW Lab',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'ECE-A'
      },
      {
        'day': 'Friday',
        'start': '13:00',
        'end': '15:00',
        'subject': 'Circuit Lab',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'ECE-A'
      },
    ],
    '216': [
      {
        'day': 'Monday',
        'start': '09:00',
        'end': '10:00',
        'subject': '216 Theory',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'CSE-A'
      },
      {
        'day': 'Monday',
        'start': '11:00',
        'end': '12:00',
        'subject': 'Data Structures',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'ECE-A'
      },
      {
        'day': 'Monday',
        'start': '13:00',
        'end': '14:00',
        'subject': 'Web Dev',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'CSE-B'
      },
      {
        'day': 'Tuesday',
        'start': '09:00',
        'end': '10:00',
        'subject': '216 Theory',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'ECE-B'
      },
      {
        'day': 'Wednesday',
        'start': '14:00',
        'end': '15:00',
        'subject': 'VM Lab',
        'faculty': 'Prof. Vikas Jain',
        'code': 'VJ',
        'section': 'ECE-A'
      },
      {
        'day': 'Thursday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'Data Structures',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'CSE-A'
      },
      {
        'day': 'Friday',
        'start': '15:00',
        'end': '16:00',
        'subject': 'Lab Session',
        'faculty': 'Dr. Ashutosh Pandey',
        'code': 'AP',
        'section': 'ECE-B'
      },
    ],
    '312': [
      {
        'day': 'Monday',
        'start': '10:00',
        'end': '12:00',
        'subject': 'DS Lab',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'CSE-A'
      },
      {
        'day': 'Monday',
        'start': '14:00',
        'end': '15:00',
        'subject': 'Network Lab',
        'faculty': 'Prof. Rakesh Kumar',
        'code': 'RK',
        'section': 'CSE-B'
      },
      {
        'day': 'Wednesday',
        'start': '10:00',
        'end': '12:00',
        'subject': 'DS Lab',
        'faculty': 'Dr. Umesh Kumar',
        'code': 'UK',
        'section': 'CSE-B'
      },
      {
        'day': 'Friday',
        'start': '09:00',
        'end': '11:00',
        'subject': 'Network Lab',
        'faculty': 'Prof. Rakesh Kumar',
        'code': 'RK',
        'section': 'CSE-A'
      },
    ],
    '314': [
      {
        'day': 'Monday',
        'start': '11:00',
        'end': '12:00',
        'subject': 'English',
        'faculty': 'Prof. Tanvi Gupta',
        'code': 'TG',
        'section': 'ECE-A'
      },
      {
        'day': 'Monday',
        'start': '13:00',
        'end': '14:00',
        'subject': 'Mathematics',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'ECE-B'
      },
      {
        'day': 'Wednesday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'Communication',
        'faculty': 'Prof. Tanvi Gupta',
        'code': 'TG',
        'section': 'ECE-B'
      },
      {
        'day': 'Thursday',
        'start': '11:00',
        'end': '12:00',
        'subject': 'Mathematics',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'ECE-A'
      },
    ],
    '315': [
      {
        'day': 'Monday',
        'start': '09:00',
        'end': '10:00',
        'subject': 'Communication',
        'faculty': 'Prof. Tanvi Gupta',
        'code': 'TG',
        'section': 'CSE-A'
      },
      {
        'day': 'Tuesday',
        'start': '14:00',
        'end': '16:00',
        'subject': 'Project Work',
        'faculty': 'Dr. Shweta Mishra',
        'code': 'SM',
        'section': 'CSE-B'
      },
      {
        'day': 'Thursday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'Seminar',
        'faculty': 'Prof. Rakesh Kumar',
        'code': 'RK',
        'section': 'ALL'
      },
    ],
    '101': [
      {
        'day': 'Monday',
        'start': '10:00',
        'end': '11:00',
        'subject': 'Guest Lecture',
        'faculty': 'Prof. Rakesh Kumar',
        'code': 'RK',
        'section': 'ALL'
      },
      {
        'day': 'Wednesday',
        'start': '14:00',
        'end': '16:00',
        'subject': 'Seminar',
        'faculty': 'Prof. Tanvi Gupta',
        'code': 'TG',
        'section': 'ALL'
      },
    ],
  };

  static final List<Booking> _bookings = [];
  static int _bookingIdCounter = 100;

  // ─────────────────── HELPERS ───────────────────

  static int _timeToMins(String t) {
    final parts = t.split(':');
    return int.parse(parts[0]) * 60 + int.parse(parts[1]);
  }

  static RoomStatus _computeStatus(
      String roomNumber, String day, String currentTime) {
    final cur = _timeToMins(currentTime);
    final entries =
        (_schedule[roomNumber] ?? []).where((e) => e['day'] == day).toList();
    final bookings = _bookings
        .where((b) =>
            b.roomNumber == roomNumber &&
            b.day == day &&
            b.status == 'confirmed')
        .toList();

    for (final e in entries) {
      if (_timeToMins(e['start']!) <= cur && cur < _timeToMins(e['end']!)) {
        return RoomStatus.busy;
      }
    }
    for (final b in bookings) {
      if (_timeToMins(b.startTime) <= cur && cur < _timeToMins(b.endTime)) {
        return RoomStatus.busy;
      }
    }
    for (final e in entries) {
      final diff = _timeToMins(e['start']!) - cur;
      if (diff > 0 && diff <= 60) return RoomStatus.soon;
    }
    for (final b in bookings) {
      final diff = _timeToMins(b.startTime) - cur;
      if (diff > 0 && diff <= 60) return RoomStatus.soon;
    }
    return RoomStatus.free;
  }

  static TimetableEntry? _getCurrentEntry(
      String roomNumber, String day, String currentTime) {
    final cur = _timeToMins(currentTime);
    final entries =
        (_schedule[roomNumber] ?? []).where((e) => e['day'] == day).toList();
    for (final e in entries) {
      if (_timeToMins(e['start']!) <= cur && cur < _timeToMins(e['end']!)) {
        final sectionInfo = _parseSectionInfo(e['section']);
        return TimetableEntry(
          startTime: e['start']!,
          endTime: e['end']!,
          subject: e['subject'],
          year: e['year'] ?? '1st',
          branch: sectionInfo['branch'],
          section: sectionInfo['section'],
          facultyName: e['faculty'],
          facultyCode: e['code'],
          day: day,
        );
      }
    }
    // check bookings
    final bookings = _bookings
        .where((b) =>
            b.roomNumber == roomNumber &&
            b.day == day &&
            b.status == 'confirmed')
        .toList();
    for (final b in bookings) {
      if (_timeToMins(b.startTime) <= cur && cur < _timeToMins(b.endTime)) {
        return TimetableEntry(
          startTime: b.startTime,
          endTime: b.endTime,
          subject: b.purpose ?? 'Booked',
          facultyName: b.bookedBy,
          day: day,
        );
      }
    }
    return null;
  }

  // ─────────────────── PUBLIC API ───────────────────

  static Future<List<RoomWithStatus>> getRoomsWithStatus(
      String day, String time, {String? date}) async {
    if (_useMock) {
      await Future.delayed(
          const Duration(milliseconds: 300)); // simulate network
      return _rooms.map((room) {
        return RoomWithStatus(
          room: room,
          status: _computeStatus(room.roomNumber, day, time),
          currentClass: _getCurrentEntry(room.roomNumber, day, time),
        );
      }).toList();
    }

    final uri = _apiUri('api/rooms/status', {
      'day': date == null ? day : null,
      'time': time,
      'date': date,
    });
    final json = await _getJson(uri);
    final rooms = (json['rooms'] as List<dynamic>?) ?? [];
    return rooms.cast<Map<String, dynamic>>().map((roomJson) {
      return _roomWithStatusFromJson(roomJson, day);
    }).toList();
  }

  static Future<List<ScheduleSlot>> getRoomSchedule(
      String roomNumber, String day, {String? date}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      final hours = List.generate(7, (i) {
        final h = 9 + i;
        return (
          '${h.toString().padLeft(2, '0')}:00',
          '${(h + 1).toString().padLeft(2, '0')}:00'
        );
      });

      final entries =
          (_schedule[roomNumber] ?? []).where((e) => e['day'] == day).toList();
      final bookings = _bookings
          .where((b) =>
              b.roomNumber == roomNumber &&
              b.day == day &&
              b.status == 'confirmed')
          .toList();

      return hours.map(((String, String) slot) {
        final sMins = _timeToMins(slot.$1);
        final entry = entries.cast<Map<String, String>?>().firstWhere(
              (e) =>
                  _timeToMins(e!['start']!) <= sMins &&
                  sMins < _timeToMins(e['end']!),
              orElse: () => null,
            );
        if (entry != null) {
          final sectionInfo = _parseSectionInfo(entry['section']);
          return ScheduleSlot(
            time: slot.$1,
            endTime: slot.$2,
            entry: TimetableEntry(
              startTime: entry['start']!,
              endTime: entry['end']!,
              subject: entry['subject'],
              year: entry['year'] ?? '1st',
              branch: sectionInfo['branch'],
              section: sectionInfo['section'],
              facultyName: entry['faculty'],
              facultyCode: entry['code'],
              day: day,
            ),
          );
        }
        final booking = bookings.cast<Booking?>().firstWhere(
              (b) =>
                  _timeToMins(b!.startTime) <= sMins &&
                  sMins < _timeToMins(b.endTime),
              orElse: () => null,
            );
        if (booking != null) {
          return ScheduleSlot(
            time: slot.$1,
            endTime: slot.$2,
            entry: TimetableEntry(
              startTime: booking.startTime,
              endTime: booking.endTime,
              subject: booking.purpose ?? 'Booked',
              facultyName: booking.bookedBy,
              day: day,
            ),
          );
        }
        return ScheduleSlot(time: slot.$1, endTime: slot.$2);
      }).toList();
    }

    final uri = _apiUri('api/rooms/$roomNumber/schedule', {
      'day': date == null ? day : null,
      'date': date,
    });
    final json = await _getJson(uri);
    final schedule = (json['schedule'] as List<dynamic>?) ?? [];
    return schedule.cast<Map<String, dynamic>>().map((slotJson) {
      return ScheduleSlot(
        time: slotJson['time'] ?? '',
        endTime: slotJson['end'] ?? slotJson['end_time'] ?? '',
        entry: _entryFromJson(slotJson['entry'] as Map<String, dynamic>?,
            defaultDay: day),
      );
    }).toList();
  }

  static Future<Teacher?> loginTeacher(String employeeId) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        return _teachers.firstWhere(
          (t) => t.employeeId.toLowerCase() == employeeId.toLowerCase(),
        );
      } catch (_) {
        return null;
      }
    }

    final json = await _postJson(_apiUri('api/teachers/login'), {'employee_id': employeeId});
    if (json is Map<String, dynamic> && json['success'] == true) {
      return Teacher.fromJson(json['teacher'] as Map<String, dynamic>);
    }
    return null;
  }

  static Future<List<Teacher>> getTeachers() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      return List.from(_teachers);
    }

    final uri = _apiUri('api/teachers');
    final json = await _getJson(uri);
    final results =
        json is List ? json : (json['teachers'] as List<dynamic>? ?? []);
    return results.cast<Map<String, dynamic>>().map(Teacher.fromJson).toList();
  }

  static Future<List<Booking>> getBookings({String? facultyCode}) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      if (facultyCode != null) {
        return _bookings.where((b) => b.facultyCode == facultyCode).toList();
      }
      return List.from(_bookings);
    }

    final uri = _apiUri(
        'api/bookings', {if (facultyCode != null) 'faculty_code': facultyCode});
    final json = await _getJson(uri);
    final results =
        json is List ? json : (json['bookings'] as List<dynamic>? ?? []);
    return results.cast<Map<String, dynamic>>().map(Booking.fromJson).toList();
  }

  static Future<({bool success, String message, int? id})> createBooking(
      Booking booking) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 400));
      // Check conflict with timetable
      final entries = (_schedule[booking.roomNumber] ?? [])
          .where((e) => e['day'] == booking.day);
      for (final e in entries) {
        if (_timeToMins(e['start']!) < _timeToMins(booking.endTime) &&
            _timeToMins(e['end']!) > _timeToMins(booking.startTime)) {
          return (
            success: false,
            message: 'Room has a scheduled class at this time',
            id: null
          );
        }
      }
      // Check conflict with other bookings
      for (final b in _bookings) {
        if (b.roomNumber == booking.roomNumber &&
            b.day == booking.day &&
            b.status == 'confirmed') {
          if (_timeToMins(b.startTime) < _timeToMins(booking.endTime) &&
              _timeToMins(b.endTime) > _timeToMins(booking.startTime)) {
            return (
              success: false,
              message: 'Room already booked at this time',
              id: null
            );
          }
        }
      }
      final id = ++_bookingIdCounter;
      _bookings.add(Booking(
        id: id,
        roomNumber: booking.roomNumber,
        day: booking.day,
        startTime: booking.startTime,
        endTime: booking.endTime,
        bookedBy: booking.bookedBy,
        facultyCode: booking.facultyCode,
        purpose: booking.purpose,
        bookingType: booking.bookingType,
      ));
      return (success: true, message: 'Room booked successfully!', id: id);
    }

    final body = await _postJson(_apiUri('api/bookings'), booking.toJson());
    return (
      success: body['success'] == true,
      message: (body['message'] as String?) ?? 'Unknown response',
      id: body['booking_id'] as int?,
    );
  }

  static Future<bool> cancelBooking(int id) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 200));
      final idx = _bookings.indexWhere((b) => b.id == id);
      if (idx == -1) return false;
      _bookings[idx] = Booking(
        id: _bookings[idx].id,
        roomNumber: _bookings[idx].roomNumber,
        day: _bookings[idx].day,
        startTime: _bookings[idx].startTime,
        endTime: _bookings[idx].endTime,
        bookedBy: _bookings[idx].bookedBy,
        facultyCode: _bookings[idx].facultyCode,
        purpose: _bookings[idx].purpose,
        bookingType: _bookings[idx].bookingType,
        status: 'cancelled',
      );
      return true;
    }

    final uri = _apiUri('api/bookings/$id');
    final response =
        await _httpClient.delete(uri, headers: {'Accept': 'application/json'});
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    }
    return false;
  }

  static Future<({bool success, String message})> addTimetableEntry({
    required String roomNumber,
    required String day,
    required String startTime,
    required String endTime,
    required String subject,
    required String facultyCode,
    required String facultyName,
    required String section,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      _schedule.putIfAbsent(roomNumber, () => []);
      _schedule[roomNumber]!.add({
        'day': day,
        'start': startTime,
        'end': endTime,
        'subject': subject,
        'faculty': facultyName,
        'code': facultyCode,
        'section': section,
      });
      return (success: true, message: 'Entry added to timetable');
    }

    final body = await _postJson(_apiUri('api/timetable'), {
      'room_number': roomNumber,
      'day': day,
      'start_time': startTime,
      'end_time': endTime,
      'subject': subject,
      'faculty_code': facultyCode,
      'faculty_name': facultyName,
      'section': section,
    });
    return (
      success: body['success'] == true,
      message: (body['message'] as String?) ?? 'Entry added',
    );
  }

  static Future<({bool success, String message})> resetSchedule() async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 300));
      _schedule.clear();
      _bookings.clear();
      return (success: true, message: 'Schedule reset successfully.');
    }

    final body = await _postJson(_apiUri('api/timetable/reset'), {});
    return (
      success: body['success'] == true,
      message: (body['message'] as String?) ?? 'Schedule reset',
    );
  }

  static Future<({bool success, String message})> uploadTimetablePdf({
    required List<int> bytes,
    required String filename,
    required String session,
  }) async {
    if (_useMock) {
      await Future.delayed(const Duration(milliseconds: 600));
      return (success: true, message: 'PDF processed successfully. Timetable updated.');
    }

    final uri = _apiUri('api/timetable/upload');
    final request = http.MultipartRequest('POST', uri)
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: filename))
      ..fields['session'] = session;
    final response = await request.send();
    final body = await response.stream.bytesToString();
    if (response.statusCode >= 200 && response.statusCode < 300) {
      final json = body.isNotEmpty ? jsonDecode(body) : <String, dynamic>{};
      return (
        success: json['success'] == true,
        message: (json['message'] as String?) ?? 'PDF processed successfully.',
      );
    }
    throw Exception('HTTP ${response.statusCode}: $body');
  }

  static List<Room> getRoomsList() => List.from(_rooms);
}
