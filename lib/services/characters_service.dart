import '../data/api/api_client.dart';
import '../data/models/character.dart';
import '../data/repositories/characters_repository.dart';

/// Сервис для работы с персонажами
/// 
/// Синглтон с кэшированием:
/// - Кэширует персонажей до перезапуска приложения
/// - Инвалидируется при смене preferredGender
class CharactersService {
  static final CharactersService _instance = CharactersService._internal();
  factory CharactersService() => _instance;
  CharactersService._internal();

  List<Character>? _characters;
  String? _loadedForGender;
  Character? _coach;
  ApiClient? _apiClient;

  /// Инициализация с ApiClient
  void init(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  /// Получить персонажей (из кэша или с сервера)
  /// 
  /// [preferredGender] - 'male', 'female', 'all'
  /// [forceRefresh] - принудительно обновить с сервера
  Future<List<Character>> getCharacters({
    required String preferredGender,
    bool forceRefresh = false,
  }) async {
    // Возвращаем из кэша если параметры совпадают
    if (!forceRefresh && 
        _characters != null && 
        _loadedForGender == preferredGender) {
      return _characters!;
    }

    // Загружаем с сервера
    if (_apiClient == null) {
      throw StateError('CharactersService not initialized. Call init() first.');
    }

    final repo = CharactersRepository(_apiClient!);
    final allCharacters = await repo.getCharacters(preferredGender: preferredGender);
    
    // Фильтруем: только персонажи (не коуч)
    _characters = allCharacters.where((c) => c.isCharacter).toList();
    _loadedForGender = preferredGender;

    return _characters!;
  }

  /// Сбросить кэш
  /// 
  /// Вызывать при изменении профиля пользователя
  void invalidate() {
    _characters = null;
    _loadedForGender = null;
    _coach = null;
  }

  /// Проверить, закэшированы ли персонажи для данного gender
  bool isCached(String preferredGender) {
    return _characters != null && _loadedForGender == preferredGender;
  }

  /// Получить закэшированных персонажей (без загрузки)
  List<Character>? get cachedCharacters => _characters;

  /// Получить коуча Хитча (из кэша или с сервера)
  Future<Character> getCoach() async {
    if (_coach != null) return _coach!;

    if (_apiClient == null) {
      throw StateError('CharactersService not initialized. Call init() first.');
    }

    final repo = CharactersRepository(_apiClient!);
    final allCharacters = await repo.getCharacters(preferredGender: 'all');

    final coach = allCharacters.firstWhere(
      (c) => c.isCoach,
      orElse: () => throw StateError('Coach character (Hitch) not found'),
    );

    _coach = coach;
    return _coach!;
  }
}
