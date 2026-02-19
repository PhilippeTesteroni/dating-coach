/// Статус подписки пользователя
class SubscriptionStatus {
  final String subscriptionStatus; // none, active, expired, cancelled
  final bool isSubscribed;
  final int messagesUsed;
  final int freeMessageLimit;
  final int? messagesRemaining; // null = unlimited (subscribed)
  final String? expiresAt;
  final String? productId;

  const SubscriptionStatus({
    required this.subscriptionStatus,
    required this.isSubscribed,
    required this.messagesUsed,
    required this.freeMessageLimit,
    this.messagesRemaining,
    this.expiresAt,
    this.productId,
  });

  factory SubscriptionStatus.fromJson(Map<String, dynamic> json) {
    return SubscriptionStatus(
      subscriptionStatus: json['subscription_status'] as String? ?? 'none',
      isSubscribed: json['is_subscribed'] as bool? ?? false,
      messagesUsed: json['messages_used'] as int? ?? 0,
      freeMessageLimit: json['free_message_limit'] as int? ?? 10,
      messagesRemaining: json['messages_remaining'] as int?,
      expiresAt: json['expires_at'] as String?,
      productId: json['product_id'] as String?,
    );
  }

  /// Можно ли отправить сообщение
  bool get canSendMessage => isSubscribed || (messagesRemaining != null && messagesRemaining! > 0);

  @override
  String toString() =>
      'SubscriptionStatus(status: $subscriptionStatus, subscribed: $isSubscribed, '
      'used: $messagesUsed/$freeMessageLimit, remaining: $messagesRemaining)';
}
