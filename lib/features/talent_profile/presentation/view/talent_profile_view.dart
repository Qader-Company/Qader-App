import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/entities/talent_profile.dart';
import '../../domain/repositories/talent_profile_repository.dart';
import '../cubit/talent_profile_cubit.dart';
import '../profile_copy.dart';
import '../widgets/profile_components.dart';
import '../widgets/profile_content.dart';

/// The talent's profile. With a [preview] profile it shows that sample
/// (logged out and preview routes); otherwise it loads `GET /talent/profile`.
class TalentProfileView extends StatelessWidget {
  const TalentProfileView({super.key, this.preview});
  final TalentProfile? preview;

  @override
  Widget build(BuildContext context) {
    if (preview case final profile?) {
      return TalentProfileScaffold(
        // A different preview status starts from a fresh screen state.
        child: ProfileContent(
          key: ValueKey(profile.status),
          profile: profile,
          preview: true,
        ),
      );
    }
    return BlocProvider(
      create: (context) =>
          TalentProfileCubit(context.read<TalentProfileRepository>())..load(),
      child: BlocBuilder<TalentProfileCubit, TalentProfileState>(
        builder: (context, state) {
          final cubit = context.read<TalentProfileCubit>();
          final profile = state.profile;
          return TalentProfileScaffold(
            onRefresh: profile == null ? null : cubit.load,
            child: profile != null
                ? ProfileContent(profile: profile, preview: false)
                : state.loading
                ? const Padding(
                    padding: EdgeInsets.symmetric(vertical: 120),
                    child: Center(child: CircularProgressIndicator()),
                  )
                : _LoadError(onRetry: cubit.load),
          );
        },
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 96, horizontal: 8),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 40,
          color: AppColors.neutral500,
        ),
        const SizedBox(height: 12),
        Text(
          tc(context, "We couldn't load your profile"),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 20 / 14),
        ),
        const SizedBox(height: 16),
        DefaultButton.compact(
          text: tc(context, 'Try again'),
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
