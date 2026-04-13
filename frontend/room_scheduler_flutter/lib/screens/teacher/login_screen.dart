import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/teacher.dart';
import '../../services/data_service.dart';
import '../../theme.dart';
import '../../widgets/avatar_widget.dart';
import 'portal_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _idCtrl = TextEditingController(text: 'AP001');
  List<Teacher> _teachers = [];

  @override
  void initState() {
    super.initState();
    DataService.getTeachers().then((t) => setState(() => _teachers = t));
  }

  @override
  void dispose() { _idCtrl.dispose(); super.dispose(); }

  Future<void> _doLogin(String employeeId) async {
    final ok = await context.read<AuthProvider>().login(employeeId);
    if (ok && mounted) {
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PortalScreen()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: AppColors.gray,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        title: const Text('Teacher Portal'),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Hero
            Container(
              padding: const EdgeInsets.fromLTRB(24, 48, 24, 32),
              child: Column(
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: const BoxDecoration(
                        color: AppColors.purpleLight, shape: BoxShape.circle),
                    child: const Icon(Icons.school_rounded, color: AppColors.purple, size: 36),
                  ),
                  const SizedBox(height: 20),
                  const Text('Welcome Back',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                          color: AppColors.purpleDark, letterSpacing: -0.5)),
                  const SizedBox(height: 4),
                  const Text('Sign in to manage room bookings',
                      style: TextStyle(fontSize: 14, color: AppColors.textMuted)),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('EMPLOYEE ID',
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: AppColors.textMuted, letterSpacing: 0.06)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _idCtrl,
                    decoration: const InputDecoration(hintText: 'e.g. AP001'),
                    textCapitalization: TextCapitalization.characters,
                    onSubmitted: (_) => _doLogin(_idCtrl.text),
                  ),
                  const SizedBox(height: 12),

                  if (auth.error != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                      margin: const EdgeInsets.only(bottom: 12),
                      decoration: BoxDecoration(
                          color: AppColors.redLight, borderRadius: BorderRadius.circular(8)),
                      child: Row(children: [
                        const Icon(Icons.error_outline, size: 16, color: AppColors.red),
                        const SizedBox(width: 8),
                        Expanded(child: Text(auth.error!,
                            style: const TextStyle(fontSize: 13, color: AppColors.red))),
                      ]),
                    ),

                  ElevatedButton(
                    onPressed: auth.isLoading ? null : () => _doLogin(_idCtrl.text),
                    child: auth.isLoading
                        ? const SizedBox(height: 20, width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Sign In'),
                  ),
                  const SizedBox(height: 20),

                  // Quick select
                  const Center(
                    child: Text('OR QUICK SELECT',
                        style: TextStyle(fontSize: 12, color: AppColors.textHint,
                            letterSpacing: 0.06)),
                  ),
                  const SizedBox(height: 12),

                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: _teachers.isEmpty
                        ? const Padding(
                            padding: EdgeInsets.all(20),
                            child: Center(child: CircularProgressIndicator(color: AppColors.purple)))
                        : Column(
                            children: _teachers.asMap().entries.map((e) {
                              final t = e.value;
                              return Column(
                                children: [
                                  if (e.key > 0) const Divider(height: 1, color: Color(0xFFF5F3FB)),
                                  InkWell(
                                    onTap: () => _doLogin(t.employeeId),
                                    borderRadius: BorderRadius.circular(12),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          AvatarWidget(name: t.name, size: 38),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text('${t.name} (${t.facultyCode})',
                                                    style: const TextStyle(
                                                        fontSize: 13, fontWeight: FontWeight.w500,
                                                        color: AppColors.purpleDark)),
                                                Text('${t.department} · ${t.employeeId}',
                                                    style: const TextStyle(
                                                        fontSize: 11, color: AppColors.textMuted)),
                                              ],
                                            ),
                                          ),
                                          const Icon(Icons.chevron_right, color: AppColors.textHint, size: 18),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
