import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'email_service.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _email;
  bool _isEmailVerified = false;
  String? _verificationCode;
  DateTime? _verificationCodeExpiry;
  String? _profileImagePath;
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
  bool get isEmailVerified => _isEmailVerified;
  String? get profileImagePath => _profileImagePath;

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

  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _isEmailVerified = prefs.getBool('isEmailVerified') ?? false;
    _profileImagePath = prefs.getString('profileImagePath');
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
        'profileImagePath': null,
      };
      await _saveUsers(users);

      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('email', email);
      await prefs.setString('password', hashedPassword);
      await prefs.setBool('isEmailVerified', false);
      await prefs.setString('verificationCode', _verificationCode!);
      await prefs.setString(
          'verificationCodeExpiry', _verificationCodeExpiry!.toIso8601String());
      await prefs.setString('profileImagePath', '');

      _userId = userId;
      _email = email;
      _isEmailVerified = false;
      _profileImagePath = null;
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isEmailVerified', true);
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
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', true);
      await prefs.setString('userId', userData['userId']);
      await prefs.setString('email', email);
      await prefs.setBool('isEmailVerified', true);
      await prefs.setString(
          'profileImagePath', userData['profileImagePath'] ?? '');

      _isLoggedIn = true;
      _userId = userData['userId'];
      _email = email;
      _isEmailVerified = true;
      _profileImagePath = userData['profileImagePath'];
      notifyListeners();
      debugPrint('User logged in successfully');
      return true;
    } catch (e) {
      debugPrint('Error during login: $e');
      return false;
    }
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('isLoggedIn', false);
    await prefs.setString('profileImagePath', '');
    _isLoggedIn = false;
    _userId = null;
    _email = null;
    _profileImagePath = null;
    notifyListeners();
    debugPrint('User logged out successfully');
  }

  Future<void> setProfileImagePath(String path) async {
    _profileImagePath = path;
    // Update users file
    final users = await _loadUsers();
    if (_email != null && users.containsKey(_email)) {
      users[_email]!['profileImagePath'] = path;
      await _saveUsers(users);
    }
    // Update local preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', path);
    notifyListeners();
  }
}
