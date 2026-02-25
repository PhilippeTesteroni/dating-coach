/// Настройки приложения из Config Service
class AppSettings {
  final String appId;
  // Credit-based (legacy, nullable for subscription-based apps)
  final int? welcomeBonus;
  final int? creditCost;
  final int referrerBonus;
  final int referredBonus;
  final List<CreditPackage>? creditPackages;
  // Subscription-based (new)
  final int? freeMessageLimit;
  final List<SubscriptionProduct>? subscriptionProducts;

  const AppSettings({
    required this.appId,
    this.welcomeBonus,
    this.creditCost,
    this.referrerBonus = 0,
    this.referredBonus = 0,
    this.creditPackages,
    this.freeMessageLimit,
    this.subscriptionProducts,
  });

  factory AppSettings.fromJson(Map<String, dynamic> json) {
    return AppSettings(
      appId: json['app_id'] as String,
      welcomeBonus: json['welcome_bonus'] as int?,
      creditCost: json['credit_cost'] as int?,
      referrerBonus: json['referrer_bonus'] as int? ?? 0,
      referredBonus: json['referred_bonus'] as int? ?? 0,
      creditPackages: json['credit_packages'] != null
          ? (json['credit_packages'] as List)
              .map((p) => CreditPackage.fromJson(p))
              .toList()
          : null,
      freeMessageLimit: json['free_message_limit'] as int?,
      subscriptionProducts: json['subscription_products'] != null
          ? (json['subscription_products'] as List)
              .map((p) => SubscriptionProduct.fromJson(p))
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

/// Продукт подписки
class SubscriptionProduct {
  final String productId;
  final String basePlanId;
  final String name;
  final String period; // week, month
  final double price;
  final String currency;
  final String? description;

  const SubscriptionProduct({
    required this.productId,
    required this.basePlanId,
    required this.name,
    required this.period,
    required this.price,
    this.currency = 'USD',
    this.description,
  });

  factory SubscriptionProduct.fromJson(Map<String, dynamic> json) {
    return SubscriptionProduct(
      productId: json['product_id'] as String,
      basePlanId: json['base_plan_id'] as String,
      name: json['name'] as String,
      period: json['period'] as String,
      price: (json['price'] as num).toDouble(),
      currency: json['currency'] as String? ?? 'USD',
      description: json['description'] as String?,
    );
  }
}
