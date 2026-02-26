import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

/// Результат покупки подписки
class SubscriptionPurchaseResult {
  final bool success;
  final String? purchaseToken;
  final String? productId;
  final String? error;

  const SubscriptionPurchaseResult({
    required this.success,
    this.purchaseToken,
    this.productId,
    this.error,
  });
}

/// Google Play Billing service для подписок Dating Coach
///
/// Product ID: week_subscription (единый в Google Play Console)
/// Base plans: 01 (weekly), 02 (monthly)
///
/// queryProductDetails для подписки возвращает список
/// GooglePlayProductDetails — по одному на каждый base plan/offer.
/// Мы находим нужный по basePlanId и запускаем покупку.
class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isInitialized = false;

  // Subscription product ID — совпадает с Google Play Console
  static const String subscriptionProductId = 'week_subscription';

  // Base plan IDs (из Google Play Console)
  static const String weeklyBasePlan = '01';
  static const String monthlyBasePlan = '02';

  // Callback для обработки результата покупки
  Function(SubscriptionPurchaseResult)? _onPurchaseResult;

  /// Initialize billing service и подписаться на purchase stream
  Future<void> initialize() async {
    if (_isInitialized) return;

    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('In-app purchases not available');
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: (error) {
        print('[BillingService] Purchase stream error: $error');
        _onPurchaseResult?.call(SubscriptionPurchaseResult(
          success: false,
          error: error.toString(),
        ));
      },
    );

    _isInitialized = true;
  }

  /// Handle purchase updates from the store
  void _handlePurchaseUpdates(List<PurchaseDetails> purchases) {
    for (final purchase in purchases) {
      _handlePurchase(purchase);
    }
  }

  /// Handle a single purchase update
  Future<void> _handlePurchase(PurchaseDetails purchase) async {
    switch (purchase.status) {
      case PurchaseStatus.purchased:
      case PurchaseStatus.restored:
        // Acknowledge — без этого Google Play отменит через 3 дня
        if (purchase.pendingCompletePurchase) {
          await _iap.completePurchase(purchase);
        }

        final token = _extractPurchaseToken(purchase);
        _onPurchaseResult?.call(SubscriptionPurchaseResult(
          success: true,
          purchaseToken: token,
          productId: purchase.productID,
        ));
        break;

      case PurchaseStatus.error:
        _onPurchaseResult?.call(SubscriptionPurchaseResult(
          success: false,
          error: purchase.error?.message ?? 'Purchase failed',
        ));
        break;

      case PurchaseStatus.canceled:
        _onPurchaseResult?.call(SubscriptionPurchaseResult(
          success: false,
          error: 'canceled',
        ));
        break;

      case PurchaseStatus.pending:
        // Pending — ждём следующего апдейта (напр. медленный платёж)
        print('[BillingService] Purchase pending: ${purchase.productID}');
        break;
    }
  }

  /// Extract purchase token (platform-specific)
  String? _extractPurchaseToken(PurchaseDetails purchase) {
    if (Platform.isAndroid) {
      final androidDetails = purchase as GooglePlayPurchaseDetails;
      return androidDetails.billingClientPurchase.purchaseToken;
    }
    // iOS — serverVerificationData содержит receipt
    return purchase.verificationData.serverVerificationData;
  }

  /// Purchase a subscription by base plan ID
  ///
  /// [basePlanId] — "01" (weekly) или "02" (monthly)
  /// [onResult] — callback с результатом покупки
  Future<void> purchaseSubscription({
    required String basePlanId,
    required Function(SubscriptionPurchaseResult) onResult,
    String? userId,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    _onPurchaseResult = onResult;

    try {
      // queryProductDetails для подписки вернёт список
      // GooglePlayProductDetails — по одному на каждый base plan
      final response = await _iap.queryProductDetails(
        {subscriptionProductId},
      );

      if (response.error != null) {
        onResult(SubscriptionPurchaseResult(
          success: false,
          error: 'Failed to load product: ${response.error}',
        ));
        return;
      }

      if (response.productDetails.isEmpty) {
        onResult(const SubscriptionPurchaseResult(
          success: false,
          error: 'Subscription product not found in store',
        ));
        return;
      }

      // Найти ProductDetails для нужного base plan
      final targetProduct = _findProductForBasePlan(
        response.productDetails,
        basePlanId,
      );

      if (targetProduct == null) {
        onResult(SubscriptionPurchaseResult(
          success: false,
          error: 'Base plan $basePlanId not found',
        ));
        return;
      }

      final purchaseParam = PurchaseParam(
        productDetails: targetProduct,
        applicationUserName: userId,
      );

      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      onResult(SubscriptionPurchaseResult(
        success: false,
        error: e.toString(),
      ));
    }
  }

  /// Найти ProductDetails для конкретного base plan
  ///
  /// queryProductDetails возвращает несколько GooglePlayProductDetails
  /// для подписки — по одному на каждый offer/base plan.
  /// Каждый имеет subscriptionIndex, через который достаём basePlanId.
  ProductDetails? _findProductForBasePlan(
    List<ProductDetails> products,
    String basePlanId,
  ) {
    if (!Platform.isAndroid) {
      // iOS — просто вернуть первый (один продукт = один plan)
      return products.isNotEmpty ? products.first : null;
    }

    for (final product in products) {
      if (product is GooglePlayProductDetails) {
        final idx = product.subscriptionIndex;
        if (idx != null) {
          final offers =
              product.productDetails.subscriptionOfferDetails;
          if (offers != null && idx < offers.length) {
            if (offers[idx].basePlanId == basePlanId) {
              return product;
            }
          }
        }
      }
    }
    return null;
  }

  /// Получить локализованные цены из Google Play.
  /// Возвращает map basePlanId → price string (напр. {"01": "$9.99", "02": "$20.99"})
  Future<Map<String, String>> queryPrices() async {
    if (!_isInitialized) await initialize();

    final response = await _iap.queryProductDetails({subscriptionProductId});
    if (response.error != null || response.productDetails.isEmpty) return {};

    final prices = <String, String>{};
    for (final product in response.productDetails) {
      if (product is GooglePlayProductDetails) {
        final idx = product.subscriptionIndex;
        if (idx != null) {
          final offers = product.productDetails.subscriptionOfferDetails;
          if (offers != null && idx < offers.length) {
            final basePlanId = offers[idx].basePlanId;
            prices[basePlanId] = product.price;
          }
        }
      }
    }
    return prices;
  }

  /// Restore purchases (подписки)
  Future<void> restorePurchases({
    required Function(SubscriptionPurchaseResult) onResult,
  }) async {
    if (!_isInitialized) {
      await initialize();
    }

    bool resultCalled = false;

    _onPurchaseResult = (result) {
      resultCalled = true;
      onResult(result);
    };

    await _iap.restorePurchases();

    // Если через 5 секунд onResult не вызвался — подписок нет
    await Future.delayed(const Duration(seconds: 5));
    if (!resultCalled) {
      _onPurchaseResult = null;
      onResult(const SubscriptionPurchaseResult(
        success: false,
        error: 'no_purchases',
      ));
    }
  }

  void dispose() {
    _subscription?.cancel();
    _onPurchaseResult = null;
    _isInitialized = false;
  }
}
