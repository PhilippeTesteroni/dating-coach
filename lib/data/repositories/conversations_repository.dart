import '../api/api_client.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../../core/constants/api_endpoints.dart';

/// Репозиторий для работы с беседами
class ConversationsRepository {
  final ApiClient _apiClient;

  ConversationsRepository(this._apiClient);

  /// Создать новую беседу
  /// 
  /// [submodeId] — режим (open_chat, first_contact, etc.)
  /// [characterId] — ID персонажа (обязателен для character modes)
  /// [language] — язык беседы (default: en)
  Future<Conversation> createConversation({
    required String submodeId,
    String? characterId,
    String language = 'en',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.conversations,
      data: {
        'submode_id': submodeId,
        if (characterId != null) 'character_id': characterId,
        'language': language,
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
}

/// Результат отправки сообщения
class SendMessageResult {
  final Message userMessage;
  final Message assistantMessage;
  final int? newBalance;

  const SendMessageResult({
    required this.userMessage,
    required this.assistantMessage,
    this.newBalance,
  });
}
