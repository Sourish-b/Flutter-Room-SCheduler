import 'package:flutter/foundation.dart';
import '../models/teacher.dart';
import '../services/data_service.dart';

class AuthProvider extends ChangeNotifier {
  Teacher? _teacher;
  bool _isAdminLoggedIn = false;
  bool _isLoading = false;
  String? _error;

  Teacher? get teacher => _teacher;
  bool get isLoggedIn => _teacher != null;
  bool get isAdminLoggedIn => _isAdminLoggedIn;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<bool> login(String employeeId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    final result = await DataService.loginTeacher(employeeId);

    _isLoading = false;
    if (result != null) {
      _teacher = result;
      _isAdminLoggedIn = false;
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = 'Employee ID not found. Try your faculty code (e.g., UK) or IDs like AP001, UK002.';
      notifyListeners();
      return false;
    }
  }

  void loginAdmin() {
    _teacher = null;
    _isAdminLoggedIn = true;
    _error = null;
    notifyListeners();
  }

  void logout() {
    _teacher = null;
    _isAdminLoggedIn = false;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
