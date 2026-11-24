import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../domain/repositories/talent_evaluation_repository.dart';
import '../cubit/talent_evaluation_cubit.dart';
import '../preview/profile_evaluation_preview.dart';
import '../profile_copy.dart';
import '../widgets/evaluation_content.dart';
import '../widgets/evaluation_skeleton.dart';
import '../widgets/profile_components.dart';

/// The talent's evaluation report. In [preview] it shows a sample (signed
/// out and preview screens); otherwise it loads
/// `GET /talent/profile/evaluation`.
class ProfileEvaluationView extends StatelessWidget {
  const ProfileEvaluationView({super.key, this.preview = false});
  final bool preview;

  @override
  Widget build(BuildContext context) {
    if (preview) {
      return TalentProfileScaffold(
        child: EvaluationContent(evaluation: previewEvaluation(context)),
      );
    }
    return BlocProvider(
      create: (context) =>
          TalentEvaluationCubit(context.read<TalentEvaluationRepository>())
            ..load(),
      child: BlocBuilder<TalentEvaluationCubit, TalentEvaluationState>(
        builder: (context, state) {
          final cubit = context.read<TalentEvaluationCubit>();
          final evaluation = state.evaluation;
          // Reports come in the app language: reload when it changes.
          return LocaleChangeListener(
            onChanged: cubit.load,
            child: TalentProfileScaffold(
              onRefresh: evaluation == null ? null : cubit.load,
              child: evaluation != null
                  ? EvaluationContent(evaluation: evaluation)
                  : state.loading
                  ? const EvaluationSkeleton()
                  : state.unavailable
                  ? const _Message(
                      icon: Icons.hourglass_empty_rounded,
                      text: 'talent_evaluation_unavailable',
                    )
                  : _Message(
                      icon: Icons.cloud_off_outlined,
                      text: 'talent_evaluation_failed',
                      onRetry: cubit.load,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _Message extends StatelessWidget {
  const _Message({required this.icon, required this.text, this.onRetry});
  final IconData icon;

  /// Translation key.
  final String text;
  final VoidCallback? onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 8),
    child: Column(
      children: [
        Icon(icon, size: 40, color: AppColors.neutral500),
        const SizedBox(height: 12),
        Text(
          text.tr(context: context),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 20 / 14),
        ),
        if (onRetry != null) ...[
          const SizedBox(height: 16),
          DefaultButton.compact(
            text: tc(context, 'Try again'),
            onPressed: onRetry,
          ),
        ],
      ],
    ),
  );
}
