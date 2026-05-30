import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../Navigation/slam_initialization_screen.dart';

class EmergencyAlertScreen extends StatelessWidget {
  final String emergencyType;
  final String affectedFloor;
  final String blockedArea;

  const EmergencyAlertScreen({
    super.key,
    required this.emergencyType,
    required this.affectedFloor,
    required this.blockedArea,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              /// ALERT ICON
              Container(
                width: 150,
                height: 150,

                decoration: BoxDecoration(
                  shape: BoxShape.circle,

                  border: Border.all(color: AppColors.neonBlue, width: 4),

                  boxShadow: const [
                    BoxShadow(color: AppColors.neonBlue, blurRadius: 35),
                  ],
                ),

                child: const Icon(
                  Icons.warning_rounded,
                  color: AppColors.neonBlue,
                  size: 85,
                ),
              ),

              const SizedBox(height: 45),

              /// TITLE
              const Text(
                'EMERGENCY ALERT',

                textAlign: TextAlign.center,

                style: TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                ),
              ),

              const SizedBox(height: 20),

              /// EMERGENCY TYPE
              Text(
                emergencyType,

                style: const TextStyle(
                  color: Colors.redAccent,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 18),

              /// FLOOR
              Text(
                'Affected Area: $affectedFloor',

                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: AppColors.textSecondary,
                  fontSize: 16,
                ),
              ),

              const SizedBox(height: 10),

              /// BLOCKED AREA
              Text(
                'Avoid: $blockedArea',

                textAlign: TextAlign.center,

                style: const TextStyle(
                  color: Colors.orange,
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),

              const SizedBox(height: 40),

              const Text(
                'Follow evacuation guidance immediately.',

                textAlign: TextAlign.center,

                style: TextStyle(color: AppColors.textSecondary, fontSize: 15),
              ),

              const SizedBox(height: 55),

              /// BUTTON
              PrimaryButton(
                text: 'START EVACUATION',

                onTap: () {
                  Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (_) => const SlamInitializationScreen(),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}













