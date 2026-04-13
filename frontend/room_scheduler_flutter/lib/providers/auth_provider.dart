import 'package:flutter/foundation.dart';
import '../models/teacher.dart';
import '../services/data_service.dart';

class AuthProvider extends ChangeNotifier {
  Teacher? _teacher;
  bool _isLoading = false;
  String? _error;

  Teacher? get teacher => _teacher;
  bool get isLoggedIn => _teacher != null;
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
      _error = null;
      notifyListeners();
      return true;
    } else {
      _error = 'Employee ID not found. Try AP001, UK002, VJ003...';
      notifyListeners();
      return false;
    }
  }

  void logout() {
    _teacher = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
