import 'package:flutter/material.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UpdateAppScreen extends StatefulWidget {
  final String updateUrl;

  const UpdateAppScreen({
    super.key,
    required this.updateUrl,
  });

  @override
  State<UpdateAppScreen> createState() => _UpdateAppScreenState();
}

class _UpdateAppScreenState extends State<UpdateAppScreen> {
  bool _isLaunching = false;
  String _selectedLanguage = 'English';

  @override
  void initState() {
    super.initState();
    _loadLanguage();
  }

  void _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _selectedLanguage = prefs.getString('app_language') ?? 'English';
      });
    }
  }

  Future<void> _launchUpdateUrl() async {
    if (_isLaunching) return;

    setState(() {
      _isLaunching = true;
    });

    try {
      final url = Uri.parse(widget.updateUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        _showErrorSnackBar();
      }
    } catch (_) {
      _showErrorSnackBar();
    } finally {
      if (mounted) {
        setState(() {
          _isLaunching = false;
        });
      }
    }
  }

  void _showErrorSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_selectedLanguage == 'Hindi'
            ? 'अपडेट लिंक नहीं खोला जा सका। कृपया सहायता से संपर्क करें।'
            : 'Could not open the update link. Please contact support.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Force update screen is non-dismissible
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF0F0F1A),
                Color(0xFF1E1E38),
              ],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),
                  // Glowing Update/Download Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.system_update_rounded,
                      size: 64,
                      color: AppColors.primaryLight,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Update Title
                  Text(
                    _selectedLanguage == 'Hindi' ? 'अपडेट आवश्यक है' : 'Update Required',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Information Text
                  Text(
                    _selectedLanguage == 'Hindi'
                        ? 'SikkaPlay का एक महत्वपूर्ण नया संस्करण उपलब्ध है। अखंडता, सुरक्षा और नवीनतम पुरस्कारों तक पहुंच बनाए रखने के लिए, जारी रखने के लिए आपको ऐप को अपडेट करना होगा।'
                        : 'A critical new version of SikkaPlay is available. To maintain integrity, security, and access to the latest rewards, you must update the app to continue.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  // "Download Update" Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLaunching ? null : _launchUpdateUrl,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                      ),
                      child: _isLaunching
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _selectedLanguage == 'Hindi' ? 'अपडेट डाउनलोड करें' : 'Download Update',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 0.5,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
