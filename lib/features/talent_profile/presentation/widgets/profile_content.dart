import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/qader_asset.dart';
import '../../domain/entities/talent_profile.dart';
import '../profile_copy.dart';
import 'edit_profile_sheet.dart';
import '../../../../core/helpers/feature_dialog.dart';
import 'profile_components.dart';
import 'profile_sections.dart';
import 'profile_summary_card.dart';
import 'restricted_profile_notice.dart';

/// Summary card, tabs and the selected section of a [profile].
class ProfileContent extends StatefulWidget {
  const ProfileContent({
    super.key,
    required this.profile,
    required this.preview,
  });
  final TalentProfile profile;

  /// Sample profile: edits stay local and links are not live.
  final bool preview;
  @override
  State<ProfileContent> createState() => _ProfileContentState();
}

class _ProfileContentState extends State<ProfileContent> {
  /// Local edits of the sample profile (preview only).
  TalentProfile? _edited;
  int _tab = 0;
  late bool _available = widget.profile.available ?? false;

  TalentProfile get _profile => _edited ?? widget.profile;

  Future<void> _edit() async {
    if (!widget.preview) {
      // Update Profile is not connected yet.
      return showPendingFeature(context, 'talent_edit_profile');
    }
    final edited = await editTalentProfile(context, _profile);
    if (edited != null && mounted) setState(() => _edited = edited);
  }

  @override
  Widget build(BuildContext context) {
    final profile = _profile;
    final status = profile.status;
    return ProfileStack(
      children: [
        ProfileSummaryCard(
          profile: profile,
          preview: widget.preview,
          onEvaluation: () => context.push(
            status == null || status == TalentProfileStatus.accepted
                ? AppRouter.profileReview
                : AppRouter.profileReport,
          ),
          onEdit: _edit,
        ),
        if (status == TalentProfileStatus.restricted)
          const RestrictedProfileNotice(),
        _ProfileTabs(
          selected: _tab,
          onSelected: (value) => setState(() => _tab = value),
        ),
        if (profile.available != null)
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
                      value: _available,
                      activeTrackColor: AppColors.blue,
                      onChanged: (value) => setState(() => _available = value),
                    ),
                  ),
                ),
              ),
            ],
          ),
        if (status == null || status == TalentProfileStatus.accepted)
          switch (_tab) {
            0 => ProfileBasicInfo(profile: profile),
            1 => ProfileSkillsExperience(
              profile: profile,
              preview: widget.preview,
            ),
            _ => ProfileWorkPreferences(
              profile: profile,
              preview: widget.preview,
            ),
          },
      ],
    );
  }
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
