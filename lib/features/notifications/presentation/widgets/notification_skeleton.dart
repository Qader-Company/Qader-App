import 'package:flutter/material.dart';
import '../../../../core/widgets/skeleton.dart';

/// Placeholder notification tiles while the list loads.
class NotificationListSkeleton extends StatelessWidget {
  const NotificationListSkeleton({super.key, this.count = 5});
  final int count;
  @override
  Widget build(BuildContext context) => Shimmer(
    child: ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      itemCount: count,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (_, _) => const _Tile(),
    ),
  );
}

/// One placeholder tile under the list while the next page loads.
class NotificationTileSkeleton extends StatelessWidget {
  const NotificationTileSkeleton({super.key});
  @override
  Widget build(BuildContext context) => const Shimmer(child: _Tile());
}

class _Tile extends StatelessWidget {
  const _Tile();
  @override
  Widget build(BuildContext context) => const SkeletonCard(
    children: [
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SkeletonBox.circle(size: 36),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonBox(width: 160, height: 14),
                SizedBox(height: 8),
                SkeletonBox(width: double.infinity, height: 10),
                SizedBox(height: 6),
                SkeletonBox(width: 180, height: 10),
                SizedBox(height: 10),
                SkeletonBox(width: 90, height: 8),
              ],
            ),
          ),
        ],
      ),
    ],
  );
}
