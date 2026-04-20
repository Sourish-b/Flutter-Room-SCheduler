import 'package:flutter/material.dart';
import 'dart:async';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/avatar_widget.dart';
import 'portal_screen.dart';

class BookRoomScreen extends StatefulWidget {
  final String? preSelectedRoom;
  const BookRoomScreen({super.key, this.preSelectedRoom});
  @override
  State<BookRoomScreen> createState() => _BookRoomScreenState();
}

class _BookRoomScreenState extends State<BookRoomScreen> {
  late String _selectedRoom;
  final ValueNotifier<DateTime> _selectedDate = ValueNotifier<DateTime>(DateTime.now());
  String _startTime = '09:00';
  String _endTime   = '10:00';
  String _bookingType = 'booking';
  final _purposeCtrl = TextEditingController();
  bool _loading = false;
  bool _success = false;
  String? _result;

  final _times = ['09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00'];
  final _bookingTypes = [
    ('booking', 'Room Booking'),
    ('reschedule', 'Class Reschedule'),
    ('extra', 'Extra Class'),
    ('meeting', 'Meeting'),
  ];

  @override
  void initState() {
    super.initState();
    _selectedRoom = widget.preSelectedRoom ?? DataService.getRoomsList().first.roomNumber;
    _endTime = _nextTime(_startTime);
  }

  @override
  void dispose() { _purposeCtrl.dispose(); super.dispose(); }

  String _nextTime(String start) {
    final idx = _times.indexOf(start);
    if (idx == -1 || idx + 1 >= _times.length) return _times.last;
    return _times[idx + 1];
  }

  Future<void> _submit() async {
    if (_purposeCtrl.text.trim().isEmpty) {
      setState(() { _result = 'Please enter the purpose of booking'; _success = false; });
      return;
    }
    final auth = context.read<AuthProvider>();
    final isAdmin = auth.isAdminLoggedIn && auth.teacher == null;
    setState(() { _loading = true; _result = null; });
    final bookingDate = DateFormat('yyyy-MM-dd').format(_selectedDate.value);
    final dayStr = DateFormat('EEEE').format(_selectedDate.value);
    try {
      final res = await context.read<RoomProvider>().book(
        roomNumber: _selectedRoom,
        day: dayStr,
        startTime: _startTime,
        endTime: _endTime,
        bookedBy: isAdmin ? 'Administrator' : auth.teacher!.name,
        facultyCode: isAdmin ? 'ADM' : auth.teacher!.facultyCode,
        purpose: _purposeCtrl.text.trim(),
        bookingType: _bookingType,
        bookingDate: bookingDate,
      ).timeout(const Duration(seconds: 4));
      if (mounted) {
        setState(() { _loading = false; _result = res.message; _success = res.success; });
        if (res.success) {
          await Future.delayed(const Duration(seconds: 1));
          if (mounted) {
            Navigator.pushReplacement(context,
                MaterialPageRoute(builder: (_) => const PortalScreen()));
          }
        }
      }
    } on TimeoutException {
      if (mounted) {
        setState(() {
          _loading = false;
          _result = 'Booking is taking too long. Please try again.';
          _success = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _result = e.toString();
          _success = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = DataService.getRoomsList();
    final auth = context.watch<AuthProvider>();
    final isAdmin = auth.isAdminLoggedIn && auth.teacher == null;
    final displayName = isAdmin ? 'Administrator' : auth.teacher!.name;
    final displayDept = isAdmin ? 'Administration' : auth.teacher!.department;

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Book a Room'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Booked by card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  AvatarWidget(name: displayName, size: 36),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(displayName,
                            style: const TextStyle(
                                fontWeight: FontWeight.w600, color: AppColors.purpleDark)),
                        Text(displayDept,
                            style: const TextStyle(fontSize: 12, color: AppColors.purple)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            if (_result != null) ...[
              _AlertBox(message: _result!, success: _success),
              const SizedBox(height: 12),
            ],

            // Form fields
            const _Label('Room'),
            DropdownButtonFormField<String>(
              initialValue: _selectedRoom,
              decoration: const InputDecoration(),
              items: rooms.map((r) => DropdownMenuItem(
                value: r.roomNumber,
                child: Text('${r.roomNumber} – ${r.roomType} (cap. ${r.capacity})',
                    style: const TextStyle(fontSize: 14)),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _selectedRoom = v); },
            ),
            const SizedBox(height: 14),

            const _Label('Date'),
            ValueListenableBuilder<DateTime>(
              valueListenable: _selectedDate,
              builder: (_, val, __) => TextFormField(
                readOnly: true,
                decoration: const InputDecoration(),
                controller: TextEditingController(
                  text: DateFormat('yyyy-MM-dd').format(val),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: val,
                    firstDate: DateTime.now().subtract(const Duration(days: 1)),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) {
                    _selectedDate.value = picked;
                  }
                },
              ),
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Label('Start Time'),
                  DropdownButtonFormField<String>(
                    initialValue: _startTime,
                    decoration: const InputDecoration(),
                    items: _times.take(_times.length - 1).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: (v) {
                      if (v != null) {
                        setState(() {
                          _startTime = v;
                          _endTime = _nextTime(v);
                        });
                      }
                    },
                  ),
                ])),
                const SizedBox(width: 12),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  const _Label('End Time'),
                  DropdownButtonFormField<String>(
                    initialValue: _endTime,
                    decoration: const InputDecoration(),
                    items: _times.skip(1).map((t) => DropdownMenuItem(value: t, child: Text(t))).toList(),
                    onChanged: null,
                  ),
                ])),
              ],
            ),
            const SizedBox(height: 14),

            const _Label('Booking Type'),
            DropdownButtonFormField<String>(
              initialValue: _bookingType,
              decoration: const InputDecoration(),
              items: _bookingTypes.map((t) => DropdownMenuItem(
                value: t.$1,
                child: Text(t.$2),
              )).toList(),
              onChanged: (v) { if (v != null) setState(() => _bookingType = v); },
            ),
            const SizedBox(height: 14),

            const _Label('Purpose'),
            TextField(
              controller: _purposeCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Extra class for mid-term preparation...',
              ),
            ),
            const SizedBox(height: 24),

            ElevatedButton(
              onPressed: _loading ? null : _submit,
              child: _loading
                  ? const SizedBox(height: 20, width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Confirm Booking'),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              onPressed: () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.textMuted,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Cancel'),
            ),
          ],
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 6),
    child: Text(text.toUpperCase(),
        style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
            color: AppColors.textMuted, letterSpacing: 0.06)),
  );
}

class _AlertBox extends StatelessWidget {
  final String message;
  final bool success;
  const _AlertBox({required this.message, required this.success});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
    decoration: BoxDecoration(
      color: success ? AppColors.greenLight : AppColors.redLight,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Row(children: [
      Icon(success ? Icons.check_circle_outline : Icons.error_outline,
          size: 18, color: success ? AppColors.green : AppColors.red),
      const SizedBox(width: 8),
      Expanded(child: Text(message,
          style: TextStyle(fontSize: 13, color: success ? AppColors.green : AppColors.red,
              fontWeight: FontWeight.w500))),
    ]),
  );
}
