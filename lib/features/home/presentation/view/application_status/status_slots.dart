part of '../application_status_view.dart';

// Interview slot selection (available / empty slots) and its actions.

extension _SlotsSection on _ApplicationStatusViewState {
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
        color: AppColors.red300,
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
        onTap: () => _update(() => selected = i),
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
                  color: isSelected ? Colors.white : AppColors.neutral100,
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
                child: SpacedColumn(
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
}
