import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../Core/Constants/app_colors.dart';
import '../../widgets/primary_button.dart';
import 'sos_incident_form_screen.dart';

class SOSImageScreen extends StatefulWidget {
  const SOSImageScreen({super.key});

  @override
  State<SOSImageScreen> createState() => _SOSImageScreenState();
}

class _SOSImageScreenState extends State<SOSImageScreen> {
  File? capturedImage;

  Future<void> _openCamera() async {
    final picker = ImagePicker();

    final XFile? photo = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );

    if (photo != null) {
      setState(() {
        capturedImage = File(photo.path);
      });
    }
  }

  void _goToIncidentForm() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SOSIncidentFormScreen(capturedImage: capturedImage),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.camera_alt_rounded,
                  size: 100,
                  color: AppColors.neonBlue,
                ),

                const SizedBox(height: 30),

                const Text(
                  'Take a Photo',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                ),

                const SizedBox(height: 16),

                const Text(
                  'Capture the hazard or emergency\nso admin can verify the situation.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 15,
                  ),
                ),

                const SizedBox(height: 40),

                if (capturedImage != null) ...[
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: Image.file(
                      capturedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),

                  const SizedBox(height: 20),

                  PrimaryButton(
                    text: 'USE THIS PHOTO',
                    onTap: _goToIncidentForm,
                  ),

                  const SizedBox(height: 16),

                  SizedBox(
                    width: double.infinity,
                    height: 58,
                    child: OutlinedButton.icon(
                      onPressed: _openCamera,
                      icon: const Icon(
                        Icons.refresh,
                        color: AppColors.neonBlue,
                      ),
                      label: const Text(
                        'RETAKE',
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
                ] else ...[
                  PrimaryButton(text: 'OPEN CAMERA', onTap: _openCamera),

                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: _goToIncidentForm,
                    child: const Text(
                      'Skip (not recommended)',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                  ),
                ],

                const SizedBox(height: 16),

                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text(
                    '← Back',
                    style: TextStyle(color: AppColors.textSecondary),
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
