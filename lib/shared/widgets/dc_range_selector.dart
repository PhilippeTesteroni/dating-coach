import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';

/// Ползунок диапазона с отображением значений
///
/// Показывает min и max над слайдером.
/// Переиспользуемый для любого range-выбора.
class DCRangeSelector extends StatelessWidget {
  final double min;
  final double max;
  final double currentMin;
  final double currentMax;
  final ValueChanged<RangeValues> onChanged;

  const DCRangeSelector({
    super.key,
    required this.min,
    required this.max,
    required this.currentMin,
    required this.currentMax,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentMin.round().toString(),
                style: AppTypography.titleMedium,
              ),
              Text(
                currentMax.round().toString(),
                style: AppTypography.titleMedium,
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: AppColors.primary,
            inactiveTrackColor: AppColors.border,
            thumbColor: AppColors.primary,
            overlayColor: AppColors.primary.withOpacity(0.12),
            trackHeight: 3,
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            rangeThumbShape: const RoundRangeSliderThumbShape(enabledThumbRadius: 10),
          ),
          child: RangeSlider(
            min: min,
            max: max,
            values: RangeValues(currentMin, currentMax),
            divisions: (max - min).round(),
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }
}
