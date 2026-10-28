import 'package:flutter/material.dart';
import '../../../../../core/widgets/qader_design.dart';
import '../profile_setup_controller.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';
import 'profile_upload.dart';
import 'profile_lookup_select.dart';
import '../../../../../core/widgets/default_form_field.dart';

class SkillsExperienceStep extends StatelessWidget {
  const SkillsExperienceStep({super.key, required this.draft});
  final ProfileSetupController draft;
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
                )
              else
                _SkillsInput(draft: draft),
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
              _ExperienceCard(
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
              _ProjectCard(
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

class _SkillsInput extends StatelessWidget {
  const _SkillsInput({required this.draft});
  final ProfileSetupController draft;
  @override
  Widget build(BuildContext context) => FormField<List<String>>(
    initialValue: draft.skills,
    validator: (_) =>
        draft.skills.isEmpty ? pc(context, 'Add at least one skill') : null,
    builder: (field) => ProfileColumn(
      gap: 6,
      children: [
        const ProfileLabel('Skills', required: true),
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            border: Border.all(
              color: field.hasError
                  ? Theme.of(context).colorScheme.error
                  : QaderDesign.border,
            ),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Wrap(
            spacing: 6,
            runSpacing: 6,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              for (final skill in draft.skills)
                Container(
                  height: 24,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  decoration: BoxDecoration(
                    color: QaderDesign.paleBlue,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        skill,
                        style: const TextStyle(
                          fontSize: 12,
                          color: Color(0xFF1D52E5),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Tooltip(
                        message: '${pc(context, 'Remove')} $skill',
                        child: InkWell(
                          onTap: () {
                            draft.skills.remove(skill);
                            field.didChange([...draft.skills]);
                            draft.refresh();
                          },
                          child: const QaderAsset(
                            'profile_close',
                            width: 12,
                            height: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              SizedBox(
                width: 112,
                child: DefaultFormField(
                  compact: true,
                  borderless: true,
                  controller: draft.text('newSkill'),
                  hint: pc(context, 'Add more skills'),
                  textInputAction: TextInputAction.done,
                  textStyle: const TextStyle(fontSize: 12, height: 1.5),
                  contentPadding: EdgeInsets.zero,
                  onSubmitted: (_) => _add(field),
                ),
              ),
            ],
          ),
        ),
        if (field.hasError)
          Text(
            field.errorText!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    ),
  );
  void _add(FormFieldState<List<String>> field) {
    final skill = draft.text('newSkill').text.trim();
    if (skill.isEmpty) return;
    if (!draft.skills.any((s) => s.toLowerCase() == skill.toLowerCase())) {
      draft.skills.add(skill);
    }
    draft.text('newSkill').clear();
    field.didChange([...draft.skills]);
    draft.refresh();
  }
}

class _ExperienceCard extends StatelessWidget {
  const _ExperienceCard({
    super.key,
    required this.draft,
    required this.entry,
    required this.index,
  });
  final ProfileSetupController draft;
  final ExperienceEntry entry;
  final int index;
  String get prefix => 'experience_${entry.id}_';
  @override
  Widget build(BuildContext context) => ProfileEntryCard(
    title: '${pc(context, 'Experience')} ${index + 1}',
    onRemove: () {
      draft.experiences.remove(entry);
      draft.refresh();
    },
    children: [
      ProfileInput(
        'Job Title',
        required: true,
        controller: draft.text('${prefix}job'),
        hint: 'e.g UI/UX Designer',
      ),
      ProfileInput(
        'Company Name',
        required: true,
        controller: draft.text('${prefix}company'),
        hint: 'e.g QADER',
      ),
      ProfileInput(
        'Company URL / LinkedIn',
        controller: draft.text('${prefix}url'),
        hint: 'https://linkedin.com',
        type: TextInputType.url,
        validator: (v) => profileUrl(context, v),
      ),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: ProfileDate(
              'From',
              required: draft.isConnected,
              controller: draft.text('${prefix}from'),
              value: entry.from,
              onChanged: (v) {
                entry.from = v;
                draft.refresh();
              },
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ProfileDate(
              'To',
              controller: draft.text('${prefix}to'),
              value: entry.to,
              enabled: !entry.current,
              onChanged: (v) {
                entry.to = v;
                draft.refresh();
              },
            ),
          ),
        ],
      ),
      FormField<bool>(
        key: ValueKey(entry.from.toString() + entry.to.toString()),
        validator: (_) =>
            entry.from != null &&
                entry.to != null &&
                entry.to!.isBefore(entry.from!)
            ? pc(context, 'End date must be after start date')
            : null,
        builder: (f) => ProfileColumn(
          gap: 4,
          children: [
            Row(
              children: [
                SizedBox(
                  width: 24,
                  height: 24,
                  child: Checkbox(
                    value: entry.current,
                    onChanged: (v) {
                      entry.current = v ?? false;
                      if (entry.current) {
                        entry.to = null;
                        draft.text('${prefix}to').clear();
                      }
                      draft.refresh();
                    },
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    pc(context, 'Currently working here'),
                    style: const TextStyle(
                      fontSize: 12,
                      color: QaderDesign.muted,
                    ),
                  ),
                ),
              ],
            ),
            if (f.hasError)
              Text(
                f.errorText!,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.error,
                ),
              ),
          ],
        ),
      ),
      ProfileInput(
        'What did you do?',
        controller: draft.text('${prefix}description'),
        hint: 'Describe your responsibilities and achievements...',
        lines: 5,
      ),
    ],
  );
}

class _ProjectCard extends StatelessWidget {
  const _ProjectCard({
    super.key,
    required this.draft,
    required this.entry,
    required this.index,
  });
  final ProfileSetupController draft;
  final ProjectEntry entry;
  final int index;
  String get prefix => 'project_${entry.id}_';
  @override
  Widget build(BuildContext context) => ProfileEntryCard(
    title: '${pc(context, 'Project')} ${index + 1}',
    onRemove: () {
      draft.projects.remove(entry);
      draft.refresh();
    },
    children: [
      ProfileInput(
        'Project Name',
        controller: draft.text('${prefix}name'),
        hint: 'e.g shelfspot',
        validator: (v) {
          final active =
              draft.isConnected ||
              draft.text('${prefix}description').text.trim().isNotEmpty ||
              draft.text('${prefix}url').text.trim().isNotEmpty ||
              entry.images.isNotEmpty;
          return active ? requiredProfile(context, v) : null;
        },
      ),
      ProfileInput(
        'Project Description',
        controller: draft.text('${prefix}description'),
        hint: 'Describe your project...',
        lines: 5,
      ),
      ProfileInput(
        'Project Link',
        controller: draft.text('${prefix}url'),
        hint: 'https://...',
        type: TextInputType.url,
        validator: (v) => profileUrl(context, v),
      ),
      ProfileColumn(
        gap: 4,
        children: [
          const ProfileLabel('Project Images'),
          Text(
            pc(
              context,
              'Upload screenshots or images of your work (max 5 images)',
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF737373),
            ),
          ),
        ],
      ),
      ProfileUpload(
        images: true,
        files: entry.images,
        onChanged: (files) {
          entry.images
            ..clear()
            ..addAll(files);
          draft.refresh();
        },
      ),
    ],
  );
}
