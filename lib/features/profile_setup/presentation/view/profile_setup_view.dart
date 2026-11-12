import 'package:flutter/material.dart';
import 'package:easy_localization/easy_localization.dart' hide TextDirection;
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../../../core/widgets/default_button.dart';
import '../cubit/profile_setup_cubit.dart';
import '../profile_copy.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/professional_field_step.dart';
import '../widgets/basic_info_step.dart';
import '../widgets/skills_experience_step.dart';
import '../widgets/work_preferences_step.dart';
import '../widgets/profile_setup_confirmation.dart';
import '../widgets/profile_setup_header.dart';
import '../../../../core/storage/app_preferences.dart';
import '../../domain/repositories/professional_fields_repository.dart';
import '../../domain/repositories/profile_lookups_repository.dart';
import '../../domain/repositories/onboarding_steps_repository.dart';
import '../../domain/repositories/onboarding_progress_repository.dart';
import '../../../../core/di/maybe_read.dart';

class ProfileSetupView extends StatefulWidget {
  const ProfileSetupView({super.key, this.seed});
  final ProfileSetupSeed? seed;
  @override
  State<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<ProfileSetupView> {
  late final _preferences = context.read<AppPreferences>();

  /// Logged-in talents use the onboarding APIs; otherwise an offline preview.
  late final draft = () {
    final live = _preferences.isLoggedIn;
    return ProfileSetupCubit(
      seed: widget.seed,
      fieldsRepository: live
          ? context.read<ProfessionalFieldsRepository>()
          : null,
      lookupsRepository: live ? context.read<ProfileLookupsRepository>() : null,
      stepsRepository: live ? context.read<OnboardingStepsRepository>() : null,
      progressRepository: live
          ? context.maybeRead<OnboardingProgressRepository>()
          : null,
    );
  }();
  final _scroll = ScrollController();
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  bool _initialProgress = true;
  @override
  void initState() {
    super.initState();
    _preferences.sessionRevision.addListener(_sessionChanged);
    if (draft.hasProgressRepository) {
      _resume();
    } else {
      draft.loadFields();
    }
  }

  void _sessionChanged() {
    if (mounted && draft.isConnected && !_preferences.isLoggedIn) {
      context.go('${AppRouter.signIn}?role=talent');
    }
  }

  Future<void> _resume() async {
    final loaded = await draft.restoreProgress();
    if (!mounted || !loaded) return;
    if (_initialProgress && draft.step == 4) {
      context.go(AppRouter.home);
      return;
    }
    _initialProgress = false;
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (draft.step == 0) {
      await draft.loadFields();
    } else if (draft.step < 4) {
      await draft.loadRelevantLookups();
      if (mounted) await draft.loadLookup(ProfileLookup.cities);
    }
  }

  @override
  void dispose() {
    _preferences.sessionRevision.removeListener(_sessionChanged);
    draft.close();
    _scroll.dispose();
    super.dispose();
  }

  void _move(int step) {
    FocusScope.of(context).unfocus();
    draft.go(step);
    if (draft.isConnected && step == 0) draft.loadFields();
    if (_scroll.hasClients) _scroll.jumpTo(0);
    if (draft.isConnected && step >= 1 && step <= 3) {
      draft.loadRelevantLookups();
    }
  }

  void _back() {
    if (draft.busy) return;
    if (draft.isConnected && draft.step == 4) {
      context.go(AppRouter.home);
      return;
    }
    if (draft.isConnected && draft.progressPending) {
      context.go(AppRouter.chooseRole);
      return;
    }
    if (draft.step > 0) {
      _move(draft.step - 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.chooseRole);
    }
  }

  Future<void> _next() async {
    if (draft.fieldsLoading || draft.busy) return;
    if (draft.step == 0) {
      final saved = await draft.saveProfessionalField();
      if (saved && mounted) {
        if (draft.hasProgressRepository) {
          await _resume();
        } else {
          _move(1);
        }
      }
      return;
    }
    final invalid = _forms[draft.step].currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        duration: const Duration(milliseconds: 250),
        alignment: .15,
      );
      return;
    }
    if (draft.isConnected && draft.step == 1) {
      final saved = await draft.savePersonalInformation();
      if (saved && mounted) {
        if (draft.hasProgressRepository) {
          await _resume();
        } else {
          _move(2);
        }
      }
      return;
    }
    if (draft.isConnected && draft.step >= 2) {
      final saved = await draft.saveDetails(work: draft.step == 3);
      if (saved && mounted) {
        if (draft.hasProgressRepository) {
          await _resume();
        } else {
          _move(draft.step + 1);
        }
      }
      return;
    }
    if (draft.step < 3) {
      _move(draft.step + 1);
      return;
    }
    FocusScope.of(context).unfocus();
    final preview = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(pc(context, 'Submission preview')),
        content: Text(
          pc(
            context,
            'The submission API is not connected yet. Your information and files have not been sent. You can preview the confirmation screen.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text(pc(context, 'Back')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(pc(context, 'Preview confirmation')),
          ),
        ],
      ),
    );
    if (preview == true && mounted) _move(4);
  }

  @override
  Widget build(
    BuildContext context,
  ) => BlocBuilder<ProfileSetupCubit, ProfileSetupState>(
    bloc: draft,
    builder: (context, _) => PopScope(
      canPop: draft.step == 0 && !draft.busy,
      onPopInvokedWithResult: (didPop, result) {
        if (!didPop) _back();
      },
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: draft.progressPending
                  ? Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (draft.progressLoading)
                            const CircularProgressIndicator(),
                          if (draft.progressFailure != null) ...[
                            Text(
                              'profile_progress_failed'.tr(),
                              textAlign: TextAlign.center,
                            ),
                            TextButton(
                              onPressed: _resume,
                              child: Text('auth_retry'.tr()),
                            ),
                          ],
                        ],
                      ),
                    )
                  : draft.step == 4
                  ? ProfileSetupConfirmation(
                      connected: draft.isConnected,
                      onBack: _back,
                    )
                  : SingleChildScrollView(
                      controller: _scroll,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      child: ProfileColumn(
                        gap: 24,
                        children: [
                          ProfileSetupHeader(
                            showBack: draft.step != 4,
                            onBack: _back,
                          ),
                          Form(
                            key: _forms[draft.step],
                            child: ProfileColumn(
                              gap: 24,
                              children: [
                                if (draft.step > 0)
                                  Row(
                                    children: [
                                      Container(
                                        width: 30,
                                        height: 30,
                                        decoration: const BoxDecoration(
                                          color: QaderDesign.primary,
                                          shape: BoxShape.circle,
                                        ),
                                        child: Center(
                                          child: Text(
                                            draft.step.toString(),
                                            style: const TextStyle(
                                              fontSize: 14,
                                              color: Colors.white,
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Text(
                                          pc(
                                            context,
                                            [
                                              '',
                                              'Basic Info',
                                              'Skills & Experience',
                                              'Work Preferences',
                                            ][draft.step],
                                          ),
                                          style: const TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                            height: 1.5,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                AbsorbPointer(
                                  absorbing: draft.busy,
                                  child: switch (draft.step) {
                                    0 => ProfessionalFieldStep(draft: draft),
                                    1 => BasicInfoStep(draft: draft),
                                    2 => SkillsExperienceStep(draft: draft),
                                    _ => WorkPreferencesStep(draft: draft),
                                  },
                                ),
                                if (draft.step == 1 &&
                                    draft.personalFailure != null)
                                  Text(
                                    draft.personalFailure!.message.tr(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
                                  ),
                                if (draft.step >= 2 &&
                                    draft.stepFailure != null)
                                  Text(
                                    draft.stepFailure!.message.tr(),
                                    style: TextStyle(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.error,
                                    ),
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
                                          onPressed: _back,
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
                                                (draft.fieldsLoading ||
                                                    draft.selectedField == null)
                                            ? null
                                            : _next,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    ),
  );
}
