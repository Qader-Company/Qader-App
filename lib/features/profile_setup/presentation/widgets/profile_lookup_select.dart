import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../profile_setup_controller.dart';
import 'profile_widgets.dart';

class ProfileLookupSelect extends StatelessWidget {
  const ProfileLookupSelect(
    this.label, {
    super.key,
    required this.draft,
    required this.lookup,
    required this.value,
    required this.onChanged,
    this.required = false,
    this.validator,
  });
  final String label;
  final ProfileSetupController draft;
  final ProfileLookup lookup;
  final String? value;
  final ValueChanged<String?> onChanged;
  final bool required;
  final String? Function(String?)? validator;

  @override
  Widget build(BuildContext context) {
    final options = draft.options(lookup);
    final labels = {for (final option in options) option.key: option.label};
    final loading = draft.lookupLoading.contains(lookup);
    final failure = draft.lookupFailures[lookup];
    final needsCountry =
        lookup == ProfileLookup.cities &&
        draft.lookupId(ProfileLookup.countries, draft.value('country')) == null;
    return ProfileColumn(
      gap: 6,
      children: [
        ProfileSelect(
          label,
          items: options.map((option) => option.key).toList(),
          value: labels.containsKey(value) ? value : null,
          itemLabel: (key) => labels[key]!,
          required: required,
          validator: validator,
          enabled: !loading && failure == null,
          onChanged: onChanged,
        ),
        if (loading) const LinearProgressIndicator(),
        if (failure != null) ...[
          Text(
            'profile_lookup_invalid'.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: TextButton(
              onPressed: () => draft.loadLookup(lookup, retry: true),
              child: Text('auth_retry'.tr()),
            ),
          ),
        ] else if (!loading && options.isEmpty)
          Text(
            (needsCountry
                    ? 'profile_lookup_select_country'
                    : 'profile_lookup_empty')
                .tr(),
          ),
      ],
    );
  }
}

class ProfileLookupMultiSelect extends StatelessWidget {
  const ProfileLookupMultiSelect(
    this.label, {
    super.key,
    required this.draft,
    required this.lookup,
    required this.selectionKey,
    this.required = false,
  });
  final String label;
  final ProfileSetupController draft;
  final ProfileLookup lookup;
  final String selectionKey;
  final bool required;
  @override
  Widget build(BuildContext context) {
    final selected = draft.selectedValues(selectionKey);
    final options = draft.options(lookup);
    final loading = draft.lookupLoading.contains(lookup);
    final failure = draft.lookupFailures[lookup];
    return FormField<Set<String>>(
      key: ValueKey('$selectionKey:${selected.join(',')}'),
      initialValue: selected,
      validator: required
          ? (v) => v == null || v.isEmpty
                ? 'profile_this_field_is_required'.tr()
                : null
          : null,
      builder: (field) => ProfileColumn(
        gap: 6,
        children: [
          ProfileLabel(label, required: required),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: [
              for (final option in options)
                FilterChip(
                  label: Text(option.label),
                  selected: selected.contains(option.key),
                  onSelected: loading || failure != null
                      ? null
                      : (checked) {
                          final values = Set<String>.of(selected);
                          checked
                              ? values.add(option.key)
                              : values.remove(option.key);
                          field.didChange(values);
                          draft.selectValues(selectionKey, values);
                        },
                ),
            ],
          ),
          if (loading) const LinearProgressIndicator(),
          if (failure != null) ...[
            Text('profile_lookup_invalid'.tr()),
            TextButton(
              onPressed: () => draft.loadLookup(lookup, retry: true),
              child: Text('auth_retry'.tr()),
            ),
          ] else if (!loading && options.isEmpty)
            Text('profile_lookup_empty'.tr()),
          if (field.hasError)
            Text(
              field.errorText!,
              style: TextStyle(color: Theme.of(context).colorScheme.error),
            ),
        ],
      ),
    );
  }
}
