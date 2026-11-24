import 'package:easy_localization/easy_localization.dart';
import '../../../../core/widgets/app_toast.dart';
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
import '../../domain/entities/talent_application.dart';
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
part 'application_status/status_actions.dart';

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
    this.busy = false,
  });
  final ApplicationStatus initialStatus;

  /// A live action is in flight: shows a progress bar and locks the
  /// sections until the application has been reloaded.
  final bool busy;
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

  /// Runs a live action and reports a failure. The caller's state drives
  /// [ApplicationStatusView.busy] meanwhile.
  Future<void> _runAction(Future<String?> Function()? action) async {
    if (action == null) return notConnected();
    if (widget.busy) return;
    final error = await action();
    if (!mounted) return;
    if (error != null) showAppToast(context, error, type: ToastType.error);
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    backgroundColor: Colors.white,
    drawer: HomeDrawer(preview: !live),
    body: SafeArea(
      child: Column(
        children: [
          const HomeHeader(),
          if (widget.busy) const LinearProgressIndicator(minHeight: 2),
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
                          absorbing: widget.busy,
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
    if (_faqs() case final faqs when faqs.isNotEmpty) ReviewFaq(items: faqs),
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
