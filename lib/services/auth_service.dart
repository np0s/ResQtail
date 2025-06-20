import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:crypto/crypto.dart';
import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'email_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService extends ChangeNotifier {
  bool _isLoggedIn = false;
  String? _userId;
  String? _email;
  String? _username;
  String? _phoneNumber;
  bool _showPhoneNumber = false;
  bool _isEmailVerified = false;
  String? _verificationCode;
  DateTime? _verificationCodeExpiry;
  String? _profileImagePath;
  final EmailService _emailService;
  static const String _usersFileName = 'users.json';
  final _firestore = FirebaseFirestore.instance;

  AuthService({
    required EmailService emailService,
  }) : _emailService = emailService {
    _loadUsers();
  }

  bool get isLoggedIn => _isLoggedIn;
  String? get userId => _userId;
  String? get email => _email;
  String? get username => _username;
  String? get phoneNumber => _phoneNumber;
  bool get showPhoneNumber => _showPhoneNumber;
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


  Future<void> checkLoginStatus() async {
    final prefs = await SharedPreferences.getInstance();
    _isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
    _userId = prefs.getString('userId');
    _email = prefs.getString('email');
    _phoneNumber = prefs.getString('phoneNumber');
    _showPhoneNumber = prefs.getBool('showPhoneNumber') ?? false;
    _isEmailVerified = prefs.getBool('isEmailVerified') ?? false;
    _profileImagePath = prefs.getString('profileImagePath');
    _username = prefs.getString('username');
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

  Future<bool> register(
      String email, String password, String phoneNumber) async {
    // Sanitize phone number
    String digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
    if (digits.startsWith('91') && digits.length == 12) {
      digits = digits.substring(2);
    } else if (digits.startsWith('0') && digits.length == 11) {
      digits = digits.substring(1);
    }
    // Validate Indian phone number
    if (!RegExp(r'^[6-9]\d{9}').hasMatch(digits)) {
      return false;
    }
    try {
      // Check if user already exists in Firestore
      final userDoc = await _firestore.collection('users').doc(email).get();
      if (userDoc.exists) {
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
        return false;
      }

      // Store user data
      final userId = const Uuid().v4();
      final hashedPassword = _hashPassword(password);
      final username = email.split('@')[0];

      // Save to Firestore
      await _firestore.collection('users').doc(email).set({
        'userId': userId,
        'password': hashedPassword,
        'phoneNumber': digits,
        'showPhoneNumber': false,
        'isEmailVerified': false,
        'verificationCode': _verificationCode,
        'verificationCodeExpiry': _verificationCodeExpiry!.toIso8601String(),
        'profileImagePath': null,
        'username': username,
      });

      // Save to local preferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('userId', userId);
      await prefs.setString('email', email);
      await prefs.setString('phoneNumber', digits);
      await prefs.setBool('showPhoneNumber', false);
      await prefs.setString('password', hashedPassword);
      await prefs.setBool('isEmailVerified', false);
      await prefs.setString('verificationCode', _verificationCode!);
      await prefs.setString(
          'verificationCodeExpiry', _verificationCodeExpiry!.toIso8601String());
      await prefs.setString('profileImagePath', '');
      await prefs.setString('username', username);

      _userId = userId;
      _email = email;
      _phoneNumber = digits;
      _showPhoneNumber = false;
      _isEmailVerified = false;
      _profileImagePath = null;
      _username = username;
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
        return false;
      }

      if (_verificationCodeExpiry == null ||
          DateTime.now().isAfter(_verificationCodeExpiry!)) {
        return false;
      }

      // Update Firestore
      if (_email != null) {
        await _firestore.collection('users').doc(_email).update({'isEmailVerified': true});
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
      // Check Firestore first
      final userDoc = await _firestore.collection('users').doc(email).get();
      final userData = userDoc.data();
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
      await prefs.setString('phoneNumber', userData['phoneNumber']);
      await prefs.setBool(
          'showPhoneNumber', userData['showPhoneNumber'] ?? false);
      await prefs.setBool('isEmailVerified', true);
      await prefs.setString(
          'profileImagePath', userData['profileImagePath'] ?? '');
      await prefs.setString('username', userData['username'] ?? email.split('@')[0]);

      _isLoggedIn = true;
      _userId = userData['userId'];
      _email = email;
      _phoneNumber = userData['phoneNumber'];
      _showPhoneNumber = userData['showPhoneNumber'] ?? false;
      _isEmailVerified = true;
      _profileImagePath = userData['profileImagePath'];
      _username = userData['username'] ?? email.split('@')[0];
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
    _phoneNumber = null;
    _showPhoneNumber = false;
    _profileImagePath = null;
    notifyListeners();
  }

  Future<String?> _uploadProfileImageZipline(String imagePath) async {
    const ziplineUrl = 'https://share.p1ng.me/api/upload';
    final apiKey = dotenv.env['ZIPLINE_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('ZIPLINE_API_KEY not set in .env');
    }
    final file = File(imagePath);
    if (!file.existsSync() || file.lengthSync() == 0) {
      throw Exception('Profile image file does not exist or is empty: \\${file.path}');
    }
    var request = http.MultipartRequest('POST', Uri.parse(ziplineUrl));
    request.files.add(await http.MultipartFile.fromPath('file', file.path));
    request.headers['authorization'] = apiKey;
    var response = await request.send();
    if (response.statusCode == 200) {
      final respStr = await response.stream.bytesToString();
      final url = RegExp(r'"url"\s*:\s*"([^"]+)"').firstMatch(respStr)?.group(1);
      if (url != null) {
        return url;
      } else {
        throw Exception('Zipline upload response missing URL');
      }
    } else {
      throw Exception('Failed to upload profile image to Zipline: ${response.statusCode}');
    }
  }

  Future<void> setProfileImagePath(String path) async {
    debugPrint('setProfileImagePath called with path=$path, email=$_email');
    String? url = path;
    if (path.isNotEmpty && !path.startsWith('http')) {
      url = await _uploadProfileImageZipline(path);
    }
    _profileImagePath = url;
    if (_email != null) {
      await _firestore.collection('users').doc(_email).update({'profileImagePath': url});
    }
    // Update local preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profileImagePath', url ?? '');
    notifyListeners();
  }

  Future<void> togglePhoneNumberVisibility(bool show) async {
    _showPhoneNumber = show;
    if (_email != null) {
      await _firestore.collection('users').doc(_email).update({'showPhoneNumber': show});
    }
    // Update local preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('showPhoneNumber', show);
    notifyListeners();
  }

  Future<void> updatePhoneNumber(String phoneNumber) async {
    _phoneNumber = phoneNumber;
    if (_email != null) {
      await _firestore.collection('users').doc(_email).update({'phoneNumber': phoneNumber});
    }
    // Update local preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('phoneNumber', phoneNumber);
    notifyListeners();
  }

  Future<void> updateUsername(String username) async {
    _username = username;
    if (_email != null) {
      await _firestore.collection('users').doc(_email).update({'username': username});
    }
    // Update local preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('username', username);
    notifyListeners();
  }
}
