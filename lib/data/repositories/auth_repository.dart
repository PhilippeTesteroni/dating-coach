import 'dart:io';
import '../../core/constants/api_endpoints.dart';
import '../api/api_client.dart';
import '../models/user_session.dart';

/// Репозиторий авторизации
/// 
/// Работает с API для register/login
class AuthRepository {
  final ApiClient _apiClient;

  AuthRepository(this._apiClient);

  /// Регистрация нового пользователя
  /// 
  /// Вызывается при первом запуске приложения
  Future<UserSession> register({
    required String deviceId,
    String? platform,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.authRegister,
      data: {
        'device_id': deviceId,
        'platform': platform ?? _getPlatform(),
      },
    );

    final session = UserSession.fromJson(response, deviceId);
    
    // Устанавливаем токен в клиент
    _apiClient.setAuthToken(session.token);
    
    return session;
  }

  /// Логин существующего пользователя
  /// 
  /// Вызывается при повторных запусках
  Future<UserSession> login({
    required String deviceId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.authLogin,
      data: {
        'device_id': deviceId,
      },
    );

    final session = UserSession.fromJson(response, deviceId);
    
    // Устанавливаем токен в клиент
    _apiClient.setAuthToken(session.token);
    
    return session;
  }

  /// Определить платформу
  String _getPlatform() {
    if (Platform.isAndroid) return 'android';
    if (Platform.isIOS) return 'ios';
    return 'unknown';
  }
}
