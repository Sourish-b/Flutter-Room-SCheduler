import 'package:flutter/material.dart';
import '../models/room.dart';
import '../models/user.dart';
import '../services/storage_service.dart';
import '../theme/app_theme.dart';
import '../widgets/room_card.dart';

class RoomListScreen extends StatefulWidget {
  final AppUser user;
  const RoomListScreen({super.key, required this.user});

  @override
  State<RoomListScreen> createState() => _RoomListScreenState();
}

class _RoomListScreenState extends State<RoomListScreen> {
  List<Room> _rooms = [];
  List<Room> _filtered = [];
  String _search = '';
  String _filterStatus = 'All'; // All, Free, Occupied
  String _filterBuilding = 'All';
  bool _loading = true;
  late String _currentDay;
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    final now = DateTime.now();
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    _currentDay = days[now.weekday - 1];
    _currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    _load();
  }

  Future<void> _load() async {
    final rooms = await StorageService().getRooms();
    if (mounted) {
      setState(() {
        _rooms = rooms;
        _filtered = rooms;
        _loading = false;
      });
      _applyFilters();
    }
  }

  void _applyFilters() {
    setState(() {
      _filtered = _rooms.where((r) {
        final matchSearch = _search.isEmpty ||
            r.name.toLowerCase().contains(_search.toLowerCase()) ||
            r.building.toLowerCase().contains(_search.toLowerCase());
        final isFree = r.isFreeAt(_currentDay, _currentTime);
        final matchStatus = _filterStatus == 'All' ||
            (_filterStatus == 'Free' && isFree) ||
            (_filterStatus == 'Occupied' && !isFree);
        final matchBuilding = _filterBuilding == 'All' || r.building == _filterBuilding;
        return matchSearch && matchStatus && matchBuilding;
      }).toList();
    });
  }

  List<String> get buildings {
    final b = _rooms.map((r) => r.building).toSet().toList()..sort();
    return ['All', ...b];
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'All Rooms',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // Search
                TextField(
                  onChanged: (v) { _search = v; _applyFilters(); },
                  style: const TextStyle(color: AppTheme.textPrimary),
                  decoration: const InputDecoration(
                    hintText: 'Search rooms...',
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.textSecondary),
                  ),
                ),
                const SizedBox(height: 12),
                // Status filter
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ..._buildChips(['All', 'Free', 'Occupied'], _filterStatus, (v) {
                        _filterStatus = v; _applyFilters();
                      }),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (_loading)
            const Expanded(child: Center(child: CircularProgressIndicator(color: AppTheme.primary)))
          else if (_filtered.isEmpty)
            const Expanded(
              child: Center(
                child: Text('No rooms found', style: TextStyle(color: AppTheme.textSecondary)),
              ),
            )
          else
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) => RoomCard(
                  room: _filtered[i],
                  currentDay: _currentDay,
                  currentTime: _currentTime,
                  showDetails: true,
                ),
              ),
            ),
        ],
      ),
    );
  }

  List<Widget> _buildChips(List<String> options, String selected, void Function(String) onSelect) {
    return options.map((opt) {
      final isSelected = opt == selected;
      Color color = AppTheme.textSecondary;
      if (opt == 'Free') color = AppTheme.available;
      if (opt == 'Occupied') color = AppTheme.occupied;
      if (opt == 'All' && isSelected) color = AppTheme.primary;

      return Padding(
        padding: const EdgeInsets.only(right: 8),
        child: GestureDetector(
          onTap: () => onSelect(opt),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: isSelected ? color.withOpacity(0.15) : AppTheme.surfaceLight,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Colors.transparent,
              ),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected ? color : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ),
        ),
      );
    }).toList();
  }
}
