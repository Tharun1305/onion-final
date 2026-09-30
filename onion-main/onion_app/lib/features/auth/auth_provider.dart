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

  /// Predefined demo accounts available for quick testing
  static const List<Map<String, String>> demoAccounts = [
    {
      'name': 'Administrator',
      'username': 'admin',
      'email': 'admin@onion.ai',
      'password': 'Admin@Onion2026',
      'role': 'Super Admin',
      'center_name': 'APMC Onion Procurement Center',
      'district': 'Nashik',
      'state': 'Maharashtra',
    },
    {
      'name': 'Ramesh Shinde',
      'username': 'inspector1',
      'email': 'inspector1@onion.ai',
      'password': 'Inspector1@2026',
      'role': 'Senior Quality Inspector',
      'center_name': 'APMC Onion Procurement Center',
      'district': 'Nashik',
      'state': 'Maharashtra',
    },
    {
      'name': 'Sunita Patil',
      'username': 'inspector2',
      'email': 'inspector2@onion.ai',
      'password': 'Inspector2@2026',
      'role': 'Quality Assessor',
      'center_name': 'APMC Onion Procurement Center',
      'district': 'Nashik',
      'state': 'Maharashtra',
    },
    {
      'name': 'Arun Kumar',
      'username': 'inspector3',
      'email': 'inspector3@onion.ai',
      'password': 'Inspector3@2026',
      'role': 'Procurement Inspector',
      'center_name': 'APMC Onion Procurement Center',
      'district': 'Nashik',
      'state': 'Maharashtra',
    },
    {
      'name': 'Vikram Deshmukh',
      'username': 'inspector4',
      'email': 'inspector4@onion.ai',
      'password': 'Inspector4@2026',
      'role': 'Audit Assessor',
      'center_name': 'APMC Onion Procurement Center',
      'district': 'Nashik',
      'state': 'Maharashtra',
    },
  ];

  /// Login with Username or Email and Password against backend or fallback demo accounts
  Future<bool> login(String usernameOrEmail, String password) async {
    final cleanIdentifier = usernameOrEmail.trim();

    if (cleanIdentifier.isEmpty || password.isEmpty) {
      throw 'Please enter both username/email and password';
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
          .timeout(const Duration(seconds: 4));

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
    } catch (e) {
      // Check fallback: if server is unreachable or offline, verify demo accounts & local accounts
      final fallbackSuccess = await _tryOfflineLogin(cleanIdentifier, password);
      if (fallbackSuccess) {
        return true;
      }

      if (e is String && !e.contains('connect') && !e.contains('SocketException') && !e.contains('Timeout')) {
        rethrow;
      }
      throw 'Invalid username or password';
    }
  }

  /// Register a new account
  Future<bool> register({
    required String name,
    required String email,
    required String username,
    required String password,
    String role = 'Quality Inspector',
    String centerName = 'APMC Onion Procurement Center',
    String district = 'Nashik',
    String state = 'Maharashtra',
  }) async {
    final cleanName = name.trim();
    final cleanEmail = email.trim().toLowerCase();
    final cleanUsername = username.trim().toLowerCase();

    if (cleanName.isEmpty || cleanEmail.isEmpty || cleanUsername.isEmpty || password.isEmpty) {
      throw 'All fields are required';
    }

    if (password.length < 4) {
      throw 'Password must be at least 4 characters';
    }

    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/auth/register');
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'name': cleanName,
              'email': cleanEmail,
              'username': cleanUsername,
              'password': password,
              'role': role,
              'center_name': centerName,
              'district': district,
              'state': state,
            }),
          )
          .timeout(const Duration(seconds: 4));

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

        // Also store locally for offline access
        await _saveLocalAccount(profile, password);

        notifyListeners();
        return true;
      } else {
        final detail = data['detail'] ?? 'Registration failed';
        throw detail.toString();
      }
    } catch (e) {
      // If server unreachable, complete registration locally
      final profile = UserProfile(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: cleanName,
        email: cleanEmail,
        username: cleanUsername,
        role: role,
        centerName: centerName,
        district: district,
        state: state,
        token: 'local_token_${DateTime.now().millisecondsSinceEpoch}',
      );

      await _saveLocalAccount(profile, password);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_inspector_session', jsonEncode(profile.toMap()));
      await prefs.setString('auth_session_token', profile.token!);

      _currentUser = profile;
      _token = profile.token;
      notifyListeners();
      return true;
    }
  }

  Future<void> _saveLocalAccount(UserProfile profile, String password) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString('local_registered_accounts') ?? '[]';
      final List<dynamic> list = jsonDecode(accountsJson);

      // Check if already exists
      list.removeWhere((item) => item['username'] == profile.username || item['email'] == profile.email);
      list.add({
        ...profile.toMap(),
        'password': password,
      });

      await prefs.setString('local_registered_accounts', jsonEncode(list));
    } catch (e) {
      debugPrint('[AuthProvider] Error saving local account: $e');
    }
  }

  Future<bool> _tryOfflineLogin(String identifier, String password) async {
    final lowerId = identifier.toLowerCase();

    // 1. Check predefined demo accounts
    for (final demo in demoAccounts) {
      if ((demo['username']!.toLowerCase() == lowerId || demo['email']!.toLowerCase() == lowerId) &&
          demo['password'] == password) {
        final profile = UserProfile(
          id: demo['username']!,
          name: demo['name']!,
          email: demo['email']!,
          username: demo['username']!,
          role: demo['role']!,
          centerName: demo['center_name']!,
          district: demo['district']!,
          state: demo['state']!,
          token: 'demo_token_${demo['username']}_${DateTime.now().millisecondsSinceEpoch}',
        );

        _currentUser = profile;
        _token = profile.token;

        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('current_inspector_session', jsonEncode(profile.toMap()));
        await prefs.setString('auth_session_token', profile.token!);

        notifyListeners();
        return true;
      }
    }

    // 2. Check locally registered accounts
    try {
      final prefs = await SharedPreferences.getInstance();
      final accountsJson = prefs.getString('local_registered_accounts') ?? '[]';
      final List<dynamic> list = jsonDecode(accountsJson);

      for (final item in list) {
        final u = (item['username'] as String?)?.toLowerCase() ?? '';
        final e = (item['email'] as String?)?.toLowerCase() ?? '';
        final p = item['password'] as String? ?? '';

        if ((u == lowerId || e == lowerId) && p == password) {
          final profile = UserProfile.fromMap(Map<String, dynamic>.from(item));
          _currentUser = profile;
          _token = 'local_token_${DateTime.now().millisecondsSinceEpoch}';

          await prefs.setString('current_inspector_session', jsonEncode(profile.toMap()));
          await prefs.setString('auth_session_token', _token!);

          notifyListeners();
          return true;
        }
      }
    } catch (_) {}

    return false;
  }

  /// Demo login — no server call, uses the entered name directly
  Future<void> loginDemo(String usernameOrEmail) async {
    final name = usernameOrEmail.trim().isEmpty ? 'Inspector' : usernameOrEmail.trim();
    final profile = UserProfile(
      id: 'demo-001',
      name: name,
      email: name.contains('@') ? name : '$name@onion.ai',
      username: name.contains('@') ? name.split('@').first : name,
      role: 'Quality Inspector',
      centerName: 'APMC Onion Procurement Center',
      district: 'Nashik',
      state: 'Maharashtra',
      token: 'demo-token',
    );
    _currentUser = profile;
    _token = 'demo-token';
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('current_inspector_session', jsonEncode(profile.toMap()));
      await prefs.setString('auth_session_token', 'demo-token');
    } catch (_) {}
    notifyListeners();
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
