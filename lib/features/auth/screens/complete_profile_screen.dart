import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const CompleteProfileScreen({super.key, required this.userData});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _usernameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cityController = TextEditingController();
  final _referralController = TextEditingController();
  String? _selectedGender;
  final AuthService _authService = AuthService();
  final PlaygroundService _playgroundService = PlaygroundService();

  Timer? _debounceTimer;
  String _usernameStatus = ''; // 'loading', 'available', 'taken', 'invalid', ''
  String _usernameError = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _phoneController.dispose();
    _cityController.dispose();
    _referralController.dispose();
    _debounceTimer?.cancel();
    super.dispose();
  }

  void _onUsernameChanged(String value) {
    if (_debounceTimer?.isActive ?? false) _debounceTimer!.cancel();

    if (value.trim().isEmpty) {
      setState(() {
        _usernameStatus = '';
        _usernameError = '';
      });
      return;
    }

    String clean = value.trim().toLowerCase();
    if (clean.startsWith('@')) clean = clean.substring(1);

    final regex = RegExp(r'^[a-zA-Z0-9_]{3,15}$');
    if (!regex.hasMatch(clean)) {
      setState(() {
        _usernameStatus = 'invalid';
        _usernameError = '3-15 chars, alphanumeric & underscores only';
      });
      return;
    }

    setState(() {
      _usernameStatus = 'loading';
      _usernameError = '';
    });

    _debounceTimer = Timer(const Duration(milliseconds: 600), () async {
      final res = await _playgroundService.checkUsernameUnique(clean);
      if (!mounted) return;

      if (res['success'] == true) {
        if (res['isUnique'] == true) {
          setState(() {
            _usernameStatus = 'available';
            _usernameError = '';
          });
        } else {
          setState(() {
            _usernameStatus = 'taken';
            _usernameError = 'This username is already taken';
          });
        }
      } else {
        setState(() {
          _usernameStatus = 'error';
          _usernameError = res['error'] ?? 'Uniqueness check failed';
        });
      }
    });
  }

  void _submitProfile() async {
    final selectedLanguage = ref.read(languageProvider);
    final username = _usernameController.text.trim();
    final phone = _phoneController.text.trim();

    if (username.isEmpty || phone.isEmpty || _cityController.text.isEmpty || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username, Phone Number, City and Gender are required')),
      );
      return;
    }

    if (_usernameStatus != 'available') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_usernameError.isNotEmpty ? _usernameError : 'Please select a unique username'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await _authService.completeGoogleSignup(
      firebaseUid: widget.userData['firebaseUid'],
      email: widget.userData['email'],
      name: widget.userData['name'] ?? '',
      city: _cityController.text.trim(),
      gender: _selectedGender!,
      username: username,
      referralCode: _referralController.text.trim(),
      phoneNumber: phone,
    );

    setState(() => _isLoading = false);

    if (result['success']) {
      if (mounted) context.go('/home');
    } else {
      if (mounted) {
        final errorMsg = result['error'] ?? context.tr('registration_failed_msg', selectedLanguage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.redAccent),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('complete_profile_title', selectedLanguage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                context.tr('welcome_name_subtitle', selectedLanguage).replaceAll('{name}', widget.userData['name'] ?? ''),
                textAlign: TextAlign.center,
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
              const SizedBox(height: 30),

              // Username input field
              _buildUsernameField(selectedLanguage),
              const SizedBox(height: 20),

              // Gender Dropdown
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedGender,
                    hint: Text(context.tr('select_gender', selectedLanguage), style: const TextStyle(color: AppColors.textSecondary)),
                    isExpanded: true,
                    dropdownColor: Colors.white,
                    style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                    icon: const Icon(Icons.arrow_drop_down, color: AppColors.textPrimary),
                    items: ['male', 'female'].map((String value) {
                      return DropdownMenuItem<String>(
                        value: value,
                        child: Text(value == 'male' ? context.tr('male', selectedLanguage) : context.tr('female', selectedLanguage)),
                      );
                    }).toList(),
                    onChanged: (newValue) {
                      setState(() {
                        _selectedGender = newValue;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Phone Number
              _buildInputField(
                controller: _phoneController,
                hint: 'Phone Number',
                icon: Icons.phone,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 20),

              // City
              _buildInputField(
                controller: _cityController,
                hint: context.tr('city', selectedLanguage),
                icon: Icons.location_city,
              ),
              const SizedBox(height: 20),

              // Referral
              _buildInputField(
                controller: _referralController,
                hint: context.tr('ref_code_opt', selectedLanguage),
                icon: Icons.card_giftcard,
              ),
              const SizedBox(height: 40),

              ElevatedButton(
                onPressed: _isLoading ? null : _submitProfile,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                  ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : Text(
                      context.tr('finish_signup', selectedLanguage),
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUsernameField(String selectedLanguage) {
    Color statusColor = AppColors.borderLight;
    Widget? suffix;

    if (_usernameStatus == 'loading') {
      suffix = const SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
      );
    } else if (_usernameStatus == 'available') {
      statusColor = Colors.green;
      suffix = const Icon(Icons.check_circle, color: Colors.green);
    } else if (_usernameStatus == 'taken' || _usernameStatus == 'invalid') {
      statusColor = Colors.redAccent;
      suffix = const Icon(Icons.cancel, color: Colors.redAccent);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: statusColor),
          ),
          child: TextField(
            controller: _usernameController,
            onChanged: _onUsernameChanged,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: InputDecoration(
              hintText: 'Username',
              hintStyle: const TextStyle(color: AppColors.textLight),
              prefixIcon: const Icon(Icons.alternate_email, color: AppColors.textSecondary),
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: suffix,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ),
        if (_usernameError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, top: 6),
            child: Text(
              _usernameError,
              style: const TextStyle(color: Colors.redAccent, fontSize: 12),
            ),
          ),
        if (_usernameStatus == 'available')
          const Padding(
            padding: EdgeInsets.only(left: 12, top: 6),
            child: Text(
              'Username is available!',
              style: TextStyle(color: Colors.green, fontSize: 12),
            ),
          ),
      ],
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
    );
  }
}
