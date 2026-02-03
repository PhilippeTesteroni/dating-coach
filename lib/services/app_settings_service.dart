import '../data/api/api_client.dart';
import '../data/models/app_settings.dart';
import '../data/repositories/app_settings_repository.dart';

/// Сервис настроек приложения
/// 
/// Синглтон с кэшированием:
/// - Загружается на splash screen
/// - Кэшируется на всё время работы приложения
class AppSettingsService {
  static final AppSettingsService _instance = AppSettingsService._internal();
  factory AppSettingsService() => _instance;
  AppSettingsService._internal();

  AppSettings? _settings;
  ApiClient? _apiClient;

  /// Текущие настройки
  AppSettings? get settings => _settings;

  /// Стоимость сообщения в кредитах
  int get creditCost => _settings?.creditCost ?? 1;

  /// Welcome bonus для новых пользователей
  int get welcomeBonus => _settings?.welcomeBonus ?? 0;

  /// Пакеты кредитов для покупки
  List<CreditPackage>? get creditPackages => _settings?.creditPackages;

  /// Инициализация с ApiClient
  void init(ApiClient apiClient) {
    _apiClient = apiClient;
  }

  /// Загрузить настройки с сервера
  Future<AppSettings?> loadSettings() async {
    if (_apiClient == null) {
      throw StateError('AppSettingsService not initialized. Call init() first.');
    }

    try {
      final repo = AppSettingsRepository(_apiClient!);
      _settings = await repo.getSettings();
      return _settings;
    } catch (e) {
      // При ошибке возвращаем null, используем дефолты
      return null;
    }
  }

  /// Проверить, загружены ли настройки
  bool get isLoaded => _settings != null;
}
