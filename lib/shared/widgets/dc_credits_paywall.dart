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

    return _handleResult(context, result);
  }

  /// Pre-training check: shows paywall when free messages are insufficient
  /// for completing the training level.
  static Future<bool> showForTraining(
    BuildContext context, {
    required int requiredMessages,
  }) async {
    final userService = UserService();
    final remaining = userService.messagesRemaining;

    final result = await DCConfirmModal.show(
      context: context,
      title: 'Not enough free messages',
      message: 'This level needs $requiredMessages messages, '
          'but you only have $remaining left.\n'
          'Subscribe to unlock unlimited training.',
      confirmText: 'View Plans',
      cancelText: 'Back',
    );

    return _handleResult(context, result);
  }

  static Future<bool> _handleResult(BuildContext context, bool? result) async {
    if (result == true && context.mounted) {
      await Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const SubscriptionScreen()),
      );

      final userService = UserService();
      await userService.loadSubscriptionStatus();

      return userService.canSendMessage;
    }

    return false;
  }
}
