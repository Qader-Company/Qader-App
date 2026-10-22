import 'package:flutter/material.dart';
import '../profile_setup_controller.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';

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
    ProfileSelect currency(String key) => ProfileSelect(
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
        ProfileSection(
          'Work Info',
          children: [
            choices('Work Type', 'workType', const [
              'Full Time',
              'Part Time',
            ], required: true),
            choices('Work Mode', 'workMode', const [
              'On Site',
              'Remote',
              'Hybrid',
            ], required: true),
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
            choices('Willing to Relocate', 'relocate', const ['Yes', 'No']),
          ],
        ),
        ProfileSection(
          'Salary Details',
          children: [
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
                          return min != null && double.parse(v!.trim()) < min
                              ? pc(context, 'Maximum must be at least minimum')
                              : null;
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ProfileColumn(
              children: [
                const ProfileLabel('Current Salary Range', required: true),
                currency('currentCurrency'),
                ProfileInput(
                  '',
                  controller: draft.text('currentSalary'),
                  hint: 'Enter your current salary',
                  type: const TextInputType.numberWithOptions(decimal: true),
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
