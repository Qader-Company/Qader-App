import 'package:flutter/material.dart';
import '../cubit/profile_setup_cubit.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';
import 'profile_lookup_select.dart';
import 'skills_input.dart';
import 'experience_card.dart';
import 'project_card.dart';

class SkillsExperienceStep extends StatelessWidget {
  const SkillsExperienceStep({super.key, required this.draft});
  final ProfileSetupCubit draft;
  @override
  Widget build(BuildContext context) => ProfileColumn(
    gap: 24,
    children: [
      if (draft.showsField('professional_summary'))
        ProfileSection(
          'Professional Summary',
          children: [
            ProfileInput(
              '',
              controller: draft.text('summary'),
              hint: 'Write a brief professional summary...',
              lines: 5,
            ),
          ],
        ),
      if (const [
        'job_title_id',
        'seniority_level',
        'years_of_experience',
        'skill_ids',
        'tool_ids',
        'industry_ids',
      ].any(draft.showsField))
        ProfileSection(
          'Technical Information',
          children: [
            if (draft.showsField('job_title_id'))
              if (draft.isConnected)
                ProfileLookupSelect(
                  'Job Title',
                  draft: draft,
                  lookup: ProfileLookup.jobTitles,
                  value: draft.value('job'),
                  required: true,
                  onChanged: (v) => draft.select('job', v),
                )
              else
                ProfileSelect(
                  'Job Title',
                  required: true,
                  hint: 'Select job title',
                  value: draft.value('job'),
                  items: draft.field.jobs,
                  onChanged: (v) => draft.select('job', v),
                ),
            if (draft.showsField('seniority_level'))
              if (draft.isConnected)
                ProfileLookupSelect(
                  'Level',
                  draft: draft,
                  lookup: ProfileLookup.seniorityLevels,
                  value: draft.value('level'),
                  required: true,
                  onChanged: (v) => draft.select('level', v),
                )
              else
                ProfileSelect(
                  'Level',
                  required: true,
                  hint: 'Select Level',
                  value: draft.value('level'),
                  items: const [
                    'Entry Level',
                    'Junior',
                    'Mid Level',
                    'Senior',
                    'Lead',
                    'Manager',
                  ],
                  onChanged: (v) => draft.select('level', v),
                ),
            if (draft.showsField('years_of_experience'))
              ProfileInput(
                'Years of Experience',
                required: true,
                controller: draft.text('years'),
                hint: 'Enter years (e.g, 3)',
                type: TextInputType.number,
                validator: (v) {
                  final missing = requiredProfile(context, v);
                  if (missing != null) return missing;
                  final n = int.tryParse(v!.trim());
                  return n != null && n >= 0 && n <= 80
                      ? null
                      : pc(context, 'Enter years between 0 and 80');
                },
              ),
            if (draft.showsField('skill_ids'))
              if (draft.isConnected)
                ProfileLookupMultiSelect(
                  'Skills',
                  draft: draft,
                  lookup: ProfileLookup.skills,
                  selectionKey: 'skill_ids',
                  required: draft.requiresField('skill_ids'),
                )
              else
                SkillsInput(draft: draft),
            if (draft.showsField('tool_ids'))
              if (draft.isConnected)
                ProfileLookupMultiSelect(
                  'Tools',
                  draft: draft,
                  lookup: ProfileLookup.tools,
                  selectionKey: 'tool_ids',
                )
              else
                ProfileSelect(
                  'Tools',
                  hint: 'Select tools you use',
                  value: draft.value('tools'),
                  items: const [
                    'VS Code',
                    'Android Studio',
                    'Figma',
                    'Adobe Photoshop',
                    'Excel',
                    'Salesforce',
                    'Other',
                  ],
                  onChanged: (v) => draft.select('tools', v),
                ),
            if (draft.isConnected && draft.showsField('industry_ids'))
              ProfileLookupMultiSelect(
                'Industries',
                draft: draft,
                lookup: ProfileLookup.industries,
                selectionKey: 'industry_ids',
                required: draft.requiresField('industry_ids'),
              ),
          ],
        ),
      if (const [
        'linkedin_url',
        'github_url',
        'behance_url',
        'portfolio_url',
      ].any(draft.showsField))
        ProfileSection(
          'Portfolio & Social Links',
          large: true,
          children: [
            for (final name in ['LinkedIn', 'Behance', 'Portfolio', 'GitHub'])
              if (!draft.isConnected ||
                  name == 'LinkedIn' && draft.showsField('linkedin_url') ||
                  name == 'Portfolio' && draft.showsField('portfolio_url') ||
                  name == 'GitHub' && draft.showsField('github_url') ||
                  name == 'Behance' && draft.showsField('behance_url'))
                ProfileInput(
                  name,
                  required: name == 'LinkedIn',
                  controller: draft.text(name),
                  hint: 'https://...',
                  type: TextInputType.url,
                  validator: (v) =>
                      profileUrl(context, v, required: name == 'LinkedIn'),
                ),
          ],
        ),
      if (draft.showsField('experiences'))
        ProfileSection(
          'Work Experience',
          large: true,
          onAdd: draft.addExperience,
          addLabel: 'Add Experience',
          children: [
            for (var i = 0; i < draft.experiences.length; i++)
              ExperienceCard(
                key: ValueKey(draft.experiences[i].id),
                draft: draft,
                entry: draft.experiences[i],
                index: i,
              ),
          ],
        ),
      if (draft.showsField('projects'))
        ProfileSection(
          'Projects',
          large: true,
          onAdd: draft.addProject,
          addLabel: 'Add Project',
          children: [
            for (var i = 0; i < draft.projects.length; i++)
              ProjectCard(
                key: ValueKey(draft.projects[i].id),
                draft: draft,
                entry: draft.projects[i],
                index: i,
              ),
          ],
        ),
    ],
  );
}
