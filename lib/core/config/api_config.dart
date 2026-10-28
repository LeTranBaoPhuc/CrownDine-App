import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyBaseUrl = 'crowndine_base_url';
  static const String _keyUseMockFallback = 'crowndine_mock_fallback';

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/';
    }
    try {
      if (Platform.isAndroid) {
        // Android emulator maps 10.0.2.2 to host machine's localhost
        return 'http://10.0.2.2:8080/api/';
      }
    } catch (_) {}
    return 'http://localhost:8080/api/';
  }

  static Future<String> getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyBaseUrl) ?? defaultBaseUrl;
  }

  static Future<void> setBaseUrl(String url) async {
    final prefs = await SharedPreferences.getInstance();
    String formatted = url.trim();
    if (!formatted.endsWith('/')) {
      formatted = '$formatted/';
    }
    await prefs.setString(_keyBaseUrl, formatted);
  }

  static Future<bool> isMockFallbackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseMockFallback) ?? true;
  }

  static Future<void> setMockFallbackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseMockFallback, enabled);
  }
}
