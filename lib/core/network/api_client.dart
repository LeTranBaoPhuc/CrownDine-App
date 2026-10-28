import 'package:dio/dio.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';
import 'api_endpoints.dart';

class ApiClient {
  static ApiClient? _instance;
  late Dio _dio;
  bool _isRefreshing = false;

  ApiClient._internal() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.defaultBaseUrl,
        connectTimeout: const Duration(seconds: 8),
        receiveTimeout: const Duration(seconds: 8),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final prefs = await SharedPreferences.getInstance();
          final token = prefs.getString('access_token');
          if (token != null && token.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          final customUrl = await ApiConfig.getBaseUrl();
          if (customUrl != options.baseUrl) {
            options.baseUrl = customUrl;
          }
          return handler.next(options);
        },
        onError: (DioException error, handler) async {
          // If request returned 401 and it's not an auth call
          final path = error.requestOptions.path;
          final isAuthCall = path.contains(ApiEndpoints.login) ||
              path.contains(ApiEndpoints.refreshToken) ||
              path.contains(ApiEndpoints.register);

          if (error.response?.statusCode == 401 && !isAuthCall && !_isRefreshing) {
            _isRefreshing = true;
            try {
              final prefs = await SharedPreferences.getInstance();
              final refreshToken = prefs.getString('refresh_token');

              if (refreshToken != null && refreshToken.isNotEmpty) {
                final refreshBaseUrl = await ApiConfig.getBaseUrl();
                // Create a standalone Dio instance without this interceptor to avoid loops
                final refreshDio = Dio(
                  BaseOptions(
                    baseUrl: refreshBaseUrl,
                    connectTimeout: const Duration(seconds: 8),
                  ),
                );

                final refreshRes = await refreshDio.post(
                  ApiEndpoints.refreshToken,
                  options: Options(
                    headers: {'X-Refresh-Token': refreshToken},
                  ),
                );

                if (refreshRes.statusCode == 200 && refreshRes.data != null) {
                  final data = refreshRes.data['data'] ?? refreshRes.data;
                  final newAccessToken = data['accessToken'] ?? '';
                  final newRefreshToken = data['refreshToken'] ?? refreshToken;

                  if (newAccessToken.isNotEmpty) {
                    await prefs.setString('access_token', newAccessToken);
                    await prefs.setString('refresh_token', newRefreshToken);

                    // Retry original request with new access token
                    final opts = error.requestOptions;
                    opts.headers['Authorization'] = 'Bearer $newAccessToken';

                    final cloneReq = await _dio.request(
                      opts.path,
                      options: Options(
                        method: opts.method,
                        headers: opts.headers,
                        contentType: opts.contentType,
                        responseType: opts.responseType,
                      ),
                      data: opts.data,
                      queryParameters: opts.queryParameters,
                    );
                    _isRefreshing = false;
                    return handler.resolve(cloneReq);
                  }
                }
              }
            } catch (_) {
              // Refresh failed or revoked, clear stored tokens
              final prefs = await SharedPreferences.getInstance();
              await prefs.remove('access_token');
              await prefs.remove('refresh_token');
            } finally {
              _isRefreshing = false;
            }
          }

          return handler.next(error);
        },
      ),
    );
  }

  static ApiClient get instance {
    _instance ??= ApiClient._internal();
    return _instance!;
  }

  Dio get dio => _dio;

  Future<void> updateBaseUrl(String newUrl) async {
    _dio.options.baseUrl = newUrl;
    await ApiConfig.setBaseUrl(newUrl);
  }
}
