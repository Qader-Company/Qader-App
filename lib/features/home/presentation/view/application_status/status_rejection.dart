part of '../application_status_view.dart';

// Rejected / blacklisted sections.

extension _RejectionSection on _ApplicationStatusViewState {
  /// Backend says the reapplication period is over (`can_reapply`).
  bool get _canReapply => live && app!.canReapply;

  bool get _blacklisted => live && app!.isBlacklisted;

  List<Widget> _rejection() => _blacklisted
      ? [
          _card([
            _heading('status_we_appreciate_your_effort'.tr(context: context)),
            Text(
              'status_unfortunately_your_application_wasn_t_successful_and'.tr(
                context: context,
              ),
              style: const TextStyle(fontSize: 14, height: 20 / 14),
            ),
          ]),
        ]
      : _rejectionOptions();

  List<Widget> _rejectionOptions() => [
    _card([
      _heading('status_we_appreciate_your_effort'.tr(context: context)),
      Text(
        'status_unfortunately_your_application_wasn_t_successful_this'.tr(
          context: context,
        ),
        style: const TextStyle(fontSize: 14, height: 20 / 14),
      ),
      Text(
        _canReapply
            ? 'status_the_reapplication_period_has_ended_you_can'.tr(
                context: context,
              )
            : 'status_we_encourage_you_to_continue_developing_your'.tr(
                context: context,
              ),
        style: const TextStyle(fontSize: 14, height: 20 / 14),
      ),
      if (!_canReapply && deadline != null && deadline!.isAfter(DateTime.now()))
        ProfileReevaluationCountdown(deadline: deadline!),
      DefaultButton.compact(
        text: 'status_update_profile'.tr(context: context),
        isOutlined: true,
        color: _grey,
        textColor: _body,
        onPressed: () => context.push('/talent-profile?status=rejected'),
      ),
      if (_canReapply)
        DefaultButton.compact(
          text: 'status_apply_again'.tr(context: context),
          onPressed: () => context.push(AppRouter.profileSetup),
        )
      else
        _disabledButton('status_apply_again'.tr(context: context)),
    ]),
    _card([
      _heading('status_rejection_feedback'.tr(context: context)),
      Container(
        height: 100,
        decoration: BoxDecoration(
          border: Border.all(color: _line),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Padding(
              padding: const EdgeInsets.all(12),
              child: ImageFiltered(
                imageFilter: ui.ImageFilter.blur(sigmaX: 4, sigmaY: 4),
                child: Text(
                  'status_your_experience_level_didn_t_fully_match'.tr(
                    context: context,
                  ),
                ),
              ),
            ),
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: QaderDesign.primary,
                shape: BoxShape.circle,
              ),
              child: const Center(
                child: ColorFiltered(
                  colorFilter: ColorFilter.mode(Colors.white, BlendMode.srcIn),
                  child: QaderAsset('lock', width: 18, height: 22),
                ),
              ),
            ),
          ],
        ),
      ),
      Text(
        'status_what_s_included'.tr(context: context),
        style: const TextStyle(fontSize: 14, color: _muted),
      ),
      for (final item in [
        (
          'status_detailed_rejection_reason'.tr(context: context),
          'status_the_specific_reasons_the_reviewer_didn_t'.tr(
            context: context,
          ),
        ),
        (
          'status_cv_review'.tr(context: context),
          'status_a_breakdown_of_what_stood_out_and'.tr(context: context),
        ),
        (
          'status_personalized_tips'.tr(context: context),
          'status_concrete_steps_to_improve_your_profile_before'.tr(
            context: context,
          ),
        ),
        (
          'status_faster_reapplication'.tr(context: context),
          'status_skip_the_waiting_period_and_reapply_right'.tr(
            context: context,
          ),
        ),
      ])
        _included(item.$1, item.$2),
      const Divider(height: 1, color: _line),
      Row(
        children: [
          Expanded(
            child: Text(
              'status_unlock_detailed_feedback'.tr(context: context),
              style: const TextStyle(fontSize: 14, color: _muted),
            ),
          ),
          Text(
            'status_egp_100'.tr(context: context),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ],
      ),
      DefaultButton.compact(
        height: 44,
        text: 'status_unlock'.tr(context: context),
        onPressed: previewNotice,
        child: _iconLabel(
          'lock',
          'status_unlock'.tr(context: context),
          Colors.white,
          size: 16,
        ),
      ),
      Text(
        'status_one_time_payment_includes_tips_to_improve'.tr(context: context),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10, color: _muted),
      ),
    ]),
  ];

  Widget _included(String title, String body) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Padding(
        padding: EdgeInsets.only(top: 2),
        child: Icon(
          Icons.workspace_premium_outlined,
          size: 16,
          color: QaderDesign.primary,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 20 / 14,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              body,
              style: const TextStyle(
                fontSize: 14,
                height: 20 / 14,
                color: _muted,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}
