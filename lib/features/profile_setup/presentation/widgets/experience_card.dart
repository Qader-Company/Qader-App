import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../cubit/profile_setup_cubit.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';

/// One work experience entry in the skills & experience step.
class ExperienceCard extends StatelessWidget {
  const ExperienceCard({
    super.key,
    required this.draft,
    required this.entry,
    required this.index,
  });
  final ProfileSetupCubit draft;
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
