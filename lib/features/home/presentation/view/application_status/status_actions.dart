part of '../application_status_view.dart';

// Notices and the slot / interview actions: live ones go through the
// widget's callbacks, preview ones only change the shown status.

extension _StatusActions on _ApplicationStatusViewState {
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

  void confirmSlot() {
    if (live) {
      if (_slots.isEmpty) return;
      final slot = _slots[selected.clamp(0, _slots.length - 1)];
      final select = widget.onSelectSlot;
      _runAction(select == null ? null : () => select(slot.id));
      return;
    }
    _update(() => status = ApplicationStatus.confirmed);
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
    _update(() => status = ApplicationStatus.cancelled);
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
    _update(() {
      rescheduled = true;
      status = ApplicationStatus.slots;
    });
  }
}
