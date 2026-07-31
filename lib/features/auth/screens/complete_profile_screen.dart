import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/auth/auth_service.dart';
import 'package:sikkaplay/core/localization/app_translations.dart';
import 'package:sikkaplay/core/localization/translation_provider.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';

class CompleteProfileScreen extends ConsumerStatefulWidget {
  final Map<String, dynamic> userData;

  const CompleteProfileScreen({super.key, required this.userData});

  @override
  ConsumerState<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends ConsumerState<CompleteProfileScreen> {
  final _cityController = TextEditingController();
  final _referralController = TextEditingController();
  String? _selectedGender;
  final AuthService _authService = AuthService();
  
  bool _isLoading = false;

  @override
  void dispose() {
    _cityController.dispose();
    _referralController.dispose();
    super.dispose();
  }


  void _submitProfile() async {
    final selectedLanguage = ref.read(languageProvider);
    if (_cityController.text.isEmpty || _selectedGender == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('City and Gender are required')),
      );
      return;
    }

    setState(() => _isLoading = true);
    
    final result = await _authService.completeGoogleSignup(
      firebaseUid: widget.userData['firebaseUid'],
      name: widget.userData['name'] ?? '',
      city: _cityController.text,
      gender: _selectedGender!,
      referralCode: _referralController.text.isNotEmpty ? _referralController.text : null,
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
              const SizedBox(height: 40),
              
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
