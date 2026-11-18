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
