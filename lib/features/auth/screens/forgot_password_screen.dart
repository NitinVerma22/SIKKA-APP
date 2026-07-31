import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';

enum ForgotPasswordState { enterPhone, enterOTP, enterNewPassword }

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  ForgotPasswordState _currentState = ForgotPasswordState.enterPhone;
  bool _isLoading = false;
  String _verificationId = '';

  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _otpController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final AuthService _authService = AuthService();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _sendOTP() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter phone number')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final formattedPhone = phone.startsWith('+') ? phone : '+91$phone';

    await _authService.sendOTP(
      phoneNumber: formattedPhone,
      codeSent: (verificationId) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _currentState = ForgotPasswordState.enterOTP;
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

  void _verifyOTP() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter OTP')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.verifyOTP(
      verificationId: _verificationId,
      smsCode: otp,
    );

    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      setState(() {
        _currentState = ForgotPasswordState.enterNewPassword;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('OTP Verified. Enter your new password.')),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Invalid OTP')),
      );
    }
  }

  void _resetPassword() async {
    final newPassword = _passwordController.text;
    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }

    setState(() => _isLoading = true);
    final result = await _authService.resetPassword(newPassword: newPassword);
    
    setState(() => _isLoading = false);

    if (result['success'] == true && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password reset successfully!')),
      );
      context.pop(); // Go back to login
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['error'] ?? 'Failed to reset password')),
      );
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
      margin: const EdgeInsets.only(bottom: 16),
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        ),
      ),
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
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 10),
              const Text(
                'Forgot Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _currentState == ForgotPasswordState.enterPhone
                    ? 'Enter your phone number to receive an OTP'
                    : _currentState == ForgotPasswordState.enterOTP
                        ? 'Enter the OTP sent to your phone'
                        : 'Create a new password',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 16,
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              
              if (_currentState == ForgotPasswordState.enterPhone)
                _buildInputField(
                  controller: _phoneController,
                  hint: context.tr('enter_phone', selectedLanguage),
                  icon: Icons.phone,
                  type: TextInputType.phone,
                )
              else if (_currentState == ForgotPasswordState.enterOTP) ...[
                Text(
                  'OTP sent to ${_phoneController.text}',
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                _buildInputField(
                  controller: _otpController,
                  hint: 'Enter OTP',
                  icon: Icons.message,
                  type: TextInputType.number,
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentState = ForgotPasswordState.enterPhone;
                      _otpController.clear();
                    });
                  },
                  child: const Text(
                    'Change Phone Number',
                    style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold),
                  ),
                )
              ] else if (_currentState == ForgotPasswordState.enterNewPassword)
                _buildInputField(
                  controller: _passwordController,
                  hint: context.tr('password', selectedLanguage),
                  icon: Icons.lock_outline,
                  isPassword: true,
                ),
              
              const SizedBox(height: 20),
              
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () {
                        if (_currentState == ForgotPasswordState.enterPhone) {
                          _sendOTP();
                        } else if (_currentState == ForgotPasswordState.enterOTP) {
                          _verifyOTP();
                        } else if (_currentState == ForgotPasswordState.enterNewPassword) {
                          _resetPassword();
                        }
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 18),
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
                      _currentState == ForgotPasswordState.enterPhone
                          ? 'Send OTP'
                          : _currentState == ForgotPasswordState.enterOTP
                              ? 'Verify OTP'
                              : 'Reset Password',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1.5,
                        color: Colors.white,
                      ),
                    ),
              ),
              
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
