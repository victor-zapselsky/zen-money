import 'package:flutter/material.dart';

class CategoryAvatar extends StatelessWidget {
  final String icon;
  final String color;
  final double size;

  const CategoryAvatar({
    super.key,
    required this.icon,
    required this.color,
    this.size = 40,
  });

  @override
  Widget build(BuildContext context) {
    final bg = _parseColor(color).withValues(alpha: 0.15);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(icon, style: TextStyle(fontSize: size * 0.45)),
    );
  }

  static Color _parseColor(String hex) {
    final h = hex.replaceFirst('#', '');
    return Color(int.parse('FF$h', radix: 16));
  }
}
