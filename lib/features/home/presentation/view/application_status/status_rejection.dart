part of '../application_status_view.dart';

// Rejected / blacklisted sections.

extension _RejectionSection on _ApplicationStatusViewState {
  /// Backend says the reapplication period is over (`can_reapply`).
  bool get _canReapply => live && app!.canReapply;

  bool get _blacklisted => live && app!.isBlacklisted;

  List<Widget> _rejection() => _blacklisted
      ? [
          _card([
            _heading(t('We Appreciate Your Effort', 'نقدّر مجهودك')),
            Text(
              t(
                "Unfortunately, your application wasn't successful, and you can't submit a new application. Thank you for your interest in Qader.",
                'للأسف لم يُقبل طلبك، ولا يمكنك تقديم طلب جديد. نشكرك على اهتمامك بقادر.',
              ),
              style: const TextStyle(fontSize: 14, height: 20 / 14),
            ),
          ]),
        ]
      : _rejectionOptions();

  List<Widget> _rejectionOptions() => [
    _card([
      _heading(t('We Appreciate Your Effort', 'نقدّر مجهودك')),
      Text(
        t(
          "Unfortunately, your application wasn't successful this time. We appreciate your time and effort, and we encourage you to apply again after the reapplication period has ended.",
          'للأسف لم يُقبل طلبك هذه المرة. نقدّر وقتك ومجهودك، ونشجعك على التقديم مرة أخرى بعد انتهاء فترة إعادة التقديم.',
        ),
        style: const TextStyle(fontSize: 14, height: 20 / 14),
      ),
      Text(
        _canReapply
            ? t(
                'The reapplication period has ended. You can now update your profile and submit a new application.',
                'انتهت فترة إعادة التقديم. يمكنك الآن تحديث ملفك وتقديم طلب جديد.',
              )
            : t(
                "We encourage you to continue developing your skills and experience, and you're welcome to submit a new application once the reapplication period has ended.",
                'نشجعك على مواصلة تطوير مهاراتك وخبراتك، ويسعدنا استقبال طلبك الجديد بعد انتهاء فترة إعادة التقديم.',
              ),
        style: const TextStyle(fontSize: 14, height: 20 / 14),
      ),
      if (!_canReapply && deadline != null && deadline!.isAfter(DateTime.now()))
        ProfileReevaluationCountdown(deadline: deadline!),
      DefaultButton.compact(
        text: t('Update Profile', 'تحديث الملف'),
        isOutlined: true,
        color: _grey,
        textColor: _body,
        onPressed: () => context.push('/talent-profile?status=rejected'),
      ),
      if (_canReapply)
        DefaultButton.compact(
          text: t('Apply Again', 'التقديم مجددًا'),
          onPressed: () => context.push(AppRouter.profileSetup),
        )
      else
        _disabledButton(t('Apply Again', 'التقديم مجددًا')),
    ]),
    _card([
      _heading(t('Rejection feedback', 'ملاحظات الرفض')),
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
                  t(
                    'Your experience level didn’t fully match the requirements for this position and we are looking for a candidate with stronger expertise in design systems.',
                    'لم يتطابق مستوى خبرتك بالكامل مع متطلبات هذه الوظيفة، ونبحث عن مرشح بخبرة أقوى في أنظمة التصميم.',
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
        t("What's included", 'ما الذي تتضمنه الخدمة'),
        style: const TextStyle(fontSize: 14, color: _muted),
      ),
      for (final item in [
        (
          t('Detailed rejection reason', 'سبب الرفض بالتفصيل'),
          t(
            "The specific reasons the reviewer didn't move you forward.",
            'الأسباب المحددة التي جعلت المراجع لا ينقلك للمرحلة التالية.',
          ),
        ),
        (
          t('CV review', 'مراجعة السيرة الذاتية'),
          t(
            "A breakdown of what stood out and what's missing in your CV.",
            'تحليل لأبرز نقاط القوة وما ينقص سيرتك الذاتية.',
          ),
        ),
        (
          t('Personalized tips', 'نصائح مخصصة'),
          t(
            'Concrete steps to improve your profile before your next application.',
            'خطوات عملية لتحسين ملفك قبل طلبك القادم.',
          ),
        ),
        (
          t('Faster reapplication', 'إعادة تقديم أسرع'),
          t(
            'Skip the waiting period and reapply right away instead of later.',
            'تخطَّ فترة الانتظار وأعد التقديم فورًا بدلًا من الانتظار.',
          ),
        ),
      ])
        _included(item.$1, item.$2),
      const Divider(height: 1, color: _line),
      Row(
        children: [
          Expanded(
            child: Text(
              t('Unlock detailed feedback', 'عرض الملاحظات التفصيلية'),
              style: const TextStyle(fontSize: 14, color: _muted),
            ),
          ),
          Text(
            t('EGP 100', '١٠٠ ج.م'),
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
        text: t('Unlock', 'فتح'),
        onPressed: previewNotice,
        child: _iconLabel('lock', t('Unlock', 'فتح'), Colors.white, size: 16),
      ),
      Text(
        t(
          'One-time payment. Includes tips to improve your next application.',
          'دفع لمرة واحدة. يتضمن نصائح لتحسين طلبك القادم.',
        ),
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
