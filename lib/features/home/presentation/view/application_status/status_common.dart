part of '../application_status_view.dart';

// Shared building blocks: cards, notices, headings, labels, FAQ.

extension _CommonSection on _ApplicationStatusViewState {
  String _round() {
    final round = app?.interview?.round ?? 1;
    return t('Round $round#', 'الجولة ${_digits('$round')}#');
  }

  /// "Technical Interview", "HR Interview"... from `current_interview.type`.
  String _interviewType({bool fallbackHr = false}) {
    final interview = app?.interview;
    if (interview?.title case final title?) return title;
    return switch (interview?.type) {
      'hr' => t('HR Interview', 'مقابلة الموارد البشرية'),
      'technical' => t('Technical Interview', 'مقابلة تقنية'),
      'general' => t('General Interview', 'مقابلة عامة'),
      'final' => t('Final Interview', 'المقابلة النهائية'),
      _ =>
        fallbackHr
            ? t('HR Interview', 'مقابلة الموارد البشرية')
            : t('Technical interview', 'مقابلة تقنية'),
    };
  }

  List<({String question, String answer})> _faqs() {
    final faqs = live ? app!.screenFaqs : const <ApplicationFaq>[];
    if (faqs.isEmpty) return [_faq()];
    return [
      for (final faq in faqs) (question: faq.question, answer: faq.answer),
    ];
  }

  ({String question, String answer}) _faq() {
    final passed = t(
      "You've passed the initial review — congratulations! The next step is to choose one of the available interview time slots.",
      'لقد اجتزت المراجعة الأولية — تهانينا! الخطوة التالية هي اختيار أحد مواعيد المقابلة المتاحة.',
    );
    return switch (status) {
      ApplicationStatus.rejected ||
      ApplicationStatus.rejectedAfterInterview => (
        question: t(
          'What does "Under Review" mean?',
          'ما معنى «قيد المراجعة»؟',
        ),
        answer: t(
          'Your application has been received and is currently being reviewed by our recruitment team to assess your qualifications and experience.',
          'تم استلام طلبك ويقوم فريق التوظيف حاليًا بمراجعته لتقييم مؤهلاتك وخبراتك.',
        ),
      ),
      ApplicationStatus.confirmed || ApplicationStatus.accepted => (
        question: t('Interview Req', 'مطلوب مقابلة'),
        answer: passed,
      ),
      ApplicationStatus.completed => (
        question: t('Interview Completed', 'اكتملت المقابلة'),
        answer: passed,
      ),
      _ => (
        question: t(
          'How long does the review process take?',
          'كم تستغرق عملية المراجعة؟',
        ),
        answer: t(
          "The review time may vary depending on the number of applications. You'll be notified as soon as your application moves to the next stage.",
          'تختلف مدة المراجعة حسب عدد الطلبات. سيتم إخطارك فور انتقال طلبك إلى المرحلة التالية.',
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
          tooltip: t('More actions', 'المزيد'),
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
