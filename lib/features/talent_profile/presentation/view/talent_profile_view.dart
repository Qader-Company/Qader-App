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

class TalentProfileView extends StatefulWidget {
  const TalentProfileView({super.key, this.profile = const TalentProfile()});
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
        LayoutBuilder(
          builder: (context, box) => Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < 3; i++)
                Expanded(
                  child: Semantics(
                    selected: tab == i,
                    button: true,
                    child: InkWell(
                      key: ValueKey('profile_tab_$i'),
                      onTap: () => setState(() => tab = i),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          vertical: 12,
                          horizontal: 2,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: tab == i
                                  ? profileBlue
                                  : Colors.transparent,
                              width: 2,
                            ),
                          ),
                        ),
                        child: Text(
                          tc(
                            context,
                            [
                              'Basic Info',
                              'Skills & Experience',
                              'Work Preferences',
                            ][i],
                          ),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            height: 1.5,
                            fontWeight: tab == i
                                ? FontWeight.w500
                                : FontWeight.w400,
                            color: tab == i
                                ? profileBlue
                                : const Color(0xFF737373),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
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
                    activeTrackColor: const Color(0xFF346AE8),
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
