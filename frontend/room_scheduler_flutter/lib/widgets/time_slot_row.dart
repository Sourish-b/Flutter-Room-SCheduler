import 'package:flutter/material.dart';
import '../models/room.dart';
import '../theme.dart';
import 'package:google_fonts/google_fonts.dart';

class TimeSlotRow extends StatelessWidget {
  final ScheduleSlot slot;
  final bool isCurrent;

  const TimeSlotRow({super.key, required this.slot, this.isCurrent = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: isCurrent ? AppColors.purpleLight.withOpacity(0.5) : Colors.transparent,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Text(slot.time,
                  style: GoogleFonts.dmMono(
                      fontSize: 11,
                      color: isCurrent ? AppColors.purple : AppColors.textMuted,
                      fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400)),
              Container(
                  width: 1, height: 20, color: AppColors.border, margin: const EdgeInsets.symmetric(vertical: 4)),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: slot.entry != null && slot.entry!.isOccupied
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(slot.entry!.subject!,
                          style: const TextStyle(
                              fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.purpleDark)),
                      const SizedBox(height: 3),
                      Text(
                        [slot.entry!.year, slot.entry!.branch, slot.entry!.section, slot.entry!.facultyName]
                            .where((s) => s != null && s.isNotEmpty)
                            .join(' · '),
                        style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      ),
                    ],
                  )
                : Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                        color: AppColors.greenLight, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Room Available',
                        style: TextStyle(
                            fontSize: 13, color: AppColors.green, fontWeight: FontWeight.w500)),
                  ),
          ),
          if (isCurrent)
            Container(
              width: 8,
              height: 8,
              margin: const EdgeInsets.only(left: 8, top: 4),
              decoration: const BoxDecoration(color: AppColors.purple, shape: BoxShape.circle),
            ),
        ],
      ),
    );
  }
}
