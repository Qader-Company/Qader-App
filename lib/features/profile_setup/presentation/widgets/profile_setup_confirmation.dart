import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../profile_copy.dart';
import 'profile_setup_header.dart';

/// Final step: profile saved (live) or submitted (offline preview).
class ProfileSetupConfirmation extends StatelessWidget {
  const ProfileSetupConfirmation({
    super.key,
    required this.connected,
    required this.onBack,
  });
  final bool connected;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: DefaultButton.compact(
          text: pc(context, connected ? 'Go to Home' : 'Preview Home'),
          onPressed: () => connected
              ? context.go(AppRouter.home)
              : context.go('${AppRouter.home}?preview=true&role=talent'),
        ),
      ),
      Padding(
        padding: const EdgeInsets.all(16),
        child: ProfileSetupHeader(showBack: false, onBack: onBack),
      ),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.blueSoft,
                ),
                child: const Center(
                  child: QaderAsset(
                    'profile_success',
                    width: 44.8,
                    height: 44.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pc(
                  context,
                  connected ? 'Profile Saved!' : 'Profile Submitted!',
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pc(
                  context,
                  connected
                      ? 'Your profile information has been saved successfully.'
                      : "Your talent profile has been submitted successfully, We'll review it and get back to you shortly.",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: AppColors.neutral500,
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
