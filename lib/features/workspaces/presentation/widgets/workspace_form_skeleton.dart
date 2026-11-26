import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Shape of "Create Your Workspace" while its lists load.
class WorkspaceFormSkeleton extends StatelessWidget {
  const WorkspaceFormSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Center(child: SkeletonBox(width: 80, height: 34)),
        const SizedBox(height: 24),
        const SkeletonBox(width: 200, height: 20),
        const SizedBox(height: 8),
        const SkeletonBox(width: 260),
        const SizedBox(height: 20),
        const SkeletonBox(width: 140, height: 14),
        const SizedBox(height: 12),
        const SkeletonBox(height: 100, radius: 8),
        for (var i = 0; i < 4; i++) ...[
          const SizedBox(height: 16),
          const SkeletonField(),
        ],
      ],
    ),
  );
}
