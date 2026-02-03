import '../api/api_client.dart';
import '../models/app_settings.dart';
import '../../core/constants/api_endpoints.dart';

/// Репозиторий для получения настроек приложения
class AppSettingsRepository {
  final ApiClient _apiClient;

  AppSettingsRepository(this._apiClient);

  /// Получить настройки приложения
  Future<AppSettings> getSettings() async {
    final response = await _apiClient.get(ApiEndpoints.settings);
    return AppSettings.fromJson(response);
  }
}
