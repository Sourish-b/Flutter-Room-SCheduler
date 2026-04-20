import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class RoomCard extends StatelessWidget {
  final RoomWithStatus roomStatus;
  final VoidCallback onTap;

  const RoomCard({super.key, required this.roomStatus, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final room = roomStatus.room;
    final cls = roomStatus.currentClass;
    final statusCfg = switch (roomStatus.status) {
      RoomStatus.free => (
        label: 'FREE',
        fg: AppColors.green,
        bg: AppColors.greenLight,
        dot: const Color(0xFF22C55E)
      ),
      RoomStatus.busy => (
        label: 'BUSY',
        fg: AppColors.red,
        bg: AppColors.redLight,
        dot: const Color(0xFFEF4444)
      ),
      RoomStatus.soon => (
        label: 'SOON',
        fg: AppColors.amber,
        bg: AppColors.amberLight,
        dot: const Color(0xFFF59E0B)
      ),
    };

    final isOccupied = cls != null && cls.isOccupied;
    final subtitle = isOccupied
        ? [cls.year, cls.branch, cls.section, cls.facultyName]
            .where((s) => s != null && s.isNotEmpty)
            .join(' · ')
        : '${room.roomType} · Cap ${room.capacity} · ${room.building}';

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColors.purpleLight,
                borderRadius: BorderRadius.circular(12),
              ),
              alignment: Alignment.center,
              child: Text(
                room.roomNumber,
                style: GoogleFonts.dmMono(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.purple),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isOccupied ? (cls.subject ?? 'In Use') : 'Available',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: AppColors.purpleDark,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusPill(
                        label: statusCfg.label,
                        fg: statusCfg.fg,
                        bg: statusCfg.bg,
                        dot: statusCfg.dot,
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.chevron_right_rounded, color: AppColors.textHint, size: 20),
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;
  final Color fg;
  final Color bg;
  final Color dot;

  const _StatusPill({
    required this.label,
    required this.fg,
    required this.bg,
    required this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(
              color: dot,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: fg,
                letterSpacing: 0.06,
              )),
        ],
      ),
    );
  }
}
