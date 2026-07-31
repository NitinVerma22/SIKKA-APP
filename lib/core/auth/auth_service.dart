import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:go_router/go_router.dart';
import 'package:sikkaplay/routes/app_router.dart';

class AuthService {
  // Centralized Base URL for the backend API.
  static const String baseUrl = 'https://sikkaplay-backend-834810172223.asia-south1.run.app/api/auth';
  final FirebaseAuth _firebaseAuth = FirebaseAuth.instance;
  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  void _checkVpnBlock(http.Response response) {
    if (response.statusCode == 403) {
      try {
        final data = jsonDecode(response.body);
        if (data is Map && data['isVpnBlocked'] == true) {
          rootNavigatorKey.currentState?.context.go('/vpn_blocked');
        }
      } catch (_) {}
    }
  }

  Future<String> _getDeviceId() async {
    final DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
    try {
      if (kIsWeb) {
        final existing = await _secureStorage.read(key: 'device_id');
        if (existing != null) return existing;
        final newId = DateTime.now().microsecondsSinceEpoch.toString();
        await _secureStorage.write(key: 'device_id', value: newId);
        return newId;
      }
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return androidInfo.id; // SSAID
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return iosInfo.identifierForVendor ?? 'ios-fallback-id';
      }
    } catch (e) {
      debugPrint('Error getting device ID: $e');
    }
    final existing = await _secureStorage.read(key: 'device_id');
    if (existing != null) return existing;
    final newId = DateTime.now().microsecondsSinceEpoch.toString();
    await _secureStorage.write(key: 'device_id', value: newId);
    return newId;
  }

  // Helper: Get Token
  Future<String?> getToken() async {
    return await _secureStorage.read(key: 'jwt_token');
  }

  // Helper: Save Token
  Future<void> saveToken(String token) async {
    await _secureStorage.write(key: 'jwt_token', value: token);
    try {
      final fcmToken = await FirebaseMessaging.instance.getToken();
      if (fcmToken != null) {
        await updateFcmTokenOnServer(fcmToken);
      }
    } catch (_) {}
  }

  // Helper: Common GET request
  Future<Map<String, dynamic>> get(String endpoint) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'error': 'No token found'};
    
    try {
      final response = await http.get(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      _checkVpnBlock(response);
      if (response.statusCode == 200) {
        return {'success': true, 'data': jsonDecode(response.body)};
      }
      return {'success': false, 'error': 'Failed to fetch data'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // Helper: Common POST request
  Future<Map<String, dynamic>> post(String endpoint, Map<String, dynamic> body) async {
    final token = await getToken();
    if (token == null) return {'success': false, 'error': 'No token found'};
    
    try {
      final response = await http.post(
        Uri.parse('$baseUrl$endpoint'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      );
      _checkVpnBlock(response);
      
      final data = jsonDecode(response.body);
      
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return {'success': true, 'data': data};
      }
      return {'success': false, 'error': data['error'] ?? 'Request failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> updateFcmTokenOnServer(String fcmToken) async {
    try {
      final token = await getToken();
      if (token == null) return;

      final String url = baseUrl.replaceAll('/auth', '/user/fcm-token');
      await http.post(
        Uri.parse(url),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'token': fcmToken}),
      );
      debugPrint('FCM Token successfully synchronized with server.');
    } catch (e) {
      debugPrint('Error updating FCM Token on server: $e');
    }
  }

  // 1. Send OTP via Firebase
  Future<void> sendOTP({
    required String phoneNumber,
    required Function(String verificationId) codeSent,
    required Function(FirebaseAuthException e) verificationFailed,
  }) async {
    await _firebaseAuth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (PhoneAuthCredential credential) {},
      verificationFailed: verificationFailed,
      codeSent: (String verificationId, int? resendToken) {
        codeSent(verificationId);
      },
      codeAutoRetrievalTimeout: (String verificationId) {},
    );
  }

  // Verify OTP and sign in with Firebase
  Future<Map<String, dynamic>> verifyOTP({
    required String verificationId,
    required String smsCode,
  }) async {
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: verificationId,
        smsCode: smsCode,
      );
      UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      if (userCredential.user != null) {
        return {'success': true, 'user': userCredential.user};
      }
      return {'success': false, 'error': 'Failed to verify OTP'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  // 2. Direct Registration (No OTP for testing)
  Future<Map<String, dynamic>> register({
    required String phoneNumber,
    required String name,
    required String city,
    required String password,
    String? gender,
    String? referralCode,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final response = await http.post(
        Uri.parse('$baseUrl/register'),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'name': name,
          'city': city,
          'gender': gender,
          'password': password,
          'referredBy': referralCode,
          'deviceId': deviceId,
        }),
      ).timeout(const Duration(seconds: 15));

      _checkVpnBlock(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        // Save JWT Session
        await _secureStorage.write(key: 'jwt_token', value: data['token']);
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Registration failed'};
    } catch (e) {
      debugPrint('Registration Error: $e');
      return {'success': false, 'error': 'Network timeout or server offline'};
    }
  }

  // 3. Login with Password (No OTP)
  Future<Map<String, dynamic>> login({
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final response = await http.post(
        Uri.parse('$baseUrl/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'phoneNumber': phoneNumber,
          'password': password,
          'deviceId': deviceId,
        }),
      ).timeout(const Duration(seconds: 10));

      _checkVpnBlock(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        await _secureStorage.write(key: 'jwt_token', value: data['token']);
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Login failed'};
    } catch (e) {
      print('Login Error: $e');
      return {'success': false, 'error': 'Network timeout or server offline'};
    }
  }

  // Google Sign-In logic
  Future<Map<String, dynamic>> signInWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      
      // Ensure we clear any previous state
      await googleSignIn.signOut();
      
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) {
        return {'success': false, 'error': 'Sign in aborted by user'};
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final UserCredential userCredential = await _firebaseAuth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
         return {'success': false, 'error': 'Firebase auth failed'};
      }

      final idToken = await firebaseUser.getIdToken();
      
      final deviceId = await _getDeviceId();
      // Send token to backend
      final response = await http.post(
        Uri.parse('$baseUrl/google-login'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'deviceId': deviceId,
        }),
      );

      _checkVpnBlock(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        if (data['action'] == 'REQUIRE_PROFILE_COMPLETION') {
           return {
             'success': true,
             'action': 'REQUIRE_PROFILE_COMPLETION',
             'firebaseUid': data['firebaseUid'],
             'email': data['email'],
             'name': data['name']
           };
        } else if (data['token'] != null) {
          await saveToken(data['token']);
          return {'success': true, 'user': data['user']};
        }
      }
      
      return {'success': false, 'error': data['error'] ?? 'Google login failed'};
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> completeGoogleSignup({
    required String firebaseUid,
    required String name,
    required String city,
    required String gender,
    String? referralCode,
  }) async {
    try {
      final deviceId = await _getDeviceId();
      final response = await http.post(
        Uri.parse('$baseUrl/complete-google-signup'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'firebaseUid': firebaseUid,
          'name': name,
          'city': city,
          'gender': gender,
          'referredBy': referralCode,
          'deviceId': deviceId,
        }),
      );

      _checkVpnBlock(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['token'] != null) {
        await saveToken(data['token']);
        return {'success': true, 'user': data['user']};
      }
      return {'success': false, 'error': data['error'] ?? 'Signup failed'};
    } catch (e) {
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> logout() async {
    await _secureStorage.delete(key: 'jwt_token');
    await _firebaseAuth.signOut();
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn();
      await googleSignIn.disconnect();
    } catch (e) {
      debugPrint('Google disconnect error: $e');
    }
  }

  // Reset Password via Backend with Firebase JWT
  Future<Map<String, dynamic>> resetPassword({
    required String newPassword,
  }) async {
    try {
      final firebaseUser = _firebaseAuth.currentUser;
      if (firebaseUser == null) {
        return {'success': false, 'error': 'Not authenticated with Firebase'};
      }

      final idToken = await firebaseUser.getIdToken();
      if (idToken == null) {
         return {'success': false, 'error': 'Could not get Firebase token'};
      }

      final response = await http.post(
        Uri.parse('$baseUrl/forgot-password'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        },
        body: jsonEncode({
          'newPassword': newPassword,
        }),
      );

      _checkVpnBlock(response);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'] ?? 'Password reset successful'};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to reset password'};
    } catch (e) {
      debugPrint('Reset Password Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<Map<String, dynamic>> deleteAccount() async {
    final token = await getToken();
    if (token == null) return {'success': false, 'error': 'No token found'};
    
    try {
      final response = await http.delete(
        Uri.parse(baseUrl.replaceAll('/auth', '/user/me')),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );
      
      _checkVpnBlock(response);
      final data = jsonDecode(response.body);
      
      if (response.statusCode == 200) {
        await logout(); // Clear secure storage and firebase session
        return {'success': true};
      }
      return {'success': false, 'error': data['error'] ?? 'Failed to delete account'};
    } catch (e) {
      debugPrint('Delete Account Error: $e');
      return {'success': false, 'error': e.toString()};
    }
  }
}
