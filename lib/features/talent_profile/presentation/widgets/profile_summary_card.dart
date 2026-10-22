import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_image.dart';
import '../../../../core/widgets/qader_asset.dart';
import '../../domain/talent_profile.dart';
import '../profile_copy.dart';
import 'profile_components.dart';
import 'profile_reevaluation_countdown.dart';

class ProfileSummaryCard extends StatelessWidget {
  const ProfileSummaryCard({
    super.key,
    required this.profile,
    required this.onEdit,
    required this.onEvaluation,
  });
  final TalentProfile profile;
  final VoidCallback onEdit, onEvaluation;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      border: Border.all(color: const Color(0xFFE5E5E5)),
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
                backgroundColor: const Color(0xFFE8EFFC),
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
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: profile.status == TalentProfileStatus.accepted
                          ? const Color(0xFFF0FDF4)
                          : const Color(0xFFFEF2F2),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Text(
                      tc(context, switch (profile.status) {
                        TalentProfileStatus.accepted => 'Accepted',
                        TalentProfileStatus.rejected => 'Rejected',
                        TalentProfileStatus.restricted => 'Profile Restricted',
                      }),
                      style: TextStyle(
                        fontSize: 12,
                        color: profile.status == TalentProfileStatus.accepted
                            ? const Color(0xFF16A34A)
                            : const Color(0xFFEF232A),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        Text(
          profile.title,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Color(0xFF525252),
          ),
        ),
        Wrap(
          spacing: 8,
          children: [
            for (final social in ['LinkedIn', 'Behance', 'Portfolio', 'GitHub'])
              SizedBox(
                width: 32,
                height: 32,
                child: IconButton(
                  padding: EdgeInsets.zero,
                  tooltip: social,
                  style: IconButton.styleFrom(
                    backgroundColor: const Color(0xFFF4F8FE),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onPressed: () => profileNotice(
                    context,
                    'Social link',
                    'This sample profile has no live social links',
                  ),
                  icon: social == 'LinkedIn' || social == 'Behance'
                      ? Text(
                          social == 'LinkedIn' ? 'in' : 'Bē',
                          style: const TextStyle(
                            color: profileBlue,
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        )
                      : Icon(
                          social == 'Portfolio' ? Icons.language : Icons.code,
                          size: 20,
                          color: profileBlue,
                        ),
                ),
              ),
          ],
        ),
        ProfileStack(
          gap: 4,
          children: [
            _contact('mail', profile.email),
            _contact('location', tc(context, 'October, Giza')),
            _contact('phone', profile.phone),
            Row(
              children: [
                const Icon(
                  Icons.work_outline,
                  size: 14,
                  color: Color(0xFF737373),
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    tc(context, '2 years experience'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF737373),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
        Text(
          profile.summary,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF737373),
          ),
        ),
        if (profile.reviewAvailableAt != null)
          ProfileReevaluationCountdown(deadline: profile.reviewAvailableAt!),
        Row(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: const LinearProgressIndicator(
                  value: .8,
                  minHeight: 6,
                  color: Color(0xFF346AE8),
                  backgroundColor: Color(0xFFE5E5E5),
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Text('80%', style: TextStyle(fontSize: 12)),
          ],
        ),
        Row(
          children: [
            Expanded(
              child: DefaultButton.compact(
                text: tc(context, 'Evaluation'),
                isOutlined: true,
                color: profileBlue,
                textStyle: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
                icon: const QaderAsset('lock', width: 12, height: 14),
                onPressed: onEvaluation,
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
  Widget _contact(String icon, String text) => Row(
    children: [
      QaderAsset(icon, width: 14, height: 14),
      const SizedBox(width: 6),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            color: Color(0xFF737373),
            height: 1.5,
          ),
        ),
      ),
    ],
  );
}
