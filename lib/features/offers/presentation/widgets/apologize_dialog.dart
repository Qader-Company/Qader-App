import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/default_form_field.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';
import 'offer_dialog_frame.dart';

/// "Apologize & Reschedule" for a confirmed [interview]. Returns the
/// talent's reason, or `null` when cancelled.
Future<String?> showApologizeDialog(
  BuildContext context,
  OfferInterview interview,
) => showInterviewReasonDialog(
  context,
  start: interview.start,
  end: interview.end,
  timeZone: interview.timeZone,
);

/// Asks why the talent cannot keep the interview at [start]–[end]: an
/// apology ([change] false, the interview is cancelled) or a request for
/// another time ([change] true). Returns the reason, or `null` when
/// cancelled. Both endpoints require it.
Future<String?> showInterviewReasonDialog(
  BuildContext context, {
  DateTime? start,
  DateTime? end,
  String timeZone = '',
  bool change = false,
}) => showDialog<String>(
  context: context,
  barrierColor: AppColors.barrier,
  builder: (_) => _ApologizeDialog(
    start: start,
    end: end,
    timeZone: timeZone,
    change: change,
  ),
);

class _ApologizeDialog extends StatefulWidget {
  const _ApologizeDialog({
    this.start,
    this.end,
    this.timeZone = '',
    this.change = false,
  });
  final DateTime? start, end;
  final String timeZone;
  final bool change;
  @override
  State<_ApologizeDialog> createState() => _ApologizeDialogState();
}

class _ApologizeDialogState extends State<_ApologizeDialog> {
  final _form = GlobalKey<FormState>();
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final locale = context.locale.toString();
    final time = DateFormat.jm(locale);
    final start = widget.start;
    final end = widget.end;
    final change = widget.change;
    return OfferDialogFrame(
      title: ot(context, change ? 'change_title' : 'apologize_title'),
      leading: Container(
        width: 36,
        height: 36,
        decoration: const BoxDecoration(
          color: AppColors.amber100,
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.warning_rounded,
          size: 20,
          color: AppColors.orange600,
        ),
      ),
      child: Form(
        key: _form,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              ot(context, change ? 'change_message' : 'apologize_message'),
              style: const TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.neutral600,
              ),
            ),
            if (start != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.neutral50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.neutral200),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      DateFormat('EEEE, MMM d, y', locale).format(start),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${time.format(start)}'
                      '${end == null ? '' : ' – ${time.format(end)}'}'
                      '${widget.timeZone.isEmpty ? '' : ' (${widget.timeZone})'}',
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.neutral600,
                      ),
                    ),
                    if (!change) ...[
                      const SizedBox(height: 8),
                      OfferChip(
                        ot(context, 'will_be_cancelled'),
                        background: AppColors.red50,
                        foreground: AppColors.red600,
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 12),
            DefaultFormField(
              key: const ValueKey('apologize-reason'),
              compact: true,
              requiredIndicator: true,
              label: ot(context, 'reschedule_reason'),
              hint: ot(context, 'reschedule_reason_hint'),
              controller: _reason,
              maxLines: 4,
              validator: (value) => (value?.trim().length ?? 0) < 10
                  ? ot(context, 'reason_too_short')
                  : null,
            ),
            const SizedBox(height: 16),
            DefaultButton.compact(
              text: ot(context, 'cancel'),
              isOutlined: true,
              color: AppColors.neutral300,
              textColor: AppColors.neutral700,
              onPressed: () => Navigator.pop(context),
            ),
            const SizedBox(height: 10),
            DefaultButton.compact(
              text: ot(context, change ? 'submit_change' : 'submit_apology'),
              color: change ? AppColors.blueStrong : AppColors.orange600,
              onPressed: () {
                if (!_form.currentState!.validate()) return;
                Navigator.pop(context, _reason.text.trim());
              },
            ),
          ],
        ),
      ),
    );
  }
}
