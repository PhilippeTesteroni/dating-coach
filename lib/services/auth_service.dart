import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/device_info_service.dart';
import '../data/api/api_client.dart';
import '../data/models/user_session.dart';
import '../data/repositories/auth_repository.dart';

/// Сервис авторизации
///
/// Управляет сессией пользователя:
/// - Первый запуск → register
/// - Повторные запуски → login
/// - Очистка данных приложения → тот же device_id из secure storage → тот же пользователь
class AuthService {
  static const String _sessionKey = 'user_session';

  final AuthRepository _authRepository;
  final ApiClient _apiClient;
  final DeviceInfoService _deviceInfoService;

  UserSession? _currentSession;

  AuthService({
    required AuthRepository authRepository,
    required ApiClient apiClient,
    required DeviceInfoService deviceInfoService,
  })  : _authRepository = authRepository,
        _apiClient = apiClient,
        _deviceInfoService = deviceInfoService;

  /// Текущая сессия
  UserSession? get currentSession => _currentSession;

  /// Авторизован ли пользователь
  bool get isAuthenticated => _currentSession != null && !_currentSession!.isExpired;

  /// Инициализация сессии
  ///
  /// Вызывается при запуске приложения.
  /// - Если есть сохранённая сессия → login с тем же device_id
  /// - Если нет → register (device_id берётся из hardware, не генерируется заново)
  Future<UserSession> initSession() async {
    final savedSession = await _loadSession();
    debugPrint('🔐 Saved session: ${savedSession?.userId}, expired: ${savedSession?.isExpired}');

    if (savedSession != null && !savedSession.isExpired) {
      try {
        debugPrint('🔐 Trying login with deviceId: ${savedSession.deviceId}');
        final session = await _authRepository.login(
          deviceId: savedSession.deviceId,
        );
        debugPrint('🔐 Login success: ${session.userId}');
        await _saveSession(session);
        _currentSession = session;
        _apiClient.setAuthToken(session.token);
        return session;
      } catch (e) {
        debugPrint('🔐 Login failed: $e, falling back to register');
        return _registerUser();
      }
    }

    debugPrint('🔐 No valid session, registering user');
    return _registerUser();
  }

  /// Регистрация / восстановление пользователя по device_id
  ///
  /// Identity Service вернёт существующего пользователя если device_id уже известен.
  Future<UserSession> _registerUser() async {
    final deviceId = await _deviceInfoService.getDeviceId();
    debugPrint('🔐 Registering with deviceId: $deviceId');

    final session = await _authRepository.register(deviceId: deviceId);
    debugPrint('🔐 User: ${session.userId}');

    await _saveSession(session);
    _currentSession = session;
    _apiClient.setAuthToken(session.token);

    return session;
  }

  /// Сохранить сессию в SharedPreferences
  Future<void> _saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_sessionKey, jsonEncode(session.toJson()));
  }

  /// Загрузить сессию из SharedPreferences
  Future<UserSession?> _loadSession() async {
    final prefs = await SharedPreferences.getInstance();
    final json = prefs.getString(_sessionKey);
    if (json == null) return null;

    try {
      final data = jsonDecode(json) as Map<String, dynamic>;
      return UserSession(
        userId: data['user_id'] as String,
        token: data['token'] as String,
        deviceId: data['device_id'] as String,
        expiresAt: data['expires_at'] != null
            ? DateTime.parse(data['expires_at'] as String)
            : null,
      );
    } catch (e) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionKey);
      return null;
    }
  }

  /// Выход из аккаунта
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_sessionKey);
    _apiClient.clearAuthToken();
    _currentSession = null;
  }
}
