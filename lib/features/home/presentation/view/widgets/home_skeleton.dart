import 'package:flutter/material.dart';
import '../../../../../core/widgets/skeleton.dart';

/// Placeholder of the home dashboard while the application loads.
class HomeSkeleton extends StatelessWidget {
  const HomeSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Status banner.
        SkeletonCard(
          padding: EdgeInsets.all(16),
          children: [
            SkeletonBox(width: 180, height: 18),
            SkeletonBox(height: 10),
            SkeletonBox(width: 230, height: 10),
            SkeletonBox(width: 120, height: 36, radius: 8),
          ],
        ),
        SizedBox(height: 24),
        // Review steps.
        SkeletonCard(
          padding: EdgeInsets.all(16),
          gap: 16,
          children: [
            SkeletonBox(width: 140, height: 16),
            _StepRow(),
            _StepRow(),
            _StepRow(),
          ],
        ),
        SizedBox(height: 24),
        SkeletonCard(
          padding: EdgeInsets.all(16),
          children: [
            SkeletonBox(width: 160, height: 14),
            SkeletonBox(height: 10),
            SkeletonBox(width: 200, height: 10),
          ],
        ),
      ],
    ),
  );
}

class _StepRow extends StatelessWidget {
  const _StepRow();
  @override
  Widget build(BuildContext context) => const Row(
    children: [
      SkeletonBox.circle(size: 28),
      SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SkeletonBox(width: 150, height: 12),
            SizedBox(height: 6),
            SkeletonBox(width: 100, height: 10),
          ],
        ),
      ),
    ],
  );
}
