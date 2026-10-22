import 'package:flutter/material.dart';
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
      ProfileColumn(
        children: [
          for (var i = 0; i < ProfessionalField.values.length; i += 2)
            IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Expanded(
                    child: _FieldCard(
                      field: ProfessionalField.values[i],
                      draft: draft,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _FieldCard(
                      field: ProfessionalField.values[i + 1],
                      draft: draft,
                    ),
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
    final selected = draft.field == field;
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
          onTap: () => draft.chooseField(field),
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
                        pc(context, field.name),
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
                  pc(context, field.description),
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
