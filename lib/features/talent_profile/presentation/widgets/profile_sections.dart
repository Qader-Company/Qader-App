import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../domain/entities/talent_profile.dart';
import '../profile_copy.dart';
import '../../../../core/helpers/feature_dialog.dart';
import 'profile_components.dart';
import 'profile_experience_widgets.dart';
import '../../../../core/resources/app_colors.dart';

class ProfileBasicInfo extends StatelessWidget {
  const ProfileBasicInfo({super.key, required this.profile});
  final TalentProfile profile;
  @override
  Widget build(BuildContext context) {
    final birth = profile.dateOfBirth;
    final details = [
      if (profile.shows('phone_number') && profile.phone.isNotEmpty)
        ProfileDetail('Phone Number', profile.phone),
      if (profile.shows('whatsapp_number') && profile.whatsapp.isNotEmpty)
        ProfileDetail('WhatsApp', profile.whatsapp),
      if (profile.shows('email') && profile.email.isNotEmpty)
        ProfileDetail('Email', profile.email),
      if (profile.shows('nationality_country_id') &&
          profile.nationality.isNotEmpty)
        ProfileDetail('Nationality', profile.nationality),
      if (profile.shows('religion') && profile.religion.isNotEmpty)
        ProfileDetail('Religion', profileCodeLabel(context, profile.religion)),
      if (profile.shows('residence_city_id') && profile.city.isNotEmpty)
        ProfileDetail('City', profile.city),
      if (profile.shows('residence_country_id') && profile.country.isNotEmpty)
        ProfileDetail('Country', profile.country),
      if (profile.shows('gender') && profile.gender.isNotEmpty)
        ProfileDetail('Gender', profileCodeLabel(context, profile.gender)),
      if (profile.shows('date_of_birth') && birth != null)
        ProfileDetail(
          'Date of Birthday',
          '${birth.day}/${birth.month}/${birth.year}',
        ),
    ];
    final languages = profile.shows('languages')
        ? profile.languages
        : const <ProfileLanguage>[];
    return ProfileStack(
      gap: 24,
      children: [
        if (details.isNotEmpty)
          ProfileStack(
            gap: 12,
            children: [const ProfileHeading('Contact & Personal'), ...details],
          ),
        if (languages.isNotEmpty)
          ProfileStack(
            gap: 12,
            children: [
              const ProfileHeading('Languages'),
              for (final language in languages) _LanguageTile(language),
            ],
          ),
      ],
    );
  }
}

class _LanguageTile extends StatelessWidget {
  const _LanguageTile(this.language);
  final ProfileLanguage language;
  @override
  Widget build(BuildContext context) {
    final native = language.level == 'native';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.surfaceMuted),
      ),
      child: Row(
        children: [
          const Icon(Icons.language, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              language.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          if (language.level.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: native ? AppColors.green50 : AppColors.purple50,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                profileCodeLabel(context, language.level),
                style: TextStyle(
                  fontSize: 12,
                  color: native ? AppColors.green600 : AppColors.purple600,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ProfileSkillsExperience extends StatelessWidget {
  const ProfileSkillsExperience({
    super.key,
    required this.profile,
    required this.preview,
  });
  final TalentProfile profile;
  final bool preview;
  @override
  Widget build(BuildContext context) => ProfileStack(
    gap: 24,
    children: [
      if (profile.shows('skill_ids') && profile.skills.isNotEmpty)
        ProfileStack(
          gap: 12,
          children: [
            const ProfileHeading('Skills'),
            ProfileTags(profile.skills),
          ],
        ),
      if (profile.shows('tool_ids') && profile.tools.isNotEmpty)
        ProfileStack(
          gap: 12,
          children: [const ProfileHeading('Tools'), ProfileTags(profile.tools)],
        ),
      if (profile.shows('experiences') && profile.experiences.isNotEmpty)
        ProfileStack(
          gap: 12,
          children: [
            const ProfileHeading('Work Experience'),
            for (final experience in profile.experiences)
              ProfileExperienceTile(experience: experience, preview: preview),
          ],
        ),
      if (profile.shows('projects') && profile.projects.isNotEmpty)
        ProfileStack(
          gap: 12,
          children: [
            const ProfileHeading('Projects'),
            for (final project in profile.projects)
              ProfileProjectCard(project: project, preview: preview),
          ],
        ),
    ],
  );
}

class ProfileWorkPreferences extends StatelessWidget {
  const ProfileWorkPreferences({
    super.key,
    required this.profile,
    required this.preview,
  });
  final TalentProfile profile;
  final bool preview;
  @override
  Widget build(BuildContext context) {
    final tags = [
      if (profile.shows('work_types'))
        for (final type in profile.workTypes) profileCodeLabel(context, type),
      if (profile.shows('work_modes'))
        for (final mode in profile.workModes) profileCodeLabel(context, mode),
    ];
    final notice = profile.noticePeriodDays;
    final relocate = profile.willingToRelocate;
    final cv = profile.shows('cv') ? profile.cvFileName : null;
    return ProfileStack(
      gap: 24,
      children: [
        ProfileStack(
          gap: 12,
          children: [
            const ProfileHeading('Availability'),
            if (tags.isNotEmpty) ProfileTags(tags),
            if (profile.shows('expected_salary') &&
                profile.expectedSalary.isNotEmpty)
              ProfileDetail('Expected Salary', profile.expectedSalary),
            if (profile.shows('current_salary') &&
                profile.currentSalary.isNotEmpty)
              ProfileDetail('Current Salary', profile.currentSalary),
            if (profile.shows('notice_period_days') && notice != null)
              ProfileDetail(
                'Notice Period',
                'talent_notice_days'.tr(
                  context: context,
                  namedArgs: {'count': '$notice'},
                ),
              ),
            if (profile.shows('willing_to_relocate') && relocate != null)
              ProfileDetail(
                'Willing to Relocate',
                tc(context, relocate ? 'Yes' : 'No'),
              ),
          ],
        ),
        if (cv != null)
          ProfileStack(
            gap: 12,
            children: [
              const ProfileHeading('CV / Resume'),
              _CvTile(fileName: cv, preview: preview),
            ],
          ),
      ],
    );
  }
}

class _CvTile extends StatelessWidget {
  const _CvTile({required this.fileName, required this.preview});
  final String fileName;
  final bool preview;
  @override
  Widget build(BuildContext context) => Material(
    color: AppColors.paleBlue,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: const BorderSide(color: AppColors.blueLight),
    ),
    child: InkWell(
      borderRadius: BorderRadius.circular(8),
      // The media download endpoint is not connected yet.
      onTap: () => preview
          ? profileNotice(
              context,
              'CV / Resume',
              'This preview does not include an uploaded CV file',
            )
          : showPendingFeature(context, 'talent_cv_resume'),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            const Icon(
              Icons.description_outlined,
              size: 24,
              color: profileBlue,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: ProfileStack(
                gap: 4,
                children: [
                  Text(
                    fileName,
                    style: const TextStyle(fontSize: 14, color: profileBlue),
                  ),
                  Text(
                    tc(context, 'Uploaded CV'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.neutral500,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}
