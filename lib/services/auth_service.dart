import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _email;
  bool _isEmailVerified = false;
  String? _verificationCode;
  DateTime? _verificationCodeExpiry;
  final EmailService _emailService;

  AuthService({
    required EmailService emailService,
  }) : _emailService = emailService;

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get email => _email;
  bool get isEmailVerified => _isEmailVerified;

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _isEmailVerified = prefs.getBool('isEmailVerified') ?? false;
    notifyListeners();
  }

  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    final hash = sha256.convert(bytes);
    return hash.toString();
  }

  String _generateVerificationCode() {
    return const Uuid().v4().substring(0, 6).toUpperCase();
  }

  Future<bool> register(String email, String password) async {
    try {
      // Generate verification code
      _verificationCode = _generateVerificationCode();
      _verificationCodeExpiry = DateTime.now().add(const Duration(hours: 24));

      // Send verification email
      final emailSent = await _emailService.sendVerificationEmail(
        email,
        _verificationCode!,
      );

      if (!emailSent) {
        return false;
      }

      // Store user data
      final prefs = await SharedPreferences.getInstance();
      final userId = const Uuid().v4();
      final hashedPassword = _hashPassword(password);

      await prefs.setString('userId', userId);
      await prefs.setString('email', email);
      await prefs.setString('password', hashedPassword);
      await prefs.setBool('isEmailVerified', false);
      await prefs.setString('verificationCode', _verificationCode!);
      await prefs.setString('verificationCodeExpiry', _verificationCodeExpiry!.toIso8601String());

      _userId = userId;
      _email = email;
      _isEmailVerified = false;
      notifyListeners();

      return true;
    } catch (e) {
      print('Registration error: $e');
      return false;
    }
  }

  Future<bool> verifyEmail(String code) async {
    if (code != _verificationCode) {
      return false;
    }

    if (_verificationCodeExpiry == null || 
        DateTime.now().isAfter(_verificationCodeExpiry!)) {
      return false;
    }

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isEmailVerified', true);
      _isEmailVerified = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Email verification error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedEmail = prefs.getString('email');
      final storedPassword = prefs.getString('password');
      final isVerified = prefs.getBool('isEmailVerified') ?? false;

      if (storedEmail != email || 
          storedPassword != _hashPassword(password) ||
          !isVerified) {
        return false;
      }

      await prefs.setBool('isLoggedIn', true);
      _isLoggedIn = true;
      _userId = prefs.getString('userId');
      _email = email;
      _isEmailVerified = true;
      notifyListeners();
      return true;
    } catch (e) {
      print('Login error: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    
    _isLoggedIn = false;
    _userId = null;
    _email = null;
    notifyListeners();
  }
} 