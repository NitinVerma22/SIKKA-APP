import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/config/config_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MaintenanceScreen extends StatefulWidget {
  const MaintenanceScreen({super.key});

  @override
  State<MaintenanceScreen> createState() => _MaintenanceScreenState();
}

class _MaintenanceScreenState extends State<MaintenanceScreen> {
  bool _isChecking = false;
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

  Future<void> _checkMaintenance() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // Fetch latest configuration to check if maintenance is resolved
      final config = await ConfigService().getAppConfig();
      if (config != null) {
        final maintenanceMode = config['maintenanceMode'] as bool? ?? false;
        if (!maintenanceMode) {
          // Maintenance resolved, navigate back to splash screen to initialize state
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(_selectedLanguage == 'Hindi' ? 'SikkaPlay वापस ऑनलाइन है! आपका स्वागत है।' : 'SikkaPlay is back online! Welcome back.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
              ),
            );
            context.go('/splash');
          }
          return;
        }
      }
      _showMaintenanceActiveSnackBar();
    } catch (_) {
      _showMaintenanceActiveSnackBar();
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _showMaintenanceActiveSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_selectedLanguage == 'Hindi'
            ? 'सिस्टम अभी भी रखरखाव के अधीन है। कृपया थोड़ी देर में पुन: प्रयास करें।'
            : 'System is still under maintenance. Please try again shortly.'),
        backgroundColor: AppColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Ensure users cannot swipe/navigate back
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
                  // Glowing Settings/Construction Icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: AppColors.accent.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.accent.withValues(alpha: 0.15),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.engineering_rounded,
                      size: 64,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Maintenance Title
                  Text(
                    _selectedLanguage == 'Hindi' ? 'रखरखाव के अधीन' : 'Under Maintenance',
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
                        ? 'SikkaPlay निर्धारित अपग्रेड और सिस्टम अनुकूलन के लिए अस्थायी रूप से ऑफ़लाइन है।\n\nहम आपको सर्वोत्तम संभव अनुभव प्रदान करने के लिए अपने इनाम सिस्टम को ठीक कर रहे हैं। आपके धैर्य के लिए धन्यवाद!'
                        : 'SikkaPlay is temporarily offline for scheduled upgrades and system optimizations.\n\nWe are fine-tuning our reward systems to provide you with the best experience possible. Thank you for your patience!',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  // "Check Again" Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkMaintenance,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        disabledBackgroundColor: AppColors.accent.withValues(alpha: 0.5),
                      ),
                      child: _isChecking
                          ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              _selectedLanguage == 'Hindi' ? 'फिर से जांचें' : 'Check Again',
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
