import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace_dashboard.dart';

/// The four counters at the top of the workspace dashboard.
class DashboardStats extends StatelessWidget {
  const DashboardStats({super.key, required this.dashboard});
  final WorkspaceDashboard dashboard;

  @override
  Widget build(BuildContext context) {
    final stats = [
      (Icons.groups_outlined, 'team_members', dashboard.teamMembers),
      (Icons.work_history_outlined, 'hiring', dashboard.activeHiringRequests),
      (Icons.assignment_outlined, 'contracts', dashboard.activeContracts),
      (Icons.grid_view_outlined, 'projects', dashboard.activeProjects),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.5,
      children: [
        for (final (icon, key, value) in stats)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: AppColors.paleBlue,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, size: 18, color: QaderDesign.blue),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'workspace_stat_$key'.tr(context: context),
                        style: const TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: AppColors.neutral500,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Text(
                  '$value',
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

/// "Build Your Team": where to start when nothing is going on yet.
class DashboardBuildTeam extends StatelessWidget {
  const DashboardBuildTeam({
    super.key,
    required this.onBrowse,
    required this.onAssistance,
  });
  final VoidCallback onBrowse;
  final VoidCallback onAssistance;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      Text(
        'workspace_build_team'.tr(context: context),
        style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
      const SizedBox(height: 6),
      Text(
        'workspace_build_team_hint'.tr(context: context),
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: QaderDesign.muted,
        ),
      ),
      const SizedBox(height: 16),
      _StartCard(
        highlighted: true,
        icon: Icons.search,
        titleKey: 'workspace_browse_talent',
        subtitleKey: 'workspace_browse_talent_hint',
        bodyKey: 'workspace_browse_talent_body',
        actionKey: 'workspace_start_browse',
        onAction: onBrowse,
      ),
      const SizedBox(height: 12),
      _StartCard(
        icon: Icons.person_add_alt_outlined,
        titleKey: 'workspace_get_help',
        subtitleKey: 'workspace_get_help_hint',
        bodyKey: 'workspace_get_help_body',
        actionKey: 'workspace_request_assistance',
        onAction: onAssistance,
      ),
    ],
  );
}

class _StartCard extends StatelessWidget {
  const _StartCard({
    required this.icon,
    required this.titleKey,
    required this.subtitleKey,
    required this.bodyKey,
    required this.actionKey,
    required this.onAction,
    this.highlighted = false,
  });
  final IconData icon;
  final String titleKey;
  final String subtitleKey;
  final String bodyKey;
  final String actionKey;
  final VoidCallback onAction;

  /// The blue gradient card ("Browse Talent").
  final bool highlighted;

  @override
  Widget build(BuildContext context) {
    final text = highlighted ? Colors.white : QaderDesign.ink;
    final muted = highlighted ? AppColors.white80 : QaderDesign.muted;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: highlighted
            ? const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.primary, AppColors.primaryNavy],
              )
            : null,
        color: highlighted ? null : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: highlighted ? null : Border.all(color: AppColors.neutral200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: highlighted ? Colors.white : AppColors.paleBlue,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 22, color: QaderDesign.blue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titleKey.tr(context: context),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: text,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitleKey.tr(context: context),
                      style: TextStyle(fontSize: 12, color: muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            bodyKey.tr(context: context),
            style: TextStyle(fontSize: 12, height: 1.5, color: text),
          ),
          const SizedBox(height: 12),
          DefaultButton.compact(
            text: actionKey.tr(context: context),
            isOutlined: !highlighted,
            color: highlighted ? Colors.white : QaderDesign.primary,
            textColor: QaderDesign.primary,
            onPressed: onAction,
          ),
        ],
      ),
    );
  }
}
