import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/router/app_router.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import '../widgets/apologize_dialog.dart';
import '../widgets/counter_offer_dialog.dart';
import '../widgets/offer_contract_card.dart';
import '../widgets/offer_notices.dart';
import '../widgets/offer_overview.dart';
import '../widgets/offer_progress_sections.dart';
import '../widgets/offer_terms_card.dart';
import 'offers_scaffold.dart';

/// One offer: company, hiring progress and the section of its stage.
///
/// Actions open their dialogs, then explain that the offers API is not
/// connected yet; nothing is sent.
class OfferDetailsView extends StatelessWidget {
  const OfferDetailsView({super.key, required this.offer});
  final TalentOffer offer;

  void _back(BuildContext context) =>
      context.canPop() ? context.pop() : context.go(AppRouter.offers);

  Future<void> _negotiate(BuildContext context) async {
    final draft = await showCounterOfferDialog(context, offer.latest);
    if (draft != null && context.mounted) {
      await showOfferActionPending(context);
    }
  }

  Future<void> _apologize(BuildContext context) async {
    final interview = offer.interview;
    if (interview == null) return;
    final reason = await showApologizeDialog(context, interview);
    if (reason != null && context.mounted) {
      await showOfferActionPending(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final closedAt = offer.closedAt;
    return OffersScaffold(
      header: AppPageHeader(title: ot(context, 'my_offers'), showSearch: false),
      children: [
        Align(
          alignment: AlignmentDirectional.centerStart,
          child: TextButton.icon(
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              foregroundColor: AppColors.neutral900,
            ),
            onPressed: () => _back(context),
            icon: Icon(
              Directionality.of(context) == TextDirection.rtl
                  ? Icons.arrow_forward
                  : Icons.arrow_back,
              size: 20,
            ),
            label: Text(
              ot(context, 'back_to_offers'),
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
        ),
        if (offer.stage == OfferStage.interviewCancelled &&
            offer.interview != null)
          OfferAlertBanner(
            icon: Icons.warning_rounded,
            title: ot(
              context,
              'interview_cancelled_title',
              args: {'company': offer.company.name},
            ),
            message: ot(
              context,
              'interview_cancelled_message',
              args: {'date': offerDate(context, offer.interview!.start)},
            ),
          ),
        OfferCompanyCard(
          company: offer.company,
          onWebsite: offer.company.website == null
              ? null
              : () => showOfferActionPending(context),
        ),
        OfferHiringProgress(stage: offer.stage),
        ..._stage(context, closedAt),
      ],
    );
  }

  List<Widget> _stage(BuildContext context, DateTime? closedAt) {
    final actions = OfferActions(
      onAccept: () => showOfferActionPending(context),
      onReject: () => showOfferActionPending(context),
      onNegotiate: () => _negotiate(context),
    );
    Widget lastOffer() => OfferTermsCard(
      terms: offer.latest,
      heading: OfferCardTitle(ot(context, 'last_offer')),
      chip: ot(context, 'client_counter'),
    );
    return switch (offer.stage) {
      OfferStage.awaitingResponse => [
        OfferTermsCard(
          terms: offer.latest,
          heading: OfferCardTitle(ot(context, 'offer_details')),
          actions: actions,
        ),
      ],
      OfferStage.negotiating => [
        for (var i = 0; i < offer.terms.length; i++)
          OfferTermsCard(
            terms: offer.terms[i],
            heading: OfferVersionHeading(
              number: offer.terms.length - i,
              party: offer.terms[i].party,
            ),
            chip: offer.terms[i].original ? ot(context, 'original') : null,
            // Only the newest client offer can be answered.
            actions: i == 0 && offer.terms[i].party == OfferParty.client
                ? actions
                : null,
          ),
      ],
      OfferStage.rejectedByTalent => [
        OfferAlertBanner(
          title: ot(context, 'rejected_title'),
          message: ot(
            context,
            'rejected_message',
            args: {
              'date': closedAt == null ? '' : offerDate(context, closedAt),
            },
          ),
        ),
        lastOffer(),
      ],
      OfferStage.cancelledNoResponse => [
        OfferAlertBanner(
          title: ot(context, 'cancelled_title'),
          message: ot(
            context,
            'cancelled_message',
            args: {
              'date': closedAt == null ? '' : offerDate(context, closedAt),
            },
          ),
        ),
        lastOffer(),
        if (offer.noResponseChancesLeft case final chances?)
          OfferNoResponseWarning(chancesLeft: chances),
      ],
      OfferStage.awaitingInterviewTimes => [
        OfferAwaitingInterview(company: offer.company.name),
      ],
      OfferStage.interviewInProgress => [
        if (offer.interview case final interview?)
          OfferInterviewCard(
            interview: interview,
            onApologize: () => _apologize(context),
            onJoin: () => showOfferActionPending(context),
          ),
      ],
      OfferStage.interviewCancelled => [const OfferInterviewStatus()],
      OfferStage.contracted => [
        if (offer.contract case final contract?)
          OfferContractCard(contract: contract),
      ],
    };
  }
}
