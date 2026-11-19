import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Placeholder offer cards while a page of offers loads.
class OfferListSkeleton extends StatelessWidget {
  const OfferListSkeleton({super.key, this.count = 3});
  final int count;
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        for (var i = 0; i < count; i++) ...[
          const SizedBox(height: 12),
          const SkeletonCard(
            children: [
              Row(
                children: [
                  SkeletonBox(width: 32, height: 32, radius: 8),
                  SizedBox(width: 8),
                  SkeletonBox(width: 100, height: 14),
                  Spacer(),
                  SkeletonBox.circle(size: 20),
                ],
              ),
              SkeletonBox(width: 190, height: 14),
              SkeletonBox(width: 130, height: 18, radius: 6),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 80, height: 10),
                        SizedBox(height: 6),
                        SkeletonBox(width: 70, height: 16),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SkeletonBox(width: 60, height: 10),
                        SizedBox(height: 6),
                        SkeletonBox(width: 60, height: 14),
                      ],
                    ),
                  ),
                ],
              ),
              SkeletonBox(width: 150, height: 10),
            ],
          ),
        ],
      ],
    ),
  );
}

/// Placeholder of an offer's details (company, progress and terms) while
/// it loads.
class OfferDetailsSkeleton extends StatelessWidget {
  const OfferDetailsSkeleton({super.key});
  @override
  Widget build(BuildContext context) => Shimmer(
    child: Column(
      children: [
        const SkeletonCard(
          children: [
            Row(
              children: [
                SkeletonBox.circle(size: 32),
                SizedBox(width: 10),
                SkeletonBox(width: 140, height: 18),
              ],
            ),
            SkeletonBox(width: 200, height: 10),
            SkeletonBox(width: 170, height: 10),
          ],
        ),
        const SizedBox(height: 16),
        SkeletonCard(
          children: [
            const SkeletonBox(width: 130, height: 16),
            Row(
              children: [
                for (var i = 0; i < 3; i++) ...[
                  if (i > 0)
                    const Expanded(child: SkeletonBox(height: 2, radius: 1)),
                  const SkeletonBox.circle(size: 24),
                ],
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        const SkeletonCard(
          children: [
            SkeletonBox(width: 120, height: 16),
            SkeletonBox(width: 150, height: 28),
            SkeletonBox(width: 90, height: 10),
            SkeletonBox(height: 10),
            SkeletonBox(width: 200, height: 10),
            SkeletonBox(width: 180, height: 10),
            SkeletonBox(width: 210, height: 10),
          ],
        ),
      ],
    ),
  );
}
