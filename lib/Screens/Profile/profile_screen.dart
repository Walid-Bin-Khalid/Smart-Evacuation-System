import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Core/Constants/app_colors.dart';
import '../Authentication/login_screen.dart';

class ProfileScreen extends StatefulWidget {
  final String employeeName;
  final String employeeId;
  final String department;

  const ProfileScreen({
    super.key,
    required this.employeeName,
    required this.employeeId,
    required this.department,
  });

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  File? profileImage;

  /// PICK IMAGE
  Future<void> pickImage() async {
    final pickedImage = await ImagePicker().pickImage(
      source: ImageSource.gallery,
    );

    if (pickedImage != null) {
      setState(() {
        profileImage = File(pickedImage.path);
      });
    }
  }

  /// PERSONAL INFORMATION DIALOG
  void showPersonalInfo() {
    showDialog(
      context: context,

      builder: (context) {
        return AlertDialog(
          backgroundColor: AppColors.cardColor,

          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),

          title: const Text(
            'Personal Information',
            style: TextStyle(color: Colors.white),
          ),

          content: Column(
            mainAxisSize: MainAxisSize.min,

            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              infoRow('Name', widget.employeeName),
              const SizedBox(height: 15),

              infoRow('Employee ID', widget.employeeId),
              const SizedBox(height: 15),

              infoRow('Role', widget.department),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },

              child: const Text(
                'Close',
                style: TextStyle(color: AppColors.neonBlue),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget infoRow(String title, String value) {
    return Row(
      children: [
        Text(
          '$title: ',

          style: const TextStyle(
            color: AppColors.neonBlue,
            fontWeight: FontWeight.bold,
          ),
        ),

        Expanded(
          child: Text(value, style: const TextStyle(color: Colors.white)),
        ),
      ],
    );
  }

  /// LOGOUT
  void logout() {
    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(builder: (_) => const LoginScreen()),

      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,

        title: const Text(
          'Profile',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),

          child: Column(
            children: [
              /// PROFILE HEADER
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),

                decoration: BoxDecoration(
                  color: AppColors.cardColor,

                  borderRadius: BorderRadius.circular(25),

                  border: Border.all(color: AppColors.neonBlue, width: 1.5),

                  boxShadow: const [
                    BoxShadow(color: AppColors.neonBlue, blurRadius: 10),
                  ],
                ),

                child: Row(
                  children: [
                    /// PROFILE IMAGE
                    GestureDetector(
                      onTap: pickImage,

                      child: Stack(
                        children: [
                          Container(
                            width: 85,
                            height: 85,

                            decoration: BoxDecoration(
                              shape: BoxShape.circle,

                              border: Border.all(
                                color: AppColors.neonBlue,
                                width: 2,
                              ),
                            ),

                            child: CircleAvatar(
                              radius: 40,
                              backgroundColor: Colors.white12,

                              backgroundImage: profileImage != null
                                  ? FileImage(profileImage!)
                                  : null,

                              child: profileImage == null
                                  ? const Icon(
                                      Icons.person,
                                      size: 45,
                                      color: Colors.white70,
                                    )
                                  : null,
                            ),
                          ),

                          Positioned(
                            bottom: 0,
                            right: 0,

                            child: Container(
                              padding: const EdgeInsets.all(6),

                              decoration: const BoxDecoration(
                                color: AppColors.neonBlue,
                                shape: BoxShape.circle,
                              ),

                              child: const Icon(
                                Icons.edit,
                                size: 16,
                                color: Colors.black,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 18),

                    /// USER INFO
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          Text(
                            widget.employeeName,

                            style: const TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),

                          const SizedBox(height: 6),

                          Text(
                            widget.employeeId,

                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),

                          const SizedBox(height: 4),

                          Text(
                            widget.department,

                            style: const TextStyle(
                              color: AppColors.textSecondary,
                              fontSize: 15,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 30),

              /// PERSONAL INFO
              ProfileTile(
                icon: Icons.person_outline,
                title: 'Personal Information',

                onTap: showPersonalInfo,
              ),

              /// EMERGENCY CONTACTS
              ProfileTile(
                icon: Icons.phone_outlined,
                title: 'Emergency Contacts',

                onTap: () {},
              ),

              /// SETTINGS
              ProfileTile(
                icon: Icons.settings_outlined,
                title: 'App Settings',

                onTap: () {},
              ),

              /// HELP
              ProfileTile(
                icon: Icons.help_outline,
                title: 'Help & Support',

                onTap: () {},
              ),

              const Spacer(),

              /// LOGOUT BUTTON
              GestureDetector(
                onTap: logout,

                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 18),

                  decoration: BoxDecoration(
                    color: AppColors.cardColor,

                    borderRadius: BorderRadius.circular(20),

                    border: Border.all(color: AppColors.neonBlue),
                  ),

                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,

                    children: const [
                      Icon(Icons.logout, color: AppColors.neonBlue),

                      SizedBox(width: 10),

                      Text(
                        'Logout',

                        style: TextStyle(
                          color: AppColors.neonBlue,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProfileTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const ProfileTile({
    super.key,
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),

      child: GestureDetector(
        onTap: onTap,

        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),

          decoration: BoxDecoration(
            color: AppColors.cardColor,

            borderRadius: BorderRadius.circular(20),

            border: Border.all(color: AppColors.neonBlue, width: 1),
          ),

          child: Row(
            children: [
              Icon(icon, color: AppColors.neonBlue),

              const SizedBox(width: 16),

              Expanded(
                child: Text(
                  title,

                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),

              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 18,
                color: AppColors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
