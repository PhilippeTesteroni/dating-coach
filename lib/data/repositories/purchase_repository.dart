import '../../core/constants/api_endpoints.dart';
import '../api/api_client.dart';

/// Результат верификации покупки
class VerifyPurchaseResult {
  final bool success;
  final int creditsAdded;
  final int newBalance;

  VerifyPurchaseResult({
    required this.success,
    required this.creditsAdded,
    required this.newBalance,
  });

  factory VerifyPurchaseResult.fromJson(Map<String, dynamic> json) {
    return VerifyPurchaseResult(
      success: json['success'] ?? false,
      creditsAdded: json['credits_added'] ?? 0,
      newBalance: json['new_balance'] ?? 0,
    );
  }
}

/// Репозиторий покупок
class PurchaseRepository {
  final ApiClient _apiClient;

  PurchaseRepository(this._apiClient);

  /// Верифицировать покупку Google Play
  Future<VerifyPurchaseResult> verifyPurchase({
    required String productId,
    required String purchaseToken,
    String platform = 'google_play',
  }) async {
    final response = await _apiClient.post(
      ApiEndpoints.purchaseVerify,
      body: {
        'product_id': productId,
        'purchase_token': purchaseToken,
        'platform': platform,
      },
    );
    return VerifyPurchaseResult.fromJson(response);
  }
}
