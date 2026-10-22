import 'package:flutter/material.dart';
import '../../../../../core/widgets/default_button.dart';
import '../../../../../core/widgets/default_form_field.dart';
import '../../../../../core/widgets/default_dropdown.dart';
import '../../../../../core/widgets/qader_design.dart';
import '../profile_copy.dart';

String? requiredProfile(BuildContext context, String? value) =>
    value == null || value.trim().isEmpty
    ? pc(context, 'This field is required')
    : null;
String? profileUrl(
  BuildContext context,
  String? value, {
  bool required = false,
}) {
  if (value == null || value.trim().isEmpty) {
    return required ? pc(context, 'This field is required') : null;
  }
  final uri = Uri.tryParse(value.trim());
  return uri != null &&
          ['https', 'http'].contains(uri.scheme) &&
          uri.host.contains('.')
      ? null
      : pc(context, 'Enter a valid URL');
}

class ProfileColumn extends StatelessWidget {
  const ProfileColumn({super.key, required this.children, this.gap = 12});
  final List<Widget> children;
  final double gap;
  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) SizedBox(height: gap),
        children[i],
      ],
    ],
  );
}

class ProfileLabel extends StatelessWidget {
  const ProfileLabel(this.text, {super.key, this.required = false});
  final String text;
  final bool required;
  @override
  Widget build(BuildContext context) => Text.rich(
    TextSpan(
      text: pc(context, text),
      children: [
        if (required)
          const TextSpan(
            text: '*',
            style: TextStyle(color: Colors.red),
          ),
      ],
    ),
    style: const TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      color: Color(0xFF404040),
    ),
  );
}

class ProfileSection extends StatelessWidget {
  const ProfileSection(
    this.title, {
    super.key,
    required this.children,
    this.onAdd,
    this.addLabel,
    this.large = false,
  });
  final String title;
  final List<Widget> children;
  final VoidCallback? onAdd;
  final String? addLabel;
  final bool large;
  @override
  Widget build(BuildContext context) => ProfileColumn(
    children: [
      Row(
        children: [
          Expanded(
            child: Text(
              pc(context, title),
              style: TextStyle(
                fontSize: large ? 16 : 14,
                fontWeight: FontWeight.w600,
                height: 1.5,
              ),
            ),
          ),
          if (onAdd != null) const SizedBox(width: 8),
          if (onAdd != null)
            DefaultButton.compact(
              text: pc(context, addLabel!),
              onPressed: onAdd,
              expand: false,
              height: 36,
              textStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
              icon: const SizedBox(
                width: 20,
                height: 20,
                child: Center(
                  child: QaderAsset(
                    'profile_add',
                    width: 14.5833,
                    height: 14.5833,
                  ),
                ),
              ),
            ),
        ],
      ),
      ...children,
    ],
  );
}

class ProfileInput extends StatelessWidget {
  const ProfileInput(
    this.label, {
    super.key,
    required this.controller,
    this.hint,
    this.required = false,
    this.lines = 1,
    this.type,
    this.validator,
    this.readOnly = false,
    this.enabled = true,
    this.onTap,
    this.suffixIcon,
    this.onSubmitted,
  });
  final String label;
  final TextEditingController controller;
  final String? hint;
  final bool required;
  final int lines;
  final TextInputType? type;
  final String? Function(String?)? validator;
  final bool readOnly;
  final bool enabled;
  final VoidCallback? onTap;
  final Widget? suffixIcon;
  final ValueChanged<String>? onSubmitted;
  @override
  Widget build(BuildContext context) => DefaultFormField(
    compact: true,
    label: label.isEmpty ? null : pc(context, label),
    requiredIndicator: required,
    controller: controller,
    hint: hint == null ? null : pc(context, hint!),
    maxLines: lines,
    keyboardType: type,
    readOnly: readOnly,
    enabled: enabled,
    onTap: onTap,
    suffixIcon: suffixIcon,
    onSubmitted: onSubmitted,
    validator:
        validator ?? (required ? (v) => requiredProfile(context, v) : null),
  );
}

class ProfileSelect extends StatelessWidget {
  const ProfileSelect(
    this.label, {
    super.key,
    required this.items,
    required this.onChanged,
    this.value,
    this.hint = 'Select',
    this.required = false,
    this.validator,
  });
  final String label;
  final List<String> items;
  final ValueChanged<String?> onChanged;
  final String? value;
  final String hint;
  final bool required;
  final String? Function(String?)? validator;
  @override
  Widget build(BuildContext context) => DefaultDropdown<String>(
    key: ValueKey(value),
    initialValue: value,
    items: items,
    compact: true,
    label: label.isEmpty ? null : pc(context, label),
    requiredIndicator: required,
    hint: pc(context, hint),
    itemLabel: (v) => pc(context, v),
    onChanged: onChanged,
    validator:
        validator ?? (required ? (v) => requiredProfile(context, v) : null),
    icon: const Padding(
      padding: EdgeInsets.all(4),
      child: QaderAsset('profile_down', width: 9, height: 5),
    ),
  );
}

class ProfileEntryCard extends StatelessWidget {
  const ProfileEntryCard({
    super.key,
    required this.title,
    required this.onRemove,
    required this.children,
  });
  final String title;
  final VoidCallback onRemove;
  final List<Widget> children;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: const Color(0xFFF5F5F5),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ProfileColumn(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            SizedBox(
              width: 20,
              height: 20,
              child: IconButton(
                padding: EdgeInsets.zero,
                tooltip: '${pc(context, 'Remove')} $title',
                onPressed: onRemove,
                icon: const QaderAsset(
                  'profile_trash',
                  width: 16.25,
                  height: 18,
                ),
              ),
            ),
          ],
        ),
        ...children,
      ],
    ),
  );
}

class ProfileChoices extends StatelessWidget {
  const ProfileChoices(
    this.label, {
    super.key,
    required this.options,
    required this.onChanged,
    this.value,
    this.required = false,
  });
  final String label;
  final List<String> options;
  final String? value;
  final bool required;
  final ValueChanged<String> onChanged;
  @override
  Widget build(BuildContext context) => FormField<String>(
    key: ValueKey(label + (value ?? '')),
    initialValue: value,
    validator: required ? (v) => requiredProfile(context, v) : null,
    builder: (state) => ProfileColumn(
      gap: 6,
      children: [
        ProfileLabel(label, required: required),
        Row(
          children: [
            for (var i = 0; i < options.length; i++) ...[
              if (i > 0) const SizedBox(width: 8),
              Expanded(
                child: Semantics(
                  selected: value == options[i],
                  child: DefaultButton.compact(
                    text: pc(context, options[i]),
                    isOutlined: true,
                    color: value == options[i]
                        ? QaderDesign.blue
                        : QaderDesign.border,
                    textColor: value == options[i]
                        ? QaderDesign.blue
                        : const Color(0xFF404040),
                    textStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                    onPressed: () {
                      state.didChange(options[i]);
                      onChanged(options[i]);
                    },
                  ),
                ),
              ),
            ],
          ],
        ),
        if (state.hasError)
          Text(
            state.errorText!,
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.error,
            ),
          ),
      ],
    ),
  );
}

class ProfileDate extends StatelessWidget {
  const ProfileDate(
    this.label, {
    super.key,
    required this.controller,
    required this.onChanged,
    this.value,
    this.birthday = false,
    this.enabled = true,
  });
  final String label;
  final TextEditingController controller;
  final ValueChanged<DateTime> onChanged;
  final DateTime? value;
  final bool birthday;
  final bool enabled;
  @override
  Widget build(BuildContext context) => ProfileInput(
    label,
    controller: controller,
    hint: 'mm/dd/yyyy',
    readOnly: true,
    enabled: enabled,
    onTap: () async {
      final now = DateTime.now();
      final picked = await showDatePicker(
        context: context,
        initialDate: value ?? (birthday ? DateTime(now.year - 25) : now),
        firstDate: DateTime(1900),
        lastDate: birthday ? now : DateTime(now.year + 10),
      );
      if (picked != null && context.mounted) {
        controller.text =
            '${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}';
        onChanged(picked);
      }
    },
  );
}
