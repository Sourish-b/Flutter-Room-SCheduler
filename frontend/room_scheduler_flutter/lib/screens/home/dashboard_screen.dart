import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/room_provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';
import '../../widgets/room_card.dart';
import '../../widgets/avatar_widget.dart';
import 'room_detail_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  static const List<String> _timeSlots = [
    '08:00',
    '09:00',
    '10:00',
    '11:00',
    '12:00',
    '13:00',
    '14:00',
    '15:00',
    '16:00',
    '17:00',
    '18:00',
  ];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<RoomProvider>().loadRooms();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<RoomProvider>();
    final auth = context.watch<AuthProvider>();
    final now = DateTime.now();
    final dayName = DateFormat('EEEE').format(now);

    return Scaffold(
      backgroundColor: AppColors.gray,
      body: RefreshIndicator(
        color: AppColors.purple,
        onRefresh: () => provider.loadRooms(),
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              floating: true,
              backgroundColor: AppColors.gray,
              surfaceTintColor: AppColors.gray,
              title: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4936C2), Color(0xFF6C5CE7)],
                      ),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('RoomScheduler',
                      style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.purpleDark,
                          letterSpacing: -0.2)),
                ],
              ),
              actions: [
                if (auth.isLoggedIn)
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: AvatarWidget(name: auth.teacher!.name, size: 32),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                      ),
                      child: Text(dayName,
                          style: const TextStyle(
                            fontSize: 12,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          )),
                    ),
                  ),
              ],
            ),

            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _HeroCard(
                    day: provider.selectedDay,
                    slotLabel: provider.slotLabel,
                    roomsTracked: provider.allRooms.length,
                  ),

                  // Date/time controls
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppColors.border),
                        boxShadow: _cardShadow(),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: _DatePickerField(
                              label: 'Date',
                              date: provider.selectedDate,
                              onPick: (picked) => provider.setSelectedDate(picked),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _LabeledDropdown(
                              label: 'Time',
                              value: provider.selectedTime,
                              items: _timeSlots,
                              onChanged: (value) {
                                if (value != null) {
                                  provider.setSelectedTime(value);
                                }
                              },
                            ),
                          ),
                          const SizedBox(width: 10),
                          SizedBox(
                            height: 40,
                            child: ElevatedButton(
                              onPressed: () => provider.useCurrentDateTime(),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(68, 40),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                backgroundColor: AppColors.purple,
                              ),
                              child: const Text('Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  if (provider.error != null) ...[
                    const SizedBox(height: 10),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: AppColors.redLight,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: const Color(0xFFF7C9C9)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.wifi_off_rounded, color: AppColors.red, size: 16),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                provider.error!,
                                style: const TextStyle(fontSize: 12, color: AppColors.red),
                              ),
                            ),
                            TextButton(
                              onPressed: () => provider.loadRooms(),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.red,
                                padding: const EdgeInsets.symmetric(horizontal: 8),
                                minimumSize: const Size(48, 32),
                              ),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],

                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _StatCard(count: provider.freeCount, label: 'Free',
                            color: AppColors.green,
                            icon: Icons.check_circle_outline_rounded,
                            active: provider.filterStatus == 'free',
                            onTap: () => provider.setFilterStatus('free')),
                        const SizedBox(width: 10),
                        _StatCard(count: provider.busyCount, label: 'Busy',
                            color: AppColors.red,
                            icon: Icons.block_rounded,
                            active: provider.filterStatus == 'busy',
                            onTap: () => provider.setFilterStatus('busy')),
                        const SizedBox(width: 10),
                        _StatCard(count: provider.soonCount, label: 'Soon',
                            color: AppColors.amber,
                            icon: Icons.schedule_rounded,
                            active: provider.filterStatus == 'soon',
                            onTap: () => provider.setFilterStatus('soon')),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Filter chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.only(left: 16, right: 16, bottom: 12),
                    child: Row(
                      children: [
                        _FilterChip(label: 'All', active: provider.filterStatus == 'all',
                            color: AppColors.purple,
                            onTap: () => provider.setFilterStatus('all')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Free', active: provider.filterStatus == 'free',
                            color: AppColors.green,
                            onTap: () => provider.setFilterStatus('free')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Busy', active: provider.filterStatus == 'busy',
                            color: AppColors.red,
                            onTap: () => provider.setFilterStatus('busy')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Soon', active: provider.filterStatus == 'soon',
                            color: AppColors.amber,
                            onTap: () => provider.setFilterStatus('soon')),
                        ...provider.buildings.map((b) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                              label: b,
                              active: provider.filterBuilding == b,
                              color: AppColors.purple,
                              onTap: () => provider.setFilterBuilding(b)),
                        )),
                      ],
                    ),
                  ),

                  const Padding(
                    padding: EdgeInsets.fromLTRB(20, 2, 20, 10),
                    child: _RoomListHeader(),
                  ),
                ],
              ),
            ),

            // Rooms list
            if (provider.isLoading)
              const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator(color: AppColors.purple)),
                ),
              )
            else if (provider.rooms.isEmpty)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No rooms match filter',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 14)),
                  ),
                ),
              )
            else
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    children: provider.rooms.map((room) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: AppColors.border),
                          boxShadow: _cardShadow(),
                        ),
                        child: RoomCard(
                          roomStatus: room,
                          onTap: () => Navigator.push(context,
                            MaterialPageRoute(
                              builder: (_) => RoomDetailScreen(room: room.room),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 22)),
          ],
        ),
      ),
    );
  }
}

class _HeroCard extends StatelessWidget {
  final String day;
  final String slotLabel;
  final int roomsTracked;

  const _HeroCard({
    required this.day,
    required this.slotLabel,
    required this.roomsTracked,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF3A2EA8), Color(0xFF6C5CE7), Color(0xFF8B7FF5)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppColors.purple.withOpacity(0.38),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            right: 20,
            bottom: -26,
            child: Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.06),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(day,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    )),
              ),
              const SizedBox(height: 8),
              Text(slotLabel,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.w800,
                      height: 1.02,
                      letterSpacing: -0.6)),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.circle, color: Color(0xFF9DFFBC), size: 8),
                  const SizedBox(width: 6),
                  Text('Live room status · $roomsTracked rooms tracked',
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.84),
                          fontSize: 12,
                          fontWeight: FontWeight.w500)),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RoomListHeader extends StatelessWidget {
  const _RoomListHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Text('LIVE ROOM STATUS',
            style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: AppColors.textMuted,
                letterSpacing: 0.1)),
        const Spacer(),
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Color(0xFF2ECC71),
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        const Text('Live',
            style: TextStyle(
              fontSize: 11,
              color: AppColors.green,
              fontWeight: FontWeight.w600,
            )),
      ],
    );
  }
}

List<BoxShadow> _cardShadow() => [
  BoxShadow(
      color: const Color(0xFF4936C2).withOpacity(0.05),
      blurRadius: 12,
      offset: const Offset(0, 4)),
  BoxShadow(
      color: Colors.black.withOpacity(0.03),
      blurRadius: 4,
      offset: const Offset(0, 1)),
];

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  const _StatCard({
    required this.count,
    required this.label,
    required this.color,
    required this.icon,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: _cardShadow(),
            border: Border(
              top: BorderSide(color: color, width: 3),
              left: BorderSide(color: active ? color.withOpacity(0.35) : AppColors.border),
              right: BorderSide(color: active ? color.withOpacity(0.35) : AppColors.border),
              bottom: BorderSide(color: active ? color.withOpacity(0.35) : AppColors.border),
            ),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(height: 8),
              Text('$count',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: color,
                      height: 1)),
              const SizedBox(height: 4),
              Text(label,
                  style: const TextStyle(
                      fontSize: 11,
                      color: AppColors.textMuted,
                      fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }
}

class _LabeledDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  const _LabeledDropdown({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.access_time_rounded, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F7FE),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: value,
              icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 18),
              items: items
                  .map((item) => DropdownMenuItem(
                        value: item,
                        child: Text(item,
                            style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textDark)),
                      ))
                  .toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }
}

class _DatePickerField extends StatelessWidget {
  final String label;
  final DateTime date;
  final ValueChanged<DateTime> onPick;

  const _DatePickerField({
    required this.label,
    required this.date,
    required this.onPick,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.textMuted),
            const SizedBox(width: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted)),
          ],
        ),
        const SizedBox(height: 6),
        GestureDetector(
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: date,
              firstDate: DateTime.now().subtract(const Duration(days: 7)),
              lastDate: DateTime.now().add(const Duration(days: 365)),
            );
            if (picked != null) {
              onPick(picked);
            }
          },
          child: Container(
            height: 40,
            padding: const EdgeInsets.symmetric(horizontal: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8F7FE),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            alignment: Alignment.centerLeft,
            child: Text(
              DateFormat('yyyy-MM-dd').format(date),
              style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark),
            ),
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool active;
  final Color color;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.active,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? color : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? color : AppColors.border),
          boxShadow: active
              ? [
                  BoxShadow(
                    color: color.withOpacity(0.30),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? Colors.white : AppColors.textMuted)),
      ),
    );
  }
}
