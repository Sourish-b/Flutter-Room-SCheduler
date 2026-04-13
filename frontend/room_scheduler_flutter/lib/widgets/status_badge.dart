import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme.dart';

class StatusBadge extends StatelessWidget {
  final RoomStatus status;
  final bool large;

  const StatusBadge({super.key, required this.status, this.large = false});

  @override
  Widget build(BuildContext context) {
    final cfg = switch (status) {
      RoomStatus.free  => (label: 'FREE',  bg: AppColors.greenLight, color: AppColors.green,  dot: const Color(0xFF2ECC71)),
      RoomStatus.busy  => (label: 'BUSY',  bg: AppColors.redLight,   color: AppColors.red,    dot: const Color(0xFFE74C3C)),
      RoomStatus.soon  => (label: 'SOON',  bg: AppColors.amberLight, color: AppColors.amber,  dot: const Color(0xFFF39C12)),
    };
    final fs = large ? 12.0 : 10.0;
    final dotSize = large ? 8.0 : 6.0;
    return Container(
      padding: EdgeInsets.symmetric(horizontal: large ? 12 : 10, vertical: large ? 5 : 3),
      decoration: BoxDecoration(
        color: cfg.bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize, height: dotSize,
            decoration: BoxDecoration(color: cfg.dot, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(cfg.label,
              style: TextStyle(
                  fontSize: fs,
                  fontWeight: FontWeight.w700,
                  color: cfg.color,
                  letterSpacing: 0.06)),
        ],
      ),
    );
  }
}
