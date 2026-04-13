import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/room.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/status_badge.dart';
import '../../widgets/time_slot_row.dart';
import '../teacher/book_room_screen.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  const RoomDetailScreen({super.key, required this.room});

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadSchedule(widget.room.roomNumber);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();
    final isToday = provider.selectedDay == DateFormat('EEEE').format(now);
    final currentTimeMins = now.hour * 60 + now.minute;

    // Find room status from dashboard data
    final roomStatus = provider.allRooms
        .cast<RoomWithStatus?>()
        .firstWhere((r) => r?.room.roomNumber == widget.room.roomNumber, orElse: () => null);

    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Room Detail'),
        actions: [
          Container(
            margin: const EdgeInsets.only(right: 16),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
                color: AppColors.purpleLight, borderRadius: BorderRadius.circular(20)),
            child: Text('Room ${widget.room.roomNumber}',
                style: const TextStyle(
                    fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.purple)),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Hero card
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                        colors: [Color(0xFF534AB7), Color(0xFF3C3489)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Room ${widget.room.roomNumber}',
                          style: const TextStyle(
                              fontSize: 24, fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(height: 4),
                      Text(
                          '${widget.room.roomType} · Capacity ${widget.room.capacity} · ${widget.room.building}',
                          style: const TextStyle(fontSize: 13, color: Colors.white70)),
                      const SizedBox(height: 12),
                      if (roomStatus != null) StatusBadge(status: roomStatus.status, large: true),
                    ],
                  ),
                ),

                // Schedule title
                Padding(
                  padding: const EdgeInsets.only(left: 20, bottom: 8),
                  child: Text(
                    "SCHEDULE — ${provider.selectedDay.toUpperCase()}",
                    style: const TextStyle(
                        fontSize: 11, fontWeight: FontWeight.w700,
                        color: AppColors.textMuted, letterSpacing: 0.08),
                  ),
                ),
              ],
            ),
          ),

          // Schedule list
          if (provider.isLoading)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
              ),
            )
          else
            SliverToBoxAdapter(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  children: provider.currentSchedule.asMap().entries.map((e) {
                    final slot = e.value;
                    final slotMins = int.parse(slot.time.split(':')[0]) * 60 +
                        int.parse(slot.time.split(':')[1]);
                    final isCurrent = isToday &&
                        slotMins <= currentTimeMins &&
                        currentTimeMins < slotMins + 60;
                    return Column(
                      children: [
                        if (e.key > 0) const Divider(height: 1, color: Color(0xFFF5F3FB)),
                        TimeSlotRow(slot: slot, isCurrent: isCurrent),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),

          // Book button
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: auth.isLoggedIn
                  ? ElevatedButton(
                      onPressed: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => BookRoomScreen(
                                  preSelectedRoom: widget.room.roomNumber))),
                      child: const Text('Book This Room'),
                    )
                  : Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                          color: AppColors.purpleLight,
                          borderRadius: BorderRadius.circular(10)),
                      child: const Row(
                        children: [
                          Icon(Icons.info_outline, color: AppColors.purple, size: 18),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text('Login as a teacher to book this room.',
                                style: TextStyle(fontSize: 13, color: AppColors.purple)),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
