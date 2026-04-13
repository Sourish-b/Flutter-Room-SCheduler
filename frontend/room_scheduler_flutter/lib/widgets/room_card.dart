import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme.dart';
import 'status_badge.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomCard extends StatelessWidget {
  final RoomWithStatus roomStatus;
  final VoidCallback onTap;

  const RoomCard({super.key, required this.roomStatus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final room = roomStatus.room;
    final cls = roomStatus.currentClass;
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        child: Row(
          children: [
            SizedBox(
              width: 44,
              child: Text(room.roomNumber,
                  style: GoogleFonts.dmMono(
                      fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.purpleDark)),
            ),
            const SizedBox(width: 4),
            SizedBox(width: 68, child: StatusBadge(status: roomStatus.status)),
            const SizedBox(width: 12),
            Expanded(
              child: cls != null && cls.isOccupied
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(cls.subject!,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.purpleDark),
                            overflow: TextOverflow.ellipsis),
                        Text(
                          [cls.year, cls.branch, cls.section, cls.facultyName]
                              .where((s) => s != null && s.isNotEmpty)
                              .join(' · '),
                          style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    )
                  : const Text('Available', style: TextStyle(fontSize: 13, color: AppColors.textMuted)),
            ),
            const Icon(Icons.chevron_right, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}
