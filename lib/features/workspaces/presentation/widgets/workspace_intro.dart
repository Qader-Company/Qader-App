import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';

/// Logo, welcome title, hint and illustration at the top of the workspace
/// screen.
class WorkspaceIntro extends StatelessWidget {
  const WorkspaceIntro({
    super.key,
    required this.titleKey,
    required this.subtitleKey,
  });
  final String titleKey;
  final String subtitleKey;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      const QaderLogo(),
      const SizedBox(height: 24),
      Text(
        titleKey.tr(context: context),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.5,
        ),
      ),
      const SizedBox(height: 8),
      Text(
        subtitleKey.tr(context: context),
        textAlign: TextAlign.center,
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: QaderDesign.muted,
        ),
      ),
      const SizedBox(height: 24),
      const _Illustration(),
    ],
  );
}

/// Stands in for the Figma illustration until its image is exported.
class _Illustration extends StatelessWidget {
  const _Illustration();
  @override
  Widget build(BuildContext context) => Container(
    height: 200,
    decoration: BoxDecoration(
      color: AppColors.paleBlue,
      borderRadius: BorderRadius.circular(16),
    ),
    child: const Center(
      child: Icon(Icons.groups_outlined, size: 64, color: AppColors.blueLight),
    ),
  );
}

/// The four things a workspace is for, under the first-workspace welcome.
class WorkspaceFeatures extends StatelessWidget {
  const WorkspaceFeatures({super.key});

  static const _features = [
    (Icons.trending_up, AppColors.green50, AppColors.green600, 'progress'),
    (Icons.store_outlined, AppColors.yellow50, AppColors.yellow700, 'custom'),
    (Icons.groups_outlined, AppColors.paleBlue, AppColors.blue, 'team'),
    (Icons.work_outline, AppColors.red50, AppColors.red600, 'work'),
  ];

  @override
  Widget build(BuildContext context) => GridView.count(
    crossAxisCount: 2,
    shrinkWrap: true,
    physics: const NeverScrollableScrollPhysics(),
    mainAxisSpacing: 16,
    crossAxisSpacing: 16,
    childAspectRatio: 1.6,
    children: [
      for (final (icon, background, color, key) in _features)
        Column(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: background,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(height: 12),
            Text(
              'workspace_feature_$key'.tr(context: context),
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ],
        ),
    ],
  );
}
