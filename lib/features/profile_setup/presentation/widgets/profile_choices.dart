import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';

/// One option box of a choice row: tinted and outlined in blue when
/// [selected]. [label] is already translated.
class ProfileChoiceBox extends StatelessWidget {
  const ProfileChoiceBox({
    super.key,
    required this.label,
    required this.selected,
    required this.onPressed,
  });
  final String label;
  final bool selected;
  final VoidCallback? onPressed;
  @override
  Widget build(BuildContext context) => Semantics(
    selected: selected,
    child: SizedBox(
      height: 40,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          backgroundColor: selected ? AppColors.paleBlue : Colors.white,
          foregroundColor: selected ? QaderDesign.blue : AppColors.neutral700,
          disabledForegroundColor: AppColors.neutral400,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          side: BorderSide(
            color: selected ? QaderDesign.blue : QaderDesign.border,
          ),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
        ),
      ),
    ),
  );
}

/// Single choice among a few equal-width boxes.
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
                child: ProfileChoiceBox(
                  label: pc(context, options[i]),
                  selected: value == options[i],
                  onPressed: () {
                    state.didChange(options[i]);
                    onChanged(options[i]);
                  },
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
