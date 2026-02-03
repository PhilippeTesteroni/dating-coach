import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/dc_back_button.dart';
import '../../shared/widgets/dc_header.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

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
                    Text('Terms &\nConditions', style: AppTypography.titleLarge),
                    const SizedBox(height: 32),
                    _buildSection(
                      'Introduction',
                      'Welcome to Dating Coach. These terms are designed to ensure a safe, supportive, and private environment for your personal growth.',
                      'By using this application, you agree to operate within these boundaries, fostering a community of respect and mindfulness.',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Usage',
                      'This app is intended for personal development and relationship guidance. It is a tool for reflection, not a substitute for professional medical or psychological advice.',
                      'We encourage you to use this space at your own pace. There is no right or wrong way to grow, only your own process.',
                    ),
                    const SizedBox(height: 24),
                    _buildSection(
                      'Privacy',
                      'Your privacy is paramount. Your conversations and reflections are processed securely, ensuring that your personal journey remains yours alone.',
                      'We do not sell or share your personal data. We believe that clarity comes from a space free of surveillance and commercial interest.',
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
      title: 'Terms',
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
