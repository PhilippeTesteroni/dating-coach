import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/utils/device_id.dart';
import '../data/api/api_client.dart';
import '../data/models/user_session.dart';
import '../data/repositories/auth_repository.dart';

/// Сервис авторизации
/// 
/// Управляет сессией пользователя:
/// - Первый запуск → register
/// - Повторные запуски → login
class AuthService {
  static const String _sessionKey = 'user_session';
  
  final AuthRepository _authRepository;
  final ApiClient _apiClient;
  
  UserSession? _currentSession;

  AuthService({
    required AuthRepository authRepository,
    required ApiClient apiClient,
  })  : _authRepository = authRepository,
        _apiClient = apiClient;

  /// Текущая сессия
  UserSession? get currentSession => _currentSession;

  /// Авторизован ли пользователь
  bool get isAuthenticated => _currentSession != null && !_currentSession!.isExpired;

  /// Инициализация сессии
  /// 
  /// Вызывается при запуске приложения
  /// - Если есть сохранённая сессия → login
  /// - Если нет → register
  Future<UserSession> initSession() async {
    // Пробуем загрузить сохранённую сессию
    final savedSession = await _loadSession();
    debugPrint('🔐 Saved session: ${savedSession?.userId}, expired: ${savedSession?.isExpired}');
    
    if (savedSession != null && !savedSession.isExpired) {
      // Есть валидная сессия — делаем login для обновления токена
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
        // Если login не удался — пробуем register
        debugPrint('🔐 Login failed: $e, falling back to register');
        return _registerNewUser();
      }
    }
    
    // Нет сессии или истекла — регистрируем нового пользователя
    debugPrint('🔐 No valid session, registering new user');
    return _registerNewUser();
  }

  /// Регистрация нового пользователя
  Future<UserSession> _registerNewUser() async {
    final deviceId = await DeviceId.get();
    debugPrint('🔐 Registering with deviceId: $deviceId');
    
    final session = await _authRepository.register(
      deviceId: deviceId,
    );
    debugPrint('🔐 Registered new user: ${session.userId}');
    
    await _saveSession(session);
    _currentSession = session;
    _apiClient.setAuthToken(session.token);
    
    return session;
  }

  /// Сохранить сессию в SharedPreferences
  Future<void> _saveSession(UserSession session) async {
    final prefs = await SharedPreferences.getInstance();
    final json = jsonEncode(session.toJson());
    await prefs.setString(_sessionKey, json);
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
      // Corrupted data — clear and return null
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
