import '../api/api_client.dart';
import '../models/conversation.dart';
import '../models/conversation_preview.dart';
import '../models/message.dart';
import '../../core/constants/api_endpoints.dart';

/// Репозиторий для работы с беседами
class ConversationsRepository {
  final ApiClient _apiClient;

  ConversationsRepository(this._apiClient);

  /// Получить список бесед для режима
  Future<List<ConversationPreview>> getConversations(String submodeId) async {
    final response = await _apiClient.get(
      ApiEndpoints.conversationsList(submodeId),
    );
    final list = response['conversations'] as List;
    return list.map((j) => ConversationPreview.fromJson(j)).toList();
  }

  /// Получить greeting без создания беседы
  Future<String> getGreeting({
    required String submodeId,
    String? characterId,
    String language = 'en',
    int? difficultyLevel,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.conversationsGreeting,
      data: {
        'submode_id': submodeId,
        if (characterId != null) 'character_id': characterId,
        'language': language,
      },
    );
    return response['content'] as String? ?? '';
  }

  /// Создать новую беседу
  /// 
  /// [submodeId] — режим (open_chat, first_contact, etc.)
  /// [characterId] — ID персонажа (обязателен для character modes)
  /// [difficultyLevel] — уровень сложности 1–3 (только для training modes)
  /// [language] — язык беседы (default: en)
  /// [seedMessage] — greeting для сохранения в историю
  Future<Conversation> createConversation({
    required String submodeId,
    String? characterId,
    int? difficultyLevel,
    String language = 'en',
    String? seedMessage,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.conversations,
      data: {
        'submode_id': submodeId,
        if (characterId != null) 'character_id': characterId,
        if (difficultyLevel != null) 'difficulty_level': difficultyLevel,
        'language': language,
        if (seedMessage != null) 'seed_message': seedMessage,
      },
    );
    return Conversation.fromJson(response);
  }

  /// Получить сообщения беседы
  Future<List<Message>> getMessages(String conversationId) async {
    final response = await _apiClient.get(
      ApiEndpoints.conversationMessages(conversationId),
    );
    final messages = response['messages'] as List;
    return messages.map((m) => Message.fromJson(m)).toList();
  }

  /// Отправить сообщение
  /// 
  /// Возвращает пару [userMessage, assistantMessage] + new_balance
  Future<SendMessageResult> sendMessage({
    required String conversationId,
    required String content,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.sendMessage(conversationId),
      data: {'content': content},
    );
    return SendMessageResult(
      userMessage: Message.fromJson(response['user_message']),
      assistantMessage: Message.fromJson(response['assistant_message']),
      newBalance: response['new_balance'] as int?,
    );
  }

  /// Удалить одну беседу
  Future<void> deleteConversation(String id) async {
    await _apiClient.delete(ApiEndpoints.conversationDelete(id));
  }

  /// Удалить все беседы пользователя
  Future<int> deleteAllConversations() async {
    final response = await _apiClient.delete(ApiEndpoints.conversationsDeleteAll);
    return response['deleted_count'] as int;
  }
}

/// Результат отправки сообщения
class SendMessageResult {
  final Message userMessage;
  final Message assistantMessage;
  final int? newBalance; // legacy, may be null for subscription-based apps

  const SendMessageResult({
    required this.userMessage,
    required this.assistantMessage,
    this.newBalance,
  });
}
