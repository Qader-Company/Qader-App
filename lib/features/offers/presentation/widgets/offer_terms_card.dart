import 'package:easy_localization/easy_localization.dart';
import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';
import 'offer_overview.dart';

/// Accept / Reject / Negotiate under the latest client offer. A `null`
/// callback hides its button.
class OfferActions {
  const OfferActions({
    this.onAccept,
    this.onReject,
    this.onNegotiate,
    this.busy = false,
  });
  final VoidCallback? onAccept, onReject, onNegotiate;

  /// An action is in flight: buttons are disabled.
  final bool busy;

  bool get isEmpty =>
      onAccept == null && onReject == null && onNegotiate == null;
}

/// One version of the offer's terms: salary, conditions, who sent it and,
/// for the offer awaiting a reply, the actions.
class OfferTermsCard extends StatelessWidget {
  const OfferTermsCard({
    super.key,
    required this.terms,
    required this.heading,
    this.chip,
    this.actions,
  });
  final OfferTerms terms;

  /// Title row, e.g. "Offer Details" or "3  Client Offer".
  final Widget heading;

  /// Under the heading, e.g. "Original".
  final String? chip;
  final OfferActions? actions;
  @override
  Widget build(BuildContext context) {
    final days = offerWorkdays(context, terms.firstWorkday, terms.lastWorkday);
    final hours =
        offerHours(context, terms.workStart, terms.workEnd) ??
        switch (terms.hoursPerDay) {
          final count? => ot(
            context,
            'hours_per_day',
            args: {'count': NumberFormat.decimalPattern().format(count)},
          ),
          null => null,
        };
    final hybridDays = offerDayNames(context, terms.hybridDays);
    final respondBy = terms.respondBy;
    return OfferPanel(
      children: [
        heading,
        if (chip != null) ...[
          const SizedBox(height: 8),
          OfferChip(
            chip!,
            background: AppColors.neutral100,
            foreground: AppColors.neutral700,
          ),
        ],
        const SizedBox(height: 8),
        Text.rich(
          TextSpan(
            text: offerMoney(context, terms.salary, terms.currency),
            children: [
              TextSpan(
                text: ' ${ot(context, 'per_month')}',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: AppColors.blueStrong,
                ),
              ),
            ],
          ),
          style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: AppColors.blueStrong,
          ),
        ),
        Text(
          ot(context, 'offered_salary'),
          style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
        ),
        const Divider(height: 20, color: AppColors.neutral200),
        if (terms.workType case final type?)
          OfferLabeledValue(
            ot(context, 'work_type'),
            offerCodeLabel(context, type),
          ),
        if (terms.workMode.isNotEmpty)
          OfferLabeledValue(
            ot(context, 'work_mode'),
            offerCodeLabel(context, terms.workMode),
          ),
        if (hybridDays != null)
          OfferLabeledValue(ot(context, 'hybrid_days'), hybridDays),
        if (terms.location case final location?)
          OfferLabeledValue(ot(context, 'work_location'), location),
        if (terms.noticeDays case final notice?)
          OfferLabeledValue(
            ot(context, 'notice_period'),
            offerNotice(context, notice),
          ),
        if (terms.sentAt case final sent?)
          OfferLabeledValue(ot(context, 'sent'), offerDateTime(context, sent)),
        if (days != null) OfferLabeledValue(ot(context, 'working_days'), days),
        if (hours != null)
          OfferLabeledValue(ot(context, 'working_hours'), hours),
        if (respondBy != null)
          OfferLabeledValue(
            ot(context, 'respond_by'),
            offerDateTime(context, respondBy),
          ),
        const Divider(height: 20, color: AppColors.neutral200),
        Text(
          // Live offers carry no names, only who proposed them.
          terms.by.isEmpty
              ? ot(
                  context,
                  terms.party == OfferParty.client ? 'from_client' : 'from_you',
                )
              : ot(
                  context,
                  terms.party == OfferParty.client
                      ? 'offered_by'
                      : 'counter_from',
                  args: {'name': terms.by},
                ),
          style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
        ),
        if (actions case final actions? when !actions.isEmpty) ...[
          if (actions.onAccept case final onAccept?) ...[
            const SizedBox(height: 12),
            DefaultButton.compact(
              text: ot(context, 'accept_offer'),
              isLoading: actions.busy,
              onPressed: actions.busy ? null : onAccept,
            ),
          ],
          if (actions.onReject != null || actions.onNegotiate != null) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                if (actions.onReject case final onReject?)
                  Expanded(
                    child: DefaultButton.compact(
                      text: ot(context, 'reject'),
                      isOutlined: true,
                      color: AppColors.red300,
                      textColor: AppColors.red600,
                      onPressed: actions.busy ? null : onReject,
                    ),
                  ),
                if (actions.onReject != null && actions.onNegotiate != null)
                  const SizedBox(width: 10),
                if (actions.onNegotiate case final onNegotiate?)
                  Expanded(
                    child: DefaultButton.compact(
                      text: ot(context, 'negotiate'),
                      isOutlined: true,
                      color: AppColors.neutral300,
                      textColor: AppColors.neutral700,
                      onPressed: actions.busy ? null : onNegotiate,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ],
    );
  }
}

/// "3  Client Offer": the number of a version in the negotiation history.
class OfferVersionHeading extends StatelessWidget {
  const OfferVersionHeading({
    super.key,
    required this.number,
    required this.party,
  });
  final int number;
  final OfferParty party;
  @override
  Widget build(BuildContext context) => Row(
    children: [
      Container(
        width: 24,
        height: 24,
        alignment: Alignment.center,
        decoration: const BoxDecoration(
          color: AppColors.blueSoft,
          shape: BoxShape.circle,
        ),
        child: Text(
          '$number',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColors.blueStrong,
          ),
        ),
      ),
      const SizedBox(width: 8),
      Text(
        party.title(context),
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
      ),
    ],
  );
}

/// Plain section title inside a terms card ("Offer Details", "Last Offer").
class OfferCardTitle extends StatelessWidget {
  const OfferCardTitle(this.text, {super.key});
  final String text;
  @override
  Widget build(BuildContext context) => Text(
    text,
    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
  );
}
