import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../domain/talent_profile.dart';
import '../profile_copy.dart';
import '../widgets/profile_components.dart';
import '../widgets/profile_summary_card.dart';
import '../widgets/profile_sections.dart';
import '../widgets/edit_profile_sheet.dart';
import '../widgets/restricted_profile_notice.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/qader_asset.dart';
import '../preview/talent_profile_preview.dart';

class TalentProfileView extends StatefulWidget {
  const TalentProfileView({super.key, this.profile = previewTalentProfile});
  final TalentProfile profile;
  @override
  State<TalentProfileView> createState() => _TalentProfileViewState();
}

class _TalentProfileViewState extends State<TalentProfileView> {
  late TalentProfile profile = widget.profile;
  @override
  void didUpdateWidget(covariant TalentProfileView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.profile.status != widget.profile.status ||
        oldWidget.profile.name != widget.profile.name ||
        oldWidget.profile.email != widget.profile.email) {
      profile = widget.profile;
      tab = 0;
      available = true;
    }
  }

  int tab = 0;
  bool available = true;
  @override
  Widget build(BuildContext context) => TalentProfileScaffold(
    child: ProfileStack(
      children: [
        ProfileSummaryCard(
          profile: profile,
          onEvaluation: () => context.push(
            profile.status == TalentProfileStatus.accepted
                ? AppRouter.profileReview
                : AppRouter.profileReport,
          ),
          onEdit: () async {
            final edited = await editTalentProfile(context, profile);
            if (edited != null && mounted) setState(() => profile = edited);
          },
        ),
        if (profile.status == TalentProfileStatus.restricted)
          const RestrictedProfileNotice(),
        _ProfileTabs(
          selected: tab,
          onSelected: (value) => setState(() => tab = value),
        ),
        Row(
          children: [
            Expanded(
              child: Text(
                tc(context, 'Availability'),
                style: const TextStyle(fontSize: 14),
              ),
            ),
            Semantics(
              label: tc(context, 'Availability'),
              child: SizedBox(
                width: 40,
                height: 32,
                child: FittedBox(
                  child: Switch.adaptive(
                    value: available,
                    activeTrackColor: AppColors.blue,
                    onChanged: (value) => setState(() => available = value),
                  ),
                ),
              ),
            ),
          ],
        ),
        if (profile.status == TalentProfileStatus.accepted)
          switch (tab) {
            0 => ProfileBasicInfo(profile: profile),
            1 => const ProfileSkillsExperience(),
            _ => const ProfileWorkPreferences(),
          },
      ],
    ),
  );
}

/// Hug-width, start-aligned tabs as in the Figma profile frames.
class _ProfileTabs extends StatelessWidget {
  const _ProfileTabs({required this.selected, required this.onSelected});
  final int selected;
  final ValueChanged<int> onSelected;
  static const _labels = [
    'Basic Info',
    'Skills & Experience',
    'Work Preferences',
  ];
  @override
  Widget build(BuildContext context) => SingleChildScrollView(
    scrollDirection: Axis.horizontal,
    child: Row(
      children: [
        for (var i = 0; i < _labels.length; i++) ...[
          if (i > 0) const SizedBox(width: 12),
          Semantics(
            selected: selected == i,
            button: true,
            child: InkWell(
              key: ValueKey('profile_tab_$i'),
              onTap: () => onSelected(i),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: selected == i ? profileBlue : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      tc(context, _labels[i]),
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: selected == i
                            ? FontWeight.w500
                            : FontWeight.w400,
                        color: selected == i
                            ? profileBlue
                            : AppColors.neutral500,
                      ),
                    ),
                    // The design shows a disclosure chevron on this tab only.
                    if (i == 1) ...const [
                      SizedBox(width: 4),
                      QaderAsset('chevron_down', width: 16, height: 16),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ],
    ),
  );
}
