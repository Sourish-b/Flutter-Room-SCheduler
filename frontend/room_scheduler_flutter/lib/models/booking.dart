class Booking {
  final int? id;
  final String roomNumber;
  final String day;
  final String? bookingDate;
  final String startTime;
  final String endTime;
  final String bookedBy;
  final String? facultyCode;
  final String? purpose;
  final String bookingType;
  final String status;
  final String? createdAt;

  const Booking({
    this.id,
    required this.roomNumber,
    required this.day,
    this.bookingDate,
    required this.startTime,
    required this.endTime,
    required this.bookedBy,
    this.facultyCode,
    this.purpose,
    this.bookingType = 'booking',
    this.status = 'confirmed',
    this.createdAt,
  });

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        id: json['id'],
        roomNumber: json['room_number'] ?? '',
        day: json['day'] ?? '',
        bookingDate: json['booking_date'],
        startTime: json['start_time'] ?? '',
        endTime: json['end_time'] ?? '',
        bookedBy: json['booked_by'] ?? '',
        facultyCode: json['faculty_code'],
        purpose: json['purpose'],
        bookingType: json['booking_type'] ?? 'booking',
        status: json['status'] ?? 'confirmed',
        createdAt: json['created_at'],
      );

  Map<String, dynamic> toJson() => {
        'room_number': roomNumber,
        'day': day,
        'booking_date': bookingDate,
        'start_time': startTime,
        'end_time': endTime,
        'booked_by': bookedBy,
        'faculty_code': facultyCode,
        'purpose': purpose,
        'booking_type': bookingType,
      };
}
