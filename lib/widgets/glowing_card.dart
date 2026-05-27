import 'package:flutter/material.dart';
import '../Core/constants/app_colors.dart';

class GlowingCard extends StatelessWidget {
  final Widget child;

  const GlowingCard({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.neonBlue),
        boxShadow: const [BoxShadow(color: AppColors.neonBlue, blurRadius: 12)],
      ),
      child: child,
    );
  }
}
