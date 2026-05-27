import 'package:flutter/material.dart';
import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController employeeIdController = TextEditingController();
  final TextEditingController newPasswordController = TextEditingController();
  final TextEditingController confirmPasswordController =
      TextEditingController();

  bool obscureNew = true;
  bool obscureConfirm = true;

  // Step: 1 = Enter Employee ID, 2 = Enter New Password
  int _step = 1;

  // Dummy valid employee IDs (same as your login dummy data)
  final List<String> _validEmployeeIds = ["CSLECT-002"];

  void _verifyEmployeeId() {
    final id = employeeIdController.text.trim();

    if (id.isEmpty) {
      _showSnack("Please enter your Employee ID");
      return;
    }

    if (_validEmployeeIds.contains(id)) {
      setState(() => _step = 2);
    } else {
      _showSnack("Employee ID not found");
    }
  }

  void _resetPassword() {
    final newPass = newPasswordController.text.trim();
    final confirmPass = confirmPasswordController.text.trim();

    if (newPass.isEmpty || confirmPass.isEmpty) {
      _showSnack("Please fill all fields");
      return;
    }

    if (newPass.length < 6) {
      _showSnack("Password must be at least 6 characters");
      return;
    }

    if (newPass != confirmPass) {
      _showSnack("Passwords do not match");
      return;
    }

    // TO-DO: Replace with actual password update logic
    _showSnack("Password reset successful!");

    Future.delayed(const Duration(seconds: 1), () {
      if (!mounted) return;
      Navigator.pop(context);
    });
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.cardColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }

  @override
  void dispose() {
    employeeIdController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  // ─────────────────────────── BUILD ───────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  // ── Back Button ──
                  GestureDetector(
                    onTap: () {
                      if (_step == 2) {
                        setState(() => _step = 1);
                      } else {
                        Navigator.pop(context);
                      }
                    },
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.neonBlue.withValues(alpha: 0.3),
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_ios_new_rounded,
                        color: AppColors.neonBlue,
                        size: 18,
                      ),
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Header Icon ──
                  Center(
                    child: Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: AppColors.cardColor,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: AppColors.neonBlue.withValues(alpha: 0.5),
                          width: 2,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.neonBlue.withValues(alpha: 0.2),
                            blurRadius: 20,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Icon(
                        _step == 1 ? Icons.badge_outlined : Icons.lock_reset,
                        color: AppColors.neonBlue,
                        size: 36,
                      ),
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ── Title ──
                  Center(
                    child: Column(
                      children: [
                        Text(
                          _step == 1 ? "Verify Identity" : "Reset Password",
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _step == 1
                              ? "Enter your Employee ID to continue"
                              : "Create a strong new password",
                          style: const TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 36),

                  // ── Step Indicator ──
                  _buildStepIndicator(),

                  const SizedBox(height: 36),

                  // ── Step 1: Employee ID ──
                  if (_step == 1) ...[
                    _buildLabel("Employee ID"),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: employeeIdController,
                      hint: "e.g. CSLECT-002",
                      prefixIcon: Icons.badge_outlined,
                    ),
                    const SizedBox(height: 30),
                    PrimaryButton(
                      text: "VERIFY & CONTINUE",
                      onTap: _verifyEmployeeId,
                    ),
                  ],

                  // ── Step 2: New Password ──
                  if (_step == 2) ...[
                    _buildLabel("New Password"),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: newPasswordController,
                      hint: "Enter new password",
                      prefixIcon: Icons.lock_outline,
                      obscure: obscureNew,
                      toggleObscure: () =>
                          setState(() => obscureNew = !obscureNew),
                    ),
                    const SizedBox(height: 22),
                    _buildLabel("Confirm Password"),
                    const SizedBox(height: 10),
                    _buildTextField(
                      controller: confirmPasswordController,
                      hint: "Re-enter new password",
                      prefixIcon: Icons.lock_outline,
                      obscure: obscureConfirm,
                      toggleObscure: () =>
                          setState(() => obscureConfirm = !obscureConfirm),
                    ),
                    const SizedBox(height: 10),
                    // Password hint
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text(
                        "• Minimum 6 characters",
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                    const SizedBox(height: 30),
                    PrimaryButton(
                      text: "RESET PASSWORD",
                      onTap: _resetPassword,
                    ),
                  ],

                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ─────────────────────── HELPER WIDGETS ───────────────────────

  Widget _buildStepIndicator() {
    return Row(
      children: [
        _stepDot(1, "Verify ID"),
        Expanded(
          child: Container(
            height: 2,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: _step == 2
                    ? [AppColors.neonBlue, AppColors.neonGreen]
                    : [
                        AppColors.neonBlue.withValues(alpha: 0.3),
                        AppColors.neonBlue.withValues(alpha: 0.3),
                      ],
              ),
            ),
          ),
        ),
        _stepDot(2, "New Pass"),
      ],
    );
  }

  Widget _stepDot(int stepNum, String label) {
    final isActive = _step >= stepNum;
    final isDone = _step > stepNum;
    return Column(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: isActive ? AppColors.neonBlue : AppColors.cardColor,
            border: Border.all(
              color: isActive
                  ? AppColors.neonBlue
                  : AppColors.neonBlue.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: isActive
                ? [
                    BoxShadow(
                      color: AppColors.neonBlue.withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Center(
            child: isDone
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : Text(
                    "$stepNum",
                    style: TextStyle(
                      color: isActive ? Colors.white : AppColors.textSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: isActive ? AppColors.neonBlue : AppColors.textSecondary,
            fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 15,
        color: AppColors.textPrimary,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    bool obscure = false,
    VoidCallback? toggleObscure,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscure,
      style: const TextStyle(color: AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: AppColors.textSecondary),
        filled: true,
        fillColor: AppColors.cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.neonBlue.withValues(alpha: 0.25),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.neonBlue, width: 1.5),
        ),
        prefixIcon: Icon(prefixIcon, color: AppColors.neonBlue, size: 22),
        suffixIcon: toggleObscure != null
            ? IconButton(
                icon: Icon(
                  obscure ? Icons.visibility_off : Icons.visibility,
                  color: AppColors.textSecondary,
                  size: 22,
                ),
                onPressed: toggleObscure,
              )
            : null,
      ),
    );
  }
}
