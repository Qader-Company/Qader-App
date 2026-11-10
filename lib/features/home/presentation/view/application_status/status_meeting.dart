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
}
