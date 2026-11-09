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
    const configured = String.fromEnvironment('API_BASE_URL');
    if (configured.isNotEmpty) return normalizeBaseUrl(configured);
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
    final formatted = normalizeBaseUrl(url);
    await prefs.setString(_keyBaseUrl, formatted);
  }

  static String normalizeBaseUrl(String input) {
    final url = Uri.tryParse(input.trim());
    if (url == null ||
        !['http', 'https'].contains(url.scheme) ||
        url.host.isEmpty ||
        url.userInfo.isNotEmpty ||
        url.hasQuery ||
        url.hasFragment) {
      throw const FormatException('URL phải có dạng http(s)://máy-chủ/api/');
    }
    final value = url.toString();
    return value.endsWith('/') ? value : '$value/';
  }

  static Future<bool> isMockFallbackEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyUseMockFallback) ?? false;
  }

  static Future<void> setMockFallbackEnabled(bool enabled) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyUseMockFallback, enabled);
  }

  /// Lấy Google Client ID an toàn (ưu tiên SharedPreferences, --dart-define, web config.json, rồi đến default)
  static Future<String> getGoogleClientId() async {
    final prefs = await SharedPreferences.getInstance();
    final cached = prefs.getString(_keyGoogleClientId);
    if (cached != null && cached.isNotEmpty) return cached;

    const fromEnv =
        String.fromEnvironment('GOOGLE_CLIENT_ID', defaultValue: '');
    if (fromEnv.isNotEmpty) return fromEnv;

    if (kIsWeb) {
      try {
        final origin = Uri.base.origin;
        final res = await Dio().get('$origin/config.json');
        if (res.statusCode == 200 && res.data != null) {
          final dynamic data =
              res.data is String ? jsonDecode(res.data) : res.data;
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
