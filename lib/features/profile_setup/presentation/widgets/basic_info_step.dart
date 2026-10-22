import 'package:flutter/material.dart';
import '../profile_setup_controller.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';
import 'profile_upload.dart';

class BasicInfoStep extends StatelessWidget {
  const BasicInfoStep({super.key, required this.draft});
  final ProfileSetupController draft;
  static const cities = {
    'Egypt': ['Cairo', 'Alexandria', 'Giza', 'Mansoura', 'Other'],
    'Saudi Arabia': ['Riyadh', 'Jeddah', 'Dammam', 'Mecca', 'Other'],
    'United Arab Emirates': ['Dubai', 'Abu Dhabi', 'Sharjah', 'Other'],
    'Jordan': ['Amman', 'Irbid', 'Other'],
    'Other': ['Other'],
  };
  @override
  Widget build(BuildContext context) {
    String? phone(String? v) {
      final missing = requiredProfile(context, v);
      if (missing != null) return missing;
      final digits = v!.replaceAll(RegExp(r'[^0-9]'), '');
      return RegExp(r'^\+?[0-9\s()-]{7,24}$').hasMatch(v.trim()) &&
              digits.length >= 7 &&
              digits.length <= 15
          ? null
          : pc(context, 'Enter a valid phone number');
    }

    ProfileSelect select(String label, String key, List<String> items) =>
        ProfileSelect(
          label,
          items: items,
          value: draft.value(key),
          onChanged: (v) => draft.select(key, v),
        );
    return ProfileColumn(
      gap: 24,
      children: [
        ProfileSection(
          'Personal Information',
          children: [
            const ProfileLabel('CV', required: true),
            ProfileUpload(
              files: [if (draft.cv != null) draft.cv!],
              onChanged: (files) {
                draft.cv = files.isEmpty ? null : files.first;
                draft.refresh();
              },
            ),
            ProfileInput(
              'Full Name',
              controller: draft.text('name'),
              readOnly: true,
            ),
            ProfileInput(
              'Email Address',
              controller: draft.text('email'),
              readOnly: true,
            ),
            ProfileInput(
              'Phone Number',
              controller: draft.text('phone'),
              hint: '+966000000000',
              required: true,
              type: TextInputType.phone,
              validator: phone,
            ),
            ProfileInput(
              'WhatsApp Number',
              controller: draft.text('whatsapp'),
              hint: '+966000000000',
              required: true,
              type: TextInputType.phone,
              validator: phone,
            ),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: ProfileSelect(
                    'Gender',
                    required: true,
                    items: const ['Male', 'Female'],
                    value: draft.value('gender'),
                    onChanged: (v) => draft.select('gender', v),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ProfileDate(
                    'Date of Birthday',
                    controller: draft.text('birthday'),
                    birthday: true,
                    value: draft.birthday,
                    onChanged: (v) {
                      draft.birthday = v;
                      draft.refresh();
                    },
                  ),
                ),
              ],
            ),
            select('Nationality', 'nationality', const [
              'Egyptian',
              'Saudi',
              'Emirati',
              'Jordanian',
              'Other',
            ]),
            select('Religion', 'religion', const [
              'Islam',
              'Christianity',
              'Other',
              'Prefer not to say',
            ]),
          ],
        ),
        ProfileSection(
          'Address',
          large: true,
          children: [
            ProfileSelect(
              'Country',
              value: draft.value('country'),
              items: cities.keys.toList(),
              onChanged: (v) {
                draft.selections['city'] = null;
                draft.select('country', v);
              },
            ),
            select('City', 'city', cities[draft.value('country')] ?? const []),
          ],
        ),
        ProfileSection(
          'Language',
          large: true,
          onAdd: draft.addLanguage,
          addLabel: 'Add Language',
          children: [
            for (var i = 0; i < draft.languages.length; i++)
              _language(context, draft.languages[i], i),
          ],
        ),
      ],
    );
  }

  Widget _language(BuildContext context, LanguageEntry entry, int index) =>
      ProfileEntryCard(
        key: ValueKey(entry.id),
        title: '${pc(context, 'Language')} ${index + 1}',
        onRemove: () {
          draft.languages.remove(entry);
          draft.refresh();
        },
        children: [
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
            onChanged: (v) {
              entry.language = v;
              draft.refresh();
            },
          ),
          ProfileSelect(
            'Proficiency',
            hint: 'Select proficiency',
            value: entry.level,
            items: const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'Native'],
            validator: (v) =>
                entry.language != null ? requiredProfile(context, v) : null,
            onChanged: (v) {
              entry.level = v;
              draft.refresh();
            },
          ),
        ],
      );
}
