/// API endpoints для Dating Coach
/// 
/// Все запросы идут ТОЛЬКО на dating-coach-api,
/// который проксирует к внутренним сервисам
abstract class ApiEndpoints {
  /// Base URL для API
  /// TODO: Вынести в .env или flavor config
  static const String baseUrl = 'https://api.dating-coach.app';
  
  /// Development URL
  static const String devBaseUrl = 'http://localhost:8007';
  
  // ============ Auth ============
  
  /// Регистрация нового пользователя
  /// POST /api/v1/auth/register
  /// Body: { "device_id": "uuid", "platform": "android" }
  /// Response: { "user_id": "uuid", "token": "jwt" }
  static const String authRegister = '/api/v1/auth/register';
  
  /// Логин существующего пользователя
  /// POST /api/v1/auth/login
  /// Body: { "device_id": "uuid" }
  /// Response: { "user_id": "uuid", "token": "jwt" }
  static const String authLogin = '/api/v1/auth/login';
  
  // ============ User ============
  
  /// Получить профиль пользователя
  /// GET /api/v1/user/profile
  static const String userProfile = '/api/v1/user/profile';
  
  /// Обновить профиль пользователя
  /// PATCH /api/v1/user/profile
  static const String userProfileUpdate = '/api/v1/user/profile';
  
  // ============ Chat ============
  
  /// Создать новую сессию чата
  /// POST /api/v1/chat/session
  static const String chatSession = '/api/v1/chat/session';
  
  /// Отправить сообщение
  /// POST /api/v1/chat/message
  static const String chatMessage = '/api/v1/chat/message';
  
  /// Получить историю чата
  /// GET /api/v1/chat/history/{session_id}
  static String chatHistory(String sessionId) => '/api/v1/chat/history/$sessionId';
}
