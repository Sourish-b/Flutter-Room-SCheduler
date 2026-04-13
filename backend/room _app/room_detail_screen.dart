import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../models/room_override.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';

class RoomDetailScreen extends StatefulWidget {
  final Room room;
  final String currentDay;
  final String currentTime;
  final AppUser? currentUser;

  const RoomDetailScreen({
    super.key,
    required this.room,
    required this.currentDay,
    required this.currentTime,
    this.currentUser,
  });

  @override
  State<RoomDetailScreen> createState() => _RoomDetailScreenState();
}

class _RoomDetailScreenState extends State<RoomDetailScreen> {
  late String _selectedDay;
  List<RoomOverride> _todayOverrides = [];

  final List<String> _days = [
    'Monday','Tuesday','Wednesday','Thursday','Friday','Saturday','Sunday'
  ];

  @override
  void initState() {
    super.initState();
    _selectedDay = widget.currentDay;
    _loadOverrides();
  }

  Future<void> _loadOverrides() async {
    final now = DateTime.now();
    final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final overrides = await StorageService().getOverridesForRoomOnDate(widget.room.id, date);
    if (mounted) setState(() => _todayOverrides = overrides);
  }

  bool get _canEdit =>
    widget.currentUser != null &&
    (widget.currentUser!.isAdmin || widget.currentUser!.isTeacher);

  Future<void> _showAddOverrideDialog() async {
    final startController = TextEditingController();
    final endController = TextEditingController();
    final reasonController = TextEditingController();
    String? selectedReason = 'Extra Class';
    final reasons = ['Extra Class', 'Event', 'Meeting', 'Exam', 'Workshop', 'Other'];

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setS) => AlertDialog(
          backgroundColor: AppTheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.add_circle_outline, color: AppTheme.primary),
              const SizedBox(width: 8),
              Text(
                'Room ${widget.room.name}',
                style: const TextStyle(color: AppTheme.textPrimary, fontSize: 16),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Reason', style: TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                const SizedBox(height: 6),
                // Reason chips
                Wrap(
                  spacing: 8, runSpacing: 8,
                  children: reasons.map((r) {
                    final isSelected = selectedReason == r;
                    return GestureDetector(
                      onTap: () => setS(() => selectedReason = r),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary.withOpacity(0.2) : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: isSelected ? AppTheme.primary : Colors.transparent),
                        ),
                        child: Text(
                          r,
                          style: TextStyle(
                            color: isSelected ? AppTheme.primary : AppTheme.textSecondary,
                            fontSize: 12,
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),
                // Custom reason
                TextField(
                  controller: reasonController,
                  style: const TextStyle(color: AppTheme.textPrimary, fontSize: 14),
                  decoration: const InputDecoration(
                    hintText: 'Ya custom reason likho...',
                    labelText: 'Custom Reason (optional)',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: startController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'Start (HH:MM)',
                          hintText: '14:00',
                        ),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                            builder: (c, child) => Theme(
                              data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primary)),
                              child: child!,
                            ),
                          );
                          if (t != null) {
                            startController.text = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextField(
                        controller: endController,
                        style: const TextStyle(color: AppTheme.textPrimary),
                        keyboardType: TextInputType.datetime,
                        decoration: const InputDecoration(
                          labelText: 'End (HH:MM)',
                          hintText: '16:00',
                        ),
                        onTap: () async {
                          final t = await showTimePicker(
                            context: ctx,
                            initialTime: TimeOfDay.now(),
                            builder: (c, child) => Theme(
                              data: ThemeData.dark().copyWith(colorScheme: const ColorScheme.dark(primary: AppTheme.primary)),
                              child: child!,
                            ),
                          );
                          if (t != null) {
                            endController.text = '${t.hour.toString().padLeft(2,'0')}:${t.minute.toString().padLeft(2,'0')}';
                          }
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: AppTheme.textSecondary)),
            ),
            ElevatedButton(
              onPressed: () async {
                final finalReason = reasonController.text.trim().isNotEmpty
                  ? reasonController.text.trim()
                  : (selectedReason ?? 'Extra Class');
                final start = startController.text.trim();
                final end = endController.text.trim();

                if (start.isEmpty || end.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Time dalna zaroori hai!'), backgroundColor: AppTheme.occupied),
                  );
                  return;
                }
                if (start.compareTo(end) >= 0) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('End time > Start time hona chahiye!'), backgroundColor: AppTheme.occupied),
                  );
                  return;
                }

                final now = DateTime.now();
                final date = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

                final override = RoomOverride(
                  id: '${DateTime.now().millisecondsSinceEpoch}',
                  roomId: widget.room.id,
                  roomName: widget.room.name,
                  date: date,
                  startTime: start,
                  endTime: end,
                  reason: finalReason,
                  addedBy: widget.currentUser!.name,
                  addedByRole: widget.currentUser!.roleLabel,
                );

                await StorageService().addOverride(override);
                if (ctx.mounted) Navigator.pop(ctx);
                await _loadOverrides();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Room $start–$end ke liye occupied mark ho gaya!'),
                      backgroundColor: AppTheme.available,
                    ),
                  );
                }
              },
              child: const Text('Mark Occupied'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _deleteOverride(String id) async {
    await StorageService().deleteOverride(id);
    await _loadOverrides();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Override hata diya gaya'), backgroundColor: AppTheme.available),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isFree = widget.room.isFreeAt(widget.currentDay, widget.currentTime);
    // Check active override
    final now = DateTime.now();
    final todayDate = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';
    final activeOverride = _todayOverrides.where((o) => o.isActiveAt(todayDate, widget.currentTime)).toList();
    final hasActiveOverride = activeOverride.isNotEmpty;

    // Final status: occupied if timetable says so OR override active
    final isActuallyFree = isFree && !hasActiveOverride;
    final statusColor = isActuallyFree ? AppTheme.available : AppTheme.occupied;

    final schedule = widget.room.schedule[_selectedDay];

    return Scaffold(
      backgroundColor: AppTheme.background,
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            // Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 8, 24, 0),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimary),
                    ),
                    Expanded(
                      child: Text(
                        widget.room.name,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700, color: AppTheme.textPrimary),
                      ),
                    ),
                    // Status badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        isActuallyFree ? '● Free Now' : '● Busy',
                        style: TextStyle(color: statusColor, fontWeight: FontWeight.w600, fontSize: 13),
                      ),
                    ),
                    // Add override button
                    if (_canEdit) ...[
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: _showAddOverrideDialog,
                        child: Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppTheme.warning.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.add_circle_outline, color: AppTheme.warning, size: 22),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),

            // Room info badges
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(color: AppTheme.surface, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _InfoBadge(icon: Icons.business_outlined, label: 'Building', value: widget.room.building),
                          _InfoBadge(icon: Icons.layers_outlined, label: 'Floor', value: '${widget.room.floor}'),
                          _InfoBadge(icon: Icons.people_outline, label: 'Capacity', value: '${widget.room.capacity}'),
                          _InfoBadge(icon: Icons.category_outlined, label: 'Type', value: widget.room.type),
                        ],
                      ),
                    ),

                    // ── TODAY'S OVERRIDES ──────────────────────────────
                    if (_todayOverrides.isNotEmpty) ...[
                      const SizedBox(height: 20),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.warning.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppTheme.warning.withOpacity(0.3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: const [
                                Icon(Icons.warning_amber_rounded, color: AppTheme.warning, size: 18),
                                SizedBox(width: 8),
                                Text(
                                  'Aaj ke Extra Events',
                                  style: TextStyle(
                                    color: AppTheme.warning,
                                    fontWeight: FontWeight.w600,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            ..._todayOverrides.map((o) {
                              final isActive = o.isActiveAt(todayDate, widget.currentTime);
                              return Container(
                                margin: const EdgeInsets.only(bottom: 8),
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: isActive
                                    ? AppTheme.occupied.withOpacity(0.1)
                                    : AppTheme.surfaceLight,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: isActive ? AppTheme.occupied.withOpacity(0.3) : Colors.transparent,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Row(
                                            children: [
                                              Text(
                                                '${o.startTime} – ${o.endTime}',
                                                style: TextStyle(
                                                  color: isActive ? AppTheme.occupied : AppTheme.primary,
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 13,
                                                ),
                                              ),
                                              if (isActive) ...[
                                                const SizedBox(width: 6),
                                                Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                                  decoration: BoxDecoration(
                                                    color: AppTheme.occupied.withOpacity(0.2),
                                                    borderRadius: BorderRadius.circular(6),
                                                  ),
                                                  child: const Text('Now', style: TextStyle(color: AppTheme.occupied, fontSize: 10, fontWeight: FontWeight.w600)),
                                                ),
                                              ],
                                            ],
                                          ),
                                          const SizedBox(height: 3),
                                          Text(o.reason, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13)),
                                          Text(
                                            'Added by ${o.addedBy} (${o.addedByRole})',
                                            style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (_canEdit)
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppTheme.occupied, size: 20),
                                        onPressed: () => _deleteOverride(o.id),
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                      ),
                                  ],
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),
                    const Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Weekly Schedule',
                        style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600, color: AppTheme.textPrimary),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            ),

            // Day tabs
            SliverToBoxAdapter(
              child: SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  itemCount: _days.length,
                  itemBuilder: (context, i) {
                    final day = _days[i];
                    final isSelected = day == _selectedDay;
                    final isToday = day == widget.currentDay;
                    return GestureDetector(
                      onTap: () => setState(() => _selectedDay = day),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.only(right: 8),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primary : AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        alignment: Alignment.center,
                        child: Row(
                          children: [
                            if (isToday) Container(
                              width: 6, height: 6,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isSelected ? Colors.white : AppTheme.accent,
                              ),
                            ),
                            Text(
                              day.substring(0, 3),
                              style: TextStyle(
                                color: isSelected ? Colors.white : AppTheme.textSecondary,
                                fontSize: 13,
                                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Schedule slots
            if (schedule == null || schedule.slots.isEmpty)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.event_available_rounded, size: 48, color: AppTheme.available.withOpacity(0.5)),
                        const SizedBox(height: 12),
                        Text('No classes on $_selectedDay', style: const TextStyle(color: AppTheme.textSecondary, fontSize: 15)),
                        const Text('Room is free all day', style: TextStyle(color: AppTheme.available, fontSize: 13)),
                      ],
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, i) {
                      final slot = schedule.slots[i];
                      final isActive = slot.isActiveAt(widget.currentTime) && _selectedDay == widget.currentDay;
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: isActive ? AppTheme.occupied.withOpacity(0.1) : AppTheme.surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: isActive ? AppTheme.occupied.withOpacity(0.3) : Colors.transparent),
                        ),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 80,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(slot.startTime, style: TextStyle(color: isActive ? AppTheme.occupied : AppTheme.primary, fontWeight: FontWeight.w600, fontSize: 14)),
                                  Container(width: 1, height: 12, margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 2), color: AppTheme.textSecondary.withOpacity(0.3)),
                                  Text(slot.endTime, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 13)),
                                ],
                              ),
                            ),
                            Container(width: 1, height: 40, color: AppTheme.surfaceLight, margin: const EdgeInsets.symmetric(horizontal: 14)),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(slot.subject, style: const TextStyle(color: AppTheme.textPrimary, fontWeight: FontWeight.w500, fontSize: 14)),
                                  if (slot.teacher.isNotEmpty) ...[
                                    const SizedBox(height: 3),
                                    Text(slot.teacher, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 12)),
                                  ],
                                ],
                              ),
                            ),
                            if (isActive)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(color: AppTheme.occupied.withOpacity(0.2), borderRadius: BorderRadius.circular(8)),
                                child: const Text('Now', style: TextStyle(color: AppTheme.occupied, fontSize: 11, fontWeight: FontWeight.w600)),
                              ),
                          ],
                        ),
                      );
                    },
                    childCount: schedule.slots.length,
                  ),
                ),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),
          ],
        ),
      ),
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoBadge({required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primary, size: 20),
        const SizedBox(height: 6),
        Text(value, style: const TextStyle(color: AppTheme.textPrimary, fontSize: 13, fontWeight: FontWeight.w600)),
        Text(label, style: const TextStyle(color: AppTheme.textSecondary, fontSize: 11)),
      ],
    );
  }
}
