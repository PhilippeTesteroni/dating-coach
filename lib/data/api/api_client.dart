import 'package:dio/dio.dart';
import '../../core/constants/api_endpoints.dart';

/// HTTP клиент для Dating Coach API
/// 
/// Единая точка входа для всех запросов к бэкенду
class ApiClient {
  late final Dio _dio;
  String? _authToken;

  ApiClient({String? baseUrl}) {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl ?? ApiEndpoints.devBaseUrl,
      connectTimeout: const Duration(seconds: 10),
      receiveTimeout: const Duration(seconds: 10),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ));

    // Interceptor для добавления токена
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) {
        if (_authToken != null) {
          options.headers['Authorization'] = 'Bearer $_authToken';
        }
        return handler.next(options);
      },
      onError: (error, handler) {
        // TODO: Handle 401 — refresh token or logout
        return handler.next(error);
      },
    ));
  }

  /// Установить токен авторизации
  void setAuthToken(String token) {
    _authToken = token;
  }

  /// Очистить токен авторизации
  void clearAuthToken() {
    _authToken = null;
  }

  /// POST запрос
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.post(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// GET запрос
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, dynamic>? queryParameters,
  }) async {
    try {
      final response = await _dio.get(path, queryParameters: queryParameters);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// PATCH запрос
  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? data,
  }) async {
    try {
      final response = await _dio.patch(path, data: data);
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// DELETE запрос
  /// Возвращает body если есть, пустую map если 204
  Future<Map<String, dynamic>> delete(String path) async {
    try {
      final response = await _dio.delete(path);
      if (response.statusCode == 204 || response.data == null || response.data is! Map) {
        return {};
      }
      return response.data as Map<String, dynamic>;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Обработка ошибок Dio
  ApiException _handleError(DioException e) {
    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return ApiException('Connection timeout', code: 'TIMEOUT');
      
      case DioExceptionType.connectionError:
        return ApiException('No internet connection', code: 'NO_CONNECTION');
      
      case DioExceptionType.badResponse:
        final statusCode = e.response?.statusCode;
        final message = e.response?.data?['detail'] ?? 'Server error';
        return ApiException(message, code: 'HTTP_$statusCode', statusCode: statusCode);
      
      default:
        return ApiException('Unknown error', code: 'UNKNOWN');
    }
  }
}

/// Исключение API
class ApiException implements Exception {
  final String message;
  final String code;
  final int? statusCode;

  ApiException(this.message, {required this.code, this.statusCode});

  @override
  String toString() => 'ApiException: [$code] $message';
}
