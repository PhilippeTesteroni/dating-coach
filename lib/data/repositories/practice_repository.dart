import '../api/api_client.dart';
import '../models/training_progress.dart';
import '../models/training_attempt_preview.dart';
import '../../core/constants/api_endpoints.dart';

/// Репозиторий для работы с прогрессом тренировок
class PracticeRepository {
  final ApiClient _apiClient;

  PracticeRepository(this._apiClient);

  /// Получить полный прогресс пользователя
  Future<TrainingProgress> getProgress() async {
    final response = await _apiClient.get(ApiEndpoints.practiceProgress);
    return TrainingProgress.fromJson(response);
  }

  /// Инициализировать прогресс после завершения пре-тренинга
  Future<void> initialize() async {
    await _apiClient.post(ApiEndpoints.practiceInitialize);
  }

  /// Оценить завершённый тренировочный разговор
  Future<Map<String, dynamic>> evaluate({
    required String conversationId,
    required String submodeId,
    required int difficultyLevel,
  }) async {
    return _apiClient.post(
      ApiEndpoints.practiceEvaluate,
      data: {
        'conversation_id': conversationId,
        'submode_id': submodeId,
        'difficulty_level': difficultyLevel,
      },
    );
  }

  /// Получить историю тренировок
  Future<List<TrainingAttemptPreview>> getHistory() async {
    final response = await _apiClient.get(ApiEndpoints.practiceHistory);
    final list = response['attempts'] as List;
    return list.map((j) => TrainingAttemptPreview.fromJson(j as Map<String, dynamic>)).toList();
  }

  /// Удалить попытку тренировки из истории
  Future<void> deleteAttempt(String attemptId) async {
    await _apiClient.delete(ApiEndpoints.practiceDeleteAttempt(attemptId));
  }
}
