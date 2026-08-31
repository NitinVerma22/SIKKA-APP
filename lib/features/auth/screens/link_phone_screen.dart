import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'package:http/http.dart' as http;
import 'package:sikkaplay/core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LinkPhoneScreen extends ConsumerStatefulWidget {
  const LinkPhoneScreen({super.key});

  @override
  ConsumerState<LinkPhoneScreen> createState() => _LinkPhoneScreenState();
}

class _LinkPhoneScreenState extends ConsumerState<LinkPhoneScreen> {
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  bool _isLoading = false;
  bool _isOtpSent = false;
  String _verificationId = '';
  final AuthService _authService = AuthService();

  @override
  void dispose() {
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  void _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter phone number')));
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
            _isOtpSent = true;
            _verificationId = verificationId;
          });
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP Sent!')));
        }
      },
      verificationFailed: (error) {
        if (mounted) {
          setState(() => _isLoading = false);
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error.message ?? 'Verification failed')));
        }
      },
    );
  }

  void _verifyOtpAndLink() async {
    if (_otpController.text.trim().isEmpty) return;
    setState(() => _isLoading = true);

    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId,
        smsCode: _otpController.text.trim(),
      );

      // Sign in with the phone credential to get a valid Firebase ID token for this phone number
      UserCredential userCredential = await FirebaseAuth.instance.signInWithCredential(credential);
      final phoneUser = userCredential.user;
      
      if (phoneUser == null) {
        throw Exception('Failed to authenticate phone number with Firebase.');
      }

      final phoneIdToken = await phoneUser.getIdToken();
      
      // Sync with backend using the phone ID token
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString('auth_token') ?? '';
      
      final response = await http.post(
        Uri.parse('${AuthService.baseUrl}/user/sync-phone'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'phoneIdToken': phoneIdToken,
        }),
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Phone number linked successfully!')));
          
          context.pop(); // Go back to wallet
        }
      } else {
        final data = jsonDecode(response.body);
        throw Exception(data['error'] ?? 'Failed to sync phone number');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    TextInputType type = TextInputType.text,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderLight),
      ),
      child: TextField(
        controller: controller,
        keyboardType: type,
        style: const TextStyle(color: AppColors.textPrimary, fontSize: 16),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: const TextStyle(color: AppColors.textSecondary),
          prefixIcon: Icon(icon, color: AppColors.primary),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Link Phone Number', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Icon(Icons.security, size: 80, color: AppColors.primary),
            const SizedBox(height: 20),
            const Text(
              'Verify Your Phone',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            const Text(
              'To withdraw your earnings securely, please link and verify your phone number.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 32),
            if (!_isOtpSent) ...[
              _buildInputField(
                controller: _phoneController,
                hint: 'Enter Phone Number',
                icon: Icons.phone,
                type: TextInputType.phone,
              ),
            ] else ...[
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
                    _isOtpSent = false;
                    _otpController.clear();
                  });
                },
                child: const Text('Change Phone Number', style: TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold)),
              )
            ],
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : (_isOtpSent ? _verifyOtpAndLink : _sendOtp),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isLoading 
                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                : Text(
                    _isOtpSent ? 'Verify & Link' : 'Send OTP',
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                  ),
            ),
          ],
        ),
      ),
    );
  }
}
