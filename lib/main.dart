import 'package:flutter/material.dart';
import 'package:smart_evacuation_system/Screens/Launch/launch_screen.dart';
import 'Core/Theme/app_theme.dart';

void main() {
  runApp(const IntelliTrakApp());
}

class IntelliTrakApp extends StatelessWidget {
  const IntelliTrakApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'IntelliTrak',
      theme: AppTheme.darkTheme,
      home: const LaunchScreen(),
    );
  }
}
