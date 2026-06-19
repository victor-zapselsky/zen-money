import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class ProgressBar extends StatelessWidget {
  final double value; // 0..1
  final Color? color;
  final double height;

  const ProgressBar({super.key, required this.value, this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    final clamped = value.clamp(0.0, 1.0);
    final barColor = color ??
        (value > 1.0
            ? AppColors.expense
            : value > 0.85
                ? AppColors.warning
                : AppColors.primary);
    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: clamped,
        minHeight: height,
        backgroundColor: AppColors.lineColor,
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
      ),
    );
  }
}
