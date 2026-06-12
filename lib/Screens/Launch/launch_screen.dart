import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:permission_handler/permission_handler.dart';

import '../Home/home_screen.dart';
import '../../Core/Constants/app_colors.dart';
import '../Authentication/login_screen.dart';
import '../Permissions/permission_screen.dart';

class LaunchScreen extends StatefulWidget {
  const LaunchScreen({super.key});

  @override
  State<LaunchScreen> createState() => _LaunchScreenState();
}

class _LaunchScreenState extends State<LaunchScreen> {
  @override
  void initState() {
    super.initState();

    checkLoginStatus();
  }

  /// CHECK LOGIN STATUS

  Future<void> checkLoginStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? token = prefs.getString('auth_token');
    bool isLoggedIn = token != null && token.isNotEmpty;
    
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;

    // Permissions check — already logged in users ke liye bhi
    bool permissionsGranted = false;
    if (isLoggedIn) {
      final locationOk = await Permission.location.isGranted;
      final cameraOk = await Permission.camera.isGranted;
      final notifOk = await Permission.notification.isGranted;
      permissionsGranted = locationOk && cameraOk && notifOk;
    }

    if (!mounted) return;

    Widget nextScreen;
    if (!isLoggedIn) {
      nextScreen = const LoginScreen();
    } else if (!permissionsGranted) {
      nextScreen = const PermissionScreen();
    } else {
      nextScreen = const HomeScreen();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => nextScreen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              /// LOGO
              Container(
                height: 120,
                width: 120,

                decoration: BoxDecoration(
                  color: AppColors.neonBlue,

                  borderRadius: BorderRadius.circular(30),
                ),

                child: const Icon(
                  Icons.directions_run,
                  size: 65,
                  color: Colors.white,
                ),
              ),

              const SizedBox(height: 30),

              /// APP NAME
              RichText(
                text: const TextSpan(
                  children: [
                    TextSpan(
                      text: "Intelli",

                      style: TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    TextSpan(
                      text: "Trak",

                      style: TextStyle(
                        color: AppColors.neonBlue,
                        fontSize: 38,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 14),

              /// SUBTITLE
              const Text(
                "Emergency Evacuation\nAssistance",

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 17, color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 70),

              /// LOADER
              const SizedBox(
                width: 35,
                height: 35,

                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  color: AppColors.neonBlue,
                ),
              ),

              const SizedBox(height: 25),

              /// LOADING TEXT
              const Text(
                "Loading...",

                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

