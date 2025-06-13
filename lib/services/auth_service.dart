import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userId = prefs.getString('userId');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    // TODO: Implement actual authentication logic
    // For now, we'll just simulate a successful login
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', true);
    await prefs.setString('userId', 'user_${DateTime.now().millisecondsSinceEpoch}');
    
    _isLoggedIn = true;
    _userId = prefs.getString('userId');
    notifyListeners();
    return true;
  }

  Future<bool> register(String email, String password) async {
    // TODO: Implement actual registration logic
    // For now, we'll just simulate a successful registration
    return await login(email, password);
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.remove('userId');
    
    _isLoggedIn = false;
    _userId = null;
    notifyListeners();
  }
} 