import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../../talent_profile/presentation/widgets/profile_components.dart';
import '../../../talent_profile/presentation/widgets/profile_reevaluation_countdown.dart';
import '../status_copy.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/review_faq.dart';

/// Interactive design preview. Never writes interview or account state.
class ApplicationStatusView extends StatefulWidget {
  const ApplicationStatusView({super.key, required this.initialStatus});
  final ApplicationStatus initialStatus;
  @override
  State<ApplicationStatusView> createState() => _ApplicationStatusViewState();
}

class _ApplicationStatusViewState extends State<ApplicationStatusView> {
  late ApplicationStatus status = widget.initialStatus;
  final deadline = DateTime.now().add(const Duration(days: 72, hours: 21));
  int selected = 0;
  bool rescheduled = false;
  final List<String> history = [];
  bool get rejected =>
      status == ApplicationStatus.rejected ||
      status == ApplicationStatus.rejectedAfterInterview;
  bool get slots =>
      status == ApplicationStatus.slots || status == ApplicationStatus.newSlots;
  String t(String en, String ar) => sc(context, en, ar);

  @override
  void didUpdateWidget(covariant ApplicationStatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialStatus != widget.initialStatus) {
      status = widget.initialStatus;
      selected = 0;
      rescheduled = false;
      history.clear();
    }
  }

  void previewNotice() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(t('Design preview', 'معاينة التصميم')),
      content: Text(
        t(
          'This action is not connected yet. No booking, payment or account change has been made.',
          'هذا الإجراء غير متصل بالخدمة بعد. لم يتم إجراء حجز أو دفع أو تغيير في الحساب.',
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Close', 'إغلاق')),
        ),
      ],
    ),
  );

  Future<void> rejectSlots() async {
    final result = await showDialog<String>(
      context: context,
      builder: (_) => const _RejectSlotsDialog(),
    );
    if (!mounted || result == null) return;
    setState(() {
      history.add(t('Slots declined', 'تم رفض المواعيد'));
      status = ApplicationStatus.cancelled;
    });
  }

  Future<void> cancelInterview() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(t('Cancel this appointment?', 'إلغاء هذا الموعد؟')),
        content: SingleChildScrollView(
          child: ProfileStack(
            children: [
              Text(
                t(
                  'Are you sure you want to cancel your scheduled interview and choose a different time slot?',
                  'هل تريد إلغاء المقابلة المحددة واختيار موعد آخر؟',
                ),
              ),
              _notice(
                t(
                  'Please note: You only have one chance to cancel and reschedule. Once you choose a new slot, it will be final and no further changes will be allowed.',
                  'يرجى ملاحظة أن لديك فرصة واحدة للإلغاء وإعادة الجدولة. الموعد الجديد نهائي ولا يمكن تغييره مرة أخرى.',
                ),
                const Color(0xFFFEE2E2),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(t('Keep My Slot', 'الاحتفاظ بموعدي')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              t('Yes, Cancel', 'نعم، إلغاء'),
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (!mounted || result != true) return;
    setState(() {
      rescheduled = true;
      history.add(t('Interview cancelled', 'تم إلغاء المقابلة'));
      status = ApplicationStatus.slots;
    });
  }

  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Scaffold(
      backgroundColor: Colors.white,
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF7F7F7),
                child: SingleChildScrollView(
                  child: Center(
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 430),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                        child: ProfileStack(
                          gap: 12,
                          children: [
                            _banner(),
                            _steps(),
                            if (slots) ...[
                              _notice(
                                status == ApplicationStatus.newSlots
                                    ? t(
                                        'We sincerely apologize\nThe Qader team has cancelled your previously scheduled interview appointments. You now have a fresh opportunity to choose from newly available interview slots.',
                                        'نعتذر بصدق\nألغى فريق قادر مواعيد المقابلات السابقة. يمكنك الآن اختيار موعد من المواعيد الجديدة المتاحة.',
                                      )
                                    : t(
                                        "Congratulations! You've passed the initial review.\nThe Qader team has reviewed your profile and approved you for an interview. Please choose one of the available time slots below and confirm your selection.",
                                        'تهانينا! لقد اجتزت المراجعة الأولية.\nراجع فريق قادر ملفك ووافق على انتقالك للمقابلة. اختر أحد المواعيد المتاحة وأكد اختيارك.',
                                      ),
                                status == ApplicationStatus.newSlots
                                    ? const Color(0xFFFEFCE8)
                                    : const Color(0xFFDCFCE7),
                              ),
                              _slotCard(),
                            ],
                            if (status == ApplicationStatus.cancelled) ...[
                              _notice(
                                t(
                                  'Your previously selected interview slots have been cancelled. The Qader team is currently reviewing and preparing new available time slots for you. You will be notified once new slots are available.',
                                  'تم إلغاء مواعيد المقابلة السابقة. يعمل فريق قادر على تجهيز مواعيد جديدة، وسيتم إخطارك عند إتاحتها.',
                                ),
                                const Color(0xFFFEE2E2),
                              ),
                              _card([
                                _heading(
                                  t(
                                    'Available Interview Slots',
                                    'مواعيد المقابلة المتاحة',
                                  ),
                                ),
                                Text(
                                  t(
                                    'No available slots at the moment. New interview slots will be posted soon.',
                                    'لا توجد مواعيد متاحة حاليًا. ستتم إضافة مواعيد جديدة قريبًا.',
                                  ),
                                ),
                                _type(),
                                const Center(
                                  child: QaderAsset(
                                    'status_calendar',
                                    width: 32,
                                    height: 32,
                                  ),
                                ),
                                _heading(
                                  t(
                                    'No available slots at the moment',
                                    'لا توجد مواعيد متاحة حاليًا',
                                  ),
                                ),
                                Text(
                                  t(
                                    'You will be notified once new slots are available.',
                                    'سنخطرك فور توفر مواعيد جديدة.',
                                  ),
                                ),
                              ]),
                            ],
                            if (status == ApplicationStatus.confirmed ||
                                status == ApplicationStatus.completed)
                              _meeting(),
                            if (status == ApplicationStatus.accepted)
                              _notice(
                                t(
                                  "Congratulations! You've successfully passed the interview and have been accepted into the Qader Talent Network. Your profile is now available for matching with suitable opportunities.",
                                  'تهانينا! لقد اجتزت المقابلة وتم قبولك في شبكة مواهب قادر. أصبح ملفك متاحًا للفرص المناسبة.',
                                ),
                                const Color(0xFFDCFCE7),
                              ),
                            if (rejected) ..._rejection(),
                            if (!rejected &&
                                status != ApplicationStatus.accepted)
                              _history(),
                            ReviewFaq(
                              items: [
                                (
                                  question: rejected
                                      ? t(
                                          'What does “Under Review” mean?',
                                          'ما معنى «قيد المراجعة»؟',
                                        )
                                      : t(
                                          'How long does the review process take?',
                                          'كم تستغرق عملية المراجعة؟',
                                        ),
                                  answer: rejected
                                      ? t(
                                          'Your application has been received and is currently being reviewed by our recruitment team to assess your qualifications and experience.',
                                          'تم استلام طلبك ويراجعه فريق التوظيف لتقييم مؤهلاتك وخبراتك.',
                                        )
                                      : t(
                                          "The review time may vary depending on the number of applications. You'll be notified as soon as your application moves to the next stage.",
                                          'تختلف مدة المراجعة حسب عدد الطلبات. سيتم إخطارك فور انتقال طلبك للمرحلة التالية.',
                                        ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );

  Widget _banner() {
    final title = rejected
        ? t('Your Application Was Rejected', 'تم رفض طلبك')
        : status == ApplicationStatus.accepted
        ? t(
            'The applicant is approved and becomes visible to companies.',
            'تم قبول طلبك وأصبح ملفك ظاهرًا للشركات.',
          )
        : status == ApplicationStatus.completed
        ? t('The interview has been completed', 'اكتملت المقابلة')
        : status == ApplicationStatus.confirmed
        ? t('Your Profile Is Being Reviewed', 'ملفك قيد المراجعة')
        : t('Interview Slot Required', 'مطلوب اختيار موعد مقابلة');
    final badge = rejected
        ? t('Rejected', 'مرفوض')
        : status == ApplicationStatus.accepted
        ? t('Accepted', 'مقبول')
        : status == ApplicationStatus.completed
        ? t('Completed', 'مكتمل')
        : status == ApplicationStatus.confirmed
        ? t('Scheduled', 'مجدولة')
        : t('Interview Req', 'مطلوب مقابلة');
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: rejected
              ? const [Color(0xFF7F1D1D), Color(0xFFDC2626)]
              : const [
                  Color(0xFF0A1F6B),
                  QaderDesign.primary,
                  QaderDesign.blue,
                ],
        ),
      ),
      child: ProfileStack(
        gap: 8,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 8,
            children: [
              Text(
                t('Hello, Olivia Rhye', 'مرحبًا، أوليفيا راي'),
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
              _badge(badge),
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
            rejected
                ? t(
                    'A Qader reviewer has evaluated your profile and decided not to move forward at this time. You can apply again later.',
                    'راجع فريق قادر ملفك وقرر عدم المتابعة حاليًا. يمكنك التقديم مرة أخرى لاحقًا.',
                  )
                : status == ApplicationStatus.accepted
                ? t(
                    'Congratulations! Companies can now discover your profile and reach out with opportunities.',
                    'تهانينا! يمكن للشركات الآن اكتشاف ملفك والتواصل معك بالفرص.',
                  )
                : t(
                    'A Qader reviewer has opened your application and is evaluating your profile.',
                    'فتح أحد مراجعي قادر طلبك ويقوم بتقييم ملفك.',
                  ),
            style: const TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _steps() {
    final active =
        status == ApplicationStatus.confirmed ||
            status == ApplicationStatus.accepted
        ? 2
        : status == ApplicationStatus.rejected
        ? 0
        : 1;
    return Row(
      children: [
        for (var i = 0; i < 3; i++)
          Expanded(
            child: Column(
              children: [
                Text(
                  [
                    t('Under Review', 'قيد المراجعة'),
                    t('Interviews', 'المقابلات'),
                    t('Accepted', 'القبول'),
                  ][i],
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: i <= active ? FontWeight.w700 : FontWeight.w400,
                    color: rejected && i == active
                        ? Colors.red
                        : i <= active
                        ? QaderDesign.primary
                        : const Color(0xFF737373),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        height: 1,
                        color: i == 0
                            ? Colors.transparent
                            : i <= active
                            ? QaderDesign.primary
                            : const Color(0xFFD4D4D4),
                      ),
                    ),
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: i < active ? QaderDesign.primary : Colors.white,
                        border: Border.all(
                          width: 4,
                          color: rejected && i == active
                              ? Colors.red
                              : i <= active
                              ? QaderDesign.primary
                              : const Color(0xFFD4D4D4),
                        ),
                      ),
                      child: i < active
                          ? const QaderAsset(
                              'status_check',
                              width: 14,
                              height: 14,
                            )
                          : null,
                    ),
                    Expanded(
                      child: Container(
                        height: 1,
                        color: i == 2
                            ? Colors.transparent
                            : i < active
                            ? QaderDesign.primary
                            : const Color(0xFFD4D4D4),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _slotCard() => _card([
    Row(
      children: [
        Expanded(
          child: _heading(
            t('Available Interview Slots', 'مواعيد المقابلة المتاحة'),
          ),
        ),
        PopupMenuButton<String>(
          icon: const QaderAsset('status_more', width: 3, height: 13),
          constraints: const BoxConstraints(minWidth: 180),
          tooltip: t('More actions', 'المزيد'),
          onSelected: (_) => rejectSlots(),
          itemBuilder: (_) => [
            PopupMenuItem(
              value: 'reject',
              child: Text(t('Reject all slots', 'رفض كل المواعيد')),
            ),
          ],
        ),
      ],
    ),
    Text(
      t(
        'Select one slot and confirm your interview',
        'اختر موعدًا وأكد مقابلتك',
      ),
    ),
    _type(),
    for (var i = 0; i < 2; i++)
      Semantics(
        selected: selected == i,
        button: true,
        child: InkWell(
          key: ValueKey('slot-$i'),
          borderRadius: BorderRadius.circular(12),
          onTap: () => setState(() => selected = i),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: selected == i ? const Color(0xFFE8EFFC) : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: selected == i
                    ? const Color(0xFFB4CBF6)
                    : const Color(0xFFE5E5E5),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 52,
                  height: 64,
                  decoration: BoxDecoration(
                    color: selected == i
                        ? Colors.white
                        : const Color(0xFFF5F5F5),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        t('August', 'أغسطس'),
                        style: const TextStyle(fontSize: 12),
                      ),
                      const Text(
                        '4',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ProfileStack(
                    gap: 8,
                    children: [
                      Text(
                        t('Monday, Aug 4, 2026', 'الاثنين، ٤ أغسطس ٢٠٢٦'),
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      _detail(
                        'status_clock',
                        t('10:00 AM – 11:00 AM', '١٠:٠٠ ص – ١١:٠٠ ص'),
                      ),
                      if (i == 1)
                        _detail(
                          'location',
                          t('Alfardos, 6 of october', 'الفردوس، ٦ أكتوبر'),
                        ),
                      Align(
                        alignment: AlignmentDirectional.centerStart,
                        child: _badge(
                          i == 0
                              ? t('Online', 'عن بُعد')
                              : t('Offline', 'حضوري'),
                          color: i == 0
                              ? QaderDesign.primary
                              : const Color(0xFFA16207),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (selected == i)
                  const QaderAsset('radio_selected', width: 20, height: 20)
                else
                  Container(
                    width: 20,
                    height: 20,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFFD4D4D4)),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    if (status == ApplicationStatus.newSlots)
      DefaultButton.compact(
        text: t('Reject all slots', 'رفض كل المواعيد'),
        isOutlined: true,
        color: Colors.red,
        onPressed: rejectSlots,
      ),
    DefaultButton.compact(
      text: t('Confirm Selected Slot', 'تأكيد الموعد المحدد'),
      height: 36,
      onPressed: () => setState(() {
        status = ApplicationStatus.confirmed;
        history.add(t('Interview confirmed', 'تم تأكيد المقابلة'));
      }),
    ),
  ]);

  Widget _type() => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: QaderDesign.primary),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const QaderAsset('status_video', width: 22, height: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            t('Technical interview', 'مقابلة تقنية'),
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          ),
        ),
        Text(
          t('Round 1#', 'الجولة ١'),
          style: const TextStyle(fontSize: 12, color: QaderDesign.primary),
        ),
      ],
    ),
  );

  Widget _meeting() => _card([
    Row(
      children: [
        Expanded(
          child: _heading(
            status == ApplicationStatus.completed
                ? t('Interview Completed', 'اكتملت المقابلة')
                : t('Interview Confirmed!', 'تم تأكيد المقابلة!'),
          ),
        ),
        if (status == ApplicationStatus.confirmed && !rescheduled)
          PopupMenuButton<String>(
            icon: const QaderAsset('status_more', width: 3, height: 13),
            tooltip: t('More actions', 'المزيد'),
            onSelected: (_) => cancelInterview(),
            itemBuilder: (_) => [
              PopupMenuItem(
                value: 'cancel',
                child: Text(t('Cancel meeting', 'إلغاء المقابلة')),
              ),
            ],
          ),
      ],
    ),
    _detail(
      'status_clock',
      status == ApplicationStatus.completed
          ? t(
              'Your interview took place on Thursday, Aug 7, 2026 at 11:00 AM – 12:00 PM',
              'أُجريت مقابلتك الخميس، ٧ أغسطس ٢٠٢٦، ١١:٠٠ ص – ١٢:٠٠ م',
            )
          : t(
              "You've selected Monday, Aug 4, 2026 at 10:00 AM – 11:00 AM.",
              'اخترت الاثنين، ٤ أغسطس ٢٠٢٦، ١٠:٠٠ ص – ١١:٠٠ ص.',
            ),
    ),
    Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _badge(
          selected == 0 ? t('Online', 'عن بُعد') : t('Offline', 'حضوري'),
          color: QaderDesign.primary,
        ),
        _badge(
          t('HR Interview', 'مقابلة الموارد البشرية'),
          color: const Color(0xFF008236),
        ),
      ],
    ),
    if (status == ApplicationStatus.confirmed)
      DefaultButton.compact(
        text: selected == 0
            ? t('Join', 'انضمام')
            : t('View Location', 'عرض الموقع'),
        height: 48,
        onPressed: previewNotice,
      ),
    _notice(
      status == ApplicationStatus.completed
          ? t(
              "We're now reviewing your interview. You'll be notified once a decision has been made",
              'نراجع مقابلتك الآن. سيتم إخطارك عند اتخاذ القرار.',
            )
          : t(
              'A confirmation email will be sent to you shortly. Add this to your calendar and prepare for your Technical Interview.',
              'سيتم إرسال رسالة تأكيد. أضف الموعد لتقويمك واستعد للمقابلة التقنية.',
            ),
      const Color(0xFFF4F8FE),
    ),
  ]);

  Widget _history() => _card([
    ExpansionTile(
      tilePadding: EdgeInsets.zero,
      dense: true,
      visualDensity: VisualDensity.compact,
      trailing: const QaderAsset('chevron_down', width: 12, height: 12),
      leading: const ColorFiltered(
        colorFilter: ColorFilter.mode(Color(0xFF262626), BlendMode.srcIn),
        child: QaderAsset('status_history', width: 20, height: 20),
      ),
      title: Text(
        t('Interview History', 'سجل المقابلات'),
        style: const TextStyle(fontSize: 14),
      ),
      children: [
        for (final entry in history)
          ListTile(
            title: Text(entry),
            subtitle: Text(t('Design preview', 'معاينة التصميم')),
          ),
        if (history.isEmpty) ...[
          ListTile(
            title: Text(
              t('Technical Interview · Round #1', 'مقابلة تقنية · الجولة ١'),
            ),
            subtitle: Text(t('Completed · Online', 'مكتملة · عن بُعد')),
          ),
          ListTile(
            title: Text(
              t('Technical Interview · Round #2', 'مقابلة تقنية · الجولة ٢'),
            ),
            subtitle: Text(t('Upcoming · Offline', 'قادمة · حضوري')),
          ),
        ],
      ],
    ),
  ], padding: 12);

  List<Widget> _rejection() => [
    _card([
      _heading(t('We Appreciate Your Effort', 'نقدر جهودك')),
      Text(
        t(
          "Unfortunately, your application wasn't successful this time. We appreciate your time and effort, and we encourage you to apply again after the reapplication period has ended.",
          'للأسف لم يتم قبول طلبك هذه المرة. نقدر وقتك وجهدك ونشجعك على التقديم مرة أخرى بعد انتهاء فترة الانتظار.',
        ),
      ),
      Text(
        t(
          "We encourage you to continue developing your skills and experience, and you're welcome to submit a new application once the reapplication period has ended.",
          'نشجعك على تطوير مهاراتك وخبراتك، ويسعدنا استقبال طلبك الجديد بعد انتهاء فترة الانتظار.',
        ),
      ),
      ProfileReevaluationCountdown(deadline: deadline),
      DefaultButton.compact(
        text: t('Update Profile', 'تحديث الملف'),
        isOutlined: true,
        onPressed: () => context.push('/talent-profile?status=rejected'),
      ),
      DefaultButton.compact(
        text: t('Apply Again', 'التقديم مجددًا'),
        onPressed: null,
      ),
    ]),
    _card([
      _heading(t('Rejection feedback', 'ملاحظات الرفض')),
      Container(
        height: 100,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFFE5E5E5)),
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
                    'Your application was reviewed against the requirements. Unlock your detailed feedback and personalized tips for your next application.',
                    'تمت مراجعة طلبك وفق المتطلبات. افتح الملاحظات التفصيلية والنصائح المخصصة لتحسين طلبك القادم.',
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
                  child: QaderAsset('lock', width: 20, height: 20),
                ),
              ),
            ),
          ],
        ),
      ),
      Text(t("What's included", 'ما الذي تتضمنه الخدمة')),
      for (final pair in [
        ('Detailed rejection reason', 'سبب الرفض بالتفصيل'),
        ('CV review', 'مراجعة السيرة الذاتية'),
        ('Personalized tips', 'نصائح مخصصة لك'),
        ('Faster reapplication', 'إعادة تقديم أسرع'),
      ])
        _detail('profile_success', t(pair.$1, pair.$2)),
      const Divider(),
      Row(
        children: [
          Expanded(
            child: Text(
              t('Unlock detailed feedback', 'عرض الملاحظات التفصيلية'),
            ),
          ),
          Text(t('EGP 100', '١٠٠ ج.م')),
        ],
      ),
      DefaultButton.compact(text: t('Unlock', 'فتح'), onPressed: previewNotice),
      Text(
        t(
          'One-time payment. Includes tips to improve your next application.',
          'دفع لمرة واحدة. يتضمن نصائح لتحسين طلبك القادم.',
        ),
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 10),
      ),
    ]),
  ];

  Widget _heading(String text) => Text(
    text,
    style: const TextStyle(
      color: Color(0xFF171717),
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
      border: Border.all(color: const Color(0xFFE5E5E5)),
    ),
    child: DefaultTextStyle.merge(
      style: const TextStyle(
        fontSize: 12,
        height: 1.5,
        color: Color(0xFF525252),
      ),
      child: ProfileStack(gap: 12, children: children),
    ),
  );
  Widget _notice(String text, Color color) => Container(
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(8),
    ),
    child: ProfileStack(
      gap: 8,
      children: [
        if (color == const Color(0xFFDCFCE7) ||
            color == const Color(0xFFFEE2E2))
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              QaderAsset(
                color == const Color(0xFFDCFCE7)
                    ? 'status_success'
                    : 'status_cancel',
                width: 24,
                height: 24,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text.split('\n').first,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 20 / 14,
                    color: Color(0xFF171717),
                  ),
                ),
              ),
            ],
          )
        else
          Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF525252),
            ),
          ),
        if (text.contains('\n') &&
            (color == const Color(0xFFDCFCE7) ||
                color == const Color(0xFFFEE2E2)))
          Text(
            text.substring(text.indexOf('\n') + 1),
            style: const TextStyle(
              fontSize: 12,
              height: 1.5,
              color: Color(0xFF525252),
            ),
          ),
      ],
    ),
  );
  Widget _badge(String text, {Color color = const Color(0xFF404040)}) =>
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Text(
          text,
          style: TextStyle(fontSize: 14, height: 20 / 14, color: color),
        ),
      );
  Widget _detail(String asset, String text) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      QaderAsset(asset, width: 16, height: 16),
      const SizedBox(width: 8),
      Expanded(
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 12,
            height: 1.5,
            color: Color(0xFF525252),
          ),
        ),
      ),
    ],
  );
}

class _RejectSlotsDialog extends StatefulWidget {
  const _RejectSlotsDialog();
  @override
  State<_RejectSlotsDialog> createState() => _RejectSlotsDialogState();
}

class _RejectSlotsDialogState extends State<_RejectSlotsDialog> {
  String reason = '';
  @override
  Widget build(BuildContext context) => AlertDialog(
    title: Text(sc(context, 'Reject Interview Slots', 'رفض مواعيد المقابلة')),
    content: SingleChildScrollView(
      child: ProfileStack(
        children: [
          Text(
            sc(
              context,
              'Please explain why none of the available slots work for you.',
              'يرجى توضيح سبب عدم مناسبة المواعيد المتاحة لك.',
            ),
          ),
          Text(
            sc(
              context,
              'Rejecting all slots will notify the Qader team to provide new available times. This may delay your application.',
              'رفض جميع المواعيد يتيح لفريق قادر تجهيز مواعيد جديدة. قد يؤدي ذلك لتأخير طلبك.',
            ),
          ),
          TextField(
            minLines: 3,
            maxLines: 5,
            maxLength: 500,
            onChanged: (value) => setState(() => reason = value.trim()),
            decoration: InputDecoration(
              labelText: sc(context, 'Reason for rejection', 'سبب الرفض'),
              border: const OutlineInputBorder(),
              helperText: reason.length < 10
                  ? sc(
                      context,
                      '${10 - reason.length} more characters required',
                      'مطلوب ${10 - reason.length} أحرف إضافية',
                    )
                  : null,
            ),
          ),
        ],
      ),
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(context),
        child: Text(sc(context, 'Cancel', 'إلغاء')),
      ),
      TextButton(
        onPressed: reason.length < 10
            ? null
            : () => Navigator.pop(context, reason),
        child: Text(sc(context, 'Submit Rejection', 'تأكيد الرفض')),
      ),
    ],
  );
}
