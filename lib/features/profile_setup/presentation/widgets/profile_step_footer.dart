import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../cubit/profile_setup_cubit.dart';
import '../profile_copy.dart';
import 'profile_widgets.dart';

/// Bottom of a profile setup step: the step's save error, then Back and
/// Continue / Next / Save Profile.
class ProfileStepFooter extends StatelessWidget {
  const ProfileStepFooter({
    super.key,
    required this.draft,
    required this.onBack,
    required this.onNext,
  });
  final ProfileSetupCubit draft;
  final VoidCallback onBack, onNext;

  @override
  Widget build(BuildContext context) {
    final failure = switch (draft.step) {
      1 => draft.personalFailure,
      >= 2 => draft.stepFailure,
      _ => null,
    };
    return ProfileColumn(
      gap: 24,
      children: [
        if (failure != null)
          Text(
            failure.message.tr(),
            style: TextStyle(color: Theme.of(context).colorScheme.error),
          ),
        Row(
          children: [
            if (draft.step >= 2) ...[
              Expanded(
                child: DefaultButton.compact(
                  text: pc(context, 'Back'),
                  isOutlined: true,
                  color: QaderDesign.border,
                  textColor: AppColors.neutral700,
                  onPressed: onBack,
                ),
              ),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: DefaultButton.compact(
                text: pc(
                  context,
                  draft.step == 0
                      ? 'Continue'
                      : draft.step == 3
                      ? draft.isConnected
                            ? 'Save Profile'
                            : 'Submit'
                      : 'Next',
                ),
                isLoading: draft.busy,
                onPressed:
                    draft.step == 0 &&
                        (draft.fieldsLoading || draft.selectedField == null)
                    ? null
                    : onNext,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
