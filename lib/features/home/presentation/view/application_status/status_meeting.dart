part of '../application_status_view.dart';

// Confirmed / completed interview card.

extension _MeetingSection on _ApplicationStatusViewState {
  Widget _meeting() {
    final completed = status == ApplicationStatus.completed;
    final booked = _booked;
    return _card([
      Row(
        children: [
          Expanded(
            child: _heading(
              completed
                  ? 'status_interview_completed'.tr(context: context)
                  : 'status_interview_confirmed_2'.tr(context: context),
            ),
          ),
          if (!completed && _canCancelInterview)
            _moreMenu(
              label: 'status_cancel_meeting'.tr(context: context),
              onSelected: cancelInterview,
            ),
        ],
      ),
      if (booked.start case final start?)
        _detail(
          'status_clock',
          completed
              ? 'status_interview_took_place_on'.tr(
                  context: context,
                  namedArgs: {
                    'day': _day(start),
                    'time': _range(start, booked.end),
                  },
                )
              : 'status_you_selected_slot'.tr(
                  context: context,
                  namedArgs: {
                    'day': _day(start),
                    'time': _range(start, booked.end),
                  },
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
                  'status_online'.tr(context: context),
                  color: QaderDesign.primary,
                  fill: _blueSoft,
                  dot: !completed,
                )
              : _Badge(
                  'status_offline'.tr(context: context),
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
              'status_round'.tr(
                context: context,
                namedArgs: {'round': _digits('${booked.round}')},
              ),
              color: _yellow,
              fill: _yellowSoft,
            ),
        ],
      ),
      if (!completed && online && !_canJoin)
        _disabledButton('status_join'.tr(context: context), height: 48)
      else if (!completed)
        DefaultButton.compact(
          height: 48,
          text: online
              ? 'status_join'.tr(context: context)
              : 'status_view_location'.tr(context: context),
          onPressed: live ? _openMeeting : previewNotice,
          child: _iconLabel(
            online ? Icons.co_present_outlined : 'status_map',
            online
                ? 'status_join'.tr(context: context)
                : 'status_view_location'.tr(context: context),
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
              ? 'status_we_re_now_reviewing_your_interview_you'.tr(
                  context: context,
                )
              : 'status_a_confirmation_email_will_be_sent_to'.tr(
                  context: context,
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
}
