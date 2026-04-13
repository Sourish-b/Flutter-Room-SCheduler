import 'package:flutter/material.dart';
import '../models/user.dart';
import '../models/room.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/room_card.dart';
import 'upload_timetable_screen.dart';

class AdminScreen extends StatefulWidget {
  final AppUser user;
  final VoidCallback onUpdate;
  const AdminScreen({super.key, required this.user, required this.onUpdate});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  List<Room> _rooms = [];
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _loadRooms();
  }

  Future<void> _loadRooms() async {
    setState(() => _loading = true);
    final rooms = await StorageService().getRooms();
    if (mounted) setState(() { _rooms = rooms; _loading = false; });
  }

  Future<void> _deleteRoom(String id) async {
    await StorageService().deleteRoom(id);
    widget.onUpdate();
    _loadRooms();
  }

  void _openUpload() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UploadTimetableScreen(
          currentUser: widget.user,
          onTimetableUpdated: () {
            widget.onUpdate();
            _loadRooms();
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    const days = ['Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'];
    final day = days[now.weekday - 1];
    final time = '${now.hour.toString().padLeft(2,'0')}:${now.minute.toString().padLeft(2,'0')}';

    return SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
            child: Row(
              children: [
                const Expanded(
                  child: Text('Admin Panel', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
                ),
              ],
            ),
          ),

          // Action buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 0),
            child: Row(
              children: [
                // Upload Timetable
                Expanded(
                  child: GestureDetector(
                    onTap: _openUpload,
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [AppTheme.primary.withOpacity(0.2), AppTheme.accent.withOpacity(0.1)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primary.withOpacity(0.4)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.upload_file_rounded, color: AppTheme.primary, size: 28),
                          SizedBox(height: 8),
                          Text('Upload\nTimetable', textAlign: TextAlign.center, style: TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w600, fontSize: 13)),
                          SizedBox(height: 4),
                          Text('PDF replace', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Stats
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppTheme.surface,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.meeting_room_rounded, color: AppTheme.accent, size: 28),
                        const SizedBox(height: 8),
                        Text('${_rooms.length}', style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w700, fontSize: 22)),
                        const Text('Total Rooms', style: TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text('Rooms', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textSecondary)),
          ),
          const SizedBox(height: 10),

          Expanded(
            child: _loading
              ? const Center(child: CircularProgressIndicator(color: AppTheme.primary))
              : _rooms.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.upload_file_rounded, size: 56, color: AppTheme.textSecondary.withOpacity(0.3)),
                        const SizedBox(height: 12),
                        const Text('Koi room nahi — PDF upload karo', style: TextStyle(color: AppTheme.textSecondary)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _openUpload,
                          icon: const Icon(Icons.upload_rounded, size: 18),
                          label: const Text('Upload Timetable'),
                        ),
                      ],
                    ),
                  )
                : ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    itemCount: _rooms.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) => Dismissible(
                      key: Key(_rooms[i].id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(color: AppTheme.occupied.withOpacity(0.2), borderRadius: BorderRadius.circular(16)),
                        child: const Icon(Icons.delete_outline, color: AppTheme.occupied),
                      ),
                      onDismissed: (_) => _deleteRoom(_rooms[i].id),
                      child: RoomCard(room: _rooms[i], currentDay: day, currentTime: time, currentUser: widget.user),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}
