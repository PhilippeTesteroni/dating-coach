import '../../core/constants/api_endpoints.dart';
import '../api/api_client.dart';
import '../models/user_balance.dart';

/// Репозиторий пользователя
/// 
/// Работает с API для получения данных пользователя
class UserRepository {
  final ApiClient _apiClient;

  UserRepository(this._apiClient);

  /// Получить баланс пользователя
  Future<UserBalance> getBalance() async {
    final response = await _apiClient.get(ApiEndpoints.userBalance);
    return UserBalance.fromJson(response);
  }
}
