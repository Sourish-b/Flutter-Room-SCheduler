import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../models/room_override.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../screens/room_detail_screen.dart';

class RoomCard extends StatefulWidget {
  final Room room;
  final String currentDay;
  final String currentTime;
  final bool showDetails;
  final AppUser? currentUser;

  const RoomCard({
    super.key,
    required this.room,
    required this.currentDay,
    required this.currentTime,
    this.showDetails = false,
    this.currentUser,
  });

  @override
  State<RoomCard> createState() => _RoomCardState();
}

class _RoomCardState extends State<RoomCard> {
  RoomOverride? _activeOverride;

  @override
  void initState() {
    super.initState();
    _checkOverride();
  }

  Future<void> _checkOverride() async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final overrides = await StorageService().getOverridesForRoomOnDate(widget.room.id, date);
    final active = overrides.where((o) => o.isActiveAt(date, widget.currentTime)).toList();
    if (mounted) setState(() => _activeOverride = active.isNotEmpty ? active.first : null);
  }

  @override
  Widget build(BuildContext context) {
    final timetableFree = widget.room.isFreeAt(widget.currentDay, widget.currentTime);
    final isActuallyFree = timetableFree && _activeOverride == null;
    final slot = widget.room.currentSlot(widget.currentDay, widget.currentTime);
    final statusColor = isActuallyFree ? AppTheme.available : AppTheme.occupied;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => RoomDetailScreen(
              room: widget.room,
              currentDay: widget.currentDay,
              currentTime: widget.currentTime,
              currentUser: widget.currentUser,
            ),
          ),
        );
        _checkOverride(); // refresh after returning
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: statusColor.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            // Status icon
            Container(
              width: 48, height: 48,
              decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(14)),
              child: Icon(
                isActuallyFree ? Icons.check_circle_rounded : Icons.do_not_disturb_on_rounded,
                color: statusColor, size: 26,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(widget.room.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: AppTheme.textPrimary)),
                      const Spacer(),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Text(isActuallyFree ? 'Free' : 'Occupied', style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${widget.room.building} • Floor ${widget.room.floor} • ${widget.room.type}', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                  const SizedBox(height: 4),
                  // Show override reason if active
                  if (_activeOverride != null)
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 13),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            '${_activeOverride!.reason} (${_activeOverride!.startTime}–${_activeOverride!.endTime})',
                            style: const TextStyle(color: AppTheme.warning, fontSize: 12),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    )
                  else if (!timetableFree && slot != null)
                    Text('${slot.subject} — ${slot.startTime}–${slot.endTime}', style: const TextStyle(color: AppTheme.occupied, fontSize: 12), overflow: TextOverflow.ellipsis)
                  else
                    Text(widget.room.nextFreeTime(widget.currentDay, widget.currentTime) ?? 'Free now', style: TextStyle(color: AppTheme.available.withOpacity(0.8), fontSize: 12)),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppTheme.textSecondary),
          ],
        ),
      ),
    );
  }
}
