import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

class NetworkService extends ChangeNotifier {
  static final NetworkService _instance = NetworkService._internal();
  factory NetworkService() => _instance;
  NetworkService._internal();

  final Connectivity _connectivity = Connectivity();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isRealConnected = true;
  bool _forceOfflineMode = false;

  bool get isOnline => !_forceOfflineMode && _isRealConnected;
  bool get forceOfflineMode => _forceOfflineMode;

  void initialize() {
    _checkInitial();
    _subscription = _connectivity.onConnectivityChanged.listen((results) {
      _isRealConnected = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    });
  }

  Future<void> _checkInitial() async {
    try {
      final results = await _connectivity.checkConnectivity();
      _isRealConnected = results.any((r) => r != ConnectivityResult.none);
      notifyListeners();
    } catch (e) {
      debugPrint('[NetworkService] Connectivity check error: $e');
    }
  }

  void toggleForceOffline() {
    _forceOfflineMode = !_forceOfflineMode;
    notifyListeners();
  }

  void toggleForceOfflineMode() => toggleForceOffline();

  void setForceOffline(bool offline) {
    if (_forceOfflineMode != offline) {
      _forceOfflineMode = offline;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }
}
