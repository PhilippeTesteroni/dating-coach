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
  
  // ============ Settings ============
  
  /// Получить настройки приложения
  /// GET /api/v1/settings
  /// Response: { "app_id": "dating_coach", "credit_cost": 1, ... }
  static const String settings = '/api/v1/settings';
  
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
  
  // ============ Characters ============
  
  /// Получить список персонажей
  /// GET /api/v1/characters?preferred_gender={all|male|female}
  /// Response: { "characters": [...] }
  static const String characters = '/api/v1/characters';
  
  // ============ Conversations ============
  
  /// Создать новую беседу
  /// POST /api/v1/conversations
  /// Body: { "submode_id": "open_chat", "character_id": "anna", "language": "ru" }
  /// Response: { "id": "uuid", "mode_id": "...", ... }
  static const String conversations = '/api/v1/conversations';
  
  /// Получить список бесед (история)
  /// GET /api/v1/conversations?submode_id=open_chat
  /// Response: { "conversations": [...] }
  static String conversationsList(String submodeId) => '/api/v1/conversations?submode_id=$submodeId';
  
  /// Получить сообщения беседы
  /// GET /api/v1/conversations/{id}/messages
  static String conversationMessages(String id) => '/api/v1/conversations/$id/messages';
  
  /// Отправить сообщение в беседу
  /// POST /api/v1/conversations/{id}/messages
  /// Body: { "content": "..." }
  /// Response: { "user_message": {...}, "assistant_message": {...} }
  static String sendMessage(String conversationId) => '/api/v1/conversations/$conversationId/messages';

  /// Удалить одну беседу
  /// DELETE /api/v1/conversations/{id}
  /// Response: 204 No Content
  static String conversationDelete(String id) => '/api/v1/conversations/$id';

  /// Удалить все беседы пользователя
  /// DELETE /api/v1/conversations
  /// Response: { "deleted_count": N }
  static const String conversationsDeleteAll = '/api/v1/conversations';
}
