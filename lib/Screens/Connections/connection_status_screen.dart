import 'package:flutter/material.dart';

import '../../Core/Constants/app_colors.dart';

class ConnectionStatusScreen extends StatelessWidget {
  final bool internetAvailable;
  final bool gpsEnabled;
  final bool arSupported;

  const ConnectionStatusScreen({
    super.key,
    required this.internetAvailable,
    required this.gpsEnabled,
    required this.arSupported,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),

          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,

            children: [
              Icon(
                internetAvailable ? Icons.wifi : Icons.wifi_off_rounded,

                size: 120,

                color: internetAvailable
                    ? AppColors.neonGreen
                    : AppColors.neonBlue,
              ),

              const SizedBox(height: 30),

              const Text(
                'SYSTEM STATUS',

                textAlign: TextAlign.center,

                style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 35),

              buildStatusTile('Internet', internetAvailable),

              buildStatusTile('GPS', gpsEnabled),

              buildStatusTile('ARCore Support', arSupported),

              const SizedBox(height: 25),

              const Text(
                'Offline evacuation mode '
                'is still available.',

                textAlign: TextAlign.center,

                style: TextStyle(color: AppColors.textSecondary, fontSize: 16),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildStatusTile(String title, bool status) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),

      padding: const EdgeInsets.all(18),

      decoration: BoxDecoration(
        color: AppColors.cardColor,

        borderRadius: BorderRadius.circular(18),

        border: Border.all(color: status ? AppColors.neonGreen : Colors.red),
      ),

      child: Row(
        children: [
          Icon(
            status ? Icons.check_circle : Icons.cancel,

            color: status ? AppColors.neonGreen : Colors.red,
          ),

          const SizedBox(width: 14),

          Expanded(child: Text(title, style: const TextStyle(fontSize: 16))),

          Text(
            status ? 'Active' : 'Unavailable',

            style: TextStyle(color: status ? AppColors.neonGreen : Colors.red),
          ),
        ],
      ),
    );
  }
}


