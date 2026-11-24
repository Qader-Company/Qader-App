import 'package:flutter/material.dart';
import '../cubit/profile_setup_cubit.dart';
import '../profile_copy.dart';
import 'profile_lookup_select.dart';
import 'profile_widgets.dart';

/// One language entry (language and proficiency) in the basic info step.
class LanguageCard extends StatelessWidget {
  const LanguageCard({
    super.key,
    required this.draft,
    required this.entry,
    required this.index,
  });
  final ProfileSetupCubit draft;
  final LanguageEntry entry;
  final int index;
  @override
  Widget build(BuildContext context) => ProfileEntryCard(
    title: '${pc(context, 'Language')} ${index + 1}',
    onRemove: () => draft.removeLanguage(entry.id),
    children: [
      if (draft.isConnected)
        ProfileLookupSelect(
          'Language',
          draft: draft,
          lookup: ProfileLookup.languages,
          value: entry.language,
          validator: (v) =>
              entry.level != null ? requiredProfile(context, v) : null,
          onChanged: (v) =>
              draft.updateLanguage(entry.id, (e) => e.copyWith(language: v)),
        )
      else
        ProfileSelect(
          'Language',
          hint: 'Select language',
          value: entry.language,
          items: const [
            'English',
            'Arabic',
            'French',
            'German',
            'Spanish',
            'Other',
          ],
          validator: (v) =>
              entry.level != null ? requiredProfile(context, v) : null,
          onChanged: (v) =>
              draft.updateLanguage(entry.id, (e) => e.copyWith(language: v)),
        ),
      if (draft.isConnected)
        ProfileLookupSelect(
          'Proficiency Level',
          draft: draft,
          lookup: ProfileLookup.languageProficiencies,
          value: entry.level,
          validator: (v) =>
              entry.language != null ? requiredProfile(context, v) : null,
          onChanged: (v) =>
              draft.updateLanguage(entry.id, (e) => e.copyWith(level: v)),
        )
      else
        ProfileSelect(
          'Proficiency Level',
          hint: 'Select proficiency',
          value: entry.level,
          items: const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'Native'],
          validator: (v) =>
              entry.language != null ? requiredProfile(context, v) : null,
          onChanged: (v) =>
              draft.updateLanguage(entry.id, (e) => e.copyWith(level: v)),
        ),
    ],
  );
}
