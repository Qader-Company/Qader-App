import 'package:easy_localization/easy_localization.dart';
import '../../../../core/widgets/app_toast.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';
import 'offer_notices.dart';
import 'offer_overview.dart';

/// The offer was accepted; the company is preparing interview slots.
class OfferAwaitingInterview extends StatelessWidget {
  const OfferAwaitingInterview({
    super.key,
    required this.company,
    this.statusLabel = '',
  });
  final String company;

  /// The backend's scheduling status (`interview_status_label`); hidden
  /// when empty (preview data).
  final String statusLabel;
  @override
  Widget build(BuildContext context) => Column(
    children: [
      OfferPanel(
        title: ot(context, 'interview_scheduling'),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: AppColors.neutral200),
            ),
            child: Column(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  alignment: Alignment.center,
                  decoration: const BoxDecoration(
                    color: AppColors.blueSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: const BoxDecoration(
                      color: AppColors.blueStrong,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.schedule,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  ot(context, 'waiting_times_title'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (statusLabel.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  OfferChip(
                    statusLabel,
                    background: AppColors.blueSoft,
                    foreground: AppColors.blueStrong,
                  ),
                ],
                const SizedBox(height: 6),
                Text(
                  ot(
                    context,
                    'waiting_times_message',
                    args: {'company': company},
                  ),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.neutral600,
                  ),
                ),
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.blueSoft,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    ot(context, 'three_options'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: AppColors.blueStrong,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          OfferInfoBox(
            ot(context, 'offer_accepted_next', args: {'company': company}),
          ),
        ],
      ),
    ],
  );
}

/// The interview happening now: time, status, meeting link and the
/// apologize menu.
class OfferInterviewCard extends StatelessWidget {
  const OfferInterviewCard({
    super.key,
    required this.interview,
    required this.onApologize,
    required this.onJoin,
  });
  final OfferInterview interview;
  final VoidCallback onApologize, onJoin;

  Future<void> _copy(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    showAppToast(context, ot(context, 'link_copied'), type: ToastType.success);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final time = DateFormat.jm(locale);
    final link = interview.meetingUrl;
    return OfferPanel(
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                ot(context, 'interview'),
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            PopupMenuButton<int>(
              tooltip: ot(context, 'more_actions'),
              icon: const Icon(Icons.more_vert, size: 20),
              position: PopupMenuPosition.under,
              onSelected: (_) => onApologize(),
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 0,
                  child: Row(
                    children: [
                      const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                        color: AppColors.red600,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        ot(context, 'apologize'),
                        style: const TextStyle(color: AppColors.red600),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: 4),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColors.neutral100,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                DateFormat('EEEE, MMM d, y', locale).format(interview.start),
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${time.format(interview.start)} – ${time.format(interview.end)}'
                '${interview.timeZone.isEmpty ? '' : ' (${interview.timeZone})'}',
                style: const TextStyle(
                  fontSize: 12,
                  color: AppColors.neutral700,
                ),
              ),
              const SizedBox(height: 8),
              OfferChip(
                ot(context, 'minutes', args: {'count': '${interview.minutes}'}),
                background: AppColors.green100,
                foreground: AppColors.green700,
              ),
              const Divider(height: 24, color: AppColors.neutral200),
              Row(
                children: [
                  Expanded(
                    child: Text(
                      ot(context, 'meeting_status'),
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ),
                  const Icon(Icons.circle, size: 8, color: AppColors.green500),
                  const SizedBox(width: 6),
                  Text(
                    ot(context, 'in_progress'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.neutral900,
                    ),
                  ),
                ],
              ),
              if (link != null) ...[
                const SizedBox(height: 8),
                Text(
                  ot(context, 'meeting_link'),
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        link,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: ot(context, 'copy_link'),
                      onPressed: () => _copy(context, link),
                      icon: const Icon(
                        Icons.copy_rounded,
                        size: 18,
                        color: AppColors.neutral600,
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                height: 40,
                child: TextButton(
                  onPressed: onJoin,
                  style: TextButton.styleFrom(
                    backgroundColor: AppColors.blueDisabled,
                    foregroundColor: AppColors.blueStrong,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    ot(context, 'join_interview'),
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// After the company cancelled the interview: new slots are coming.
class OfferInterviewStatus extends StatelessWidget {
  const OfferInterviewStatus({super.key});
  @override
  Widget build(BuildContext context) => OfferPanel(
    title: ot(context, 'interview_status'),
    children: [
      OfferInfoBox(ot(context, 'new_times_coming')),
      const SizedBox(height: 12),
      Row(
        children: [
          const Icon(Icons.schedule, size: 16, color: AppColors.neutral600),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              ot(context, 'waiting_new_times'),
              style: const TextStyle(fontSize: 12, color: AppColors.neutral700),
            ),
          ),
        ],
      ),
    ],
  );
}
