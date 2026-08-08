import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/features/playground/services/playground_service.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _isOtpSent = false;
  String _verificationId = '';
  String? _selectedGender;
  bool _acceptedTerms = false;
  final TextEditingController _usernameController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _referralController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final AuthService _authService = AuthService();
  final PlaygroundService _playgroundService = PlaygroundService();

  Timer? _debounceTimer;
  String _usernameStatus = ''; // 'loading', 'available', 'taken', 'invalid', ''
  String _usernameError = '';

  @override
  void dispose() {
    _usernameController.dispose();
    _nameController.dispose();
    _cityController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _referralController.dispose();
    _otpController.dispose();
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

  void _initiateRegistration() async {
    final selectedLanguage = ref.read(languageProvider);
    final phone = _phoneController.text.trim();
    final username = _usernameController.text.trim();

    if (username.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Username is required')),
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

    if (phone.isEmpty || _passwordController.text.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(context.tr('register_validation', selectedLanguage))),
      );
      return;
    }

    if (_selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select your gender')),
      );
      return;
    }

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the Terms of Service & Privacy Policy')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    // Make sure we include country code for database
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    await _authService.sendOTP(
      phoneNumber: formattedPhone,
      codeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _isOtpSent = true;
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('OTP Sent successfully!')),
          );
        }
      },
      verificationFailed: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(error.message ?? 'Verification failed')),
          );
        }
      },
    );
  }

  void _verifyAndRegister() async {
    final selectedLanguage = ref.read(languageProvider);
    if (_otpController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final otpResult = await _authService.verifyOTP(
      verificationId: _verificationId,
      smsCode: _otpController.text.trim(),
    );

    if (otpResult['success'] == true) {
      final phone = _phoneController.text.trim();
      final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

      final result = await _authService.register(
        phoneNumber: formattedPhone,
        name: _nameController.text.trim(),
        city: _cityController.text.trim(),
        password: _passwordController.text,
        username: _usernameController.text.trim(),
        gender: _selectedGender?.toUpperCase(),
        referralCode: _referralController.text.trim().isEmpty ? null : _referralController.text.trim(),
      );

      setState(() => _isLoading = false);

      if (result['success'] == true && mounted) {
        context.go('/home');
      } else if (mounted) {
        final errorMsg = result['error'] ?? context.tr('registration_failed_msg', selectedLanguage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg)),
        );
      }
    } else {
      setState(() => _isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(otpResult['error'] ?? 'Invalid OTP')),
        );
      }
    }
  }

  void _handleGoogleLogin() async {
    setState(() => _isLoading = true);
    final result = await _authService.signInWithGoogle();
    setState(() => _isLoading = false);

    if (result['success']) {
      if (result['action'] == 'REQUIRE_PROFILE_COMPLETION') {
        if (mounted) {
          context.push('/complete_profile', extra: {
            'firebaseUid': result['firebaseUid'],
            'email': result['email'],
            'name': result['name'],
          });
        }
      } else {
        if (mounted) {
          context.go('/home');
        }
      }
    } else {
      if (mounted) {
        final selectedLanguage = ref.read(languageProvider);
        String errorMsg = result['error'] ?? context.tr('google_login_failed_msg', selectedLanguage);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMsg), backgroundColor: Colors.orange),
        );
      }
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
    bool isPassword = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        obscureText: isPassword && _obscurePassword,
        keyboardType: type,
        style: const TextStyle(color: AppColors.textPrimary),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textLight),
          prefixIcon: Icon(icon, color: AppColors.textSecondary),
          suffixIcon: isPassword
              ? IconButton(
                  icon: Icon(
                    _obscurePassword ? Icons.visibility_off : Icons.visibility,
                    color: AppColors.textSecondary,
                  ),
                  onPressed: () {
                    setState(() {
                      _obscurePassword = !_obscurePassword;
                    });
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
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
          margin: const EdgeInsets.only(bottom: 4),
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
              hintStyle: const TextStyle(color: AppColors.textLight, fontSize: 14),
              prefixIcon: const Icon(Icons.alternate_email, color: AppColors.textSecondary),
              suffixIcon: suffix != null
                  ? Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: suffix,
                    )
                  : null,
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            ),
          ),
        ),
        if (_usernameError.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 12, bottom: 10),
            child: Text(
              _usernameError,
              style: const TextStyle(color: Colors.redAccent, fontSize: 11),
            ),
          ),
        if (_usernameStatus == 'available')
          const Padding(
            padding: EdgeInsets.only(left: 12, bottom: 10),
            child: Text(
              'Username is available!',
              style: TextStyle(color: Colors.green, fontSize: 11),
            ),
          ),
        if (_usernameStatus == '')
          const SizedBox(height: 6),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final selectedLanguage = ref.watch(languageProvider);
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 40,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 0.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                context.tr('create_account', selectedLanguage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                context.tr('join_and_earn', selectedLanguage),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              
              if (!_isOtpSent) ...[
                // Username field first
                _buildUsernameField(selectedLanguage),

                _buildInputField(
                  controller: _nameController,
                  hint: context.tr('full_name', selectedLanguage),
                  icon: Icons.person_outline,
                ),
                
                _buildInputField(
                  controller: _cityController,
                  hint: context.tr('city', selectedLanguage),
                  icon: Icons.location_city,
                ),
                
                _buildInputField(
                  controller: _phoneController,
                  hint: context.tr('enter_phone', selectedLanguage),
                  icon: Icons.phone,
                  type: TextInputType.phone,
                ),
                
                _buildInputField(
                  controller: _passwordController,
                  hint: context.tr('password', selectedLanguage),
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
                
                _buildInputField(
                  controller: _referralController,
                  hint: context.tr('ref_code_opt', selectedLanguage),
                  icon: Icons.card_giftcard,
                ),
                
                // Gender Dropdown
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: _selectedGender,
                      isExpanded: true,
                      dropdownColor: Colors.white,
                      hint: const Text(
                        'Select Gender',
                        style: TextStyle(color: AppColors.textLight, fontSize: 14),
                      ),
                      icon: const Icon(Icons.arrow_drop_down, color: AppColors.textSecondary),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      items: ['Male', 'Female', 'Other']
                          .map((String value) => DropdownMenuItem<String>(
                                value: value,
                                child: Text(value),
                              ))
                          .toList(),
                      onChanged: (newValue) {
                        setState(() {
                          _selectedGender = newValue;
                        });
                      },
                    ),
                  ),
                ),

                // Terms & Privacy Checkbox
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        activeColor: AppColors.primary,
                        checkColor: Colors.white,
                        side: const BorderSide(color: AppColors.textSecondary),
                        onChanged: (value) {
                          setState(() {
                            _acceptedTerms = value ?? false;
                          });
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/terms');
                        },
                        child: RichText(
                          text: const TextSpan(
                            text: 'I agree to the ',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                            children: [
                              TextSpan(
                                text: 'Terms of Service & Privacy Policy',
                                style: TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ] else ...[
                Text(
                  'OTP sent to ${_phoneController.text}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                _buildInputField(
                  controller: _otpController,
                  hint: 'Enter OTP',
                  icon: Icons.message,
                  type: TextInputType.number,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _isOtpSent = false;
                      _isLoading = false;
                      _otpController.clear();
                    });
                  },
                  child: const Text(
                    'Change Phone Number',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                )
              ],
              
              const SizedBox(height: 12),
              
              ElevatedButton(
                onPressed: _isLoading ? null : (_isOtpSent ? _verifyAndRegister : _initiateRegistration),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 0,
                ),
                child: _isLoading
                  ? const SizedBox(
                      height: 24,
                      width: 24,
                      child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                    )
                  : Text(
                      _isOtpSent ? 'Verify & Register' : context.tr('register_btn', selectedLanguage),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
              ),

              if (!_isOtpSent) ...[
                const SizedBox(height: 12),
                // Google Login
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.borderLight)),
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: Text('OR', style: TextStyle(color: AppColors.textSecondary)),
                    ),
                    Expanded(child: Divider(color: AppColors.borderLight)),
                  ],
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _isLoading ? null : _handleGoogleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.grey.shade200, // Splash color
                    elevation: 1,
                    shadowColor: Colors.black26,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                      side: BorderSide(color: Colors.grey.shade300, width: 1),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Image.network(
                        'https://img.icons8.com/color/48/000000/google-logo.png',
                        height: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Continue with Google',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}
