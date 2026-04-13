import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/auth_provider.dart';
import '../../providers/room_provider.dart';
import '../../theme.dart';
import '../../widgets/avatar_widget.dart';
import 'book_room_screen.dart';
import 'login_screen.dart';
import '../../main.dart';

class PortalScreen extends StatefulWidget {
  const PortalScreen({super.key});
  @override
  State<PortalScreen> createState() => _PortalScreenState();
}

class _PortalScreenState extends State<PortalScreen> {
  DateTime? _filterDate;
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = context.read<AuthProvider>();
      if (auth.isLoggedIn) {
        context.read<RoomProvider>().loadBookings(facultyCode: auth.teacher!.facultyCode);
      }
    });
  }

  Future<void> _logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Sign Out', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Sign Out', style: TextStyle(color: AppColors.red))),
        ],
      ),
    );
    if (confirm == true && mounted) {
      context.read<AuthProvider>().logout();
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<RoomProvider>();
    final teacher = auth.teacher!;
    final bookings = provider.bookings.where((b) {
      if (b.status != 'confirmed') return false;
      if (_filterDate == null) return true;
      if (b.bookingDate == null || b.bookingDate!.isEmpty) return false;
      return b.bookingDate == DateFormat('yyyy-MM-dd').format(_filterDate!);
    }).toList();

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Teacher Portal'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pushReplacement(
                context, MaterialPageRoute(builder: (_) => const MainShell(initialIndex: 0))),
            child: const Text('Dashboard',
                style: TextStyle(color: AppColors.purple, fontSize: 13)),
          ),
          TextButton(
            onPressed: _logout,
            child: const Text('Sign out', style: TextStyle(color: AppColors.red, fontSize: 13)),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () => provider.loadBookings(facultyCode: teacher.facultyCode),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Profile card
              Container(
                margin: const EdgeInsets.all(16),
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    AvatarWidget(name: teacher.name, size: 52),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(teacher.name,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.w700,
                                  color: AppColors.purpleDark, letterSpacing: -0.3)),
                          const SizedBox(height: 2),
                          Text('${teacher.department} · ${teacher.employeeId}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                            decoration: BoxDecoration(
                                color: AppColors.purpleLight, borderRadius: BorderRadius.circular(20)),
                            child: Text(teacher.facultyCode,
                                style: const TextStyle(
                                    fontSize: 12, fontWeight: FontWeight.w600,
                                    color: AppColors.purple)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Actions
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => Navigator.push(
                            context, MaterialPageRoute(builder: (_) => const BookRoomScreen())),
                        icon: const Icon(Icons.add_rounded, size: 18),
                        label: const Text('Book a Room'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Date filter
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('DATE',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.textMuted, letterSpacing: 0.06)),
                            const SizedBox(height: 6),
                            GestureDetector(
                              onTap: () async {
                                final picked = await showDatePicker(
                                  context: context,
                                  initialDate: _filterDate ?? DateTime.now(),
                                  firstDate: DateTime.now().subtract(const Duration(days: 365)),
                                  lastDate: DateTime.now().add(const Duration(days: 365)),
                                );
                                if (picked != null) {
                                  setState(() => _filterDate = picked);
                                }
                              },
                              child: Container(
                                height: 40,
                                padding: const EdgeInsets.symmetric(horizontal: 10),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFF9F8FD),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: AppColors.border),
                                ),
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  _filterDate == null
                                      ? 'All dates'
                                      : DateFormat('yyyy-MM-dd').format(_filterDate!),
                                  style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textDark),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      SizedBox(
                        height: 40,
                        child: OutlinedButton(
                          onPressed: _filterDate == null
                              ? null
                              : () => setState(() => _filterDate = null),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.purple,
                            side: const BorderSide(color: AppColors.border),
                          ),
                          child: const Text('Clear'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // My Bookings
              const Padding(
                padding: EdgeInsets.only(left: 20, bottom: 8),
                child: Text('MY BOOKINGS',
                    style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.textMuted, letterSpacing: 0.08)),
              ),

              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: bookings.isEmpty
                    ? const Padding(
                        padding: EdgeInsets.all(28),
                        child: Column(
                          children: [
                            Icon(Icons.calendar_today_rounded, color: AppColors.textHint, size: 36),
                            SizedBox(height: 12),
                            Text('No bookings yet',
                                style: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w500)),
                            SizedBox(height: 4),
                            Text('Browse rooms and book one!',
                                style: TextStyle(fontSize: 13, color: AppColors.textHint)),
                          ],
                        ),
                      )
                    : Column(
                        children: bookings.asMap().entries.map((e) {
                          final b = e.value;
                          return Column(
                            children: [
                              if (e.key > 0) const Divider(height: 1, color: Color(0xFFF5F3FB)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 42, height: 42,
                                      decoration: BoxDecoration(
                                          color: AppColors.purpleLight,
                                          borderRadius: BorderRadius.circular(10)),
                                      alignment: Alignment.center,
                                      child: Text(b.roomNumber,
                                          style: const TextStyle(
                                              fontFamily: 'DM Mono',
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: AppColors.purple)),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(b.purpose ?? 'Booking',
                                              style: const TextStyle(
                                                  fontWeight: FontWeight.w500, fontSize: 14,
                                                  color: AppColors.purpleDark)),
                                          const SizedBox(height: 2),
                                          Text('${b.bookingDate ?? b.day} · ${b.startTime}–${b.endTime}',
                                              style: const TextStyle(
                                                  fontSize: 12, color: AppColors.textMuted)),
                                        ],
                                      ),
                                    ),
                                    TextButton(
                                      onPressed: () async {
                                        final ok = await provider.cancelBooking(
                                            b.id!, facultyCode: teacher.facultyCode);
                                        if (ok && mounted) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Booking cancelled'),
                                                backgroundColor: AppColors.green));
                                        }
                                      },
                                      style: TextButton.styleFrom(
                                        foregroundColor: AppColors.red,
                                        padding: const EdgeInsets.symmetric(horizontal: 8),
                                      ),
                                      child: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
