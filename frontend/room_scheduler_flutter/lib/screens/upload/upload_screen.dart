import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:provider/provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:intl/intl.dart';
import '../../providers/room_provider.dart';
import '../../services/data_service.dart';
import '../../theme.dart';

class UploadScreen extends StatefulWidget {
  const UploadScreen({super.key});
  @override
  State<UploadScreen> createState() => _UploadScreenState();
}

class _UploadScreenState extends State<UploadScreen> {
  String? _uploadedFileName;
  bool _uploadLoading = false;
  String? _uploadResult;
  bool _uploadSuccess = false;

  final _dayCtrl = ValueNotifier<String>('Monday');
  final _startCtrl = ValueNotifier<String>('09:00');
  final _endCtrl = ValueNotifier<String>('10:00');
  final _roomCtrl = ValueNotifier<String>('203');
  final _subjectCtrl = TextEditingController();
  final _fcCtrl = TextEditingController();
  final _fnCtrl = TextEditingController();
  final _secCtrl = TextEditingController();
  bool _entryLoading = false;
  String? _entryResult;
  bool _entrySuccess = false;
  bool _resetLoading = false;
  String? _resetResult;
  bool _resetSuccess = false;

  final _session = ValueNotifier<String>('2025-26');

  final _days = ['Monday','Tuesday','Wednesday','Thursday','Friday'];
  final _times = ['09:00','10:00','11:00','12:00','13:00','14:00','15:00','16:00'];
  final _sessions = ['2025-26','2024-25','2023-24'];

  @override
  void dispose() {
    _subjectCtrl.dispose();
    _fcCtrl.dispose();
    _fnCtrl.dispose();
    _secCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _startCtrl.addListener(() {
      _endCtrl.value = _nextTime(_startCtrl.value);
    });
  }

  String _nextTime(String start) {
    final idx = _times.indexOf(start);
    if (idx == -1 || idx + 1 >= _times.length) return _times.last;
    return _times[idx + 1];
  }

  Future<void> _pickFile() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null) return;
    final file = result.files.first;
    final bytes = file.bytes;
    if (bytes == null) {
      setState(() {
        _uploadSuccess = false;
        _uploadResult = kIsWeb
            ? 'Unable to read file bytes in browser.'
            : 'Unable to read file. Please try again.';
      });
      return;
    }
    setState(() { _uploadLoading = true; _uploadResult = null; });
    final res = await DataService.uploadTimetablePdf(
      bytes: bytes,
      filename: file.name,
      session: _session.value,
    );
    setState(() {
      _uploadLoading = false;
      _uploadedFileName = file.name;
      _uploadSuccess = res.success;
      _uploadResult = res.message;
    });
    if (res.success) {
      context.read<RoomProvider>().loadRooms();
    }
  }

  Future<void> _addEntry() async {
    if (_subjectCtrl.text.trim().isEmpty) {
      setState(() { _entryResult = 'Please enter a subject name'; _entrySuccess = false; });
      return;
    }
    setState(() { _entryLoading = true; _entryResult = null; });
    final res = await DataService.addTimetableEntry(
      roomNumber: _roomCtrl.value,
      day: _dayCtrl.value,
      startTime: _startCtrl.value,
      endTime: _endCtrl.value,
      subject: _subjectCtrl.text.trim(),
      facultyCode: _fcCtrl.text.trim(),
      facultyName: _fnCtrl.text.trim(),
      section: _secCtrl.text.trim(),
    );
    if (mounted) {
      setState(() {
        _entryLoading = false;
        _entrySuccess = res.success;
        _entryResult = res.message;
      });
      if (res.success) {
        _subjectCtrl.clear(); _fcCtrl.clear(); _fnCtrl.clear(); _secCtrl.clear();
        context.read<RoomProvider>().loadRooms();
      }
    }
  }

  Future<void> _resetSchedule() async {
    setState(() {
      _resetLoading = true;
      _resetResult = null;
    });
    final res = await DataService.resetSchedule();
    if (mounted) {
      setState(() {
        _resetLoading = false;
        _resetSuccess = res.success;
        _resetResult = res.message;
      });
      if (res.success) {
        context.read<RoomProvider>().loadRooms();
      }
    }
  }

  Future<void> _confirmReset() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Reset schedule?'),
        content: const Text(
          'This will delete all timetable entries and bookings. This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Reset'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await _resetSchedule();
    }
  }

  @override
  Widget build(BuildContext context) {
    final rooms = DataService.getRoomsList();
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Upload Timetable'),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(child: Text('Admin',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted))),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section header
            const Text('Upload Timetable PDF',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                    color: AppColors.purpleDark, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            const Text('Upload the department PDF timetable to auto-populate room schedules.',
                style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
            const SizedBox(height: 16),

            // Dropzone
            GestureDetector(
              onTap: _pickFile,
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(
                      color: _uploadSuccess ? AppColors.green : AppColors.purpleMid,
                      width: 1.5,
                      style: BorderStyle.solid),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _uploadLoading
                    ? const Column(children: [
                        CircularProgressIndicator(color: AppColors.purple),
                        SizedBox(height: 12),
                        Text('Processing PDF...', style: TextStyle(color: AppColors.purple)),
                      ])
                    : Column(
                        children: [
                          Container(
                            width: 52, height: 52,
                            decoration: BoxDecoration(
                              color: _uploadSuccess ? AppColors.greenLight : AppColors.purpleLight,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              _uploadSuccess ? Icons.check_rounded : Icons.upload_file_rounded,
                              color: _uploadSuccess ? AppColors.green : AppColors.purple,
                              size: 26,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            _uploadSuccess
                                ? (_uploadedFileName ?? 'File uploaded')
                                : 'Drop timetable PDF here',
                            style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: _uploadSuccess ? AppColors.green : AppColors.purple),
                          ),
                          const SizedBox(height: 4),
                          const Text('or tap to browse',
                              style: TextStyle(fontSize: 12, color: AppColors.textMuted)),
                        ],
                      ),
              ),
            ),

            if (_uploadResult != null) ...[
              const SizedBox(height: 10),
              _Alert(message: _uploadResult!, success: _uploadSuccess),
            ],
            const SizedBox(height: 16),

            // Config card
            _SectionCard(children: [
              _DropdownRow(
                label: 'Academic Session',
                value: _session,
                items: _sessions,
              ),
              const Divider(height: 1, color: AppColors.border),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('CURRENTLY LOADED',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                            color: AppColors.textMuted, letterSpacing: 0.06)),
                    const SizedBox(height: 10),
                    ...[
                      '1st Year CSE-A', '1st Year CSE-B',
                      '1st Year ECE-A', '1st Year ECE-B',
                    ].map((s) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Container(width: 8, height: 8,
                              decoration: const BoxDecoration(
                                  color: Color(0xFF2ECC71), shape: BoxShape.circle)),
                          const SizedBox(width: 8),
                          Text(s, style: const TextStyle(fontSize: 13, color: Color(0xFF555555))),
                        ],
                      ),
                    )),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: _pickFile,
              icon: const Icon(Icons.upload_rounded, size: 18),
              label: const Text('Upload & Process PDF'),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              onPressed: _resetLoading ? null : _confirmReset,
              icon: _resetLoading
                  ? const SizedBox(
                      height: 16,
                      width: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.restart_alt_rounded, size: 18),
              label: const Text('Reset Schedule'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
                side: const BorderSide(color: AppColors.border),
                foregroundColor: AppColors.red,
              ),
            ),
            if (_resetResult != null) ...[
              const SizedBox(height: 8),
              _Alert(message: _resetResult!, success: _resetSuccess),
            ],
            const SizedBox(height: 24),

            // Manual entry
            const Text('MANUAL ENTRY',
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                    color: AppColors.textMuted, letterSpacing: 0.08)),
            const SizedBox(height: 8),
            _SectionCard(children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _DropdownField(
                            label: 'Day',
                            value: _dayCtrl,
                            items: _days,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ValueListenableBuilder<String>(
                            valueListenable: _roomCtrl,
                            builder: (_, val, __) => _DropdownField2(
                              label: 'Room',
                              value: val,
                              items: rooms.map((r) => r.roomNumber).toList(),
                              onChanged: (v) => _roomCtrl.value = v,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _DropdownField(label: 'Start', value: _startCtrl, items: _times.take(7).toList())),
                        const SizedBox(width: 10),
                        Expanded(child: _DropdownField(label: 'End', value: _endCtrl, items: _times.skip(1).toList())),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TextField(label: 'Subject', ctrl: _subjectCtrl, hint: 'e.g. Data Structures'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(child: _TextField(label: 'Faculty Code', ctrl: _fcCtrl, hint: 'AP')),
                        const SizedBox(width: 10),
                        Expanded(child: _TextField(label: 'Section', ctrl: _secCtrl, hint: 'CSE-A')),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _TextField(label: 'Faculty Name', ctrl: _fnCtrl, hint: 'Dr. Ashutosh Pandey'),
                    const SizedBox(height: 14),
                    if (_entryResult != null) ...[
                      _Alert(message: _entryResult!, success: _entrySuccess),
                      const SizedBox(height: 10),
                    ],
                    ElevatedButton(
                      onPressed: _entryLoading ? null : _addEntry,
                      child: _entryLoading
                          ? const SizedBox(height: 20, width: 20,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                          : const Text('Add to Timetable'),
                    ),
                  ],
                ),
              ),
            ]),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final List<Widget> children;
  const _SectionCard({required this.children});
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: AppColors.border),
    ),
    child: Column(children: children),
  );
}

class _Alert extends StatelessWidget {
  final String message;
  final bool success;
  const _Alert({required this.message, required this.success});
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
    decoration: BoxDecoration(
      color: success ? AppColors.greenLight : AppColors.redLight,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        Icon(success ? Icons.check_circle : Icons.error_outline,
            size: 16, color: success ? AppColors.green : AppColors.red),
        const SizedBox(width: 8),
        Expanded(child: Text(message,
            style: TextStyle(fontSize: 13, color: success ? AppColors.green : AppColors.red))),
      ],
    ),
  );
}

class _DropdownRow extends StatelessWidget {
  final String label;
  final ValueNotifier<String> value;
  final List<String> items;
  const _DropdownRow({required this.label, required this.value, required this.items});
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                color: AppColors.textMuted, letterSpacing: 0.06)),
        const SizedBox(height: 6),
        ValueListenableBuilder<String>(
          valueListenable: value,
          builder: (_, val, __) => DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: val,
              isExpanded: true,
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: (v) { if (v != null) value.value = v; },
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.purpleDark),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DropdownField extends StatelessWidget {
  final String label;
  final ValueNotifier<String> value;
  final List<String> items;
  final bool enabled;
  const _DropdownField({
    required this.label,
    required this.value,
    required this.items,
  });
  @override
  Widget build(BuildContext context) => ValueListenableBuilder<String>(
    valueListenable: value,
    builder: (_, val, __) => Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(),
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                color: AppColors.textMuted, letterSpacing: 0.06)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: items.contains(val) ? val : items.first,
          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
          items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
          onChanged: enabled ? (v) { if (v != null) value.value = v; } : null,
        ),
      ],
    ),
  );
}

class _DropdownField2 extends StatelessWidget {
  final String label;
  final String value;
  final List<String> items;
  final ValueChanged<String> onChanged;
  const _DropdownField2({required this.label, required this.value, required this.items, required this.onChanged});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 0.06)),
      const SizedBox(height: 4),
      DropdownButtonFormField<String>(
        initialValue: items.contains(value) ? value : items.first,
        decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10)),
        items: items.map((i) => DropdownMenuItem(value: i, child: Text(i, style: const TextStyle(fontSize: 13)))).toList(),
        onChanged: (v) { if (v != null) onChanged(v); },
      ),
    ],
  );
}

class _TextField extends StatelessWidget {
  final String label;
  final TextEditingController ctrl;
  final String hint;
  const _TextField({required this.label, required this.ctrl, required this.hint});
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(label.toUpperCase(),
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
              color: AppColors.textMuted, letterSpacing: 0.06)),
      const SizedBox(height: 4),
      TextFormField(
        controller: ctrl,
        decoration: InputDecoration(hintText: hint),
        style: const TextStyle(fontSize: 14),
      ),
    ],
  );
}
