import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../models/teacher.dart';
import '../providers/room_provider.dart';
import '../services/data_service.dart';
import '../theme.dart';

class LogAbsenceForm extends StatefulWidget {
  final bool isAdmin;
  final String? inferredTeacherId;

  const LogAbsenceForm({
    super.key,
    required this.isAdmin,
    this.inferredTeacherId,
  });

  @override
  State<LogAbsenceForm> createState() => _LogAbsenceFormState();
}

class _LogAbsenceFormState extends State<LogAbsenceForm> {
  final _teacherIdCtrl = TextEditingController();
  DateTime _startDate = DateTime.now();
  DateTime _endDate = DateTime.now();
  TimeOfDay? _endTime;
  bool _loading = false;
  bool _success = false;
  String? _result;
  List<Teacher> _teachers = const [];
  String? _selectedTeacherId;

  @override
  void initState() {
    super.initState();
    if (!widget.isAdmin && widget.inferredTeacherId != null) {
      _teacherIdCtrl.text = widget.inferredTeacherId!;
    }
    if (widget.isAdmin) {
      _loadTeachers();
    }
  }

  @override
  void dispose() {
    _teacherIdCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadTeachers() async {
    try {
      final teachers = await DataService.getTeachers();
      if (!mounted) return;
      setState(() {
        _teachers = teachers;
        if (_teachers.isNotEmpty) {
          _selectedTeacherId = _teachers.first.employeeId;
        }
      });
    } catch (_) {
      // Keep manual teacher ID input as fallback.
    }
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? _startDate : _endDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 730)),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      } else {
        _endDate = picked;
      }
    });
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime ?? const TimeOfDay(hour: 23, minute: 59),
    );
    if (picked == null) return;
    setState(() => _endTime = picked);
  }

  String _formatDate(DateTime value) => DateFormat('yyyy-MM-dd').format(value);

  String? get _effectiveTeacherId {
    if (!widget.isAdmin) {
      return widget.inferredTeacherId;
    }
    final manual = _teacherIdCtrl.text.trim();
    if (manual.isNotEmpty) return manual;
    return _selectedTeacherId;
  }

  String? _formatEndTime() {
    if (_endTime == null) return null;
    final hh = _endTime!.hour.toString().padLeft(2, '0');
    final mm = _endTime!.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }

  Future<void> _submit() async {
    final teacherId = _effectiveTeacherId;
    if (teacherId == null || teacherId.isEmpty) {
      setState(() {
        _success = false;
        _result = 'Teacher ID is required.';
      });
      return;
    }
    if (_endDate.isBefore(_startDate)) {
      setState(() {
        _success = false;
        _result = 'End date cannot be before start date.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _result = null;
    });

    try {
      final res = await DataService.logTeacherAbsence(
        teacherId: teacherId,
        startDate: _formatDate(_startDate),
        endDate: _formatDate(_endDate),
        endTime: _formatEndTime(),
      );
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = res.success;
        _result = '${res.message}. Affected slots: ${res.affectedCount}';
      });
      if (res.success) {
        await context.read<RoomProvider>().loadRooms();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _success = false;
        _result = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final endTimeLabel = _endTime == null
        ? '23:59 (default end of day)'
        : '${_endTime!.hour.toString().padLeft(2, '0')}:${_endTime!.minute.toString().padLeft(2, '0')}';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'LOG ABSENCE',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: AppColors.textMuted,
              letterSpacing: 0.08,
            ),
          ),
          const SizedBox(height: 10),
          if (widget.isAdmin) ...[
            if (_teachers.isNotEmpty) ...[
              DropdownButtonFormField<String>(
                initialValue: _selectedTeacherId,
                decoration: const InputDecoration(
                  labelText: 'Select Teacher',
                ),
                isExpanded: true,
                menuMaxHeight: 320,
                items: _teachers
                    .map((t) => DropdownMenuItem(
                          value: t.employeeId,
                          child: Text('${t.name} (${t.employeeId})'),
                        ))
                    .toList(),
                onChanged: (value) => setState(() => _selectedTeacherId = value),
              ),
              const SizedBox(height: 10),
            ],
            TextFormField(
              controller: _teacherIdCtrl,
              decoration: const InputDecoration(
                labelText: 'Teacher ID (optional override)',
                hintText: 'e.g. AP001 or AP',
              ),
            ),
            const SizedBox(height: 10),
          ] else ...[
            TextFormField(
              initialValue: widget.inferredTeacherId ?? '',
              readOnly: true,
              decoration: const InputDecoration(
                labelText: 'Teacher ID',
              ),
            ),
            const SizedBox(height: 10),
          ],
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(start: true),
                  icon: const Icon(Icons.date_range_rounded, size: 18),
                  label: Text('Start: ${_formatDate(_startDate)}'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pickDate(start: false),
                  icon: const Icon(Icons.event_rounded, size: 18),
                  label: Text('End: ${_formatDate(_endDate)}'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: _pickEndTime,
            icon: const Icon(Icons.access_time_rounded, size: 18),
            label: Text('End time: $endTimeLabel'),
          ),
          if (_result != null) ...[
            const SizedBox(height: 10),
            _AbsenceAlert(message: _result!, success: _success),
          ],
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: _loading ? null : _submit,
            icon: _loading
                ? const SizedBox(
                    height: 16,
                    width: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.event_busy_rounded, size: 18),
            label: const Text('Submit Absence'),
          ),
        ],
      ),
    );
  }
}

class _AbsenceAlert extends StatelessWidget {
  final String message;
  final bool success;

  const _AbsenceAlert({required this.message, required this.success});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: success ? AppColors.greenLight : AppColors.redLight,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            success ? Icons.check_circle_outline : Icons.error_outline,
            size: 16,
            color: success ? AppColors.green : AppColors.red,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 13,
                color: success ? AppColors.green : AppColors.red,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
