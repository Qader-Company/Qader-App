import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../../core/router/app_router.dart';
import '../../../../../core/widgets/qader_design.dart';
import '../../../../../core/widgets/default_button.dart';
import '../profile_setup_controller.dart';
import '../profile_copy.dart';
import '../widgets/profile_widgets.dart';
import '../widgets/professional_field_step.dart';
import '../widgets/basic_info_step.dart';
import '../widgets/skills_experience_step.dart';
import '../widgets/work_preferences_step.dart';

class ProfileSetupView extends StatefulWidget {
  const ProfileSetupView({super.key, this.seed});
  final ProfileSetupSeed? seed;
  @override
  State<ProfileSetupView> createState() => _ProfileSetupViewState();
}

class _ProfileSetupViewState extends State<ProfileSetupView> {
  late final draft = ProfileSetupController(seed: widget.seed);
  final _scroll = ScrollController();
  final _forms = List.generate(4, (_) => GlobalKey<FormState>());
  @override
  void dispose() {
    draft.dispose();
    _scroll.dispose();
    super.dispose();
  }

  void _move(int step) {
    FocusScope.of(context).unfocus();
    draft.go(step);
    if (_scroll.hasClients) _scroll.jumpTo(0);
  }

  void _back() {
    if (draft.step > 0) {
      _move(draft.step - 1);
    } else if (context.canPop()) {
      context.pop();
    } else {
      context.go(AppRouter.chooseRole);
    }
  }

  Future<void> _next() async {
    final invalid = _forms[draft.step].currentState!.validateGranularly();
    if (invalid.isNotEmpty) {
      await Scrollable.ensureVisible(
        invalid.first.context,
        duration: const Duration(milliseconds: 250),
        alignment: .15,
      );
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

  Widget _header() => SizedBox(
    height: 40,
    width: double.infinity,
    child: Stack(
      alignment: Alignment.center,
      children: [
        const QaderLogo(),
        if (draft.step != 4)
          Align(
            alignment: AlignmentDirectional.centerStart,
            child: SizedBox(
              width: 40,
              height: 40,
              child: IconButton(
                style: IconButton.styleFrom(
                  backgroundColor: const Color(0xFFFAFAFA),
                ),
                tooltip: pc(context, 'Back'),
                onPressed: _back,
                icon: Directionality.of(context) == TextDirection.rtl
                    ? const RotatedBox(
                        quarterTurns: 2,
                        child: QaderAsset(
                          'profile_back',
                          width: 7.5,
                          height: 13.5,
                        ),
                      )
                    : const QaderAsset(
                        'profile_back',
                        width: 7.5,
                        height: 13.5,
                      ),
              ),
            ),
          ),
      ],
    ),
  );
  @override
  Widget build(BuildContext context) => QaderTheme(
    child: AnimatedBuilder(
      animation: draft,
      builder: (context, _) => PopScope(
        canPop: draft.step == 0,
        onPopInvokedWithResult: (didPop, result) {
          if (!didPop) _back();
        },
        child: Scaffold(
          backgroundColor: Colors.white,
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 430),
                child: draft.step == 4
                    ? _confirmation(context)
                    : SingleChildScrollView(
                        controller: _scroll,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        child: ProfileColumn(
                          gap: 24,
                          children: [
                            _header(),
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
                                  switch (draft.step) {
                                    0 => ProfessionalFieldStep(draft: draft),
                                    1 => BasicInfoStep(draft: draft),
                                    2 => SkillsExperienceStep(draft: draft),
                                    _ => WorkPreferencesStep(draft: draft),
                                  },
                                  Row(
                                    children: [
                                      if (draft.step >= 2) ...[
                                        Expanded(
                                          child: DefaultButton.compact(
                                            text: pc(context, 'Back'),
                                            isOutlined: true,
                                            color: QaderDesign.border,
                                            textColor: const Color(0xFF404040),
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
                                                ? 'Submit'
                                                : 'Next',
                                          ),
                                          onPressed: _next,
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
    ),
  );
  Widget _confirmation(BuildContext context) => Stack(
    children: [
      Positioned(
        left: 16,
        right: 16,
        bottom: 24,
        child: DefaultButton.compact(
          text: pc(context, 'Preview Home'),
          onPressed: () =>
              context.go('${AppRouter.home}?preview=true&role=talent'),
        ),
      ),
      Padding(padding: const EdgeInsets.all(16), child: _header()),
      Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFFE8EFFC),
                ),
                child: const Center(
                  child: QaderAsset(
                    'profile_success',
                    width: 44.8,
                    height: 44.8,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pc(context, 'Profile Submitted!'),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  height: 32 / 24,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                pc(
                  context,
                  "Your talent profile has been submitted successfully, We'll review it and get back to you shortly.",
                ),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: Color(0xFF737373),
                ),
              ),
            ],
          ),
        ),
      ),
    ],
  );
}
