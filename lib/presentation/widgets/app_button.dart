import 'package:flutter/material.dart';
import '../../core/theme/colors.dart';

class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onTap;
  final bool outlined;
  final bool fullWidth;

  const AppButton({
    super.key,
    required this.label,
    this.onTap,
    this.outlined = false,
    this.fullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final Widget btn = outlined
        ? OutlinedButton(
            onPressed: onTap,
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppColors.primary),
              foregroundColor: AppColors.primary,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          )
        : ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              elevation: 0,
            ),
            child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          );

    return fullWidth ? SizedBox(width: double.infinity, child: btn) : btn;
  }
}
