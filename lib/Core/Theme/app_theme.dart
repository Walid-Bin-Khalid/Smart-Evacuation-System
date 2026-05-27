import 'package:flutter/material.dart';
import '../Constants/app_colors.dart';

class AppTheme {
  static ThemeData darkTheme = ThemeData(
    scaffoldBackgroundColor: AppColors.background,
    brightness: Brightness.dark,
    fontFamily: 'Roboto',

    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
    ),

    textTheme: const TextTheme(bodyMedium: TextStyle(color: Colors.white)),
  );
}
