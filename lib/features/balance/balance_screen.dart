import 'package:flutter/material.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../data/api/api_client.dart';
import '../../data/repositories/purchase_repository.dart';
import '../../data/services/billing_service.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_scaffold.dart';
import '../../shared/widgets/dc_loader.dart';
import 'widgets/credit_package_card.dart';

/// Экран баланса и покупки кредитов
class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  final BillingService _billingService = BillingService();
  late final PurchaseRepository _purchaseRepository;
  
  List<ProductDetails> _products = [];
  bool _isLoading = true;
  bool _isPurchasing = false;
  String? _purchasingProductId;
  String? _error;

  @override
  void initState() {
    super.initState();
    _purchaseRepository = PurchaseRepository(ApiClient());
    _initBilling();
  }

  Future<void> _initBilling() async {
    try {
      await _billingService.initialize(
        onPurchaseUpdate: _handlePurchaseUpdate,
      );
      
      final products = await _billingService.loadProducts();
      
      if (mounted) {
        setState(() {
          _products = products;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _handlePurchaseUpdate(PurchaseDetails purchase) async {
    if (purchase.status == PurchaseStatus.pending) {
      setState(() => _isPurchasing = true);
    } else if (purchase.status == PurchaseStatus.error) {
      setState(() {
        _isPurchasing = false;
        _purchasingProductId = null;
        _error = purchase.error?.message ?? 'Purchase failed';
      });
      if (purchase.pendingCompletePurchase) {
        await _billingService.completePurchase(purchase);
      }
    } else if (purchase.status == PurchaseStatus.canceled) {
      setState(() {
        _isPurchasing = false;
        _purchasingProductId = null;
      });
    } else if (purchase.status == PurchaseStatus.purchased ||
               purchase.status == PurchaseStatus.restored) {
      await _verifyPurchase(purchase);
    }
  }

  Future<void> _verifyPurchase(PurchaseDetails purchase) async {
    try {
      // Verify with backend
      final result = await _purchaseRepository.verifyPurchase(
        productId: purchase.productID,
        purchaseToken: purchase.verificationData.serverVerificationData,
        platform: 'google_play',
      );
      
      // Consume purchase after successful verification
      await _billingService.completePurchase(purchase);
      
      // Update local balance
      UserService().updateBalance(result.newBalance);
      
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _purchasingProductId = null;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Added ${result.creditsAdded} credits!')),
        );
      }
    } catch (e) {
      // Check if already processed (409)
      if (e.toString().contains('409') || e.toString().contains('already')) {
        await _billingService.completePurchase(purchase);
        await UserService().loadBalance();
        
        if (mounted) {
          setState(() {
            _isPurchasing = false;
            _purchasingProductId = null;
          });
        }
        return;
      }
      
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _purchasingProductId = null;
          _error = 'Failed to verify purchase';
        });
      }
    }
  }

  Future<void> _purchaseProduct(ProductDetails product) async {
    setState(() {
      _isPurchasing = true;
      _purchasingProductId = product.id;
      _error = null;
    });

    try {
      final userId = UserService().session?.userId;
      await _billingService.purchaseProduct(product, userId: userId);
    } catch (e) {
      if (mounted) {
        setState(() {
          _isPurchasing = false;
          _purchasingProductId = null;
          _error = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return DCScaffold(
      showMenu: false,
      child: Column(
        children: [
          // Header with back button
          _buildHeader(),
          
          const SizedBox(height: 32),
          
          // Balance display
          _buildBalanceDisplay(),
          
          const SizedBox(height: 40),
          
          // Products list
          Expanded(
            child: _isLoading
                ? const Center(child: DCLoader())
                : _buildProductsList(),
          ),
          
          // Footer text
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Icon(
            Icons.arrow_back,
            size: 24,
            color: AppColors.textPrimary,
          ),
        ),
        const Expanded(
          child: Center(
            child: Text('Balance', style: AppTypography.titleMedium),
          ),
        ),
        const SizedBox(width: 24), // Spacer for centering
      ],
    );
  }

  Widget _buildBalanceDisplay() {
    final balance = UserService().balance;
    
    return Column(
      children: [
        Text(
          '$balance',
          style: AppTypography.displayLarge,
        ),
        const SizedBox(height: 4),
        Text(
          'credits',
          style: AppTypography.bodyMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildProductsList() {
    if (_error != null && _products.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Failed to load packages',
              style: AppTypography.bodyMedium,
            ),
            const SizedBox(height: 16),
            GestureDetector(
              onTap: _initBilling,
              child: Text(
                'Tap to retry',
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.action,
                ),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _products.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final product = _products[index];
        final credits = BillingService.getCreditAmountFromProductId(product.id);
        final isFeatured = BillingService.isFeaturedProduct(product.id);
        final isThisLoading = _purchasingProductId == product.id;

        return CreditPackageCard(
          credits: credits,
          price: product.price,
          isFeatured: isFeatured,
          isLoading: isThisLoading,
          onTap: _isPurchasing ? null : () => _purchaseProduct(product),
        );
      },
    );
  }

  Widget _buildFooter() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Text(
        'Credits are used for interactions and\npractice sessions.',
        style: AppTypography.bodySmall.copyWith(
          color: AppColors.textSecondary,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }
}
