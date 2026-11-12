import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_image.dart';
import '../../../../core/widgets/qader_asset.dart';
import '../../domain/entities/talent_profile.dart';
import '../profile_copy.dart';
import 'profile_components.dart';
import '../../../../core/widgets/reevaluation_countdown.dart';
import '../../../../core/resources/app_colors.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.preview,
    required this.onEdit,
    required this.onEvaluation,
  });
  final TalentProfile profile;

  /// Sample profile: links explain they are not live instead of opening.
  final bool preview;
  final VoidCallback onEdit, onEvaluation;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: AppColors.neutral200),
      borderRadius: BorderRadius.circular(12),
    ),
    child: ProfileStack(
      gap: 8,
      children: [
        Row(
          children: [
            if (profile.avatarUrl != null)
              DefaultImage(
                imageUrl: profile.avatarUrl,
                width: 64,
                height: 64,
                radius: 32,
              )
            else
              CircleAvatar(
                radius: 32,
                backgroundColor: AppColors.blueSoft,
                child: Text(
                  profile.name
                      .trim()
                      .split(RegExp(r'\s+'))
                      .where((s) => s.isNotEmpty)
                      .take(2)
                      .map((s) => s[0])
                      .join(),
                  style: const TextStyle(fontSize: 20, color: profileBlue),
                ),
              ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    profile.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      height: 1.5,
                    ),
                  ),
                  if (profile.status case final status?) ...[
                    const SizedBox(height: 4),
                    _StatusBadge(status),
                  ],
                ],
              ),
            ),
          ],
        ),
        if (profile.title.isNotEmpty)
          Text(
            profile.title,
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.neutral600,
            ),
          ),
        if (profile.links.isNotEmpty)
          Wrap(
            spacing: 8,
            children: [
              for (final link in profile.links)
                _LinkButton(link: link, preview: preview),
            ],
          ),
        ProfileStack(
          gap: 4,
          children: [
            if (profile.email.isNotEmpty)
              _Contact(
                const QaderAsset('mail', width: 14, height: 14),
                profile.email,
              ),
            if (profile.location.isNotEmpty)
              _Contact(
                const QaderAsset('location', width: 14, height: 14),
                profile.location,
              ),
            if (profile.phone.isNotEmpty)
              _Contact(
                const QaderAsset('phone', width: 14, height: 14),
                profile.phone,
              ),
            if (profile.yearsOfExperience case final years?)
              _Contact(
                const Icon(
                  Icons.work_outline,
                  size: 14,
                  color: AppColors.neutral500,
                ),
                'talent_years_experience'.tr(
                  context: context,
                  namedArgs: {'count': '$years'},
                ),
              ),
          ],
        ),
        if (profile.summary.isNotEmpty)
          Text(
            profile.summary,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.neutral500,
            ),
          ),
        if (profile.reviewAvailableAt != null)
          ProfileReevaluationCountdown(deadline: profile.reviewAvailableAt!),
        if (profile.completion case final completion?)
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: completion,
                    minHeight: 6,
                    color: AppColors.blue,
                    backgroundColor: AppColors.neutral200,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(completion * 100).round()}%',
                style: const TextStyle(fontSize: 12),
              ),
            ],
          ),
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 40,
                // Plain OutlinedButton: the shared DefaultButton has no
                // tinted-fill outlined variant.
                child: OutlinedButton(
                  onPressed: onEvaluation,
                  style: OutlinedButton.styleFrom(
                    backgroundColor: AppColors.paleBlue,
                    foregroundColor: profileBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    side: const BorderSide(color: AppColors.blueLight),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const QaderAsset('lock', width: 12, height: 14),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text(
                          tc(context, 'Evaluation'),
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DefaultButton.compact(
                text: tc(context, 'Edit Profile'),
                onPressed: onEdit,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge(this.status);
  final TalentProfileStatus status;
  @override
  Widget build(BuildContext context) {
    final accepted = status == TalentProfileStatus.accepted;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: accepted ? AppColors.green50 : AppColors.red50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        tc(context, switch (status) {
          TalentProfileStatus.accepted => 'Accepted',
          TalentProfileStatus.rejected => 'Rejected',
          TalentProfileStatus.restricted => 'Profile Restricted',
        }),
        style: TextStyle(
          fontSize: 12,
          color: accepted ? AppColors.green600 : AppColors.alertRed,
        ),
      ),
    );
  }
}

class _LinkButton extends StatelessWidget {
  const _LinkButton({required this.link, required this.preview});
  final ProfileLink link;
  final bool preview;
  @override
  Widget build(BuildContext context) => SizedBox(
    width: 32,
    height: 32,
    child: IconButton(
      padding: EdgeInsets.zero,
      tooltip: switch (link.kind) {
        ProfileLinkKind.linkedin => 'LinkedIn',
        ProfileLinkKind.behance => 'Behance',
        ProfileLinkKind.portfolio => 'Portfolio',
        ProfileLinkKind.github => 'GitHub',
      },
      style: IconButton.styleFrom(
        backgroundColor: AppColors.paleBlue,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
      ),
      onPressed: () => openProfileLink(
        context,
        preview: preview,
        url: link.url,
        title: 'Social link',
        sampleMessage: 'This sample profile has no live social links',
      ),
      icon: switch (link.kind) {
        ProfileLinkKind.linkedin => const _LinkText('in'),
        ProfileLinkKind.behance => const _LinkText('Bē'),
        ProfileLinkKind.portfolio => const Icon(
          Icons.language,
          size: 20,
          color: profileBlue,
        ),
        ProfileLinkKind.github => const Icon(
          Icons.code,
          size: 20,
          color: profileBlue,
        ),
      },
    ),
  );
}

class _LinkText extends StatelessWidget {
  const _LinkText(this.text);
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(
      color: profileBlue,
      fontSize: 16,
      fontWeight: FontWeight.w600,
    ),
  );
}

class _Contact extends StatelessWidget {
  const _Contact(this.icon, this.text);
  final Widget icon;
  final String text;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      icon,
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: AppColors.neutral500,
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}
