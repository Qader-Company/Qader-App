import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../domain/entities/workspace_dashboard.dart';

/// Section title with "View all" at the end.
class DashboardSectionHeader extends StatelessWidget {
  const DashboardSectionHeader({
    super.key,
    required this.titleKey,
    required this.onViewAll,
  });
  final String titleKey;
  final VoidCallback onViewAll;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          titleKey.tr(context: context),
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
        ),
      ),
      TextButton(
        onPressed: onViewAll,
        style: TextButton.styleFrom(
          minimumSize: Size.zero,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        ),
        child: Text(
          'workspace_view_all'.tr(context: context),
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: QaderDesign.primary,
          ),
        ),
      ),
    ],
  );
}

/// Backend status text ("Open", "Active", "In Progress") in a green chip.
class DashboardStatusChip extends StatelessWidget {
  const DashboardStatusChip(this.label, {super.key});
  final String label;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: AppColors.green50,
      borderRadius: BorderRadius.circular(6),
    ),
    child: Text(
      label,
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: AppColors.green700,
      ),
    ),
  );
}

BoxDecoration get _card => BoxDecoration(
  color: Colors.white,
  borderRadius: BorderRadius.circular(12),
  border: Border.all(color: AppColors.neutral200),
);

class DashboardRequestCard extends StatelessWidget {
  const DashboardRequestCard({super.key, required this.request});
  final DashboardHiringRequest request;
  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: _card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  request.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              DashboardStatusChip(request.statusLabel),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            request.subtitle,
            style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _Fact(
                  labelKey: 'workspace_date_posted',
                  value: DateFormat.yMMMd(locale).format(request.postedAt),
                ),
              ),
              Expanded(
                child: _Fact(
                  labelKey: 'workspace_candidates',
                  value: '${request.candidates}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Fact extends StatelessWidget {
  const _Fact({required this.labelKey, required this.value});
  final String labelKey;
  final String value;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        labelKey.tr(context: context),
        style: const TextStyle(fontSize: 12, color: AppColors.neutral500),
      ),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(fontSize: 13)),
    ],
  );
}

/// The team members in one card, separated by lines.
class DashboardTeamCard extends StatelessWidget {
  const DashboardTeamCard({super.key, required this.team});
  final List<DashboardMember> team;
  @override
  Widget build(BuildContext context) => Container(
    decoration: _card,
    child: Column(
      children: [
        for (var i = 0; i < team.length; i++) ...[
          if (i > 0) const Divider(height: 1, color: AppColors.neutral200),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 18,
                  backgroundColor: AppColors.purple50,
                  child: Text(
                    team[i].name.isEmpty ? '' : team[i].name[0],
                    style: const TextStyle(color: AppColors.purple600),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        team[i].name,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      Text(
                        team[i].role,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.neutral600,
                        ),
                      ),
                    ],
                  ),
                ),
                DashboardStatusChip(team[i].statusLabel),
              ],
            ),
          ),
        ],
      ],
    ),
  );
}

class DashboardProjectCard extends StatelessWidget {
  const DashboardProjectCard({super.key, required this.project});
  final DashboardProject project;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: _card,
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                project.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            DashboardStatusChip(project.statusLabel),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          project.category,
          style: const TextStyle(fontSize: 13, color: AppColors.neutral600),
        ),
        const SizedBox(height: 12),
        Text(
          'workspace_team_size_value'.tr(
            context: context,
            namedArgs: {'count': '${project.teamSize}'},
          ),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500),
        ),
      ],
    ),
  );
}
