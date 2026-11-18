import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Placeholder of the profile page (summary card, tabs and details) while
/// `GET /talent/profile` loads.
class ProfileSkeleton extends StatelessWidget {
  const ProfileSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SkeletonCard(
          padding: const EdgeInsets.all(16),
          children: [
            const Row(
              children: [
                SkeletonBox.circle(size: 64),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SkeletonBox(width: 150, height: 16),
                      SizedBox(height: 8),
                      SkeletonBox(width: 70, height: 18, radius: 9),
                    ],
                  ),
                ),
              ],
            ),
            const SkeletonBox(width: 190, height: 14),
            Row(
              children: [
                for (var i = 0; i < 4; i++) ...const [
                  SkeletonBox(width: 32, height: 32, radius: 4),
                  SizedBox(width: 8),
                ],
              ],
            ),
            for (final width in const [200.0, 120.0, 140.0, 110.0])
              SkeletonBox(width: width, height: 10),
            const SkeletonBox(height: 10),
            const SkeletonBox(height: 10),
            const SkeletonBox(width: 220, height: 10),
            const SkeletonBox(height: 6, radius: 3),
            const Row(
              children: [
                Expanded(child: SkeletonBox(height: 40, radius: 8)),
                SizedBox(width: 12),
                Expanded(child: SkeletonBox(height: 40, radius: 8)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 20),
        const Row(
          children: [
            SkeletonBox(width: 64, height: 14),
            SizedBox(width: 16),
            SkeletonBox(width: 110, height: 14),
            SizedBox(width: 16),
            SkeletonBox(width: 100, height: 14),
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonBox(width: 150, height: 16),
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(height: 12),
          const SkeletonCard(
            children: [
              SkeletonBox(width: 90, height: 10),
              SkeletonBox(width: 160, height: 14),
            ],
          ),
        ],
      ],
    ),
  );
}
