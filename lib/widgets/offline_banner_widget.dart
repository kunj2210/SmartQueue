import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/connectivity_service.dart';
import '../utils/app_colors.dart';

class OfflineBannerWidget extends StatelessWidget {
  const OfflineBannerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<ConnectivityService>(
      builder: (context, connectivity, _) {
        if (connectivity.isOnline) return const SizedBox.shrink();
        return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
            color: AppColors.offlineBanner,
            border: Border(
              bottom: BorderSide(color: Color(0xFFFFDC7A), width: 1),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.wifi_off_rounded,
                  color: AppColors.offlineText, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '⚠️ You\'re offline. Appointments will sync when connected.',
                  style: const TextStyle(
                    color: AppColors.offlineText,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
