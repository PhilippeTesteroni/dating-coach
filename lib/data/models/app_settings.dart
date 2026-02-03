/// Настройки приложения из Config Service
class AppSettings {
  final String appId;
  final int welcomeBonus;
  final int creditCost;
  final int referrerBonus;
  final int referredBonus;
  final List<CreditPackage>? creditPackages;

  const AppSettings({
    required this.appId,
    required this.welcomeBonus,
    required this.creditCost,
    required this.referrerBonus,
    required this.referredBonus,
    this.creditPackages,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      appId: json['app_id'] as String,
      welcomeBonus: json['welcome_bonus'] as int,
      creditCost: json['credit_cost'] as int,
      referrerBonus: json['referrer_bonus'] as int,
      referredBonus: json['referred_bonus'] as int,
      creditPackages: json['credit_packages'] != null
          ? (json['credit_packages'] as List)
              .map((p) => CreditPackage.fromJson(p))
              .toList()
          : null,
    );
  }
}

/// Пакет кредитов для покупки
class CreditPackage {
  final String productId;
  final int credits;
  final double price;
  final String currency;

  const CreditPackage({
    required this.productId,
    required this.credits,
    required this.price,
    this.currency = 'USD',
  });

  factory CreditPackage.fromJson(Map<String, dynamic> json) {
    return CreditPackage(
      productId: json['product_id'] as String,
      credits: json['credits'] as int,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
    );
  }
}
