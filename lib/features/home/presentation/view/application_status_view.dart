import 'package:easy_localization/easy_localization.dart';
import 'dart:async';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/qader_design.dart';
import '../../../../core/widgets/spaced_column.dart';
import '../../../../core/widgets/reevaluation_countdown.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../domain/talent_application.dart';
import '../preview/status_preview_data.dart';
import '../status_copy.dart';
import 'widgets/home_drawer.dart';
import 'widgets/home_header.dart';
import 'widgets/review_faq.dart';

part 'application_status/status_palette.dart';
part 'application_status/status_banner.dart';
part 'application_status/status_common.dart';
part 'application_status/status_slots.dart';
part 'application_status/status_meeting.dart';
part 'application_status/status_history.dart';
part 'application_status/status_rejection.dart';
part 'application_status/status_format.dart';
part 'application_status/status_dialogs.dart';

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
  /// `setState` for the section extensions in the part files.
  void _update(VoidCallback fn) => setState(fn);

  late ApplicationStatus status = widget.initialStatus;
  final _previewDeadline = StatusPreviewData.reapplyAt();
  TalentApplication? get app => widget.application;
  bool get live => app != null;
  DateTime? get deadline => live ? app!.reapplyAt : _previewDeadline;

  List<InterviewSlot> get _slots {
    if (!live) return StatusPreviewData.slots;
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
    final previewSlots = StatusPreviewData.slots;
    final slot = previewSlots[selected.clamp(0, previewSlots.length - 1)];
    return (
      start: StatusPreviewData.bookedStart,
      end: StatusPreviewData.bookedEnd,
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
      title: Text('status_design_preview'.tr(context: context)),
      content: Text(
        'status_this_action_is_not_connected_yet_no'.tr(context: context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('status_close'.tr(context: context)),
        ),
      ],
    ),
  );

  /// Live actions whose endpoints are not wired yet.
  void notConnected() => showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      content: Text(
        'status_this_action_will_be_available_soon'.tr(context: context),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('status_close'.tr(context: context)),
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
      barrierColor: AppColors.barrier,
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
      barrierColor: AppColors.barrier,
      builder: (context) => _StatusDialog(
        centered: true,
        title: 'status_cancel_this_appointment'.tr(context: context),
        content: [
          Text(
            'status_are_you_sure_you_want_to_cancel'.tr(context: context),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              height: 20 / 14,
              color: _muted,
            ),
          ),
          _DialogWarning(
            lead: 'status_please_note'.tr(context: context),
            text: 'status_you_only_have_one_chance_to_cancel'.tr(
              context: context,
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
            text: 'status_keep_my_slot'.tr(context: context),
          ),
          DefaultButton.compact(
            height: 44,
            color: _red,
            onPressed: () => Navigator.pop(context, true),
            text: 'status_yes_cancel'.tr(context: context),
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
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    drawer: HomeDrawer(preview: !live),
    body: SafeArea(
      child: Column(
        children: [
          const HomeHeader(),
          if (_busy) const LinearProgressIndicator(minHeight: 2),
          Expanded(
            child: ColoredBox(
              color: AppColors.background,
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
                          child: SpacedColumn(gap: 12, children: _sections()),
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
  );

  Widget _refreshable(Widget child) => widget.onRefresh == null
      ? child
      : RefreshIndicator(onRefresh: widget.onRefresh!, child: child);

  List<Widget> _sections() => [
    _banner(),
    _StatusSteps(
      labels: [
        'status_under_review'.tr(context: context),
        'status_interviews'.tr(context: context),
        'status_accepted'.tr(context: context),
      ],
      steps: _stepStates(),
    ),
    ...switch (status) {
      ApplicationStatus.slots => [
        _notice(
          _Tone.success,
          title: 'status_congratulations_you_ve_passed_the_initial_review'.tr(
            context: context,
          ),
          body: 'status_the_qader_team_has_reviewed_your_profile'.tr(
            context: context,
          ),
        ),
        _slots.isEmpty ? _emptySlotsCard() : _slotCard(),
      ],
      ApplicationStatus.newSlots => [
        _notice(
          _Tone.warning,
          title: 'status_we_sincerely_apologize'.tr(context: context),
          body: 'status_the_qader_team_has_cancelled_your_previously'.tr(
            context: context,
          ),
        ),
        _slots.isEmpty ? _emptySlotsCard() : _slotCard(),
      ],
      ApplicationStatus.cancelled => [
        _notice(
          _Tone.danger,
          lead: 'status_your_previously_selected_interview_slots_have_been'.tr(
            context: context,
          ),
          body: 'status_we_appreciate_your_patience_once_new_slots'.tr(
            context: context,
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
          body:
              'status_congratulations_you_ve_successfully_passed_the_interview'
                  .tr(context: context),
        ),
      ],
      ApplicationStatus.rejected ||
      ApplicationStatus.rejectedAfterInterview => _rejection(),
    },
    if (_showsHistory) _history(),
    ReviewFaq(items: _faqs()),
  ];

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
}
