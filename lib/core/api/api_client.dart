import 'package:dio/dio.dart';
import 'endpoints.dart';

/// Wraps all recoverable API error states.
class AppException implements Exception {
  const AppException(this.message, {this.statusCode});
  final String message;
  final int? statusCode;

  @override
  String toString() => 'AppException($statusCode): $message';
}

/// Dio-backed HTTP client for the WorldCup26 API.
///
/// Authentication: the API currently accepts unauthenticated GET requests.
/// A JWT interceptor is wired in [_setupJwtInterceptor] (no-op by default).
/// Call [enableJwt] with a token if the API starts requiring authentication.
class ApiClient {
  ApiClient({Dio? dio}) : _dio = dio ?? _buildDio();

  final Dio _dio;

  static Dio _buildDio() {
    final d = Dio(BaseOptions(
      baseUrl: Endpoints.baseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 30),
      headers: {'Accept': 'application/json'},
    ));
    return d;
  }

  /// Optionally enable JWT auth (no-op unless called).
  void enableJwt(String token) {
    _dio.interceptors.removeWhere((i) => i is _JwtInterceptor);
    _dio.interceptors.add(_JwtInterceptor(token));
  }

  Future<Map<String, dynamic>> get(String path) async {
    try {
      final res = await _dio.get<dynamic>(path);
      final data = res.data;
      if (data is Map<String, dynamic>) return data;
      throw const AppException('Unexpected response body type');
    } on DioException catch (e) {
      throw AppException(
        e.message ?? 'Network error',
        statusCode: e.response?.statusCode,
      );
    }
  }
}

class _JwtInterceptor extends Interceptor {
  _JwtInterceptor(this._token);
  final String _token;

  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    options.headers['Authorization'] = 'Bearer $_token';
    handler.next(options);
  }
}
