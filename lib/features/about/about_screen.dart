import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../shared/widgets/dc_back_button.dart';

/// Экран "О приложении"
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 24),
                    
                    // Title
                    Text('About', style: AppTypography.titleLarge),
                    
                    const SizedBox(height: 32),
                    
                    // Paragraphs
                    _buildParagraph(
                      'This app is a space for observing conversations, '
                      'situations, and your own reactions.',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildParagraph(
                      'It doesn\'t teach you what to say, how to behave, or '
                      'who to be. It helps you slow down, look at what is '
                      'happening, and notice patterns that are often missed '
                      'in the moment.',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildParagraph(
                      'Some modes are open and unstructured. Others offer a '
                      'framework for reflection or practice. All of them are '
                      'built around the same idea: clarity comes from '
                      'observation, not correction.',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildParagraph(
                      'This is not therapy, coaching, or advice. It\'s a tool '
                      'for understanding how interactions unfold — and how '
                      'you respond to them.',
                    ),
                    
                    const SizedBox(height: 24),
                    
                    _buildParagraph(
                      'Use it at your own pace. There is nothing here to complete.',
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

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          const DCBackButton(),
          Expanded(
            child: Text(
              'About',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
          ),
          // Placeholder для симметрии
          const SizedBox(width: 40),
        ],
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: AppTypography.bodyMedium.copyWith(
        height: 1.5,
      ),
    );
  }
}
