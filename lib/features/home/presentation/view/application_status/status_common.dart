part of '../application_status_view.dart';

// Shared building blocks: cards, notices, headings, labels, FAQ.

extension _CommonSection on _ApplicationStatusViewState {
  String _round() {
    final round = app?.interview?.round ?? 1;
    return 'status_round'.tr(
      context: context,
      namedArgs: {'round': _digits('$round')},
    );
  }

  /// "Technical Interview", "HR Interview"... from `current_interview.type`.
  String _interviewType({bool fallbackHr = false}) {
    final interview = app?.interview;
    if (interview?.title case final title?) return title;
    return switch (interview?.type) {
      'hr' => 'status_hr_interview'.tr(context: context),
      'technical' => 'status_technical_interview'.tr(context: context),
      'general' => 'status_general_interview'.tr(context: context),
      'final' => 'status_final_interview'.tr(context: context),
      _ =>
        fallbackHr
            ? 'status_hr_interview'.tr(context: context)
            : 'status_technical_interview_2'.tr(context: context),
    };
  }

  /// Live: only the backend FAQs for this screen (none → no FAQ card).
  /// Preview: the sample question from the design.
  List<({String question, String answer})> _faqs() {
    if (!live) return [_faq()];
    final faqs = app!.screenFaqs;
    return [
      for (final faq in faqs) (question: faq.question, answer: faq.answer),
    ];
  }

  ({String question, String answer}) _faq() {
    final passed = 'status_you_ve_passed_the_initial_review_congratulations'.tr(
      context: context,
    );
    return switch (status) {
      ApplicationStatus.rejected ||
      ApplicationStatus.rejectedAfterInterview => (
        question: 'status_what_does_under_review_mean'.tr(context: context),
        answer: 'status_your_application_has_been_received_and_is'.tr(
          context: context,
        ),
      ),
      ApplicationStatus.confirmed || ApplicationStatus.accepted => (
        question: 'status_interview_req'.tr(context: context),
        answer: passed,
      ),
      ApplicationStatus.completed => (
        question: 'status_interview_completed'.tr(context: context),
        answer: passed,
      ),
      _ => (
        question: 'status_how_long_does_the_review_process_take'.tr(
          context: context,
        ),
        answer: 'status_the_review_time_may_vary_depending_on'.tr(
          context: context,
        ),
      ),
    };
  }

  Widget _moreMenu({required String label, required VoidCallback onSelected}) =>
      SizedBox.square(
        dimension: 24,
        child: PopupMenuButton<int>(
          padding: EdgeInsets.zero,
          iconSize: 24,
          icon: const QaderAsset('status_more', width: 3, height: 13),
          tooltip: 'status_more_actions'.tr(context: context),
          color: Colors.white,
          elevation: 6,
          shadowColor: AppColors.shadow20,
          position: PopupMenuPosition.under,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          onSelected: (_) => onSelected(),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 0,
              height: 40,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const QaderAsset('status_cancel', width: 16, height: 16),
                  const SizedBox(width: 8),
                  Text(
                    label,
                    style: const TextStyle(fontSize: 14, color: _red),
                  ),
                ],
              ),
            ),
          ],
        ),
      );

  Widget _heading(String text) => Text(
    text,
    style: const TextStyle(
      color: _ink,
      fontSize: 16,
      fontWeight: FontWeight.w600,
      height: 1.5,
    ),
  );

  Widget _card(List<Widget> children, {double padding = 16}) => Container(
    padding: EdgeInsets.all(padding),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: _line),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(fontSize: 12, height: 1.5, color: _muted),
      child: SpacedColumn(gap: 12, children: children),
    ),
  );

  Widget _notice(
    _Tone tone, {
    String? title,
    String? lead,
    required String body,
    bool clockIcon = false,
  }) {
    final (fill, icon) = switch (tone) {
      _Tone.success => (_greenSoft, 'status_success'),
      _Tone.warning => (_yellowSoft, 'status_success'),
      _Tone.danger => (_redSoft, 'status_cancel'),
      _Tone.info => (QaderDesign.paleBlue, 'status_success'),
    };
    Widget iconWidget = QaderAsset(icon, width: 22, height: 22);
    if (tone == _Tone.warning) {
      iconWidget = ColorFiltered(
        colorFilter: const ColorFilter.mode(
          AppColors.yellow600,
          BlendMode.srcIn,
        ),
        child: iconWidget,
      );
    }
    if (clockIcon) {
      iconWidget = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: AppColors.green600,
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.schedule, size: 15, color: Colors.white),
      );
    }
    const strong = TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      height: 20 / 14,
      color: _ink,
    );
    final bodyStyle = TextStyle(
      fontSize: tone == _Tone.success && title != null ? 12 : 14,
      height: tone == _Tone.success && title != null ? 1.5 : 20 / 14,
      color: tone == _Tone.success && title != null ? _muted : _body,
    );
    final Widget text = lead != null
        ? Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: lead,
                  style: strong.copyWith(fontWeight: FontWeight.w600),
                ),
                TextSpan(text: body),
              ],
            ),
            style: strong.copyWith(fontWeight: FontWeight.w400, color: _body),
          )
        : title != null
        ? Text(title, style: strong)
        : Text(body, style: strong.copyWith(fontWeight: FontWeight.w400));
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(8),
      ),
      child: SpacedColumn(
        gap: 8,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.only(top: 1),
                child: iconWidget,
              ),
              const SizedBox(width: 8),
              Expanded(child: text),
            ],
          ),
          if (title != null) Text(body, style: bodyStyle),
        ],
      ),
    );
  }

  Widget _detail(String asset, String text, {Widget? trailing}) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 1),
        child: QaderAsset(asset, width: 16, height: 16),
      ),
      const SizedBox(width: 8),
      Flexible(
        child: Text(
          text,
          style: const TextStyle(fontSize: 12, height: 1.5, color: _muted),
        ),
      ),
      if (trailing != null) ...[const SizedBox(width: 6), trailing],
    ],
  );
}

/// [icon] is either an asset name under `assets/icons/figma` or [IconData].
Widget _iconLabel(Object icon, String text, Color color, {double size = 20}) =>
    Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (icon is IconData)
          Icon(icon, size: size, color: color)
        else
          ColorFiltered(
            colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
            child: QaderAsset(icon as String, width: size, height: size),
          ),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );

Widget _disabledButton(String text, {double height = 40}) => Semantics(
  button: true,
  enabled: false,
  child: Container(
    height: height,
    alignment: Alignment.center,
    decoration: BoxDecoration(
      color: _disabledFill,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _muted,
      ),
    ),
  ),
);
