import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Placeholder of the evaluation report (salary card, heading and the open
/// profile review) while `GET /talent/profile/evaluation` loads.
class EvaluationSkeleton extends StatelessWidget {
  const EvaluationSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonCard(
          padding: EdgeInsets.all(16),
          children: [
            SkeletonBox(width: 200, height: 14),
            Center(child: SkeletonBox(width: 160, height: 28)),
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonBox(width: 170, height: 16),
        const SizedBox(height: 8),
        const SkeletonBox(width: 260, height: 12),
        const SizedBox(height: 24),
        SkeletonCard(
          padding: const EdgeInsets.all(12),
          children: [
            const Row(
              children: [
                SkeletonBox.circle(size: 28),
                SizedBox(width: 8),
                SkeletonBox(width: 120, height: 14),
              ],
            ),
            for (var i = 0; i < 4; i++)
              const SkeletonBox(height: 72, radius: 8),
          ],
        ),
      ],
    ),
  );
}
