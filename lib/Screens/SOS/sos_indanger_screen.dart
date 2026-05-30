import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'sos_image_screen.dart';

class SOSInDangerScreen extends StatelessWidget {
  const SOSInDangerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                size: 120,
                color: Colors.white,
              ),

              const SizedBox(height: 30),

              const Text(
                'Are you in danger?',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 20),

              const Text(
                'This will send emergency alert to admin.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary),
              ),

              const SizedBox(height: 40),

              PrimaryButton(
                text: 'YES, CONTINUE',
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const SOSImageScreen()),
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
