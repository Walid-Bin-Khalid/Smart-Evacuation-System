import 'package:flutter/material.dart';
import '../Permissions/permission_screen.dart';
import '../../widgets/primary_button.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  // Controllers
  final TextEditingController fullNameController = TextEditingController();

  final TextEditingController badgeIdController = TextEditingController();

  final TextEditingController departmentController = TextEditingController();

  final TextEditingController passwordController = TextEditingController();

  final TextEditingController confirmPasswordController =
      TextEditingController();

  // Role Dropdown
  String selectedRole = "Employee";

  final List<String> departments = [
    "Employee",
    "Admin",
    "Supervisor",
    "Employer",
  ];

  bool obscurePassword = true;

  void createAccount() {
    String fullName = fullNameController.text.trim();

    String badgeId = badgeIdController.text.trim();

    String password = passwordController.text.trim();

    String confirmPassword = confirmPasswordController.text.trim();

    // Empty Validation
    if (fullName.isEmpty ||
        badgeId.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Please fill all fields")));

      return;
    }

    // Password Match Validation
    if (password != confirmPassword) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Passwords do not match")));

      return;
    }

    // Success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Account Created Successfully")),
    );

      Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const PermissionScreen()),
    );
  
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
                  const SizedBox(height: 20),

                  // Heading
                  const Center(
                    child: Column(
                      children: [
                        Text(
                          "Create Account",
                          style: TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        SizedBox(height: 8),

                        Text(
                          "Sign up to continue",
                          style: TextStyle(color: Colors.grey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Employee ID
                  const Text(
                    "Employee ID",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: badgeIdController,

                    decoration: InputDecoration(
                      hintText: "Enter Employee ID",

                      filled: true,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),

                        borderSide: BorderSide.none,
                      ),

                      prefixIcon: const Icon(Icons.badge_outlined),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Full Name
                  const Text(
                    "Full Name",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: fullNameController,

                    decoration: InputDecoration(
                      hintText: "Enter Full Name",

                      filled: true,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),

                        borderSide: BorderSide.none,
                      ),

                      prefixIcon: const Icon(Icons.person_outline),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Role
                  const Text(
                    "Role",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14),

                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),

                      border: Border.all(color: Colors.grey.shade400),
                    ),

                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: selectedRole,

                        isExpanded: true,

                        items: departments.map((String department) {
                          return DropdownMenuItem<String>(
                            value: department,

                            child: Text(department),
                          );
                        }).toList(),

                        onChanged: (value) {
                          setState(() {
                            selectedRole = value!;
                          });
                        },
                      ),
                    ),
                  ),

                  const SizedBox(height: 22),

                  // Password
                  const Text(
                    "Password",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

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

                      prefixIcon: const Icon(Icons.lock_outline),

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

                  const SizedBox(height: 22),

                  // Confirm Password
                  const Text(
                    "Confirm Password",
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                  ),

                  const SizedBox(height: 10),

                  TextField(
                    controller: confirmPasswordController,

                    obscureText: obscurePassword,

                    decoration: InputDecoration(
                      hintText: "Confirm Password",

                      filled: true,

                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),

                        borderSide: BorderSide.none,
                      ),

                      prefixIcon: const Icon(Icons.lock_outline),

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

                  const SizedBox(height: 35),

                  // Signup Button
                  PrimaryButton(text: "SIGN UP", onTap: createAccount),

                  const SizedBox(height: 25),

                  // Login Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: [
                      const Text("Already have an account?"),

                      TextButton(
                        onPressed: () {
                          Navigator.pop(context);
                        },

                        child: const Text(
                          "Login",
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
