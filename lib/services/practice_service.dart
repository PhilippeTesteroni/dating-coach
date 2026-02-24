import '../data/models/training_attempt_preview.dart';
import '../data/models/training_meta.dart';
import '../data/models/training_progress.dart';
import '../data/models/scenario_info.dart';
import '../data/repositories/practice_repository.dart';
import 'user_service.dart';

/// Сервис тренировок
///
/// Кэширует прогресс локально, обновляет после evaluate/initialize.
class PracticeService {
  static final PracticeService _instance = PracticeService._internal();
  factory PracticeService() => _instance;
  PracticeService._internal();

  TrainingProgress? _progress;
  final Map<String, ScenarioInfo> _scenarioCache = {};

  PracticeRepository get _repo =>
      PracticeRepository(UserService().apiClient);

  TrainingProgress? get progress => _progress;

  /// Загрузить прогресс с сервера (кэширует результат).
  /// Параллельно подгружает scenario info для всех trainings.
  Future<TrainingProgress> loadProgress() async {
    _progress = await _repo.getProgress();
    // Prefetch scenarios in background — don't block progress
    _prefetchScenarios();
    return _progress!;
  }

  void _prefetchScenarios() {
    for (final t in kTrainings) {
      if (!_scenarioCache.containsKey(t.submodeId)) {
        getScenarioInfo(t.submodeId).catchError((_) => null);
      }
    }
  }

  /// Оценить разговор. Возвращает сырой ответ сервера.
  Future<Map<String, dynamic>> evaluate({
    required String conversationId,
    required String submodeId,
    required int difficultyLevel,
  }) async {
    final result = await _repo.evaluate(
      conversationId: conversationId,
      submodeId: submodeId,
      difficultyLevel: difficultyLevel,
    );
    _progress = null; // сбросить кэш — могли разблокироваться новые уровни
    return result;
  }

  /// Сбросить кэш (например, при logout)
  void clear() {
    _progress = null;
    _scenarioCache.clear();
  }

  /// Получить историю тренировочных разговоров
  Future<List<TrainingConversationPreview>> getHistory() async {
    return _repo.getHistory();
  }

  /// Удалить тренировочный разговор из истории
  Future<void> deleteConversation(String conversationId) async {
    await _repo.deleteConversation(conversationId);
  }

  /// Получить информацию о scenario (description + message limits).
  /// Кэширует результат — повторные вызовы мгновенны.
  Future<ScenarioInfo> getScenarioInfo(String submodeId) async {
    final cached = _scenarioCache[submodeId];
    if (cached != null) return cached;
    final info = await _repo.getScenarioInfo(submodeId);
    _scenarioCache[submodeId] = info;
    return info;
  }

  /// Получить message_limit для уровня сложности
  Future<int?> getMessageLimit(String submodeId, int difficultyLevel) async {
    final info = await getScenarioInfo(submodeId);
    return info.messageLimit(difficultyLevel);
  }
}
