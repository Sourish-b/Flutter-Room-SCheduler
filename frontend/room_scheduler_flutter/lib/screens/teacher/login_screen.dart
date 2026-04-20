import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../theme.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _employeeIdCtrl = TextEditingController();
  String? _localError;

  @override
  void dispose() {
    _employeeIdCtrl.dispose();
    super.dispose();
  }

  bool _isAdminId(String employeeId) {
    const adminIds = {'ADMIN', 'AD001'};
    return adminIds.contains(employeeId.toUpperCase());
  }

  Future<void> _doLogin() async {
    FocusScope.of(context).unfocus();
    final employeeId = _employeeIdCtrl.text.trim().toUpperCase();

    setState(() => _localError = null);

    if (employeeId.isEmpty) {
      setState(() => _localError = 'Please enter Employee ID.');
      return;
    }

    if (_isAdminId(employeeId)) {
      context.read<AuthProvider>().loginAdmin();
      return;
    }

    final ok = await context.read<AuthProvider>().login(employeeId);
    if (!ok && mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Teacher / Admin Login'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            const Text(
              'Room Scheduler Login',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                color: AppColors.purpleDark,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter Employee ID to continue',
              style: TextStyle(fontSize: 14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _employeeIdCtrl,
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Employee ID',
                hintText: 'e.g. AP001 or ADMIN',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
              onSubmitted: (_) => _doLogin(),
            ),
            const SizedBox(height: 12),
            if (_localError != null)
              Text(_localError!, style: const TextStyle(color: AppColors.red)),
            if (auth.error != null)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Text(auth.error!, style: const TextStyle(color: AppColors.red)),
              ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.isLoading ? null : _doLogin,
                child: auth.isLoading
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Sign In'),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Admin IDs: ADMIN, AD001',
              style: TextStyle(fontSize: 12, color: AppColors.textHint),
            ),
          ],
        ),
      ),
    );
  }
}