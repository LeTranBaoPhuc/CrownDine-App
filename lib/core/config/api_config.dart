import 'dart:convert';
import 'dart:io' show Platform;
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ApiConfig {
  static const String _keyBaseUrl = 'crowndine_base_url';
  static const String _keyUseMockFallback = 'crowndine_mock_fallback';
  static const String _keyGoogleClientId = 'crowndine_google_client_id';

  static String get defaultBaseUrl {
    if (kIsWeb) {
      return 'http://localhost:8080/api/';
    }
    try {
      if (Platform.isAndroid) {
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

  /// Lấy Google Client ID an toàn (ưu tiên --dart-define, SharedPreferences, rồi đến local config.json)
  static Future<String> getGoogleClientId() async {
    const fromEnv = String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_keyGoogleClientId);
    if (cached != null && cached.isNotEmpty) return cached;

    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        final res = await Dio().get('$origin/config.json');
        if (res.statusCode == 200 && res.data != null) {
          final dynamic data = res.data is String ? jsonDecode(res.data) : res.data;
          final id = data['googleClientId']?.toString() ?? '';
          if (id.isNotEmpty) {
            await setGoogleClientId(id);
            return id;
          }
        }
      } catch (_) {}
    }

    return '';
  }

  static Future<void> setGoogleClientId(String clientId) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyGoogleClientId, clientId.trim());
  }
}
