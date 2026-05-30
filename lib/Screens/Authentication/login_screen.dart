import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';

import 'signup_screen.dart';
import 'reset_password_screen.dart';
import '../../Screens/Home/home_screen.dart';
import '../Permissions/permission_screen.dart';
import '../../widgets/primary_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // Controllers
  final TextEditingController employeeIdController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  // Dummy Login Data
  final String dummyEmployeeId = "CSLECT-002";
  final String dummyPassword = "123456";

  bool obscurePassword = true;

  // Login Function
  void login() async {
    String employeeId = employeeIdController.text.trim();

    String password = passwordController.text.trim();

    // Empty Fields Check
    if (employeeId.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));

      return;
    }

    // Login Validation
    if (employeeId == dummyEmployeeId && password == dummyPassword) {
      // Save Login State
      SharedPreferences prefs = await SharedPreferences.getInstance();

      await prefs.setBool('isLoggedIn', true);

      // Context Safety Check
      if (!mounted) return;

      // Success Message
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Login Successful")));

      // Permission check — agar koi permission missing ho toh PermissionScreen
      final locationOk = await Permission.location.isGranted;
      final cameraOk = await Permission.camera.isGranted;
      final notifOk = await Permission.notification.isGranted;
      final allGranted = locationOk && cameraOk && notifOk;

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) =>
              allGranted ? const HomeScreen() : const PermissionScreen(),
        ),
      );
    } else {
      // Invalid Credentials
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Invalid Employee ID or Password")),
      );
    }
  }

  @override
  void dispose() {
    employeeIdController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Space
                  const SizedBox(height: 30),

                  // Heading
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          "Welcome Back!",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Login to your account",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 45),

                  // Employee ID Label
                  const Text(
                    "Employee ID",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  // Employee ID Field
                  TextField(
                    controller: employeeIdController,
                    decoration: InputDecoration(
                      hintText: "Enter Employee ID",

                      filled: true,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none,
                      ),

                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Password Label
                  const Text(
                    "Password",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  // Password Field
                  TextField(
                    controller: passwordController,

                    obscureText: obscurePassword,

                    decoration: InputDecoration(
                      hintText: "Enter Password",

                      filled: true,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),

                        borderSide: BorderSide.none,
                      ),

                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                        ),

                        onPressed: () {
                          setState(() {
                            obscurePassword = !obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 14),

                  // Forgot Password
                  Align(
                    alignment: Alignment.centerRight,

                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const ResetPasswordScreen(),
                          ),
                        );
                      },

                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Login Button
                  PrimaryButton(
                    text: "LOGIN",

                    onTap: () {
                      login();
                    },
                  ),

                  const SizedBox(height: 30),

                  // Bottom Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      const Text("Don't have an account?"),

                      TextButton(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const SignupScreen(),
                            ),
                          );
                        },

                        child: const Text(
                          "Sign Up",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
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
