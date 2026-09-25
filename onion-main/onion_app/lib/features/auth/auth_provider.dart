import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/api_config.dart';

class UserProfile {
  final String id;
  final String name;
  final String email;
  final String username;
  final String role;
  final String centerName;
  final String district;
  final String state;
  final String? token;

  UserProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.username,
    this.role = 'Quality Inspector',
    this.centerName = 'APMC Onion Procurement Center',
    this.district = 'Nashik',
    this.state = 'Maharashtra',
    this.token,
  });

  // Backward compatibility getters
  String get inspectorId => id.toUpperCase().replaceAll('-', '');
  String get fullName => name;
  String get centerId => 'center-01';
  String get centerCode => 'ON-01';

  Map<String, dynamic> toMap() => {
        'id': id,
        'name': name,
        'email': email,
        'username': username,
        'role': role,
        'center_name': centerName,
        'district': district,
        'state': state,
        'token': token,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] ?? map['inspector_id'] ?? 'acc-1',
        name: map['name'] ?? map['full_name'] ?? 'Quality Inspector',
        email: map['email'] ?? 'inspector@onion.ai',
        username: map['username'] ?? (map['email'] != null ? map['email'].split('@').first : 'inspector'),
        role: map['role'] ?? 'Quality Inspector',
        centerName: map['center_name'] ?? 'APMC Onion Procurement Center',
        district: map['district'] ?? 'Nashik',
        state: map['state'] ?? 'Maharashtra',
        token: map['token'],
      );
}

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  String? _token;
  bool _isLoading = true;

  UserProfile? get currentUser => _currentUser;
  String? get token => _token;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString('current_inspector_session');
      final savedToken = prefs.getString('auth_session_token');

      if (userJson != null && savedToken != null) {
        // Validate saved token with backend
        try {
          final url = Uri.parse('${ApiConfig.baseUrl}/auth/me');
          final response = await http.get(
            url,
            headers: {'Authorization': 'Bearer $savedToken'},
          ).timeout(const Duration(seconds: 4));

          if (response.statusCode == 200) {
            final data = jsonDecode(response.body);
            data['token'] = savedToken;
            _currentUser = UserProfile.fromMap(data);
            _token = savedToken;
          } else {
            // Token expired or invalid on backend
            await prefs.remove('current_inspector_session');
            await prefs.remove('auth_session_token');
            _currentUser = null;
            _token = null;
          }
        } catch (_) {
          // If offline, restore session locally
          _currentUser = UserProfile.fromMap(jsonDecode(userJson));
          _token = savedToken;
        }
      } else {
        _currentUser = null;
        _token = null;
      }
    } catch (e) {
      debugPrint('[AuthProvider] Session load error: $e');
      _currentUser = null;
      _token = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Login with Username or Email and Password against the 5 predefined accounts
  Future<bool> login(String usernameOrEmail, String password) async {
    final cleanIdentifier = usernameOrEmail.trim();

    if (cleanIdentifier.isEmpty || password.isEmpty) {
      throw 'Invalid username or password';
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/login');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username_or_email': cleanIdentifier,
              'password': password,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final data = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final token = data['token'] as String;
        final userData = Map<String, dynamic>.from(data['user'] ?? {});
        userData['token'] = token;

        final profile = UserProfile.fromMap(userData);
        _currentUser = profile;
        _token = token;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_inspector_session', jsonEncode(profile.toMap()));
        await prefs.setString('auth_session_token', token);

        notifyListeners();
        return true;
      } else {
        final detail = data['detail'] ?? 'Invalid username or password';
        throw detail.toString();
      }
    } on http.ClientException {
      throw 'Unable to connect to the server. Please check your connection.';
    } catch (e) {
      if (e is String) rethrow;
      throw 'Invalid username or password';
    }
  }

  /// Logout securely
  Future<void> logout() async {
    try {
      if (_token != null) {
        final url = Uri.parse('${ApiConfig.baseUrl}/auth/logout');
        await http
            .post(
              url,
              headers: {
                'Content-Type': 'application/json',
                'Authorization': 'Bearer $_token',
              },
              body: jsonEncode({'token': _token}),
            )
            .timeout(const Duration(seconds: 3));
      }
    } catch (_) {}

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_inspector_session');
    await prefs.remove('auth_session_token');

    _currentUser = null;
    _token = null;
    notifyListeners();
  }
}
