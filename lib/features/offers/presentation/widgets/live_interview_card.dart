import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/resources/app_colors.dart';
import '../../domain/entities/hiring_interview.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';
import 'offer_overview.dart';

/// The item's interview from the API: when, its status and the talent's
/// answer (both labelled by the backend), the meeting link, and "Join"
/// while `can_join` is true.
class LiveInterviewCard extends StatelessWidget {
  const LiveInterviewCard({super.key, required this.interview});
  final HiringInterview interview;

  Future<void> _copy(BuildContext context, String link) async {
    await Clipboard.setData(ClipboardData(text: link));
    if (!context.mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(ot(context, 'link_copied'))));
  }

  Future<void> _join(String link) async {
    final uri = Uri.tryParse(link);
    if (uri != null) await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final time = DateFormat.jm(locale);
    final start = interview.start;
    final end = interview.end;
    final minutes = interview.minutes;
    final link = interview.meetingUrl;
    return OfferPanel(
      title: ot(context, 'interview'),
      children: [
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
              if (start != null) ...[
                Text(
                  DateFormat('EEEE, MMM d, y', locale).format(start),
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  end == null
                      ? time.format(start)
                      : '${time.format(start)} – ${time.format(end)}',
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral700,
                  ),
                ),
              ],
              if (minutes != null && minutes > 0) ...[
                const SizedBox(height: 8),
                OfferChip(
                  ot(context, 'minutes', args: {'count': '$minutes'}),
                  background: AppColors.green100,
                  foreground: AppColors.green700,
                ),
              ],
              const Divider(height: 24, color: AppColors.neutral200),
              if (interview.statusLabel.isNotEmpty)
                _Row(
                  label: ot(context, 'meeting_status'),
                  value: interview.statusLabel,
                ),
              if (interview.responseLabel.isNotEmpty) ...[
                const SizedBox(height: 8),
                _Row(
                  label: ot(context, 'your_response'),
                  value: interview.responseLabel,
                ),
              ],
              if (interview.responseReason case final reason?) ...[
                const SizedBox(height: 4),
                Text(
                  reason,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.neutral600,
                  ),
                ),
              ],
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
              if (interview.canJoin && link != null) ...[
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  height: 40,
                  child: TextButton(
                    onPressed: () => _join(link),
                    style: TextButton.styleFrom(
                      backgroundColor: AppColors.blueStrong,
                      foregroundColor: AppColors.white,
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
            ],
          ),
        ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  const _Row({required this.label, required this.value});
  final String label, value;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Expanded(
        child: Text(
          label,
          style: const TextStyle(fontSize: 12, color: AppColors.neutral600),
        ),
      ),
      Text(
        value,
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.neutral900,
        ),
      ),
    ],
  );
}
