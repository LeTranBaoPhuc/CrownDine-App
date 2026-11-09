import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

class ApiClient {
  static ApiClient? _instance;
  final Dio _dio;
  final Dio _refreshDio;
  Future<String?>? _refreshing;
  void Function()? onSessionExpired;

  ApiClient._internal()
      : _dio = Dio(BaseOptions(
            baseUrl: ApiConfig.defaultBaseUrl,
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8),
            headers: {
              'Content-Type': 'application/json',
              'Accept': 'application/json'
            })),
        _refreshDio = Dio(BaseOptions(
            connectTimeout: const Duration(seconds: 8),
            receiveTimeout: const Duration(seconds: 8))) {
    _configure();
  }
  ApiClient.forTesting({required Dio dio, required Dio refreshDio})
      : _dio = dio,
        _refreshDio = refreshDio {
    _configure();
  }

  static ApiClient get instance => _instance ??= ApiClient._internal();
  Dio get dio => _dio;

  void _configure() {
    _dio.interceptors
        .add(InterceptorsWrapper(onRequest: (options, handler) async {
      final prefs = await SharedPreferences.getInstance();
      options.baseUrl = await ApiConfig.getBaseUrl();
      options.extra
          .putIfAbsent('sessionUser', () => prefs.getString('username'));
      options.headers.remove('Authorization');
      final token = prefs.getString('access_token');
      if (!options.path.startsWith('auth/') &&
          token != null &&
          token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      handler.next(options);
    }, onError: (error, handler) async {
      final request = error.requestOptions;
      if (error.response?.statusCode != 401 ||
          request.path.startsWith('auth/') ||
          request.extra['retried'] == true) {
        handler.next(error);
        return;
      }
      try {
        final prefs = await SharedPreferences.getInstance();
        if (request.extra['sessionUser'] != prefs.getString('username')) {
          handler.next(error);
          return;
        }
        final currentToken = prefs.getString('access_token');
        final failedToken = request.headers['Authorization'];
        String? token;
        if (currentToken != null && failedToken != 'Bearer $currentToken') {
          token = currentToken;
        } else {
          _refreshing ??= _refresh();
          final refreshing = _refreshing!;
          try {
            token = await refreshing;
          } finally {
            if (identical(_refreshing, refreshing)) _refreshing = null;
          }
        }
        if (token != null &&
            request.extra['sessionUser'] == prefs.getString('username') &&
            request.baseUrl == await ApiConfig.getBaseUrl()) {
          final response = await _dio.fetch(request.copyWith(
            headers: {...request.headers, 'Authorization': 'Bearer $token'},
            extra: {...request.extra, 'retried': true},
            data: request.data is FormData
                ? (request.data as FormData).clone()
                : request.data,
          ));
          handler.resolve(response);
          return;
        }
      } catch (_) {
        /* Preserve the original request error. Never retry mutations blindly. */
      }
      handler.next(error);
    }));
  }

  Future<String?> _refresh() async {
    final prefs = await SharedPreferences.getInstance();
    final base = await ApiConfig.getBaseUrl();
    final refresh = prefs.getString('refresh_token');
    if (refresh == null || refresh.isEmpty) {
      onSessionExpired?.call();
      return null;
    }
    try {
      final response = await _refreshDio.post('${base}auth/refresh-token',
          options: Options(headers: {'X-Refresh-Token': refresh}));
      final data = response.data is Map ? response.data['data'] : null;
      if (data is! Map ||
          data['accessToken'] is! String ||
          (data['accessToken'] as String).isEmpty) {
        throw const FormatException('Không nhận được token mới.');
      }
      // Logout, account switch and server changes invalidate the in-flight refresh.
      if (prefs.getString('refresh_token') != refresh ||
          await ApiConfig.getBaseUrl() != base) return null;
      await Future.wait([
        prefs.setString('access_token', data['accessToken']),
        if (data['refreshToken'] is String)
          prefs.setString('refresh_token', data['refreshToken'])
      ]);
      return data['accessToken'];
    } on DioException catch (error) {
      if ([400, 401, 403, 409].contains(error.response?.statusCode) &&
          prefs.getString('refresh_token') == refresh &&
          await ApiConfig.getBaseUrl() == base) {
        await prefs.remove('access_token');
        await prefs.remove('refresh_token');
        onSessionExpired?.call();
      }
      return null;
    }
  }

  Future<void> updateBaseUrl(String newUrl) async {
    final old = await ApiConfig.getBaseUrl();
    final normalized = ApiConfig.normalizeBaseUrl(newUrl);
    if (old != normalized) {
      final prefs = await SharedPreferences.getInstance();
      await Future.wait([
        prefs.remove('access_token'),
        prefs.remove('refresh_token'),
        prefs.remove('username')
      ]);
      onSessionExpired?.call();
    }
    await ApiConfig.setBaseUrl(normalized);
    _dio.options.baseUrl = normalized;
  }
}
