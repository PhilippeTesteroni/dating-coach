import '../data/models/training_progress.dart';
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

  PracticeRepository get _repo =>
      PracticeRepository(UserService().apiClient);

  TrainingProgress? get progress => _progress;

  bool get onboardingComplete => _progress?.onboardingComplete ?? false;

  /// Загрузить прогресс с сервера (кэширует результат)
  Future<TrainingProgress> loadProgress() async {
    _progress = await _repo.getProgress();
    return _progress!;
  }

  /// Инициализировать прогресс после пре-тренинга
  Future<void> initialize() async {
    await _repo.initialize();
    _progress = null; // сбросить кэш — следующий loadProgress подтянет свежие данные
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
  }
}
