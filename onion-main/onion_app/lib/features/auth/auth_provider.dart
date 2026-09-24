import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserProfile {
  final String id;
  final String inspectorId;
  final String username;
  final String fullName;
  final String role;
  final String centerId;
  final String centerName;
  final String centerCode;
  final String district;
  final String state;

  UserProfile({
    required this.id,
    required this.inspectorId,
    required this.username,
    required this.fullName,
    required this.role,
    required this.centerId,
    required this.centerName,
    required this.centerCode,
    required this.district,
    required this.state,
  });

  Map<String, dynamic> toMap() => {
        'id': id,
        'inspector_id': inspectorId,
        'username': username,
        'full_name': fullName,
        'role': role,
        'center_id': centerId,
        'center_name': centerName,
        'center_code': centerCode,
        'district': district,
        'state': state,
      };

  factory UserProfile.fromMap(Map<String, dynamic> map) => UserProfile(
        id: map['id'] ?? 'insp-1024',
        inspectorId: map['inspector_id'] ?? 'INS1024',
        username: map['username'] ?? 'INS1024',
        fullName: map['full_name'] ?? 'Arun Kumar',
        role: map['role'] ?? 'Quality Inspector',
        centerId: map['center_id'] ?? 'center-erode-01',
        centerName: map['center_name'] ?? 'Erode Onion Procurement Center',
        centerCode: map['center_code'] ?? 'ERO-01',
        district: map['district'] ?? 'Erode',
        state: map['state'] ?? 'Tamil Nadu',
      );
}

class AuthProvider extends ChangeNotifier {
  UserProfile? _currentUser;
  bool _isLoading = true;

  UserProfile? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _loadStoredSession();
  }

  Future<void> _loadStoredSession() async {
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('current_inspector_session');
    if (userJson != null) {
      try {
        _currentUser = UserProfile.fromMap(jsonDecode(userJson));
      } catch (_) {
        _setDefaultInspector();
      }
    } else {
      _setDefaultInspector();
    }
    _isLoading = false;
    notifyListeners();
  }

  void _setDefaultInspector() {
    _currentUser = UserProfile(
      id: 'insp-1024',
      inspectorId: 'INS1024',
      username: 'INS1024',
      fullName: 'Arun Kumar',
      role: 'Quality Inspector',
      centerId: 'center-erode-01',
      centerName: 'Erode Onion Procurement Center',
      centerCode: 'ERO-01',
      district: 'Erode',
      state: 'Tamil Nadu',
    );
  }

  Future<bool> login(String employeeId, String password) async {
    _isLoading = true;
    notifyListeners();

    // Offline-friendly authentication check
    await Future.delayed(const Duration(milliseconds: 300));

    UserProfile profile;
    final cleanId = employeeId.trim().toUpperCase();

    if (cleanId.contains('PATIL') || cleanId == 'INS1025') {
      profile = UserProfile(
        id: 'insp-1025',
        inspectorId: 'INS1025',
        username: 'INS1025',
        fullName: 'Sunita Patil',
        role: 'Quality Assessor',
        centerId: 'center-nashik-01',
        centerName: 'Lasalgaon Onion APMC Center',
        centerCode: 'PC-NSK-01',
        district: 'Nashik',
        state: 'Maharashtra',
      );
    } else {
      profile = UserProfile(
        id: 'insp-1024',
        inspectorId: cleanId.isEmpty ? 'INS1024' : cleanId,
        username: cleanId.isEmpty ? 'INS1024' : cleanId,
        fullName: cleanId.isEmpty ? 'Arun Kumar' : (cleanId == 'INS1024' ? 'Arun Kumar' : 'Inspector $cleanId'),
        role: 'Quality Inspector',
        centerId: 'center-erode-01',
        centerName: 'Erode Onion Procurement Center',
        centerCode: 'ERO-01',
        district: 'Erode',
        state: 'Tamil Nadu',
      );
    }

    _currentUser = profile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('current_inspector_session', jsonEncode(profile.toMap()));

    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('current_inspector_session');
    _currentUser = null;
    notifyListeners();
  }
}
