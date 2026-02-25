import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/models/app_settings.dart';
import '../../data/services/billing_service.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../services/app_settings_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_header.dart';
import 'widgets/subscription_plan_card.dart';

/// Экран подписки
class SubscriptionScreen extends StatefulWidget {
  const SubscriptionScreen({super.key});

  @override
  State<SubscriptionScreen> createState() => _SubscriptionScreenState();
}

class _SubscriptionScreenState extends State<SubscriptionScreen> {
  final BillingService _billing = BillingService();
  late final SubscriptionRepository _subscriptionRepo;

  bool _isPurchasing = false;
  String? _purchasingBasePlanId;

  // Цены из Google Play (null пока не загружены — fallback на S3)
  Map<String, String> _storePrices = {};

  @override
  void initState() {
    super.initState();
    _subscriptionRepo = SubscriptionRepository(UserService().apiClient);
    _initBilling();
    _refreshStatus();
    _loadStorePrices();
  }

  Future<void> _loadStorePrices() async {
    try {
      final response = await _billing.queryPrices();
      if (mounted && response.isNotEmpty) {
        setState(() => _storePrices = response);
      }
    } catch (e) {
      // Fallback на цены из S3 — ничего не делаем
      debugPrint('[SubscriptionScreen] Store prices unavailable: $e');
    }
  }

  Future<void> _initBilling() async {
    try {
      await _billing.initialize();
    } catch (e) {
      print('[SubscriptionScreen] Billing init error: $e');
    }
  }

  Future<void> _refreshStatus() async {
    await UserService().loadSubscriptionStatus();
    if (mounted) setState(() {});
  }

  /// Покупка подписки
  Future<void> _onPlanTap(SubscriptionProduct product) async {
    if (_isPurchasing) return;

    setState(() {
      _isPurchasing = true;
      _purchasingBasePlanId = product.basePlanId;
    });

    await _billing.purchaseSubscription(
      basePlanId: product.basePlanId,
      userId: UserService().session?.userId,
      onResult: (result) async {
        if (!mounted) return;

        if (result.success && result.purchaseToken != null) {
          // Верифицируем покупку на бэкенде
          await _verifyPurchase(
            productId: result.productId ?? product.productId,
            purchaseToken: result.purchaseToken!,
            basePlanId: product.basePlanId,
          );
        } else if (result.error == 'canceled') {
          // Пользователь отменил — молча сбрасываем
          _resetPurchaseState();
        } else {
          // Ошибка покупки
          _resetPurchaseState();
          _showError(result.error ?? 'Purchase failed');
        }
      },
    );
  }

  /// Верификация покупки на бэкенде
  Future<void> _verifyPurchase({
    required String productId,
    required String purchaseToken,
    String? basePlanId,
  }) async {
    try {
      await _subscriptionRepo.verifySubscription(
        productId: productId,
        purchaseToken: purchaseToken,
        platform: 'google_play',
        basePlanId: basePlanId,
      );

      // Обновить статус подписки с сервера
      await UserService().loadSubscriptionStatus();

      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _purchasingBasePlanId = null;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Subscription activated! 🎉'),
            backgroundColor: AppColors.action,
          ),
        );

        // Вернуться в чат — подписка активна
        if (mounted) {
          Navigator.pop(context);
        }
      }
    } catch (e) {
      print('[SubscriptionScreen] Verify error: $e');
      _resetPurchaseState();
      _showError('Failed to verify purchase. Please try again.');
    }
  }

  void _resetPurchaseState() {
    if (mounted) {
      setState(() {
        _isPurchasing = false;
        _purchasingBasePlanId = null;
      });
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  /// Restore purchases
  Future<void> _onRestoreTap() async {
    if (_isPurchasing) return;

    setState(() => _isPurchasing = true);

    await _billing.restorePurchases(
      onResult: (result) async {
        if (!mounted) return;

        if (result.success && result.purchaseToken != null) {
          await _verifyPurchase(
            productId: result.productId ?? BillingService.subscriptionProductId,
            purchaseToken: result.purchaseToken!,
          );
        } else {
          _resetPurchaseState();
          if (result.error != 'canceled') {
            _showError('No active subscription found');
          }
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  children: [
                    const SizedBox(height: 20),
                    _buildStatusDisplay(),
                    const SizedBox(height: 40),
                    if (!UserService().isSubscribed)
                      Expanded(child: _buildPlansList()),
                    _buildFooter(),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return DCHeader(
      title: 'Subscription',
      leading: const DCBackButton(),
    );
  }

  Widget _buildStatusDisplay() {
    final userService = UserService();

    if (userService.isSubscribed) {
      return Column(
        children: [
          const Icon(Icons.check_circle_outline, size: 48, color: AppColors.action),
          const SizedBox(height: 12),
          Text('Premium Active', style: AppTypography.displaySmall),
          const SizedBox(height: 4),
          Text(
            'Unlimited messages',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      );
    }

    final remaining = userService.messagesRemaining ?? 0;
    final limit = userService.freeMessageLimit;

    return Column(
      children: [
        Text(
          '$remaining',
          style: AppTypography.displayLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'free messages remaining',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '${userService.messagesUsed} of $limit used',
          style: AppTypography.bodySmall.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildPlansList() {
    final products = AppSettingsService().subscriptionProducts;

    if (products == null || products.isEmpty) {
      return Center(
        child: Text(
          'Subscription plans coming soon',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      );
    }

    return ListView.separated(
      itemCount: products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = products[index];
        final isThisLoading = _purchasingBasePlanId == product.basePlanId;
        // Цена из Google Play если есть, иначе из S3
        final storePrice = _storePrices[product.basePlanId];
        final displayPrice = storePrice ?? '\$${product.price.toStringAsFixed(2)}';

        return SubscriptionPlanCard(
          name: product.name,
          price: displayPrice,
          period: product.period,
          description: product.description,
          isFeatured: product.period == 'month',
          isLoading: isThisLoading,
          onTap: _isPurchasing ? null : () => _onPlanTap(product),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          Text(
            'Subscribe to unlock unlimited\nmessages and practice sessions.',
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
          if (!UserService().isSubscribed) ...[
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _isPurchasing ? null : _onRestoreTap,
              child: Text(
                'Restore purchases',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.textSecondary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
