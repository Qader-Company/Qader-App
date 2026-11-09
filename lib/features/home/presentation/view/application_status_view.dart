import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../../talent_profile/presentation/widgets/profile_components.dart';
import '../../../talent_profile/presentation/widgets/profile_reevaluation_countdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/talent_application.dart';
import '../status_copy.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/review_faq.dart';

// Palette taken from the "status" section of the Qader Figma file.
const _ink = Color(0xFF171717);
const _body = Color(0xFF404040);
const _muted = Color(0xFF525252);
const _line = Color(0xFFE5E5E5);
const _grey = Color(0xFFD4D4D4);
const _red = Color(0xFFDC2626);
const _redSoft = Color(0xFFFEE2E2);
const _green = Color(0xFF008236);
const _greenSoft = Color(0xFFDCFCE7);
const _yellow = Color(0xFFA16207);
const _yellowSoft = Color(0xFFFEFCE8);
const _blueSoft = Color(0xFFE8EFFC);
const _blueBorder = Color(0xFFB4CBF6);
const _disabledFill = Color(0xFFD5E0FA);

enum _Tone { success, warning, danger, info }

enum _Step { done, current, pending, failedDone, failedCurrent }

/// A single round shown in "Interview History".
class _HistoryEntry {
  const _HistoryEntry({
    required this.round,
    required this.completed,
    required this.date,
    required this.online,
    this.location,
  });
  final int round;
  final bool completed;
  final String date;
  final bool online;
  final String? location;
}

/// Application status screens (Figma "status" section).
///
/// With [application] it renders live data from `GET /talent/application`;
/// without it, it is an interactive design preview that never writes
/// interview or account state.
class ApplicationStatusView extends StatefulWidget {
  const ApplicationStatusView({
    super.key,
    required this.initialStatus,
    this.application,
    this.userName,
    this.onRefresh,
    this.onSelectSlot,
    this.onRejectSlots,
    this.onCancelInterview,
  });
  final ApplicationStatus initialStatus;
  final TalentApplication? application;
  final String? userName;
  final Future<void> Function()? onRefresh;

  /// Live actions. Each returns an error message, or `null` on success; the
  /// caller reloads the application afterwards.
  final Future<String?> Function(int slotId)? onSelectSlot;
  final Future<String?> Function(String reason)? onRejectSlots;
  final Future<String?> Function()? onCancelInterview;
  @override
  State<ApplicationStatusView> createState() => _ApplicationStatusViewState();
}

class _ApplicationStatusViewState extends State<ApplicationStatusView> {
  late ApplicationStatus status = widget.initialStatus;
  final _previewDeadline = DateTime.now().add(
    const Duration(days: 72, hours: 21),
  );
  TalentApplication? get app => widget.application;
  bool get live => app != null;
  DateTime? get deadline => live ? app!.reapplyAt : _previewDeadline;

  static final _previewSlots = [
    InterviewSlot(
      id: 1,
      start: DateTime(2026, 8, 4, 10),
      end: DateTime(2026, 8, 4, 11),
    ),
    InterviewSlot(
      id: 2,
      start: DateTime(2026, 8, 4, 10),
      end: DateTime(2026, 8, 4, 11),
      online: false,
      location: 'Alfardos , 6 of october',
    ),
  ];

  List<InterviewSlot> get _slots {
    if (!live) return _previewSlots;
    return app!.slots;
  }

  /// The booked interview (live) or the slot picked in the preview.
  ({DateTime? start, DateTime? end, bool online, String? location, int round})
  get _booked {
    if (live) {
      final interview = app!.interview;
      return (
        start: interview?.start,
        end: interview?.end,
        online: interview?.online ?? true,
        location: interview?.location,
        round: interview?.round ?? 1,
      );
    }
    final slot = _previewSlots[selected.clamp(0, _previewSlots.length - 1)];
    return (
      start: DateTime(2026, 8, 7, 11),
      end: DateTime(2026, 8, 7, 12),
      online: slot.online,
      location: slot.location,
      round: 1,
    );
  }

  int selected = 0;
  bool rescheduled = false;
  bool historyOpen = false;

  bool get rejected =>
      status == ApplicationStatus.rejected ||
      status == ApplicationStatus.rejectedAfterInterview;
  bool get slots =>
      status == ApplicationStatus.slots || status == ApplicationStatus.newSlots;
  bool get online => _booked.online;
  String t(String en, String ar) => sc(context, en, ar);

  @override
  void didUpdateWidget(covariant ApplicationStatusView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.application != widget.application) _scheduleJoinRefresh();
    if (oldWidget.initialStatus != widget.initialStatus) {
      status = widget.initialStatus;
      selected = 0;
      rescheduled = false;
      historyOpen = false;
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

  /// Live actions whose endpoints are not wired yet.
  void notConnected() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(
        t('This action will be available soon.', 'سيتوفر هذا الإجراء قريبًا.'),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('Close', 'إغلاق')),
        ),
      ],
    ),
  );

  bool _busy = false;

  /// Runs a live action with a progress bar and reports a failure.
  Future<void> _runAction(Future<String?> Function()? action) async {
    if (action == null) return notConnected();
    if (_busy) return;
    setState(() => _busy = true);
    final messenger = ScaffoldMessenger.maybeOf(context);
    final error = await action();
    if (mounted) setState(() => _busy = false);
    if (error != null) {
      messenger
        ?..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  void confirmSlot() {
    if (live) {
      if (_slots.isEmpty) return;
      final slot = _slots[selected.clamp(0, _slots.length - 1)];
      final select = widget.onSelectSlot;
      _runAction(select == null ? null : () => select(slot.id));
      return;
    }
    setState(() => status = ApplicationStatus.confirmed);
  }

  Future<void> _openMeeting() async {
    final interview = app?.interview;
    final query = interview?.latitude != null && interview?.longitude != null
        ? '${interview!.latitude},${interview.longitude}'
        : _booked.location;
    final url = online
        ? interview?.meetingUrl
        : query == null
        ? null
        : 'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(query)}';
    final uri = url == null ? null : Uri.tryParse(url);
    if (uri == null ||
        !await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      if (mounted) notConnected();
    }
  }

  Future<void> rejectSlots() async {
    final result = await showDialog<String>(
      context: context,
      barrierColor: const Color(0x962D2C2C),
      builder: (_) => const _RejectSlotsDialog(),
    );
    if (!mounted || result == null) return;
    if (live) {
      final reject = widget.onRejectSlots;
      return _runAction(reject == null ? null : () => reject(result));
    }
    setState(() => status = ApplicationStatus.cancelled);
  }

  Future<void> cancelInterview() async {
    final result = await showDialog<bool>(
      context: context,
      barrierColor: const Color(0x962D2C2C),
      builder: (context) => _StatusDialog(
        centered: true,
        title: t('Cancel this appointment?', 'إلغاء هذا الموعد؟'),
        content: [
          Text(
            t(
              'Are you sure you want to cancel your scheduled interview and choose a different time slot?',
              'هل أنت متأكد من إلغاء المقابلة المحددة واختيار موعد آخر؟',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: _muted,
            ),
          ),
          _DialogWarning(
            lead: t('Please note', 'يرجى الملاحظة'),
            text: t(
              'You only have one chance to cancel and reschedule. Once you choose a new slot, it will be final and no further changes will be allowed.',
              'لديك فرصة واحدة فقط للإلغاء وإعادة الجدولة. بمجرد اختيار موعد جديد سيكون نهائيًا ولن يُسمح بأي تغيير آخر.',
            ),
            destructive: true,
          ),
        ],
        actions: [
          DefaultButton.compact(
            height: 44,
            isOutlined: true,
            color: _grey,
            textColor: _body,
            onPressed: () => Navigator.pop(context, false),
            text: t('Keep My Slot', 'الاحتفاظ بموعدي'),
          ),
          DefaultButton.compact(
            height: 44,
            color: _red,
            onPressed: () => Navigator.pop(context, true),
            text: t('Yes, Cancel', 'نعم، إلغاء'),
          ),
        ],
      ),
    );
    if (!mounted || result != true) return;
    if (live) return _runAction(widget.onCancelInterview);
    setState(() {
      rescheduled = true;
      status = ApplicationStatus.slots;
    });
  }

  @override
  Widget build(BuildContext context) => QaderTheme(
    child: Scaffold(
      backgroundColor: Colors.white,
      drawer: HomeDrawer(preview: !live),
      body: SafeArea(
        child: Column(
          children: [
            const HomeHeader(),
            if (_busy) const LinearProgressIndicator(minHeight: 2),
            Expanded(
              child: ColoredBox(
                color: const Color(0xFFF7F7F7),
                child: _refreshable(
                  SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 430),
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                          child: AbsorbPointer(
                            absorbing: _busy,
                            child: ProfileStack(gap: 12, children: _sections()),
                          ),
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

  Widget _refreshable(Widget child) => widget.onRefresh == null
      ? child
      : RefreshIndicator(onRefresh: widget.onRefresh!, child: child);

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

  List<Widget> _sections() => [
    _banner(),
    _StatusSteps(
      labels: [
        t('Under Review', 'قيد المراجعة'),
        t('Interviews', 'المقابلات'),
        t('Accepted', 'القبول'),
      ],
      steps: _stepStates(),
    ),
    ...switch (status) {
      ApplicationStatus.slots => [
        _notice(
          _Tone.success,
          title: t(
            "Congratulations! You've passed the initial review.",
            'تهانينا! لقد اجتزت المراجعة الأولية.',
          ),
          body: t(
            'The Qader team has reviewed your profile and approved you for an interview. Please choose one of the available time slots below and confirm your selection.',
            'راجع فريق قادر ملفك ووافق على انتقالك إلى المقابلة. يرجى اختيار أحد المواعيد المتاحة أدناه وتأكيد اختيارك.',
          ),
        ),
        _slots.isEmpty ? _emptySlotsCard() : _slotCard(),
      ],
      ApplicationStatus.newSlots => [
        _notice(
          _Tone.warning,
          title: t('We sincerely apologize', 'نعتذر بصدق'),
          body: t(
            "The Qader team has cancelled your previously scheduled interview appointments. We understand this may be inconvenient, and we're sorry for any disruption. You now have a fresh opportunity to choose from newly available interview slots. Please confirm to proceed and select your preferred time.",
            'ألغى فريق قادر مواعيد المقابلة التي حددتها سابقًا. نتفهم أن ذلك قد يسبب لك إزعاجًا ونعتذر عنه. لديك الآن فرصة جديدة لاختيار موعد من المواعيد المتاحة حديثًا. يرجى التأكيد واختيار الموعد المناسب لك.',
          ),
        ),
        _slots.isEmpty ? _emptySlotsCard() : _slotCard(),
      ],
      ApplicationStatus.cancelled => [
        _notice(
          _Tone.danger,
          lead: t(
            'Your previously selected interview slots have been cancelled. The Qader team is currently reviewing and preparing new available time slots for you. You will be notified once new slots are available',
            'تم إلغاء مواعيد المقابلة التي اخترتها سابقًا. يعمل فريق قادر حاليًا على مراجعة وتجهيز مواعيد جديدة لك، وسيتم إخطارك فور توفرها',
          ),
          body: t(
            ", We appreciate your patience. Once new slots are available, you'll receive an email notification and can select a new time from this page..",
            '. نقدّر صبرك. عند توفر مواعيد جديدة ستصلك رسالة على بريدك الإلكتروني ويمكنك اختيار موعد جديد من هذه الصفحة.',
          ),
        ),
        _emptySlotsCard(),
      ],
      ApplicationStatus.confirmed ||
      ApplicationStatus.completed => [_meeting()],
      ApplicationStatus.accepted => [
        _notice(
          _Tone.success,
          clockIcon: true,
          body: t(
            "Congratulations! You've successfully passed the interview and have been accepted into the Qader Talent Network. Your profile is now available for matching with suitable opportunities.",
            'تهانينا! لقد اجتزت المقابلة بنجاح وتم قبولك في شبكة مواهب قادر. أصبح ملفك متاحًا الآن للترشيح للفرص المناسبة.',
          ),
        ),
      ],
      ApplicationStatus.rejected ||
      ApplicationStatus.rejectedAfterInterview => _rejection(),
    },
    if (_showsHistory) _history(),
    ReviewFaq(items: _faqs()),
  ];

  bool get _showsHistory => live
      ? app!.history.isNotEmpty
      : switch (status) {
          ApplicationStatus.slots ||
          ApplicationStatus.cancelled ||
          ApplicationStatus.confirmed ||
          ApplicationStatus.completed => true,
          _ => false,
        };

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
              ? const [Color(0xFF7F1D1D), _red]
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
              color: Color(0xCCFFFFFF),
              fontSize: 12,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
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
          shadowColor: const Color(0x33000000),
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

  Widget _slotCard() => _card([
    Row(
      children: [
        Expanded(
          child: _heading(
            t('Available Interview Slots', 'مواعيد المقابلة المتاحة'),
          ),
        ),
        if (_canRejectSlots)
          _moreMenu(
            label: t('reject all slots', 'رفض كل المواعيد'),
            onSelected: rejectSlots,
          ),
      ],
    ),
    Text(
      t(
        'Select one slot and confirm your interview',
        'اختر موعدًا وأكد مقابلتك',
      ),
    ),
    _type(outlined: true),
    for (var i = 0; i < _slots.length; i++) _slot(i),
    if (status == ApplicationStatus.newSlots && _canRejectSlots)
      DefaultButton.compact(
        height: 36,
        isOutlined: true,
        color: const Color(0xFFFCA5A5),
        textColor: _red,
        text: t('Reject all slots', 'رفض كل المواعيد'),
        onPressed: rejectSlots,
        child: _iconLabel(
          'status_close',
          t('Reject all slots', 'رفض كل المواعيد'),
          _red,
          size: 12,
        ),
      ),
    if (_canSelectSlot)
      DefaultButton.compact(
        text: t('Confirm Selected Slot', 'تأكيد الموعد المحدد'),
        height: 36,
        onPressed: confirmSlot,
      )
    else
      _disabledButton(
        t('Confirm Selected Slot', 'تأكيد الموعد المحدد'),
        height: 36,
      ),
  ]);

  // Backend `interview.actions`; the preview allows everything.
  InterviewActions? get _actions => live ? app!.interview?.actions : null;
  bool get _canSelectSlot => _actions?.canSelectSlot ?? true;
  bool get _canRejectSlots =>
      _actions?.canRejectAllSlots ??
      (app?.interview?.rejectionsRemaining ?? 1) > 0;
  bool get _canCancelInterview => live
      ? _actions?.canCancelAndReschedule ??
            !(app!.interview?.rescheduleUsed ?? false)
      : !rescheduled;
  bool get _canJoin {
    if (!live) return true;
    final interview = app!.interview;
    if (interview == null) return false;
    if (interview.actions.canJoin == null &&
        interview.joinWindowStart == null) {
      return true;
    }
    return interview.canJoinAt(DateTime.now());
  }

  /// Rebuilds when the join window opens or closes while the screen is open.
  Timer? _joinTimer;
  void _scheduleJoinRefresh() {
    _joinTimer?.cancel();
    final interview = app?.interview;
    final now = DateTime.now();
    final next = [interview?.joinWindowStart, interview?.joinWindowEnd]
        .whereType<DateTime>()
        .where((at) => at.isAfter(now))
        .fold<DateTime?>(
          null,
          (soonest, at) =>
              soonest == null || at.isBefore(soonest) ? at : soonest,
        );
    if (next == null) return;
    _joinTimer = Timer(next.difference(now) + const Duration(seconds: 1), () {
      if (!mounted) return;
      setState(() {});
      _scheduleJoinRefresh();
    });
  }

  @override
  void initState() {
    super.initState();
    _scheduleJoinRefresh();
  }

  @override
  void dispose() {
    _joinTimer?.cancel();
    super.dispose();
  }

  Widget _slot(int i) {
    final slot = _slots[i];
    final isSelected = selected == i;
    final isOnline = slot.online;
    return Semantics(
      selected: isSelected,
      button: true,
      child: InkWell(
        key: ValueKey('slot-$i'),
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => selected = i),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isSelected ? _blueSoft : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? _blueBorder : _line),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 52,
                height: 64,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : const Color(0xFFF5F5F5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Long names ("November") shrink instead of wrapping.
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          _month(slot.start),
                          maxLines: 1,
                          style: const TextStyle(fontSize: 12, color: _ink),
                        ),
                      ),
                    ),
                    Text(
                      _digits('${slot.start.day}'),
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: _ink,
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
                      _day(slot.start),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _ink,
                      ),
                    ),
                    _detail('status_clock', _range(slot.start, slot.end)),
                    if (!isOnline && slot.location != null)
                      _detail(
                        'location',
                        slot.location!,
                        trailing: const QaderAsset(
                          'status_map',
                          width: 14,
                          height: 14,
                        ),
                      ),
                    Align(
                      alignment: AlignmentDirectional.centerStart,
                      child: isOnline
                          ? _Badge(
                              t('Online', 'عن بُعد'),
                              color: QaderDesign.primary,
                              fill: isSelected ? Colors.white : _blueSoft,
                            )
                          : _Badge(
                              t('Offline', 'حضوري'),
                              color: _yellow,
                              fill: isSelected ? Colors.white : _yellowSoft,
                            ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (isSelected)
                const QaderAsset('radio_selected', width: 20, height: 20)
              else
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _grey),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _type({required bool outlined}) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: outlined ? Colors.white : _blueSoft,
      border: outlined ? Border.all(color: QaderDesign.primary) : null,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      children: [
        const QaderAsset('status_video', width: 22, height: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            _interviewType(),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: _ink,
            ),
          ),
        ),
        if (outlined)
          Text(
            _round(),
            style: const TextStyle(fontSize: 14, color: QaderDesign.primary),
          ),
      ],
    ),
  );

  Widget _emptySlotsCard() => _card([
    Row(
      children: [
        Expanded(
          child: _heading(
            t('Available Interview Slots', 'مواعيد المقابلة المتاحة'),
          ),
        ),
        _Badge(_round(), color: QaderDesign.primary, fill: _blueSoft),
      ],
    ),
    Text(
      t(
        'No available slots at the moment. New interview slots will be posted soon.',
        'لا توجد مواعيد متاحة حاليًا. سيتم نشر مواعيد مقابلة جديدة قريبًا.',
      ),
    ),
    _type(outlined: false),
    Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: _line),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: [
          const QaderAsset('status_calendar', width: 32, height: 32),
          const SizedBox(height: 12),
          Text(
            t(
              'No available slots at the moment',
              'لا توجد مواعيد متاحة حاليًا',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              height: 1.5,
              color: _ink,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            t(
              'New interview slots will be posted soon. You will be notified once new slots are available.',
              'سيتم نشر مواعيد مقابلة جديدة قريبًا، وسنخطرك فور توفرها.',
            ),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: _muted,
            ),
          ),
        ],
      ),
    ),
    Text(
      t(
        'No actions available until new slots are posted.',
        'لا توجد إجراءات متاحة حتى يتم نشر مواعيد جديدة.',
      ),
      style: const TextStyle(fontSize: 14, height: 20 / 14, color: _body),
    ),
  ]);

  Widget _meeting() {
    final completed = status == ApplicationStatus.completed;
    final booked = _booked;
    return _card([
      Row(
        children: [
          Expanded(
            child: _heading(
              completed
                  ? t('Interview Completed', 'اكتملت المقابلة')
                  : t('Interview Confirmed!', 'تم تأكيد المقابلة!'),
            ),
          ),
          if (!completed && _canCancelInterview)
            _moreMenu(
              label: t('Cancel meeting', 'إلغاء المقابلة'),
              onSelected: cancelInterview,
            ),
        ],
      ),
      if (booked.start case final start?)
        _detail(
          'status_clock',
          completed
              ? t(
                  'Your interview took place on ${_day(start)} at ${_range(start, booked.end)}',
                  'أُجريت مقابلتك يوم ${_day(start)} ${_range(start, booked.end)}',
                )
              : t(
                  "You've selected ${_day(start)} at ${_range(start, booked.end)}.",
                  'اخترت يوم ${_day(start)} ${_range(start, booked.end)}.',
                ),
        ),
      if (!online && booked.location != null)
        _detail('location', booked.location!),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          online
              ? _Badge(
                  t('Online', 'عن بُعد'),
                  color: QaderDesign.primary,
                  fill: _blueSoft,
                  dot: !completed,
                )
              : _Badge(
                  t('Offline', 'حضوري'),
                  color: _yellow,
                  fill: _yellowSoft,
                  dot: !completed,
                ),
          _Badge(
            _interviewType(fallbackHr: true),
            color: _green,
            fill: _greenSoft,
            dot: !completed,
          ),
          if (completed)
            _Badge(
              t(
                'Round ${booked.round}#',
                'الجولة ${_digits('${booked.round}')}#',
              ),
              color: _yellow,
              fill: _yellowSoft,
            ),
        ],
      ),
      if (!completed && online && !_canJoin)
        _disabledButton(t('Join', 'انضمام'), height: 48)
      else if (!completed)
        DefaultButton.compact(
          height: 48,
          text: online ? t('Join', 'انضمام') : t('View Location', 'عرض الموقع'),
          onPressed: live ? _openMeeting : previewNotice,
          child: _iconLabel(
            online ? Icons.co_present_outlined : 'status_map',
            online ? t('Join', 'انضمام') : t('View Location', 'عرض الموقع'),
            Colors.white,
          ),
        ),
      Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: QaderDesign.paleBlue,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          completed
              ? t(
                  "We're now reviewing your interview. You'll be notified once a decision has been made",
                  'نراجع مقابلتك الآن، وسيتم إخطارك فور اتخاذ القرار.',
                )
              : t(
                  'A confirmation email will be sent to you shortly. Add this to your calendar and prepare for your Technical Interview.',
                  'ستصلك رسالة تأكيد على بريدك الإلكتروني قريبًا. أضف الموعد إلى تقويمك واستعد للمقابلة التقنية.',
                ),
          style: TextStyle(
            fontSize: completed ? 14 : 12,
            height: completed ? 20 / 14 : 1.5,
            color: _muted,
          ),
        ),
      ),
    ]);
  }

  List<_HistoryEntry> get _historyEntries => live
      ? [
          for (final entry in app!.history)
            _HistoryEntry(
              round: entry.round,
              completed: entry.completed,
              date: entry.start == null
                  ? '-'
                  : '${_day(entry.start!)}, ${_time(entry.start!)}',
              online: entry.online,
              location: entry.online ? null : entry.location,
            ),
        ]
      : const [
          _HistoryEntry(
            round: 1,
            completed: true,
            date: 'Monday, Aug 4, 2026, 10:00 AM',
            online: true,
          ),
          _HistoryEntry(
            round: 2,
            completed: false,
            date: 'Monday, Aug 4, 2026, 10:00 AM',
            online: false,
            location: 'Alfardos , 6 of october',
          ),
        ];

  Widget _history() {
    if (!historyOpen) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => setState(() => historyOpen = true),
        child: _card([
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: Color(0xFF262626)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  t('Interview History', 'سجل المقابلات'),
                  style: const TextStyle(fontSize: 14, color: _ink),
                ),
              ),
              const QaderAsset('chevron_down', width: 12, height: 12),
            ],
          ),
        ], padding: 12),
      );
    }
    final entries = _historyEntries;
    return _card([
      Row(
        children: [
          Text(
            t('Interview History', 'سجل المقابلات'),
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: _ink,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: const BoxDecoration(
              color: QaderDesign.primary,
              shape: BoxShape.circle,
            ),
            child: Text(
              '${entries.length}',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
          ),
          const Spacer(),
          IconButton(
            tooltip: t('Close', 'إغلاق'),
            visualDensity: VisualDensity.compact,
            onPressed: () => setState(() => historyOpen = false),
            icon: const QaderAsset('status_close', width: 13, height: 13),
          ),
        ],
      ),
      for (final entry in entries) _historyItem(entry),
    ]);
  }

  Widget _historyItem(_HistoryEntry entry) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: _line),
      borderRadius: BorderRadius.circular(8),
    ),
    child: ProfileStack(
      gap: 8,
      children: [
        Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: const BoxDecoration(
                color: QaderDesign.primary,
                shape: BoxShape.circle,
              ),
              child: Text(
                'R${entry.round}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                t('Technical Interview', 'مقابلة تقنية'),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
          ],
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            entry.completed
                ? _Badge(
                    t('Completed', 'مكتملة'),
                    color: _green,
                    fill: _greenSoft,
                  )
                : _Badge(
                    t('Upcoming', 'قادمة'),
                    color: QaderDesign.primary,
                    fill: _blueSoft,
                  ),
            _Badge(
              t('Round #${entry.round}', 'الجولة #${entry.round}'),
              color: QaderDesign.primary,
              fill: _blueSoft,
            ),
          ],
        ),
        Row(
          children: [
            Expanded(child: _detail('status_clock', entry.date)),
            const SizedBox(width: 8),
            const ColorFiltered(
              colorFilter: ColorFilter.mode(_muted, BlendMode.srcIn),
              child: QaderAsset('status_video', width: 14, height: 12),
            ),
            const SizedBox(width: 6),
            Text(
              entry.online ? t('Online', 'عن بُعد') : t('Offline', 'حضوري'),
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
        if (entry.location != null) _detail('location', entry.location!),
      ],
    ),
  );

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

  bool get _ar => Localizations.localeOf(context).languageCode == 'ar';
  static const _monthsEn = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];
  static const _monthsAr = [
    'يناير',
    'فبراير',
    'مارس',
    'أبريل',
    'مايو',
    'يونيو',
    'يوليو',
    'أغسطس',
    'سبتمبر',
    'أكتوبر',
    'نوفمبر',
    'ديسمبر',
  ];
  static const _daysEn = [
    'Monday',
    'Tuesday',
    'Wednesday',
    'Thursday',
    'Friday',
    'Saturday',
    'Sunday',
  ];
  static const _daysAr = [
    'الاثنين',
    'الثلاثاء',
    'الأربعاء',
    'الخميس',
    'الجمعة',
    'السبت',
    'الأحد',
  ];

  String _digits(String value) => _ar
      ? value.replaceAllMapped(
          RegExp('[0-9]'),
          (m) => '٠١٢٣٤٥٦٧٨٩'[int.parse(m[0]!)],
        )
      : value;

  String _month(DateTime date) => (_ar ? _monthsAr : _monthsEn)[date.month - 1];

  /// "Monday, Aug 4, 2026" / "الاثنين، ٤ أغسطس ٢٠٢٦".
  String _day(DateTime date) => _ar
      ? _digits(
          '${_daysAr[date.weekday - 1]}، ${date.day} ${_month(date)} ${date.year}',
        )
      : '${_daysEn[date.weekday - 1]}, ${_month(date).substring(0, 3)} '
            '${date.day}, ${date.year}';

  /// "10:00 AM" / "١٠:٠٠ ص".
  String _time(DateTime date) {
    final hour = date.hour % 12 == 0 ? 12 : date.hour % 12;
    final minute = '${date.minute}'.padLeft(2, '0');
    final am = date.hour < 12;
    return _digits('$hour:$minute ${am ? t('AM', 'ص') : t('PM', 'م')}');
  }

  String _range(DateTime start, DateTime? end) =>
      end == null ? _time(start) : '${_time(start)} – ${_time(end)}';

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
      child: ProfileStack(gap: 12, children: children),
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
        colorFilter: const ColorFilter.mode(Color(0xFFCA8A04), BlendMode.srcIn),
        child: iconWidget,
      );
    }
    if (clockIcon) {
      iconWidget = Container(
        width: 24,
        height: 24,
        decoration: const BoxDecoration(
          color: Color(0xFF16A34A),
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
      child: ProfileStack(
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
                    color: const Color(0xFFF7F7F7),
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
                            ? const Color(0xFF737373)
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

/// White rounded dialog used by the status screens (Figma "modal").
class _StatusDialog extends StatelessWidget {
  const _StatusDialog({
    required this.title,
    required this.content,
    required this.actions,
    this.centered = false,
  });
  final String title;
  final List<Widget> content;
  final List<Widget> actions;
  final bool centered;

  @override
  Widget build(BuildContext context) {
    final close = IconButton(
      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
      visualDensity: VisualDensity.compact,
      onPressed: () => Navigator.pop(context),
      icon: const QaderAsset('status_close', width: 13, height: 13),
    );
    final heading = Text(
      title,
      textAlign: centered ? TextAlign.center : TextAlign.start,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        height: 28 / 18,
        color: _ink,
      ),
    );
    return Dialog(
      backgroundColor: Colors.white,
      surfaceTintColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 400),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: ProfileStack(
            gap: 16,
            children: [
              if (centered) ...[
                Align(alignment: AlignmentDirectional.centerEnd, child: close),
                heading,
              ] else
                Row(
                  children: [
                    Expanded(child: heading),
                    close,
                  ],
                ),
              ...content,
              ProfileStack(gap: 12, children: actions),
            ],
          ),
        ),
      ),
    );
  }
}

class _DialogWarning extends StatelessWidget {
  const _DialogWarning({
    required this.text,
    this.lead,
    this.destructive = false,
  });
  final String text;
  final String? lead;
  final bool destructive;

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: destructive ? _redSoft : const Color(0xFFFEF9C3),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        QaderAsset(
          destructive ? 'status_warning_red' : 'status_warning_yellow',
          width: 21,
          height: 20,
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                if (lead != null)
                  TextSpan(
                    text: '$lead: ',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                TextSpan(text: text),
              ],
            ),
            style: const TextStyle(fontSize: 14, height: 20 / 14, color: _body),
          ),
        ),
      ],
    ),
  );
}

class _RejectSlotsDialog extends StatefulWidget {
  const _RejectSlotsDialog();
  @override
  State<_RejectSlotsDialog> createState() => _RejectSlotsDialogState();
}

class _RejectSlotsDialogState extends State<_RejectSlotsDialog> {
  static const _minLength = 10;
  String reason = '';
  String t(String en, String ar) => sc(context, en, ar);

  @override
  Widget build(BuildContext context) {
    final missing = _minLength - reason.length;
    return _StatusDialog(
      title: t('Reject Interview Slots', 'رفض مواعيد المقابلة'),
      content: [
        Text(
          t(
            'Please explain why none of the available slots work for you.',
            'يرجى توضيح سبب عدم مناسبة أي من المواعيد المتاحة لك.',
          ),
          style: const TextStyle(fontSize: 14, height: 20 / 14, color: _muted),
        ),
        const Divider(height: 1, color: _line),
        _DialogWarning(
          text: t(
            'Rejecting all slots will notify the Qader team to provide new available times. This may delay your application.',
            'رفض جميع المواعيد سيُخطر فريق قادر بتوفير مواعيد جديدة، وقد يؤدي ذلك إلى تأخير طلبك.',
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              t('Reason for rejection *', 'سبب الرفض *'),
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: _body,
              ),
            ),
            const SizedBox(height: 8),
            TextField(
              minLines: 3,
              maxLines: 5,
              maxLength: 500,
              onChanged: (value) => setState(() => reason = value.trim()),
              style: const TextStyle(fontSize: 14, color: _ink),
              decoration: InputDecoration(
                counterText: '',
                hintText: t(
                  "e.g. I'm unavailable on all three dates due to a prior commitment. Please provide slots for the following week.",
                  'مثال: لست متاحًا في المواعيد الثلاثة بسبب التزام سابق. يرجى توفير مواعيد في الأسبوع التالي.',
                ),
                hintStyle: const TextStyle(
                  fontSize: 14,
                  height: 20 / 14,
                  color: Color(0xFF737373),
                ),
                contentPadding: const EdgeInsets.all(12),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: _grey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: const BorderSide(color: QaderDesign.primary),
                ),
              ),
            ),
            if (missing > 0) ...[
              const SizedBox(height: 6),
              Text(
                t(
                  '$missing more characters required',
                  'مطلوب $missing أحرف إضافية',
                ),
                textAlign: TextAlign.end,
                style: const TextStyle(fontSize: 12, color: _red),
              ),
            ],
          ],
        ),
      ],
      actions: [
        if (missing > 0)
          _disabledButton(t('Submit Rejection', 'تأكيد الرفض'), height: 44)
        else
          DefaultButton.compact(
            height: 44,
            text: t('Submit Rejection', 'تأكيد الرفض'),
            onPressed: () => Navigator.pop(context, reason.trim()),
          ),
        DefaultButton.compact(
          height: 44,
          isOutlined: true,
          color: _grey,
          textColor: _body,
          text: t('Cancel', 'إلغاء'),
          onPressed: () => Navigator.pop(context),
        ),
      ],
    );
  }
}
