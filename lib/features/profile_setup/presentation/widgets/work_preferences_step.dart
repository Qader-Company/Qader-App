import 'package:flutter/material.dart';
import '../profile_setup_controller.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';
import 'profile_lookup_select.dart';

class WorkPreferencesStep extends StatelessWidget {
  const WorkPreferencesStep({super.key, required this.draft});
  final ProfileSetupController draft;
  @override
  Widget build(BuildContext context) {
    ProfileChoices choices(
      String label,
      String key,
      List<String> options, {
      bool required = false,
    }) => ProfileChoices(
      label,
      value: draft.value(key),
      options: options,
      required: required,
      onChanged: (v) => draft.select(key, v),
    );
    Widget currency(String key) => draft.isConnected
        ? ProfileLookupSelect(
            '',
            draft: draft,
            lookup: ProfileLookup.currencies,
            value: draft.value(key),
            required: true,
            onChanged: (v) => draft.select(key, v),
          )
        : ProfileSelect(
            '',
            hint: 'Select currency',
            value: draft.value(key),
            required: true,
            items: const ['SAR', 'EGP', 'AED', 'USD', 'EUR'],
            onChanged: (v) => draft.select(key, v),
          );
    String? salary(String? value) {
      final missing = requiredProfile(context, value);
      if (missing != null) return missing;
      final n = double.tryParse(value!.trim());
      return n != null && n.isFinite && n >= 0
          ? null
          : pc(context, 'Enter a valid salary');
    }

    return ProfileColumn(
      gap: 24,
      children: [
        if (const [
          'work_types',
          'work_modes',
          'notice_period_days',
          'willing_to_relocate',
        ].any(draft.showsField))
          ProfileSection(
            'Work Info',
            children: [
              if (draft.showsField('work_types'))
                if (draft.isConnected)
                  ProfileLookupMultiSelect(
                    'Work Type',
                    draft: draft,
                    lookup: ProfileLookup.workTypes,
                    selectionKey: 'work_types',
                    required: true,
                  )
                else
                  choices('Work Type', 'workType', const [
                    'Full Time',
                    'Part Time',
                  ], required: true),
              if (draft.showsField('work_modes'))
                if (draft.isConnected)
                  ProfileLookupMultiSelect(
                    'Work Mode',
                    draft: draft,
                    lookup: ProfileLookup.workModes,
                    selectionKey: 'work_modes',
                    required: true,
                  )
                else
                  choices('Work Mode', 'workMode', const [
                    'On Site',
                    'Remote',
                    'Hybrid',
                  ], required: true),
              if (draft.showsField('notice_period_days'))
                if (draft.isConnected)
                  ProfileInput(
                    'Notice Period',
                    controller: draft.text('noticeDays'),
                    required: true,
                    type: TextInputType.number,
                    validator: (v) {
                      final n = int.tryParse(v?.trim() ?? '');
                      return n != null && n >= 0 && n <= 365
                          ? null
                          : pc(context, 'Enter notice days between 0 and 365');
                    },
                  )
                else
                  ProfileSelect(
                    'Notice Period',
                    required: true,
                    hint: 'Select Period',
                    value: draft.value('notice'),
                    items: const [
                      'Immediately',
                      '2 weeks',
                      '1 month',
                      '2 months',
                      '3 months',
                    ],
                    onChanged: (v) => draft.select('notice', v),
                  ),
              if (draft.showsField('willing_to_relocate'))
                choices('Willing to Relocate', 'relocate', const ['Yes', 'No']),
            ],
          ),
        if (draft.showsField('expected_salary') ||
            draft.showsField('current_salary'))
          ProfileSection(
            'Salary Details',
            children: [
              if (draft.showsField('expected_salary'))
                ProfileColumn(
                  gap: 8,
                  children: [
                    const ProfileLabel('Expected Salary Range', required: true),
                    currency('expectedCurrency'),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ProfileInput(
                            '',
                            controller: draft.text('minSalary'),
                            hint: 'Min 0',
                            type: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: salary,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ProfileInput(
                            '',
                            controller: draft.text('maxSalary'),
                            hint: 'Max 0',
                            type: const TextInputType.numberWithOptions(
                              decimal: true,
                            ),
                            validator: (v) {
                              final invalid = salary(v);
                              if (invalid != null) return invalid;
                              final min = double.tryParse(
                                draft.text('minSalary').text.trim(),
                              );
                              return min != null &&
                                      double.parse(v!.trim()) < min
                                  ? pc(
                                      context,
                                      'Maximum must be at least minimum',
                                    )
                                  : null;
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              if (draft.showsField('current_salary'))
                ProfileColumn(
                  children: [
                    const ProfileLabel('Current Salary Range', required: true),
                    currency('currentCurrency'),
                    ProfileInput(
                      '',
                      controller: draft.text('currentSalary'),
                      hint: 'Enter your current salary',
                      type: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: salary,
                    ),
                  ],
                ),
            ],
          ),
      ],
    );
  }
}
