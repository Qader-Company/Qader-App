part of '../application_status_view.dart';

// Interview History (previous rounds).

extension _HistorySection on _ApplicationStatusViewState {
  bool get _showsHistory => live
      ? app!.history.isNotEmpty
      : switch (status) {
          ApplicationStatus.slots ||
          ApplicationStatus.cancelled ||
          ApplicationStatus.confirmed ||
          ApplicationStatus.completed => true,
          _ => false,
        };

  List<_HistoryEntry> get _historyEntries => [
    for (final entry in live ? app!.history : StatusPreviewData.history)
      _HistoryEntry(
        round: entry.round,
        completed: entry.completed,
        date: entry.start == null
            ? '-'
            : '${_day(entry.start!)}, ${_time(entry.start!)}',
        online: entry.online,
        location: entry.online ? null : entry.location,
      ),
  ];

  Widget _history() {
    if (!historyOpen) {
      return InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _update(() => historyOpen = true),
        child: _card([
          Row(
            children: [
              const Icon(Icons.history, size: 20, color: AppColors.neutral800),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'status_interview_history'.tr(context: context),
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
            'status_interview_history'.tr(context: context),
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
            tooltip: 'status_close'.tr(context: context),
            visualDensity: VisualDensity.compact,
            onPressed: () => _update(() => historyOpen = false),
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
    child: SpacedColumn(
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
                'status_technical_interview'.tr(context: context),
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
                    'status_completed'.tr(context: context),
                    color: _green,
                    fill: _greenSoft,
                  )
                : _Badge(
                    'status_upcoming'.tr(context: context),
                    color: QaderDesign.primary,
                    fill: _blueSoft,
                  ),
            _Badge(
              'status_round_number'.tr(
                context: context,
                namedArgs: {'round': '${entry.round}'},
              ),
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
              entry.online
                  ? 'status_online'.tr(context: context)
                  : 'status_offline'.tr(context: context),
              style: const TextStyle(fontSize: 12, color: _muted),
            ),
          ],
        ),
        if (entry.location != null) _detail('location', entry.location!),
      ],
    ),
  );
}
