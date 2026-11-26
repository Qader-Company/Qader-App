import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Shape of the workspace dashboard while it loads.
class DashboardSkeleton extends StatelessWidget {
  const DashboardSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SkeletonBox(width: 220, height: 20),
        const SizedBox(height: 8),
        const SkeletonBox(width: 280),
        const SizedBox(height: 16),
        for (var row = 0; row < 2; row++) ...[
          const Row(
            children: [
              Expanded(child: SkeletonBox(height: 96, radius: 12)),
              SizedBox(width: 12),
              Expanded(child: SkeletonBox(height: 96, radius: 12)),
            ],
          ),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 12),
        const SkeletonBox(height: 40, radius: 8),
        const SizedBox(height: 24),
        for (var i = 0; i < 2; i++) ...[
          const SkeletonCard(
            children: [
              SkeletonBox(width: 180, height: 14),
              SkeletonBox(width: 120),
              SkeletonBox(width: 200),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}
