import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/talent_profile.dart';
import '../profile_copy.dart';
import 'profile_components.dart';

/// One job on the work-experience timeline.
class ProfileExperienceTile extends StatelessWidget {
  const ProfileExperienceTile({
    super.key,
    required this.experience,
    required this.preview,
  });
  final ProfileExperience experience;
  final bool preview;

  String _period(BuildContext context) {
    final format = DateFormat('MMM yyyy', context.locale.toString());
    final start = experience.start;
    final end = experience.end;
    return [
      if (start != null) format.format(start),
      if (experience.current)
        tc(context, 'Present')
      else if (end != null)
        format.format(end),
    ].join(' - ');
  }

  @override
  Widget build(BuildContext context) {
    final period = _period(context);
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: experience.current
                      ? profileBlue
                      : AppColors.neutral300,
                ),
              ),
              Expanded(child: Container(width: 1, color: AppColors.neutral200)),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfileStack(
              gap: 4,
              children: [
                Text(
                  experience.title,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (experience.company.isNotEmpty)
                  Text(
                    experience.company,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral600,
                    ),
                  ),
                if (period.isNotEmpty)
                  Text(
                    period,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                if (experience.description.isNotEmpty)
                  Text(
                    experience.description,
                    style: const TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.neutral500,
                    ),
                  ),
                if (experience.companyUrl case final url?)
                  _ExternalLink(
                    label: tc(context, 'Company profile'),
                    onPressed: () => openProfileLink(
                      context,
                      preview: preview,
                      url: url,
                      title: 'Company profile',
                      sampleMessage: 'Company details are not connected yet',
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class ProfileProjectCard extends StatelessWidget {
  const ProfileProjectCard({
    super.key,
    required this.project,
    required this.preview,
  });
  final ProfileProject project;
  final bool preview;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.neutral200),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ProfileStack(
      gap: 8,
      children: [
        Text(
          project.name,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        if (project.description.isNotEmpty)
          Text(
            project.description,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.neutral500,
            ),
          ),
        if (project.url case final url?)
          _ExternalLink(
            label: project.name,
            onPressed: () => openProfileLink(
              context,
              preview: preview,
              url: url,
              title: 'Project link',
              sampleMessage: 'This sample project has no live URL',
            ),
          ),
      ],
    ),
  );
}

class _ExternalLink extends StatelessWidget {
  const _ExternalLink({required this.label, required this.onPressed});
  final String label;
  final VoidCallback onPressed;
  @override
  Widget build(BuildContext context) => Align(
    alignment: AlignmentDirectional.centerStart,
    child: TextButton.icon(
      style: TextButton.styleFrom(padding: EdgeInsets.zero),
      icon: const Icon(Icons.open_in_new, size: 14),
      label: Text(label, style: const TextStyle(fontSize: 12)),
      onPressed: onPressed,
    ),
  );
}
