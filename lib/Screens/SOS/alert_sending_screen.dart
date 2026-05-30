import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';
import '../Navigation/slam_initialization_screen.dart';

class AlertSendingScreen extends StatelessWidget {
  const AlertSendingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.check_circle,
                  color: AppColors.neonGreen,
                  size: 120,
                ),

                const SizedBox(height: 30),

                const Text(
                  'Alert Has Been Sent!',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 20),

                const Text(
                  'Admin has been notified successfully.\nWhat would you like to do?',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ),

                const SizedBox(height: 40),

                /// PRIMARY BUTTON
                PrimaryButton(
                  text: 'START EVACUATION BY MOBILE',
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const SlamInitializationScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 16),

                /// SECONDARY BUTTON
                SizedBox(
                  width: double.infinity,
                  height: 58,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    },

                    icon: const Icon(
                      Icons.home_outlined,
                      color: AppColors.neonBlue,
                    ),

                    label: const Text(
                      'EVACUATE BY YOUR OWN SELF',
                      style: TextStyle(
                        color: AppColors.neonBlue,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),

                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(
                        color: AppColors.neonBlue,
                        width: 1.5,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
