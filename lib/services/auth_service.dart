import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;
import 'package:hive_flutter/hive_flutter.dart';
import '../utils/constants.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: kIsWeb ? AppConstants.googleClientId : null,
    scopes: ['email', 'profile'],
  );

  final http.Client _client = http.Client();

  // ── Auth Data ────────────────────────────────────────────────────────────────

  String? get token {
    final box = Hive.box(AppConstants.hiveBoxAuth);
    return box.get('token');
  }

  Map<String, dynamic>? get user {
    final box = Hive.box(AppConstants.hiveBoxAuth);
    final userJson = box.get('user');
    if (userJson != null) {
      return Map<String, dynamic>.from(jsonDecode(userJson));
    }
    return null;
  }

  bool get isAuthenticated => token != null;

  // ── Methods ──────────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return false;

      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiAuthGoogle}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': googleUser.email,
          'full_name': googleUser.displayName ?? '',
          'google_id': googleUser.id,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['token'], data['user']);
        return true;
      }
      return false;
    } catch (e) {
      print('Google Sign-In Error: $e');
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiAuthLogin}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': password}),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['access_token'], data['user']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      final response = await _client.post(
        Uri.parse('${AppConstants.apiBaseUrl}${AppConstants.apiAuthRegister}'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'full_name': name,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _saveAuthData(data['access_token'], data['user']);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  Future<void> signOut() async {
    final box = Hive.box(AppConstants.hiveBoxAuth);
    await box.clear();
    await _googleSignIn.signOut();
  }

  Future<void> _saveAuthData(String token, Map<String, dynamic> user) async {
    final box = Hive.box(AppConstants.hiveBoxAuth);
    await box.put('token', token);
    await box.put('user', jsonEncode(user));
  }
}
