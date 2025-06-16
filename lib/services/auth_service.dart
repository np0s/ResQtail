import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'email_service.dart';
import 'package:flutter/material.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _email;
  String? _username;
  String? _profileImagePath;
  bool _isEmailVerified = false;
  String? _verificationCode;
  DateTime? _verificationCodeExpiry;
  final EmailService _emailService;
  static const String _usersFileName = 'users.json';

  AuthService({
    required EmailService emailService,
  }) : _emailService = emailService {
    _loadUsers();
  }

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get profileImagePath => _profileImagePath;
  bool get isEmailVerified => _isEmailVerified;

  Future<String> get _usersFilePath async {
    final directory = await getApplicationDocumentsDirectory();
    return '${directory.path}/$_usersFileName';
  }

  Future<Map<String, dynamic>> _loadUsers() async {
    try {
      final file = File(await _usersFilePath);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return json.decode(contents);
      }
    } catch (e) {
      debugPrint('Error loading users: $e');
    }
    return {};
  }

  Future<void> _saveUsers(Map<String, dynamic> users) async {
    try {
      final file = File(await _usersFilePath);
      await file.writeAsString(json.encode(users));
    } catch (e) {
      debugPrint('Error saving users: $e');
    }
  }

  Future<void> _loadUserData() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _email = prefs.getString('email');
    _userId = prefs.getString('userId');
    _username = prefs.getString('username');
    _profileImagePath = prefs.getString('profileImagePath');
    _isEmailVerified = prefs.getBool('isEmailVerified') ?? false;
    _verificationCode = prefs.getString('verificationCode');
    _verificationCodeExpiry = prefs.getString('verificationCodeExpiry') != null
        ? DateTime.parse(prefs.getString('verificationCodeExpiry')!)
        : null;
    notifyListeners();
  }

  Future<void> _saveUserData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', _isLoggedIn);
    await prefs.setString('email', _email ?? '');
    await prefs.setString('userId', _userId ?? '');
    await prefs.setString('username', _username ?? '');
    await prefs.setString('profileImagePath', _profileImagePath ?? '');
    await prefs.setBool('isEmailVerified', _isEmailVerified);
    await prefs.setString('verificationCode', _verificationCode ?? '');
    await prefs.setString('verificationCodeExpiry',
        _verificationCodeExpiry?.toIso8601String() ?? '');
  }

  Future<void> checkLoginStatus() async {
    await _loadUserData();
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
      // Check if user already exists
      final users = await _loadUsers();
      if (users.containsKey(email)) {
        debugPrint('User already exists');
        return false;
      }

      // Generate verification code
      _verificationCode = _generateVerificationCode();
      _verificationCodeExpiry = DateTime.now().add(const Duration(hours: 24));

      // Send verification email
      final emailSent = await _emailService.sendVerificationEmail(
        email,
        _verificationCode!,
      );

      if (!emailSent) {
        debugPrint('Failed to send verification email');
        return false;
      }

      // Store user data
      final userId = const Uuid().v4();
      final hashedPassword = _hashPassword(password);

      // Save to users file
      users[email] = {
        'userId': userId,
        'password': hashedPassword,
        'isEmailVerified': false,
        'verificationCode': _verificationCode,
        'verificationCodeExpiry': _verificationCodeExpiry!.toIso8601String(),
      };
      await _saveUsers(users);

      // Save to local preferences
      await _saveUserData();

      _userId = userId;
      _email = email;
      _username = email.split('@')[0];
      _isEmailVerified = false;
      notifyListeners();

      debugPrint('User registered successfully');
      return true;
    } catch (e) {
      debugPrint('Error during registration: $e');
      return false;
    }
  }

  Future<bool> verifyEmail(String code) async {
    try {
      if (code != _verificationCode) {
        debugPrint('Invalid verification code');
        return false;
      }

      if (_verificationCodeExpiry == null ||
          DateTime.now().isAfter(_verificationCodeExpiry!)) {
        debugPrint('Verification code has expired');
        return false;
      }

      // Update users file
      final users = await _loadUsers();
      if (users.containsKey(_email)) {
        users[_email]!['isEmailVerified'] = true;
        await _saveUsers(users);
      }

      // Update local preferences
      await _saveUserData();

      _isEmailVerified = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error during email verification: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Check users file first
      final users = await _loadUsers();
      final userData = users[email];

      if (userData == null ||
          userData['password'] != _hashPassword(password) ||
          !userData['isEmailVerified']) {
        return false;
      }

      // Update local preferences
      await _saveUserData();

      _isLoggedIn = true;
      notifyListeners();
      debugPrint('User logged in successfully');
      return true;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    _isLoggedIn = false;
    _email = null;
    _userId = null;
    _username = null;
    _profileImagePath = null;
    _isEmailVerified = false;
    _verificationCode = null;
    _verificationCodeExpiry = null;
    await _saveUserData();
    notifyListeners();
    debugPrint('User logged out successfully');
  }

  Future<void> updateUsername(String newUsername) async {
    _username = newUsername;
    await _saveUserData();
    notifyListeners();
  }

  Future<void> updateProfileImage(String imagePath) async {
    _profileImagePath = imagePath;
    await _saveUserData();
    notifyListeners();
  }
}
