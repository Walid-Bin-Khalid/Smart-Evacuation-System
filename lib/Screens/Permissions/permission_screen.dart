import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

import '../Home/home_screen.dart';
import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';

class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> {
  Widget permissionTile({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),

      decoration: BoxDecoration(
        color: AppColors.cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.neonBlue),
      ),

      child: Row(
        children: [
          Icon(icon, color: AppColors.neonBlue, size: 24),

          const SizedBox(width: 14),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,

              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),

                const SizedBox(height: 4),

                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: Colors.grey.shade400,
                    height: 1.3,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> requestPermissions() async {
    await Permission.location.request();

    await Permission.camera.request();

    await Permission.notification.request();

    bool locationGranted = await Permission.location.isGranted;

    bool cameraGranted = await Permission.camera.isGranted;

    bool notificationGranted = await Permission.notification.isGranted;

    if (locationGranted && cameraGranted && notificationGranted) {
      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please allow all permissions')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundColor,

      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 26),

            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 30),

              decoration: BoxDecoration(
                color: AppColors.cardColor,

                borderRadius: BorderRadius.circular(26),

                border: Border.all(color: AppColors.neonBlue),
              ),

              child: Column(
                mainAxisSize: MainAxisSize.min,

                children: [
                  const Text(
                    'Permissions Required',
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'We need the following permissions\n'
                    'to ensure your safety',

                    textAlign: TextAlign.center,

                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 28),

                  permissionTile(
                    icon: Icons.location_on_outlined,
                    title: 'Location',
                    subtitle: 'Track your current position',
                  ),

                  permissionTile(
                    icon: Icons.videocam_outlined,
                    title: 'Camera',
                    subtitle: 'For indoor navigation (SLAM)',
                  ),

                  permissionTile(
                    icon: Icons.notifications_none_rounded,
                    title: 'Notifications',
                    subtitle: 'To receive emergency alerts',
                  ),

                  const SizedBox(height: 10),

                  const Text(
                    'You can change permissions later from settings.',

                    textAlign: TextAlign.center,

                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),

                  const SizedBox(height: 28),

                  PrimaryButton(
                    text: 'GRANT PERMISSIONS',
                    onTap: requestPermissions,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
