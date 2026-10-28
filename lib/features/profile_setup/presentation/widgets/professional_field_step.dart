import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart';
import '../../../../../core/widgets/qader_design.dart';
import '../profile_setup_controller.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';

class ProfessionalFieldStep extends StatelessWidget {
  const ProfessionalFieldStep({super.key, required this.draft});
  final ProfileSetupController draft;
  @override
  Widget build(BuildContext context) => ProfileColumn(
    gap: 24,
    children: [
      ProfileColumn(
        gap: 4,
        children: [
          Text.rich(
            TextSpan(
              text: '${pc(context, 'Select your')}\n',
              children: [
                TextSpan(
                  text: pc(context, 'Professional Field'),
                  style: const TextStyle(color: QaderDesign.blue),
                ),
              ],
            ),
            style: const TextStyle(
              fontSize: 24,
              height: 32 / 24,
              fontWeight: FontWeight.w700,
            ),
          ),
          Text(
            pc(
              context,
              'Please choose the field that best matches your professional background. You will select your specific job title in the next step.',
            ),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: QaderDesign.muted,
            ),
          ),
        ],
      ),
      if (draft.fieldsLoading) const Center(child: CircularProgressIndicator()),
      if (draft.fieldFailure case final failure?) ...[
        Text(
          failure.message.startsWith('profile_')
              ? failure.message.tr(context: context)
              : failure.message,
          style: TextStyle(color: Theme.of(context).colorScheme.error),
        ),
        if (draft.fields.isEmpty)
          TextButton(
            onPressed: draft.fieldsLoading ? null : draft.loadFields,
            child: Text('auth_retry'.tr(context: context)),
          ),
      ],
      if (!draft.fieldsLoading &&
          draft.fieldFailure == null &&
          draft.fields.isEmpty)
        Text('profile_fields_empty'.tr(context: context)),
      ProfileColumn(
        children: [
          for (var i = 0; i < draft.fields.length; i += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _FieldCard(field: draft.fields[i], draft: draft),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: i + 1 < draft.fields.length
                        ? _FieldCard(field: draft.fields[i + 1], draft: draft)
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
        ],
      ),
      Text(
        pc(context, 'Only one field can be selected at a time.'),
        style: const TextStyle(
          fontSize: 12,
          height: 1.5,
          color: QaderDesign.muted,
        ),
      ),
    ],
  );
}

class _FieldCard extends StatelessWidget {
  const _FieldCard({required this.field, required this.draft});
  final ProfessionalField field;
  final ProfileSetupController draft;
  @override
  Widget build(BuildContext context) {
    final selected = draft.selectedField == field;
    return Semantics(
      selected: selected,
      button: true,
      child: Material(
        color: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: selected ? QaderDesign.blue : QaderDesign.border,
            width: selected ? 2 : 1,
          ),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: draft.savingField || draft.fieldsLoading
              ? null
              : () => draft.chooseField(field),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        field.id == null ? pc(context, field.name) : field.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          height: 1.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    if (selected)
                      const QaderAsset('profile_radio', width: 16, height: 16)
                    else
                      Container(
                        width: 16,
                        height: 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: QaderDesign.border),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  field.id == null
                      ? pc(context, field.description)
                      : field.description,
                  style: const TextStyle(
                    fontSize: 10,
                    height: 1.8,
                    color: Color(0xFF737373),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
