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
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      // ignore: use_build_context_synchronously
      await context.read<AuthService>().setProfileImagePath(image.path);
      if (!mounted) return;
      await _loadUserData();
    }
  }

  Future<void> _deleteProfilePicture() async {
    await context.read<AuthService>().setProfileImagePath('');
    await _loadUserData();
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
                              ? NetworkImage(profileImagePath) as ImageProvider<Object>
                              : FileImage(File(profileImagePath)) as ImageProvider<Object>)
                          : null,
                      child: profileImagePath == null ||
                              profileImagePath.isEmpty
                          ? const Icon(Icons.person,
                              color: Colors.deepPurple, size: 40)
                          : null,
                    ),
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.deepPurple,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 2,
                          ),
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
              if (profileImagePath != null &&
                  profileImagePath.isNotEmpty)
                IconButton(
                  icon: const Icon(Icons.delete_outline,
                      color: Colors.deepPurple),
                  onPressed: _deleteProfilePicture,
                  tooltip: 'Delete profile picture',
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
              if (!_isEditingUsername)
                IconButton(
                  icon: const Icon(Icons.edit,
                      color: Colors.deepPurple),
                  onPressed: () {
                    setState(() {
                      _isEditingUsername = true;
                    });
                  },
                )
              else
                IconButton(
                  icon: const Icon(Icons.check,
                      color: Colors.deepPurple),
                  onPressed: () async {
                    await authService.updateUsername(_usernameController.text);
                    await _loadUserData();
                                      setState(() {
                      _usernameController.text = _usernameController.text;
                      _isEditingUsername = false;
                    });
                  },
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
            title: _isEditingPhone
                ? TextField(
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      hintText: 'Enter 10-digit phone number',
                      border: InputBorder.none,
                      counterText: '',
                      isDense: true,
                      contentPadding: EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _phoneNumber = value;
                        _isPhoneValid = RegExp(r'^[6-9]\d{9}$').hasMatch(value);
                        _phoneErrorText = _isPhoneValid ? null : 'Enter a valid 10-digit Indian phone number';
                      });
                    },
                    maxLength: 10,
                    style: const TextStyle(fontSize: 16),
                  )
                : Text(
                    authService.phoneNumber ?? 'No phone number',
                    style: TextStyle(
                      color: Colors.deepPurple.withAlpha(179),
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
            trailing: _isEditingPhone
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: _isPhoneValid
                            ? () async {
                                if (_phoneController.text.isNotEmpty) {
                                  await authService.updatePhoneNumber(_phoneController.text);
                                  await _loadUserData();
                                  setState(() {
                                    _isEditingPhone = false;
                                    _phoneNumber = _phoneController.text;
                                  });
                                }
                              }
                            : null,
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () {
                          setState(() {
                            _isEditingPhone = false;
                            _phoneController.text = _phoneNumber ?? '';
                            _isPhoneValid = true;
                            _phoneErrorText = null;
                          });
                        },
                      ),
                    ],
                  )
                : IconButton(
                    icon: const Icon(Icons.edit, color: Colors.deepPurple),
                    onPressed: () {
                      setState(() {
                        _isEditingPhone = true;
                        _phoneController.text = _phoneNumber ?? '';
                        _isPhoneValid = true;
                        _phoneErrorText = null;
                      });
                    },
                  ),
          ),
          if (!_isEditingPhone && _phoneErrorText != null)
            Padding(
              padding: const EdgeInsets.only(top: 4, left: 8, right: 8),
              child: Text(
                _phoneErrorText!,
                style: const TextStyle(color: Colors.red, fontSize: 13),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          if (!_isEditingPhone)
            SwitchListTile(
              title: const Text('Show phone number to others'),
              value: _isPhoneVisible,
              onChanged: (value) async {
                setState(() {
                  _isPhoneVisible = value;
                });
                await authService.togglePhoneNumberVisibility(value);
              },
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        backgroundColor: Colors.deepPurple,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
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
    );
  }
} 