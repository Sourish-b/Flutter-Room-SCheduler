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
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.white,
              title: Row(
                children: [
                  Container(
                    width: 28, height: 28,
                    decoration: BoxDecoration(
                        color: AppColors.purple, borderRadius: BorderRadius.circular(8)),
                    child: const Icon(Icons.grid_view_rounded, color: Colors.white, size: 16),
                  ),
                  const SizedBox(width: 8),
                  const Text('RoomScheduler',
                      style: TextStyle(
                          fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.purpleDark)),
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
                    child: Center(
                      child: Text(dayName,
                          style: const TextStyle(fontSize: 13, color: AppColors.textMuted)),
                    ),
                  ),
              ],
              bottom: PreferredSize(
                preferredSize: const Size.fromHeight(1),
                child: Container(height: 1, color: AppColors.border),
              ),
            ),

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
                        Text(provider.selectedDay,
                            style: const TextStyle(fontSize: 13, color: Colors.white70)),
                        const SizedBox(height: 4),
                        Text(provider.slotLabel,
                            style: const TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.5)),
                        const SizedBox(height: 10),
                        Text('Live room status · ${provider.allRooms.length} rooms tracked',
                            style: const TextStyle(fontSize: 12, color: Colors.white60)),
                      ],
                    ),
                  ),

                  // Date/time controls
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
                            child: OutlinedButton(
                              onPressed: () => provider.useCurrentDateTime(),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.purple,
                                side: const BorderSide(color: AppColors.border),
                              ),
                              child: const Text('Now'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // Stats
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Row(
                      children: [
                        _StatCard(count: provider.freeCount, label: 'Free',
                            color: AppColors.green,
                            onTap: () => provider.setFilterStatus('free')),
                        const SizedBox(width: 10),
                        _StatCard(count: provider.busyCount, label: 'Busy',
                            color: AppColors.red,
                            onTap: () => provider.setFilterStatus('busy')),
                        const SizedBox(width: 10),
                        _StatCard(count: provider.soonCount, label: 'Soon',
                            color: AppColors.amber,
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
                            onTap: () => provider.setFilterStatus('all')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Free', active: provider.filterStatus == 'free',
                            onTap: () => provider.setFilterStatus('free')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Busy', active: provider.filterStatus == 'busy',
                            onTap: () => provider.setFilterStatus('busy')),
                        const SizedBox(width: 8),
                        _FilterChip(label: 'Soon', active: provider.filterStatus == 'soon',
                            onTap: () => provider.setFilterStatus('soon')),
                        ...provider.buildings.map((b) => Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: _FilterChip(
                              label: b,
                              active: provider.filterBuilding == b,
                              onTap: () => provider.setFilterBuilding(b)),
                        )),
                      ],
                    ),
                  ),

                  // Section title
                  const Padding(
                    padding: EdgeInsets.only(left: 20, bottom: 8),
                    child: Text('LIVE ROOM STATUS',
                        style: TextStyle(
                            fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.textMuted, letterSpacing: 0.08)),
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
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: Column(
                    children: [
                      // Table header
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFFF9F8FD),
                          borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                        ),
                        child: const Row(
                          children: [
                            SizedBox(width: 44, child: Text('ROOM',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.textHint, letterSpacing: 0.06))),
                            SizedBox(width: 4),
                            SizedBox(width: 70, child: Text('STATUS',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.textHint, letterSpacing: 0.06))),
                            SizedBox(width: 12),
                            Expanded(child: Text('CLASS INFO',
                                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                    color: AppColors.textHint, letterSpacing: 0.06))),
                          ],
                        ),
                      ),
                      ...provider.rooms.asMap().entries.map((e) {
                        return Column(
                          children: [
                            if (e.key > 0)
                              const Divider(height: 1, color: Color(0xFFF3F0FB)),
                            RoomCard(
                              roomStatus: e.value,
                              onTap: () => Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (_) => RoomDetailScreen(room: e.value.room),
                                )),
                            ),
                          ],
                        );
                      }),
                    ],
                  ),
                ),
              ),
            const SliverToBoxAdapter(child: SizedBox(height: 16)),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final int count;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _StatCard({required this.count, required this.label, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.border),
          ),
          child: Column(
            children: [
              Text('$count',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700, color: color)),
              const SizedBox(height: 4),
              Text(label, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
        const SizedBox(height: 6),
        Container(
          height: 40,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8FD),
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
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textMuted)),
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
              color: const Color(0xFFF9F8FD),
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
  final VoidCallback onTap;

  const _FilterChip({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
        decoration: BoxDecoration(
          color: active ? AppColors.purple : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: active ? AppColors.purple : AppColors.border),
        ),
        child: Text(label,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: active ? Colors.white : AppColors.textMuted)),
      ),
    );
  }
}
