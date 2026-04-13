import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import '../models/room.dart';
import '../models/booking.dart';
import '../services/data_service.dart';

class RoomProvider extends ChangeNotifier {
  List<RoomWithStatus> _rooms = [];
  List<ScheduleSlot> _currentSchedule = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String? _error;
  String _filterStatus = 'all';
  String _filterBuilding = 'all';
  static const List<String> _timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  String _selectedDay = DateFormat('EEEE').format(DateTime.now());
  String _selectedTime = _normalizeTime(DateFormat('HH:mm').format(DateTime.now()));
  DateTime _selectedDate = DateTime.now();
  static String _normalizeTime(String time) {
    if (_timeSlots.contains(time)) return time;
    final parts = time.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? 0;
    final target = h * 60 + m;
    var best = _timeSlots.first;
    var bestDiff = 24 * 60;
    for (final slot in _timeSlots) {
      final sParts = slot.split(':');
      final sH = int.parse(sParts[0]);
      final sM = int.parse(sParts[1]);
      final diff = (sH * 60 + sM - target).abs();
      if (diff < bestDiff) {
        best = slot;
        bestDiff = diff;
      }
    }
    return best;
  }

  List<RoomWithStatus> get rooms => _filtered;
  List<RoomWithStatus> get allRooms => _rooms;
  List<ScheduleSlot> get currentSchedule => _currentSchedule;
  List<Booking> get bookings => _bookings;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get filterStatus => _filterStatus;
  String get filterBuilding => _filterBuilding;
  String get selectedDay => _selectedDay;
  String get selectedTime => _selectedTime;
  DateTime get selectedDate => _selectedDate;

  int get freeCount => _rooms.where((r) => r.status == RoomStatus.free).length;
  int get busyCount => _rooms.where((r) => r.status == RoomStatus.busy).length;
  int get soonCount => _rooms.where((r) => r.status == RoomStatus.soon).length;

  List<String> get buildings =>
      _rooms.map((r) => r.room.building).toSet().toList()..sort();

  List<RoomWithStatus> get _filtered {
    var list = List<RoomWithStatus>.from(_rooms);
    if (_filterStatus != 'all') {
      final s = {
        'free': RoomStatus.free,
        'busy': RoomStatus.busy,
        'soon': RoomStatus.soon,
      }[_filterStatus];
      list = list.where((r) => r.status == s).toList();
    }
    if (_filterBuilding != 'all') {
      list = list.where((r) => r.room.building == _filterBuilding).toList();
    }
    return list;
  }

  void setFilterStatus(String status) {
    _filterStatus = status;
    notifyListeners();
  }

  void setFilterBuilding(String building) {
    _filterBuilding = _filterBuilding == building ? 'all' : building;
    notifyListeners();
  }

  String get currentDay => DateFormat('EEEE').format(DateTime.now());
  String get currentTime => DateFormat('HH:mm').format(DateTime.now());

  String get slotLabel {
    final parts = _selectedTime.split(':');
    final h = int.tryParse(parts[0]) ?? DateTime.now().hour;
    final m = int.tryParse(parts.length > 1 ? parts[1] : '') ?? DateTime.now().minute;
    final total = h * 60 + m;
    if (total < 9 * 60 || total >= 16 * 60) return 'After Hours';
    final slotH = ((total - 9 * 60) ~/ 60) + 9;
    return '${slotH.toString().padLeft(2, '0')}:00 – ${(slotH + 1).toString().padLeft(2, '0')}:00';
  }

  Future<void> setSelectedDay(String day) async {
    _selectedDay = day;
    await loadRooms();
  }

  Future<void> setSelectedTime(String time) async {
    _selectedTime = _normalizeTime(time);
    await loadRooms();
  }

  Future<void> setSelectedDate(DateTime date) async {
    _selectedDate = date;
    _selectedDay = DateFormat('EEEE').format(date);
    await loadRooms();
  }

  Future<void> useCurrentDateTime() async {
    _selectedDate = DateTime.now();
    _selectedDay = currentDay;
    _selectedTime = _normalizeTime(currentTime);
    await loadRooms();
  }

  Future<void> loadRooms() async {
    _isLoading = true;
    _error = null;
    notifyListeners();
    try {
      final dateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
      _rooms = await DataService.getRoomsWithStatus(_selectedDay, _selectedTime, date: dateStr);
      _error = null;
    } catch (e) {
      _error = 'Failed to load rooms: $e';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadSchedule(String roomNumber) async {
    _isLoading = true;
    notifyListeners();
    try {
      _currentSchedule = await DataService.getRoomSchedule(roomNumber, _selectedDay);
    } catch (e) {
      _error = 'Failed to load schedule';
    }
    _isLoading = false;
    notifyListeners();
  }

  Future<void> loadBookings({String? facultyCode}) async {
    try {
      _bookings = await DataService.getBookings(facultyCode: facultyCode);
      notifyListeners();
    } catch (_) {}
  }

  Future<({bool success, String message})> book({
    required String roomNumber,
    required String day,
    required String startTime,
    required String endTime,
    required String bookedBy,
    required String facultyCode,
    required String purpose,
    required String bookingType,
    String? bookingDate,
  }) async {
    final result = await DataService.createBooking(Booking(
      roomNumber: roomNumber,
      day: day,
      bookingDate: bookingDate,
      startTime: startTime,
      endTime: endTime,
      bookedBy: bookedBy,
      facultyCode: facultyCode,
      purpose: purpose,
      bookingType: bookingType,
    ));
    if (result.success) {
      await loadRooms();
      await loadBookings(facultyCode: facultyCode);
    }
    return (success: result.success, message: result.message);
  }

  Future<bool> cancelBooking(int id, {String? facultyCode}) async {
    final ok = await DataService.cancelBooking(id);
    if (ok) await loadBookings(facultyCode: facultyCode);
    return ok;
  }
}
