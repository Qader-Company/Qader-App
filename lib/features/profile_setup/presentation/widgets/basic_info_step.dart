import 'package:flutter/material.dart';
import '../profile_setup_controller.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';
import 'profile_upload.dart';
import 'profile_lookup_select.dart';
import 'profile_phone_input.dart';

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

    Widget select(
      String label,
      String key,
      List<String> items,
      ProfileLookup lookup,
    ) => draft.isConnected
        ? ProfileLookupSelect(
            label,
            draft: draft,
            lookup: lookup,
            value: draft.value(key),
            onChanged: (v) => draft.select(key, v),
          )
        : ProfileSelect(
            label,
            items: draft.isConnected ? const [] : items,
            value: draft.value(key),
            onChanged: (v) => draft.select(key, v),
          );
    return ProfileColumn(
      gap: 24,
      children: [
        if (const [
          'cv',
          'full_name',
          'email',
          'phone_number',
          'whatsapp_number',
          'gender',
          'date_of_birth',
          'nationality_country_id',
          'religion',
        ].any(draft.showsField))
          ProfileSection(
            'Personal Information',
            children: [
              if (draft.showsField('cv')) ...[
                const ProfileLabel('CV', required: true),
                ProfileUpload(
                  savedFileName: draft.savedCv?['file_name']?.toString(),
                  files: [if (draft.cv != null) draft.cv!],
                  onChanged: (files) {
                    draft.cv = files.isEmpty ? null : files.first;
                    draft.refresh();
                    // A new CV fills the empty fields of every step.
                    if (draft.cv case final file?) {
                      draft.parseCv(file);
                    } else {
                      draft.cancelCvParse();
                    }
                  },
                ),
                if (draft.isConnected) _CvAutofillStatus(draft: draft),
              ],
              if (draft.showsField('full_name'))
                ProfileInput(
                  'Full Name',
                  controller: draft.text('name'),
                  readOnly: !draft.isConnected,
                  required: draft.isConnected,
                ),
              if (draft.showsField('email'))
                ProfileInput(
                  'Email Address',
                  controller: draft.text('email'),
                  readOnly: true,
                ),
              if (draft.showsField('phone_number'))
                if (draft.isConnected)
                  ProfilePhoneInput(
                    key: const ValueKey('phone-input'),
                    label: 'Phone Number',
                    codeController: draft.text('phoneCountryCode'),
                    numberController: draft.text('phone'),
                    validator: phone,
                  )
                else
                  ProfileInput(
                    'Phone Number',
                    controller: draft.text('phone'),
                    hint: draft.isConnected
                        ? 'Enter phone number'
                        : '+966000000000',
                    required: true,
                    type: TextInputType.phone,
                    validator: phone,
                  ),
              if (draft.showsField('whatsapp_number'))
                if (draft.isConnected)
                  ProfilePhoneInput(
                    key: const ValueKey('whatsapp-input'),
                    label: 'WhatsApp Number',
                    codeController: draft.text('whatsappCountryCode'),
                    numberController: draft.text('whatsapp'),
                    validator: phone,
                  )
                else
                  ProfileInput(
                    'WhatsApp Number',
                    controller: draft.text('whatsapp'),
                    hint: draft.isConnected
                        ? 'Enter phone number'
                        : '+966000000000',
                    required: true,
                    type: TextInputType.phone,
                    validator: phone,
                  ),
              if (draft.showsField('gender') ||
                  draft.showsField('date_of_birth'))
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (draft.showsField('gender'))
                      Expanded(
                        child: draft.isConnected
                            ? ProfileLookupSelect(
                                'Gender',
                                draft: draft,
                                lookup: ProfileLookup.genders,
                                value: draft.value('gender'),
                                required: true,
                                onChanged: (v) => draft.select('gender', v),
                              )
                            : ProfileSelect(
                                'Gender',
                                required: true,
                                items: draft.isConnected
                                    ? const []
                                    : const ['Male', 'Female'],
                                value: draft.value('gender'),
                                onChanged: (v) => draft.select('gender', v),
                              ),
                      ),
                    if (draft.showsField('gender') &&
                        draft.showsField('date_of_birth'))
                      const SizedBox(width: 12),
                    if (draft.showsField('date_of_birth'))
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
              if (draft.showsField('nationality_country_id'))
                select('Nationality', 'nationality', const [
                  'Egyptian',
                  'Saudi',
                  'Emirati',
                  'Jordanian',
                  'Other',
                ], ProfileLookup.countries),
              if (draft.showsField('religion'))
                select('Religion', 'religion', const [
                  'Islam',
                  'Christianity',
                  'Other',
                  'Prefer not to say',
                ], ProfileLookup.religions),
            ],
          ),
        if (draft.showsField('residence_country_id') ||
            draft.showsField('residence_city_id'))
          ProfileSection(
            'Address',
            large: true,
            children: [
              if (draft.showsField('residence_country_id'))
                if (draft.isConnected)
                  ProfileLookupSelect(
                    'Country',
                    draft: draft,
                    lookup: ProfileLookup.countries,
                    value: draft.value('country'),
                    onChanged: draft.selectResidenceCountry,
                  )
                else
                  ProfileSelect(
                    'Country',
                    value: draft.value('country'),
                    items: draft.isConnected ? const [] : cities.keys.toList(),
                    onChanged: (v) {
                      draft.selections['city'] = null;
                      draft.select('country', v);
                    },
                  ),
              if (draft.showsField('residence_city_id'))
                select(
                  'City',
                  'city',
                  cities[draft.value('country')] ?? const [],
                  ProfileLookup.cities,
                ),
            ],
          ),
        if (draft.showsField('languages'))
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
          if (draft.isConnected)
            ProfileLookupSelect(
              'Language',
              draft: draft,
              lookup: ProfileLookup.languages,
              value: entry.language,
              validator: (v) =>
                  entry.level != null ? requiredProfile(context, v) : null,
              onChanged: (v) {
                entry.language = v;
                draft.refresh();
              },
            )
          else
            ProfileSelect(
              'Language',
              hint: 'Select language',
              value: entry.language,
              items: draft.isConnected
                  ? const []
                  : const [
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
          if (draft.isConnected)
            ProfileLookupSelect(
              'Proficiency',
              draft: draft,
              lookup: ProfileLookup.languageProficiencies,
              value: entry.level,
              validator: (v) =>
                  entry.language != null ? requiredProfile(context, v) : null,
              onChanged: (v) {
                entry.level = v;
                draft.refresh();
              },
            )
          else
            ProfileSelect(
              'Proficiency',
              hint: 'Select proficiency',
              value: entry.level,
              items: draft.isConnected
                  ? const []
                  : const ['A1', 'A2', 'B1', 'B2', 'C1', 'C2', 'Native'],
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

/// Progress and result of filling the form from the uploaded CV.
class _CvAutofillStatus extends StatelessWidget {
  const _CvAutofillStatus({required this.draft});
  final ProfileSetupController draft;
  @override
  Widget build(BuildContext context) {
    final (icon, color, fill, message) = draft.parsingCv
        ? (
            null,
            const Color(0xFF0A32DB),
            const Color(0xFFF4F8FE),
            pc(context, 'Reading your CV to fill in your details'),
          )
        : draft.cvParseFailure != null
        ? (
            Icons.info_outline,
            const Color(0xFFA16207),
            const Color(0xFFFEFCE8),
            pc(
              context,
              "We couldn't read your CV automatically. Please fill in your details",
            ),
          )
        : draft.cvAutofilled
        ? (
            Icons.check_circle_outline,
            const Color(0xFF008236),
            const Color(0xFFDCFCE7),
            pc(
              context,
              'We filled in your details from your CV. Please review them before continuing',
            ),
          )
        : (null, null, null, null);
    if (message == null) return const SizedBox.shrink();
    return Semantics(
      liveRegion: true,
      child: Container(
        key: const ValueKey('cv-autofill-status'),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: fill,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            if (icon == null)
              SizedBox.square(
                dimension: 16,
                child: CircularProgressIndicator(strokeWidth: 2, color: color),
              )
            else
              Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                message,
                style: TextStyle(fontSize: 12, height: 1.5, color: color),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
