import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Placeholder of a profile form step while the saved profile loads.
class ProfileFormSkeleton extends StatelessWidget {
  const ProfileFormSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            SkeletonBox.circle(size: 30),
            SizedBox(width: 8),
            SkeletonBox(width: 120, height: 16),
          ],
        ),
        const SizedBox(height: 24),
        const SkeletonBox(width: 170, height: 16),
        const SizedBox(height: 16),
        const SkeletonBox(height: 64, radius: 8),
        for (final width in const [80.0, 110.0, 120.0, 140.0, 90.0, 100.0]) ...[
          const SizedBox(height: 16),
          SkeletonField(labelWidth: width),
        ],
      ],
    ),
  );
}

/// Placeholder of the professional field cards while they load.
class ProfessionalFieldSkeleton extends StatelessWidget {
  const ProfessionalFieldSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        for (var row = 0; row < 3; row++) ...[
          if (row > 0) const SizedBox(height: 12),
          const Row(
            children: [
              Expanded(child: _FieldCard()),
              SizedBox(width: 12),
              Expanded(child: _FieldCard()),
            ],
          ),
        ],
      ],
    ),
  );
}

class _FieldCard extends StatelessWidget {
  const _FieldCard();
  @override
  Widget build(BuildContext context) => const SkeletonCard(
    gap: 8,
    children: [
      SkeletonBox(width: 90, height: 12),
      SkeletonBox(height: 8),
      SkeletonBox(width: 70, height: 8),
    ],
  );
}
