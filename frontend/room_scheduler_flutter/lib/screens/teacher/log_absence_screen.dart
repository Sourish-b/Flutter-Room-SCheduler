import 'package:flutter/material.dart';

import '../../theme.dart';
import '../../widgets/log_absence_form.dart';

class LogAbsenceScreen extends StatelessWidget {
  final bool isAdmin;
  final String? inferredTeacherId;

  const LogAbsenceScreen({
    super.key,
    required this.isAdmin,
    this.inferredTeacherId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Log Absence'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: LogAbsenceForm(
          isAdmin: isAdmin,
          inferredTeacherId: inferredTeacherId,
        ),
      ),
    );
  }
}
