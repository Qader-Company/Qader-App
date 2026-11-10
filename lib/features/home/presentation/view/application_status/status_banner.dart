part of '../application_status_view.dart';

// Top banner (greeting, title, status badge) and the 3-step progress.

extension _BannerSection on _ApplicationStatusViewState {
  /// Banner badge: the application's `status_label`, except on the
  /// completed screen where the application is still "Scheduled" and the
  /// interview's own label ("Completed") matches the design.
  String _badgeLabel(String fallback) {
    if (!live) return fallback;
    if (status == ApplicationStatus.completed) {
      return app!.interview?.statusLabel ?? fallback;
    }
    return app!.statusLabel ?? fallback;
  }

  List<_Step> _stepStates() => switch (status) {
    ApplicationStatus.confirmed => [_Step.done, _Step.done, _Step.current],
    ApplicationStatus.rejected => [
      _Step.failedDone,
      _Step.pending,
      _Step.pending,
    ],
    ApplicationStatus.rejectedAfterInterview => [
      _Step.done,
      _Step.failedCurrent,
      _Step.pending,
    ],
    _ => [_Step.done, _Step.current, _Step.pending],
  };

  Widget _banner() {
    final reviewing = t(
      'A Qader reviewer has opened your application and is evaluating your profile.',
      'فتح أحد مراجعي قادر طلبك ويقوم بتقييم ملفك.',
    );
    final (title, badge, subtitle) = switch (status) {
      ApplicationStatus.rejected ||
      ApplicationStatus.rejectedAfterInterview => (
        t('Your Application Was Rejected', 'تم رفض طلبك'),
        t('Rejected', 'مرفوض'),
        t(
          'A Qader reviewer has evaluated your profile and decided not to move forward at this time. You can apply again later.',
          'قيّم أحد مراجعي قادر ملفك وقرر عدم المتابعة في الوقت الحالي. يمكنك التقديم مرة أخرى لاحقًا.',
        ),
      ),
      ApplicationStatus.accepted => (
        t(
          'The applicant is approved and becomes visible to companies.',
          'تم قبولك وأصبح ملفك ظاهرًا للشركات.',
        ),
        t('Accepted', 'مقبول'),
        t(
          'Congratulations! Companies can now discover your profile and reach out with opportunities.',
          'تهانينا! يمكن للشركات الآن اكتشاف ملفك والتواصل معك بالفرص المناسبة.',
        ),
      ),
      ApplicationStatus.completed => (
        t('The interview has been completed', 'اكتملت المقابلة'),
        t('Completed', 'مكتملة'),
        t(
          "Check the details below and make sure you're ready on time.",
          'راجع التفاصيل أدناه وتأكد من استعدادك في الموعد.',
        ),
      ),
      ApplicationStatus.confirmed => (
        t('Your Profile Is Being Reviewed', 'ملفك قيد المراجعة'),
        t('Scheduled', 'مجدولة'),
        reviewing,
      ),
      ApplicationStatus.slots => (
        t('Interview Slot Required', 'مطلوب اختيار موعد المقابلة'),
        t('Interview Req', 'مطلوب مقابلة'),
        t(
          "You've successfully passed the initial review! Please select one of the available interview slots below to schedule your interview.",
          'لقد اجتزت المراجعة الأولية بنجاح! يرجى اختيار أحد مواعيد المقابلة المتاحة أدناه لجدولة مقابلتك.',
        ),
      ),
      ApplicationStatus.newSlots || ApplicationStatus.cancelled => (
        t('Interview Slot Required', 'مطلوب اختيار موعد المقابلة'),
        t('Interview Req', 'مطلوب مقابلة'),
        reviewing,
      ),
    };
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rejected
              ? const [AppColors.red900, _red]
              : const [
                  AppColors.primaryNavy,
                  QaderDesign.primary,
                  QaderDesign.blue,
                ],
        ),
      ),
      child: SpacedColumn(
        gap: 8,
        children: [
          Row(
            children: [
              Expanded(
                child: Text.rich(
                  TextSpan(
                    text: t('Hello, ', 'مرحبًا، '),
                    children: [
                      TextSpan(
                        text:
                            widget.userName ?? t('Olivia Rhye', 'أوليفيا راي'),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
              ),
              const SizedBox(width: 12),
              _Badge(_badgeLabel(badge), color: _body, fill: Colors.white),
            ],
          ),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
            ),
          ),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppColors.white80,
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge(
    this.text, {
    required this.color,
    required this.fill,
    this.dot = false,
  });
  final String text;
  final Color color;
  final Color fill;
  final bool dot;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
    decoration: BoxDecoration(
      color: fill,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dot) ...[
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
        ],
        Text(
          text,
          style: TextStyle(fontSize: 14, height: 20 / 14, color: color),
        ),
      ],
    ),
  );
}

/// Three-step progress (Under Review → Interviews → Accepted).
class _StatusSteps extends StatelessWidget {
  const _StatusSteps({required this.labels, required this.steps});
  final List<String> labels;
  final List<_Step> steps;

  static bool _failed(_Step s) =>
      s == _Step.failedDone || s == _Step.failedCurrent;

  Color _color(_Step s) => switch (s) {
    _Step.pending => _grey,
    _Step.failedDone || _Step.failedCurrent => _red,
    _ => QaderDesign.primary,
  };

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final w = constraints.maxWidth;
      final centers = [w / 6, w / 2, w * 5 / 6];
      Widget connector(int i) {
        final from = steps[i];
        final to = steps[i + 1];
        // The line after a failed step is red and carries a ✕ (Figma).
        final failed = _failed(from);
        final active = failed || to != _Step.pending;
        final color = failed ? _red : (active ? QaderDesign.primary : _grey);
        final left = centers[i] + 12;
        final width = centers[i + 1] - centers[i] - 24;
        return PositionedDirectional(
          start: left,
          top: 30,
          width: width,
          child: SizedBox(
            height: 12,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(height: 1, color: color),
                if (failed)
                  Container(
                    color: AppColors.background,
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: const ColorFiltered(
                      colorFilter: ColorFilter.mode(_red, BlendMode.srcIn),
                      child: QaderAsset('status_close', width: 8, height: 8),
                    ),
                  ),
              ],
            ),
          ),
        );
      }

      Widget circle(int i) {
        final s = steps[i];
        final color = _color(s);
        final filled = s == _Step.done || s == _Step.failedDone;
        return PositionedDirectional(
          start: centers[i] - 12,
          top: 24,
          child: Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: filled ? color : Colors.white,
              border: Border.all(width: 4, color: color),
            ),
            child: filled
                ? const QaderAsset('status_check', width: 14, height: 14)
                : null,
          ),
        );
      }

      return SizedBox(
        height: 48,
        child: Stack(
          children: [
            Row(
              children: [
                for (var i = 0; i < 3; i++)
                  Expanded(
                    child: Text(
                      labels[i],
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.5,
                        fontWeight: steps[i] == _Step.pending
                            ? FontWeight.w400
                            : FontWeight.w700,
                        color: steps[i] == _Step.pending
                            ? AppColors.neutral500
                            : _color(steps[i]),
                      ),
                    ),
                  ),
              ],
            ),
            connector(0),
            connector(1),
            for (var i = 0; i < 3; i++) circle(i),
          ],
        ),
      );
    },
  );
}
