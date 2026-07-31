import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/core/constants/app_colors.dart';
import 'package:sikkaplay/core/user/user_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class VpnBlockedScreen extends StatefulWidget {
  const VpnBlockedScreen({super.key});

  @override
  State<VpnBlockedScreen> createState() => _VpnBlockedScreenState();
}

class _VpnBlockedScreenState extends State<VpnBlockedScreen> {
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

  Future<void> _checkConnection() async {
    if (_isChecking) return;

    setState(() {
      _isChecking = true;
    });

    try {
      // Fetch user profile to verify connection.
      // If the request succeeds (statusCode 200), it means the VPN is disabled
      // and the middleware let the request pass.
      final profile = await UserService().getProfile();
      
      if (profile != null) {
        // VPN is turned off. We can navigate back to the main layout / home.
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(_selectedLanguage == 'Hindi' ? 'कनेक्शन बहाल हो गया! पहुंच स्वीकृत।' : 'Connection restored! Access granted.'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
          context.go('/home');
        }
      } else {
        _showVpnActiveSnackBar();
      }
    } catch (_) {
      _showVpnActiveSnackBar();
    } finally {
      if (mounted) {
        setState(() {
          _isChecking = false;
        });
      }
    }
  }

  void _showVpnActiveSnackBar() {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_selectedLanguage == 'Hindi'
            ? 'VPN/प्रॉक्सी अभी भी सक्रिय है। कृपया इसे बंद करें और पुन: प्रयास करें।'
            : 'VPN/Proxy is still active. Please turn it off and try again.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false, // Make screen non-dismissible via back gestures/buttons
      child: Scaffold(
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF1A1A2E),
                Color(0xFF16213E),
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
                  // Glowing warning shield icon
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.red.withValues(alpha: 0.2),
                          blurRadius: 30,
                          spreadRadius: 5,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.vpn_lock_rounded,
                      size: 64,
                      color: Colors.redAccent,
                    ),
                  ),
                  const SizedBox(height: 40),
                  // Block title
                  Text(
                    _selectedLanguage == 'Hindi' ? 'VPN या प्रॉक्सी का पता चला' : 'VPN or Proxy Detected',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  // Informative warning text
                  Text(
                    _selectedLanguage == 'Hindi'
                        ? 'निष्पक्ष खेल सुनिश्चित करने और हमारे विज्ञापन नेटवर्क नीतियों का पालन करने के लिए, SikkaPlay VPN, प्रॉक्सी या अनाम होस्टिंग नेटवर्क से ट्रैफ़िक की अनुमति नहीं देता है।\n\nकृपया अपनी VPN/प्रॉक्सी सेवा बंद करें और पुन: प्रयास करें।'
                        : 'To ensure fair play and comply with our ad network policies, SikkaPlay does not allow traffic from VPNs, Proxies, or Anonymous Hosting Networks.\n\nPlease turn off your VPN/Proxy service and retry.',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 15,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const Spacer(),
                  // Premium Action Button
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isChecking ? null : _checkConnection,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.redAccent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 4,
                        disabledBackgroundColor: Colors.redAccent.withValues(alpha: 0.5),
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
                              _selectedLanguage == 'Hindi' ? 'कनेक्शन पुन: प्रयास करें' : 'Retry Connection',
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
