import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../services/auth_service.dart';
import '../services/firestore_service.dart';

class AppProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final FirestoreService _firestoreService = FirestoreService();

  UserModel? _currentUser;
  bool _isLoading = false;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isAdmin => _currentUser?.role == 'admin';
  bool get isDonor => _currentUser?.role == 'donor';

  void setLoading(bool v) { _isLoading = v; notifyListeners(); }
  void setError(String? e) { _error = e; notifyListeners(); }

  Future<void> loadCurrentUser() async {
    try {
      _currentUser = await _authService.getCurrentUserData();
      notifyListeners();
    } catch (e) {
      setError(e.toString());
    }
  }

  Future<bool> loginDonor(String email, String password) async {
    setLoading(true); setError(null);
    try {
      _currentUser = await _authService.login(email, password);
      notifyListeners();
      return true;
    } catch (e) {
      setError(_parseFirebaseError(e.toString()));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> loginAdmin(String email, String password) async {
    setLoading(true); setError(null);
    try {
      _currentUser = await _authService.loginAdmin(email, password);
      notifyListeners();
      return true;
    } catch (e) {
      setError(_parseFirebaseError(e.toString()));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<bool> registerDonor({
    required String email, required String password, required String name,
    required String phone, required String bloodType,
    required int age, required String gender,
  }) async {
    setLoading(true); setError(null);
    try {
      _currentUser = await _authService.registerDonor(
        email: email, password: password, name: name,
        phone: phone, bloodType: bloodType, age: age, gender: gender,
      );
      notifyListeners();
      return true;
    } catch (e) {
      setError(_parseFirebaseError(e.toString()));
      return false;
    } finally {
      setLoading(false);
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> updateProfile(Map<String, dynamic> data) async {
    if (_currentUser == null) return;
    setLoading(true);
    try {
      await _authService.updateProfile(_currentUser!.uid, data);
      await loadCurrentUser();
    } finally {
      setLoading(false);
    }
  }

  Future<bool> createBloodRequest(BloodRequestModel request) async {
    setLoading(true);
    try {
      await _firestoreService.createBloodRequest(request);
      return true;
    } catch (e) {
      setError(e.toString());
      return false;
    } finally {
      setLoading(false);
    }
  }

  String _parseFirebaseError(String error) {
    if (error.contains('user-not-found') || error.contains('wrong-password')) {
      return 'Invalid email or password.';
    } else if (error.contains('email-already-in-use')) {
      return 'This email is already registered.';
    } else if (error.contains('weak-password')) {
      return 'Password must be at least 6 characters.';
    } else if (error.contains('network-request-failed')) {
      return 'Network error. Check your internet connection.';
    } else if (error.contains('Access denied')) {
      return 'Admin access required.';
    }
    return 'Something went wrong. Please try again.';
  }
}
