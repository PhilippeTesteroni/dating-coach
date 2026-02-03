import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../services/user_service.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_header.dart';
import '../../shared/widgets/dc_scaffold.dart';
import 'widgets/credit_package_card.dart';

/// Mock пакет кредитов
class _MockPackage {
  final String id;
  final int credits;
  final String price;
  final bool isFeatured;

  const _MockPackage({
    required this.id,
    required this.credits,
    required this.price,
    this.isFeatured = false,
  });
}

/// Mock пакеты для отображения
const _mockPackages = [
  _MockPackage(id: 'credits_20', credits: 20, price: '\$4.99'),
  _MockPackage(id: 'credits_40', credits: 40, price: '\$8.99'),
  _MockPackage(id: 'credits_70', credits: 70, price: '\$14.99', isFeatured: true),
  _MockPackage(id: 'credits_100', credits: 100, price: '\$19.99'),
];

/// Экран баланса и покупки кредитов
class BalanceScreen extends StatefulWidget {
  const BalanceScreen({super.key});

  @override
  State<BalanceScreen> createState() => _BalanceScreenState();
}

class _BalanceScreenState extends State<BalanceScreen> {
  bool _isPurchasing = false;
  String? _purchasingProductId;

  Future<void> _onPackageTap(_MockPackage package) async {
    // TODO: Implement real purchase when Google Play is set up
    setState(() {
      _isPurchasing = true;
      _purchasingProductId = package.id;
    });

    // Simulate purchase delay
    await Future.delayed(const Duration(seconds: 1));

    if (mounted) {
      setState(() {
        _isPurchasing = false;
        _purchasingProductId = null;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Purchase not available yet')),
      );
    }
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
                    _buildBalanceDisplay(),
                    const SizedBox(height: 40),
                    Expanded(child: _buildProductsList()),
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
      title: 'Balance',
      leading: const DCBackButton(),
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
    return ListView.separated(
      itemCount: _mockPackages.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final package = _mockPackages[index];
        final isThisLoading = _purchasingProductId == package.id;

        return CreditPackageCard(
          credits: package.credits,
          price: package.price,
          isFeatured: package.isFeatured,
          isLoading: isThisLoading,
          onTap: _isPurchasing ? null : () => _onPackageTap(package),
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
