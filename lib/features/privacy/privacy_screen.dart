import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_header.dart';

class PrivacyScreen extends StatelessWidget {
  const PrivacyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    Text('Privacy Policy', style: AppTypography.titleLarge),
                    const SizedBox(height: 32),
                    _buildSection(
                      'Your Data',
                      'We believe your thoughts belong to you. When you use this app, you aren\'t sending your reflections into the void or to our servers.',
                      'We do not collect personal usage statistics, nor do we build a profile of your habits. Your journey is yours to define, unobserved.',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Local Storage',
                      'All entries, preferences, and reflection history are stored securely on your local device.',
                      'This means if you delete the app, your data goes with it. We prioritize ownership and control over convenience and cloud synchronization.',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Our Commitment',
                      'We pledge never to sell, trade, or share your information with third parties.',
                      'Our business model relies on the value of the tool itself, not on the monetization of your attention or your private moments.',
                    ),
                    const SizedBox(height: 48),
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
      title: 'Privacy',
      leading: const DCBackButton(),
    );
  }

  Widget _buildSection(String title, String mainText, String secondaryText) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppTypography.fieldLabel),
        const SizedBox(height: 12),
        Text(mainText, style: AppTypography.fieldValue),
        const SizedBox(height: 12),
        Text(secondaryText, style: AppTypography.bodyMedium),
      ],
    );
  }
}
