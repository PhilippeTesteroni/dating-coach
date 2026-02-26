import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/api/api_client.dart';
import '../../data/models/app_settings.dart';
import '../../data/services/billing_service.dart';
import '../../data/repositories/subscription_repository.dart';
import '../../services/analytics_service.dart';
import '../../services/app_settings_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_header.dart';
import 'widgets/subscription_plan_card.dart';

/// Экран подписки
class SubscriptionScreen extends StatefulWidget {
  /// Откуда открыт экран: 'paywall' или 'menu'
  final String source;

  const SubscriptionScreen({super.key, this.source = 'menu'});

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
    // Логируем только если открыт из меню — при открытии из paywall
    // событие уже залогировано в DCCreditsPaywall._handleResult
    if (widget.source == 'menu') {
      AnalyticsService().logSubscriptionScreenOpened(source: 'menu');
    }
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

    AnalyticsService().logSubscriptionPlanTapped(plan: product.basePlanId);

    setState(() {
      _isPurchasing = true;
      _purchasingBasePlanId = product.basePlanId;
    });

    AnalyticsService().logSubscriptionPurchaseStarted(plan: product.basePlanId);

    await _billing.purchaseSubscription(
      basePlanId: product.basePlanId,
      userId: UserService().session?.userId,
      onResult: (result) async {
        if (!mounted) return;

        if (result.success && result.purchaseToken != null) {
          await _verifyPurchase(
            productId: result.productId ?? product.productId,
            purchaseToken: result.purchaseToken!,
            basePlanId: product.basePlanId,
          );
        } else if (result.error == 'canceled') {
          AnalyticsService().logSubscriptionPurchaseCancelled(plan: product.basePlanId);
          _resetPurchaseState();
        } else {
          AnalyticsService().logSubscriptionPurchaseFailed(
            plan: product.basePlanId,
            error: result.error ?? 'unknown',
          );
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
    } on ApiException catch (e) {
      // 409 = токен уже обработан, подписка активна — это не ошибка
      if (e.statusCode != 409) {
        debugPrint('[SubscriptionScreen] Verify error: $e');
        _resetPurchaseState();
        _showError('Failed to verify purchase. Please try again.');
        return;
      }
      debugPrint('[SubscriptionScreen] Purchase already processed, treating as success');
    } catch (e) {
      debugPrint('[SubscriptionScreen] Verify error: $e');
      _resetPurchaseState();
      _showError('Failed to verify purchase. Please try again.');
      return;
    }

    // Обновить статус подписки с сервера
    await UserService().loadSubscriptionStatus();

    if (mounted) {
      AnalyticsService().logSubscriptionPurchaseCompleted(
        plan: basePlanId ?? 'unknown',
      );

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

      if (mounted) Navigator.pop(context);
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
          AnalyticsService().logSubscriptionRestored();
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Column(
              children: [
                const Icon(Icons.check_circle_outline, size: 48, color: AppColors.action),
                const SizedBox(height: 12),
                Text('Premium Active', style: AppTypography.displaySmall),
                const SizedBox(height: 4),
                Text(
                  'You\'re all set 🎉',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          Text(
            'Your benefits',
            style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildPerk(Icons.all_inclusive, 'Unlimited messages', 'No daily limits, practice as much as you want'),
          _buildPerk(Icons.people_outline, 'All characters', 'Access to every coach and practice partner'),
          _buildPerk(Icons.psychology_outlined, 'All training modes', 'Practice, Understanding, Reflection & Open Chat'),
          _buildPerk(Icons.trending_up, 'Full progress tracking', 'Detailed feedback and skill progression'),
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

  Widget _buildPerk(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.action.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 20, color: AppColors.action),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w500)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter() {
    final isSubscribed = UserService().isSubscribed;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        children: [
          if (!isSubscribed)
            Text(
              'Subscribe to unlock unlimited\nmessages and practice sessions.',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          if (!isSubscribed) ...[
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
