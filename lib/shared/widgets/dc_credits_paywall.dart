import 'package:flutter/material.dart';
import '../../features/balance/balance_screen.dart';
import 'dc_confirm_modal.dart';

/// Показывает модалку «Not enough credits» и ведёт на BalanceScreen
class DCCreditsPaywall {
  DCCreditsPaywall._();

  static Future<void> show(BuildContext context) async {
    final result = await DCConfirmModal.show(
      context: context,
      title: 'Not enough credits',
      message: 'This attempt requires more credits\nthan you have right now.',
      confirmText: 'Add Credits',
      cancelText: 'Back',
    );

    if (result == true && context.mounted) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const BalanceScreen()),
      );
    }
  }
}
