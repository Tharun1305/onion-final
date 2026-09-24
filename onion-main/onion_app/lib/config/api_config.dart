import 'package:flutter/foundation.dart';

/// Configuration for the Onion AI FastAPI server.
/// Automatically resolves:
/// - Flutter Web / Chrome -> 'http://127.0.0.1:8000'
/// - Windows Desktop -> 'http://127.0.0.1:8000'
/// - Physical Android Phone -> 'http://172.18.32.227:8000'
/// - Android Emulator -> 'http://10.0.2.2:8000'
class ApiConfig {
  /// Default LAN IP for testing on physical Android devices.
  static const String androidPhysicalLanUrl = 'http://172.18.32.227:8000';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8000';
  static const String localHostUrl = 'http://127.0.0.1:8000';

  /// Optional manual override (leave empty to use automatic platform routing)
  static String customServerUrl = '';

  static String get baseUrl {
    if (customServerUrl.isNotEmpty) {
      return customServerUrl;
    }

    if (kIsWeb) {
      return localHostUrl;
    }

    // Platform-safe target check without importing or executing dart:io
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return androidPhysicalLanUrl;
      case TargetPlatform.windows:
      case TargetPlatform.macOS:
      case TargetPlatform.linux:
        return localHostUrl;
      default:
        return localHostUrl;
    }
  }

  static String get predictUrl => '$baseUrl/predict';
  static String get rootUrl => '$baseUrl/';
}
