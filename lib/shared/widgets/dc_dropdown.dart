import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Элемент дропдауна
class DCDropdownItem<T> {
  final T value;
  final String label;

  const DCDropdownItem({required this.value, required this.label});
}

/// Дропдаун с лейблом (без анимации)
class DCDropdown<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<DCDropdownItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final String? hint;

  const DCDropdown({
    super.key,
    required this.label,
    required this.items,
    this.value,
    this.onChanged,
    this.hint,
  });

  String? get _displayText {
    if (value == null) return hint;
    final item = items.where((i) => i.value == value).firstOrNull;
    return item?.label ?? hint;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppTypography.fieldLabel),
        const SizedBox(height: 8),
        PopupMenuButton<T>(
          onSelected: onChanged,
          offset: const Offset(0, 48),
          color: AppColors.inputBackground,
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          itemBuilder: (context) => items.map((item) {
            return PopupMenuItem<T>(
              value: item.value,
              height: 44,
              child: Text(item.label, style: AppTypography.fieldValue),
            );
          }).toList(),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.inputBackground,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.border),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _displayText ?? '',
                    style: value != null 
                        ? AppTypography.fieldValue 
                        : AppTypography.bodyMedium,
                  ),
                ),
                const Icon(
                  Icons.keyboard_arrow_down,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
