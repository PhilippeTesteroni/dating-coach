/// API endpoints для Dating Coach
/// 
/// Все запросы идут ТОЛЬКО на dating-coach-api,
/// который проксирует к внутренним сервисам
abstract class ApiEndpoints {
  /// Base URL для API (Render production)
  static const String baseUrl = 'https://dating-coach-api-tp7h.onrender.com';
  
  /// Development URL (use baseUrl for real device testing)
  static const String devBaseUrl = 'https://dating-coach-api-tp7h.onrender.com';
  
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
  
  /// Получить баланс пользователя
  /// GET /api/v1/user/balance
  /// Response: { "balance": 12 }
  static const String userBalance = '/api/v1/user/balance';
  
  // ============ Purchase ============
  
  /// Верифицировать покупку
  /// POST /api/v1/purchase/verify
  /// Body: { "product_id": "credits_10", "purchase_token": "...", "platform": "google_play" }
  /// Response: { "success": true, "credits_added": 10, "new_balance": 22 }
  static const String purchaseVerify = '/api/v1/purchase/verify';
  
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
