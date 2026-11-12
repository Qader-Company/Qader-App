import 'package:flutter/material.dart';
import '../../../../core/widgets/qader_design.dart';
import '../cubit/profile_setup_cubit.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';
import '../../../../core/widgets/default_form_field.dart';

/// Free-text skills with chips (offline preview of the skills step).
class SkillsInput extends StatelessWidget {
  const SkillsInput({super.key, required this.draft});
  final ProfileSetupCubit draft;
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
                          color: AppColors.blueStrong,
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
