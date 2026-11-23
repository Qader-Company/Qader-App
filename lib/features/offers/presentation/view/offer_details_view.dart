import 'package:flutter/material.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../domain/entities/talent_offer.dart';
import '../offers_copy.dart';
import '../widgets/apologize_dialog.dart';
import '../widgets/offer_back_link.dart';
import '../widgets/offer_contract_card.dart';
import '../widgets/offer_notices.dart';
import '../widgets/offer_overview.dart';
import '../widgets/offer_progress_sections.dart';
import '../widgets/offer_terms_card.dart';
import 'offers_scaffold.dart';

/// Designed screen of a sample offer in a stage the live details screen
/// cannot show yet (interview, closed, contracted). Offer, negotiation and
/// waiting-for-interview previews use [LiveOfferDetailsView] instead (see
/// `PreviewOfferDetailsView`).
///
/// Actions open their dialogs, then explain that the API is not connected
/// yet; nothing is sent.
class OfferDetailsView extends StatelessWidget {
  const OfferDetailsView({super.key, required this.offer});
  final TalentOffer offer;

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
      header: AppPageHeader(title: ot(context, 'my_offers')),
      children: [
        const OfferBackLink(),
        if ({
              OfferStage.interviewCancelled,
              OfferStage.interviewApologized,
            }.contains(offer.stage) &&
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
        OfferHiringProgress(
          step: offer.stage.progressStep,
          failed: offer.stage.failed,
          completed: offer.stage == OfferStage.contracted,
        ),
        ..._stage(context, closedAt),
      ],
    );
  }

  List<Widget> _stage(BuildContext context, DateTime? closedAt) {
    Widget lastOffer() => OfferTermsCard(
      terms: offer.latest,
      heading: OfferCardTitle(ot(context, 'last_offer')),
      chip: ot(context, 'client_counter'),
    );
    return switch (offer.stage) {
      // Shown by LiveOfferDetailsView.
      OfferStage.awaitingResponse ||
      OfferStage.negotiating ||
      OfferStage.awaitingInterviewTimes => const [],
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
      OfferStage.interviewInProgress => [
        if (offer.interview case final interview?)
          OfferInterviewCard(
            interview: interview,
            onApologize: () => _apologize(context),
            onJoin: () => showOfferActionPending(context),
          ),
      ],
      OfferStage.interviewCancelled ||
      OfferStage.interviewApologized => [const OfferInterviewStatus()],
      OfferStage.contracted => [
        if (offer.contract case final contract?)
          OfferContractCard(contract: contract),
      ],
    };
  }
}
