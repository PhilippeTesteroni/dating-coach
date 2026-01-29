import 'dart:async';
import 'dart:io';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';

/// Google Play Billing service wrapper для Dating Coach
class BillingService {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  bool _isInitialized = false;

  // Product IDs — должны совпадать с Google Play Console
  static const String credits10 = 'credits_10';
  static const String credits25 = 'credits_25';
  static const String credits50 = 'credits_50';

  static const List<String> productIds = [
    credits10,
    credits25,
    credits50,
  ];

  List<ProductDetails> _products = [];
  List<ProductDetails> get products => _products;

  /// Initialize billing service
  Future<void> initialize({
    required Function(PurchaseDetails) onPurchaseUpdate,
  }) async {
    if (_isInitialized) return;

    final available = await _iap.isAvailable();
    if (!available) {
      throw Exception('In-app purchases not available');
    }

    _subscription = _iap.purchaseStream.listen(
      (purchases) {
        for (final purchase in purchases) {
          onPurchaseUpdate(purchase);
        }
      },
      onError: (error) {
        print('[BillingService] Purchase stream error: $error');
      },
    );

    _isInitialized = true;
  }

  /// Load available products from Google Play
  Future<List<ProductDetails>> loadProducts() async {
    final response = await _iap.queryProductDetails(productIds.toSet());

    if (response.error != null) {
      throw Exception('Failed to load products: ${response.error}');
    }

    if (response.productDetails.isEmpty) {
      print('[BillingService] No products found');
      return [];
    }

    // Sort by credit amount
    _products = response.productDetails..sort((a, b) {
      final creditsA = getCreditAmountFromProductId(a.id);
      final creditsB = getCreditAmountFromProductId(b.id);
      return creditsA.compareTo(creditsB);
    });

    return _products;
  }

  /// Purchase a product
  Future<void> purchaseProduct(ProductDetails product, {String? userId}) async {
    final purchaseParam = PurchaseParam(
      productDetails: product,
      applicationUserName: userId,
    );

    final success = await _iap.buyConsumable(
      purchaseParam: purchaseParam,
      autoConsume: false,
    );

    if (!success) {
      throw Exception('Purchase canceled or failed');
    }
  }

  /// Complete purchase (acknowledge + consume)
  Future<void> completePurchase(PurchaseDetails purchase) async {
    if (Platform.isAndroid) {
      final androidAddition = _iap.getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();
      
      await _iap.completePurchase(purchase);
      final consumeResult = await androidAddition.consumePurchase(purchase);
      
      if (consumeResult.responseCode != BillingResponse.ok) {
        print('[BillingService] Consume failed: ${consumeResult.responseCode}');
      }
    } else {
      await _iap.completePurchase(purchase);
    }
  }

  /// Restore purchases
  Future<void> restorePurchases() async {
    await _iap.restorePurchases();
  }

  /// Get credit amount from product ID
  static int getCreditAmountFromProductId(String productId) {
    switch (productId) {
      case credits10:
        return 10;
      case credits25:
        return 25;
      case credits50:
        return 50;
      default:
        return 0;
    }
  }

  /// Get interaction estimate (1 credit ≈ 1 interaction)
  static int getInteractionsFromCredits(int credits) => credits;

  /// Check if product is featured (middle package)
  static bool isFeaturedProduct(String productId) => productId == credits25;

  void dispose() {
    _subscription?.cancel();
    _isInitialized = false;
  }
}
