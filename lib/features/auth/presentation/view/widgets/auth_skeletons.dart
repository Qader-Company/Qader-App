import 'package:flutter/material.dart';
import '../../../../../core/widgets/skeleton.dart';

/// Placeholder of the signed-in user (name, email and the profile button)
/// while the session is restored.
class AccountSkeleton extends StatelessWidget {
  const AccountSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonBox(width: 180, height: 20),
        SizedBox(height: 12),
        SkeletonBox(width: 220, height: 12),
        SizedBox(height: 20),
        SkeletonBox(height: 40, radius: 8),
      ],
    ),
  );
}

/// Placeholder of the email verification form (heading, email, the six
/// code boxes and both buttons) while the app moves on after verifying.
class OtpFormSkeleton extends StatelessWidget {
  const OtpFormSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        const SkeletonBox(width: 200, height: 22),
        const SizedBox(height: 12),
        const SkeletonBox(width: 260, height: 12),
        const SizedBox(height: 8),
        const SkeletonBox(width: 160, height: 12),
        const SizedBox(height: 24),
        // Six code boxes that share the width, like the real field.
        Row(
          children: [
            for (var i = 0; i < 6; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              const Expanded(child: SkeletonBox(height: 52, radius: 8)),
            ],
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonBox(height: 40, radius: 8),
        const SizedBox(height: 12),
        const SkeletonBox(height: 40, radius: 8),
      ],
    ),
  );
}
