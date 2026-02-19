import '../../core/constants/api_endpoints.dart';
import '../api/api_client.dart';
import '../models/subscription_status.dart';

/// Репозиторий подписки
class SubscriptionRepository {
  final ApiClient _apiClient;

  SubscriptionRepository(this._apiClient);

  /// Получить статус подписки и free-tier
  Future<SubscriptionStatus> getSubscriptionStatus() async {
    final response = await _apiClient.get(ApiEndpoints.userSubscription);
    return SubscriptionStatus.fromJson(response);
  }

  /// Верифицировать покупку подписки
  Future<Map<String, dynamic>> verifySubscription({
    required String productId,
    required String purchaseToken,
    String platform = 'google_play',
    String? basePlanId,
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.subscriptionVerify,
      data: {
        'product_id': productId,
        'purchase_token': purchaseToken,
        'platform': platform,
        if (basePlanId != null) 'base_plan_id': basePlanId,
      },
    );
    return response;
  }
}
