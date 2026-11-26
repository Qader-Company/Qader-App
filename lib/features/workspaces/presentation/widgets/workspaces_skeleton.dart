import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Shape of the workspace screen while the list loads.
class WorkspacesSkeleton extends StatelessWidget {
  const WorkspacesSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        const SkeletonBox(width: 80, height: 34),
        const SizedBox(height: 24),
        const SkeletonBox(width: 240, height: 22),
        const SizedBox(height: 12),
        const SkeletonBox(height: 12),
        const SizedBox(height: 6),
        const SkeletonBox(width: 200, height: 12),
        const SizedBox(height: 24),
        const SkeletonBox(height: 200, radius: 16),
        const SizedBox(height: 24),
        for (var i = 0; i < 3; i++) ...[
          const SkeletonCard(
            children: [
              SkeletonBox(width: 140, height: 14),
              SkeletonBox(width: 90),
              SkeletonBox(width: 70, height: 16),
            ],
          ),
          const SizedBox(height: 12),
        ],
      ],
    ),
  );
}
