import 'package:flutter/material.dart';
import '../../features/subscription/subscription_screen.dart';
import '../../services/user_service.dart';
import 'dc_confirm_modal.dart';

/// Показывает модалку «Free messages used up» и ведёт на SubscriptionScreen.
/// Возвращает true если подписка была оформлена (можно продолжать).
class DCCreditsPaywall {
  DCCreditsPaywall._();

  static Future<bool> show(BuildContext context) async {
    final userService = UserService();
    final used = userService.messagesUsed;
    final limit = userService.freeMessageLimit;

    final result = await DCConfirmModal.show(
      context: context,
      title: 'Free messages used up',
      message: 'You\'ve used $used of $limit free messages.\nSubscribe to unlock unlimited access.',
      confirmText: 'View Plans',
      cancelText: 'Back',
    );

    if (result == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );

      // Refresh subscription status when returning from SubscriptionScreen
      await userService.loadSubscriptionStatus();

      // Return true if subscription is now active
      return userService.canSendMessage;
    }

    return false;
  }
}
