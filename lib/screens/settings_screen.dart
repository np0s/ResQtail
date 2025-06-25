import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late AuthService authService;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool _isEditingUsername = false;
  bool _isEditingPhone = false;
  String? _phoneNumber;
  bool _isPhoneVisible = true;
  bool _isLoading = false;
  final ImagePicker _picker = ImagePicker();
  bool _isPhoneValid = true;
  String? _phoneErrorText;

  @override
  void initState() {
    super.initState();
    // AuthService will be assigned in didChangeDependencies
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    authService = Provider.of<AuthService>(context, listen: false);
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    setState(() {
      _isLoading = true;
    });
    try {
      await authService.checkLoginStatus();
      setState(() {
        _usernameController.text = authService.username ?? '';
        _phoneNumber = authService.phoneNumber;
        _isPhoneVisible = authService.showPhoneNumber;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading user data: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _usernameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    setState(() {
      _isLoading = true;
    });
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // ignore: use_build_context_synchronously
      await context.read<AuthService>().setProfileImagePath(image.path);
      if (!mounted) return;
      await _loadUserData();
    }
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _deleteProfilePicture() async {
    setState(() {
      _isLoading = true;
    });
    await context.read<AuthService>().setProfileImagePath('');
    await _loadUserData();
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Widget _buildProfileImageSection() {
    final profileImagePath = authService.profileImagePath;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Picture',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              GestureDetector(
                onTap: _pickImage,
                child: Stack(
                  children: [
                    CircleAvatar(
                      radius: 32,
                      backgroundColor: Colors.deepPurple[100],
                      backgroundImage: profileImagePath != null &&
                              profileImagePath.isNotEmpty
                          ? (profileImagePath.startsWith('http')
                              ? NetworkImage(profileImagePath)
                                  as ImageProvider<Object>
                              : FileImage(File(profileImagePath))
                                  as ImageProvider<Object>)
                          : null,
                      child:
                          profileImagePath == null || profileImagePath.isEmpty
                              ? const Icon(Icons.person,
                                  color: Colors.deepPurple, size: 40)
                              : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Profile Picture',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.deepPurple,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to change or remove',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.deepPurple.withAlpha(179),
                      ),
                    ),
                  ],
                ),
              ),
              if (profileImagePath != null && profileImagePath.isNotEmpty)
                IconButton(
                  onPressed: _deleteProfilePicture,
                  icon: const Icon(Icons.delete, color: Colors.red),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsernameSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withAlpha(128),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Profile Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.deepPurple,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Icon(
                Icons.person,
                color: Colors.deepPurple.withAlpha(179),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _isEditingUsername
                    ? TextField(
                        controller: _usernameController,
                        autofocus: true,
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.deepPurple,
                        ),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          isDense: true,
                          contentPadding: EdgeInsets.zero,
                        ),
                      )
                    : Text(
                        _usernameController.text,
                        style: TextStyle(
                          color: Colors.deepPurple.withAlpha(179),
                          fontSize: 16,
                        ),
                      ),
              ),
              IconButton(
                onPressed: () async {
                  if (_isEditingUsername) {
                    if (_usernameController.text.trim().isNotEmpty) {
                      await authService
                          .updateUsername(_usernameController.text.trim());
                      setState(() {
                        _isEditingUsername = false;
                      });
                    }
                  } else {
                    setState(() {
                      _isEditingUsername = true;
                    });
                  }
                },
                icon: Icon(
                  _isEditingUsername ? Icons.check : Icons.edit,
                  color: Colors.deepPurple.withAlpha(179),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPhoneNumberSection() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isEditingPhone
              ? (_isPhoneValid ? Colors.green : Colors.red)
              : Colors.deepPurple.withAlpha(77),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.deepPurple.withAlpha(16),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          ListTile(
            leading: Icon(
              Icons.phone,
              color: Colors.deepPurple.withAlpha(179),
            ),
            title: const Text(
              'Phone Number',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.deepPurple,
              ),
            ),
            subtitle: _isEditingPhone
                ? TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Colors.deepPurple,
                    ),
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: EdgeInsets.zero,
                      errorText: _phoneErrorText,
                    ),
                    onChanged: (value) {
                      setState(() {
                        _phoneErrorText = null;
                        _isPhoneValid = true;
                      });
                    },
                  )
                : Text(
                    _phoneNumber ?? 'Not set',
                    style: TextStyle(
                      color: Colors.deepPurple.withAlpha(179),
                      fontSize: 16,
                    ),
                  ),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_isPhoneVisible)
                  Icon(
                    Icons.visibility,
                    color: Colors.deepPurple.withAlpha(179),
                    size: 20,
                  ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: () async {
                    if (_isEditingPhone) {
                      final phoneNumber = _phoneController.text.trim();
                      if (phoneNumber.isEmpty) {
                        setState(() {
                          _phoneErrorText = 'Phone number cannot be empty';
                          _isPhoneValid = false;
                        });
                        return;
                      }

                      // Validate Indian phone number
                      String digits = phoneNumber.replaceAll(RegExp(r'\D'), '');
                      if (digits.startsWith('91') && digits.length == 12) {
                        digits = digits.substring(2);
                      } else if (digits.startsWith('0') &&
                          digits.length == 11) {
                        digits = digits.substring(1);
                      }

                      if (!RegExp(r'^[6-9]\d{9}').hasMatch(digits)) {
                        setState(() {
                          _phoneErrorText =
                              'Please enter a valid Indian phone number';
                          _isPhoneValid = false;
                        });
                        return;
                      }

                      await authService.updatePhoneNumber(digits);
                      setState(() {
                        _phoneNumber = digits;
                        _isEditingPhone = false;
                        _isPhoneValid = true;
                        _phoneErrorText = null;
                      });
                    } else {
                      setState(() {
                        _isEditingPhone = true;
                        _phoneController.text = _phoneNumber ?? '';
                      });
                    }
                  },
                  icon: Icon(
                    _isEditingPhone ? Icons.check : Icons.edit,
                    color: Colors.deepPurple.withAlpha(179),
                  ),
                ),
              ],
            ),
          ),
          if (!_isEditingPhone)
            ListTile(
              leading: const SizedBox.shrink(),
              title: const Text(
                'Show Phone Number',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.deepPurple,
                ),
              ),
              trailing: Switch(
                value: _isPhoneVisible,
                onChanged: (value) async {
                  await authService.togglePhoneNumberVisibility(value);
                  setState(() {
                    _isPhoneVisible = value;
                  });
                },
                activeColor: Colors.deepPurple,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Column(
            children: [
              AppBar(
                title: const Text('Settings'),
                backgroundColor: Colors.deepPurple,
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildProfileImageSection(),
                      const SizedBox(height: 24),
                      _buildUsernameSection(),
                      const SizedBox(height: 16),
                      _buildPhoneNumberSection(),
                    ],
                  ),
                ),
              ),
            ],
          ),
          if (_isLoading)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        color: Colors.deepPurple,
                        strokeWidth: 3.0,
                      ),
                      SizedBox(height: 18),
                      Text(
                        'Loading...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1.1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
