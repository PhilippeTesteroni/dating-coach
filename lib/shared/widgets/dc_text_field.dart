import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Текстовое поле с лейблом
class DCTextField extends StatelessWidget {
  final String label;
  final String? value;
  final String? hint;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;

  const DCTextField({
    super.key,
    required this.label,
    this.value,
    this.hint,
    this.controller,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.fieldLabel),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: AppTypography.fieldValue,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: AppTypography.bodyMedium,
            filled: true,
            fillColor: AppColors.inputBackground,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.border),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary),
            ),
          ),
        ),
      ],
    );
  }
}
