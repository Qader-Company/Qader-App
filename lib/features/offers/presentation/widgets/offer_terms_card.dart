import 'package:flutter/material.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/default_button.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import 'offer_badges.dart';
import 'offer_overview.dart';

/// Accept / Reject / Negotiate under the latest client offer.
class OfferActions {
  const OfferActions({
    required this.onAccept,
    required this.onReject,
    required this.onNegotiate,
  });
  final VoidCallback onAccept, onReject, onNegotiate;
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
    final hours = offerHours(context, terms.workStart, terms.workEnd);
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
        OfferLabeledValue(
          ot(context, 'work_mode'),
          offerCodeLabel(context, terms.workMode),
        ),
        if (terms.noticeDays case final notice?)
          OfferLabeledValue(
            ot(context, 'notice_period'),
            offerNotice(context, notice),
          ),
        OfferLabeledValue(
          ot(context, 'sent'),
          offerDateTime(context, terms.sentAt),
        ),
        if (days != null) OfferLabeledValue(ot(context, 'working_days'), days),
        if (hours != null)
          OfferLabeledValue(ot(context, 'working_hours'), hours),
        const Divider(height: 20, color: AppColors.neutral200),
        Text(
          ot(
            context,
            terms.party == OfferParty.client ? 'offered_by' : 'counter_from',
            args: {'name': terms.by},
          ),
          style: const TextStyle(fontSize: 11, color: AppColors.neutral600),
        ),
        if (actions case final actions?) ...[
          const SizedBox(height: 12),
          DefaultButton.compact(
            text: ot(context, 'accept_offer'),
            onPressed: actions.onAccept,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DefaultButton.compact(
                  text: ot(context, 'reject'),
                  isOutlined: true,
                  color: AppColors.red300,
                  textColor: AppColors.red600,
                  onPressed: actions.onReject,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DefaultButton.compact(
                  text: ot(context, 'negotiate'),
                  isOutlined: true,
                  color: AppColors.neutral300,
                  textColor: AppColors.neutral700,
                  onPressed: actions.onNegotiate,
                ),
              ),
            ],
          ),
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
