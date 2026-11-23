import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../../core/resources/app_colors.dart';
import '../../../../core/widgets/app_page_header.dart';
import '../../../../core/widgets/default_button.dart';
import '../../../../core/widgets/locale_change_listener.dart';
import '../../domain/entities/hiring_interview.dart';
import '../../domain/entities/hiring_offer_details.dart';
import '../../domain/entities/talent_offer.dart';
import '../../domain/repositories/offers_repository.dart';
import '../cubit/offer_details_cubit.dart';
import '../offers_copy.dart';
import '../widgets/apologize_dialog.dart';
import '../widgets/counter_offer_dialog.dart';
import '../widgets/live_interview_card.dart';
import '../widgets/offer_back_link.dart';
import '../widgets/offer_card_skeleton.dart';
import '../widgets/offer_notices.dart';
import '../widgets/offer_overview.dart';
import '../widgets/offer_progress_sections.dart';
import '../widgets/offer_terms_card.dart';
import 'offers_scaffold.dart';
import '../../domain/entities/hiring_codes.dart';

/// A signed-in talent's offer from `GET /talent/hiring-offers/{id}`:
/// company, hiring progress, status notice and every version of the terms.
///
/// Accept / reject / counter appear when `available_actions` allows them.
class LiveOfferDetailsView extends StatelessWidget {
  const LiveOfferDetailsView({super.key, required this.offerId});
  final String offerId;

  @override
  Widget build(BuildContext context) => BlocProvider(
    // A new offer id needs a new cubit: without the key, going from one
    // offer to another in place keeps showing the first one.
    key: ValueKey(offerId),
    create: (context) =>
        OfferDetailsCubit(context.read<OffersRepository>(), offerId)..load(),
    child: BlocBuilder<OfferDetailsCubit, OfferDetailsState>(
      builder: (context, state) {
        final cubit = context.read<OfferDetailsCubit>();
        final details = state.details;
        final busy = state.submitting || state.loading;
        // Statuses and labels come localized from the backend.
        return LocaleChangeListener(
          onChanged: cubit.load,
          child: OffersScaffold(
            onRefresh: details == null ? null : cubit.load,
            header: AppPageHeader(title: ot(context, 'my_offers')),
            children: [
              const OfferBackLink(),
              if (details != null)
                ..._content(context, details, cubit, busy)
              else if (state.loading)
                const OfferDetailsSkeleton()
              else
                _LoadError(onRetry: cubit.load),
            ],
          ),
        );
      },
    ),
  );

  Future<void> _accept(BuildContext context, OfferDetailsCubit cubit) async {
    final go = await confirmOfferAction(
      context,
      title: ot(context, 'accept_confirm_title'),
      message: ot(context, 'accept_confirm_message'),
      action: ot(context, 'accept_offer'),
    );
    if (!go || !context.mounted) return;
    final failure = await cubit.accept();
    if (!context.mounted) return;
    showOfferActionResult(
      context,
      failure: failure?.message,
      success: ot(context, 'accepted_done'),
    );
  }

  Future<void> _reject(BuildContext context, OfferDetailsCubit cubit) async {
    final go = await confirmOfferAction(
      context,
      title: ot(context, 'reject_confirm_title'),
      message: ot(context, 'reject_confirm_message'),
      action: ot(context, 'reject'),
      destructive: true,
    );
    if (!go || !context.mounted) return;
    final failure = await cubit.reject();
    if (!context.mounted) return;
    showOfferActionResult(
      context,
      failure: failure?.message,
      success: ot(context, 'rejected_done'),
    );
  }

  Future<void> _counter(
    BuildContext context,
    OfferDetailsCubit cubit,
    OfferTerms base,
  ) async {
    final offer = await showCounterOfferDialog(context, base);
    if (offer == null || !context.mounted) return;
    final failure = await cubit.counter(offer);
    if (!context.mounted) return;
    showOfferActionResult(
      context,
      failure: failure?.message,
      success: ot(context, 'counter_done'),
    );
  }

  Future<void> _acceptTime(
    BuildContext context,
    OfferDetailsCubit cubit,
  ) async {
    final failure = await cubit.acceptInterviewTime();
    if (!context.mounted) return;
    showOfferActionResult(
      context,
      failure: failure?.message,
      success: ot(context, 'time_accepted'),
    );
  }

  /// Request a new time ([change]) or apologize: both need a reason.
  Future<void> _interviewReason(
    BuildContext context,
    OfferDetailsCubit cubit,
    HiringInterview interview, {
    required bool change,
  }) async {
    final reason = await showInterviewReasonDialog(
      context,
      start: interview.start,
      end: interview.end,
      change: change,
    );
    if (reason == null || !context.mounted) return;
    final failure = change
        ? await cubit.requestInterviewChange(reason)
        : await cubit.apologizeForInterview(reason);
    if (!context.mounted) return;
    showOfferActionResult(
      context,
      failure: failure?.message,
      success: ot(context, change ? 'change_requested' : 'apology_sent'),
    );
  }

  /// Accept / reject / counter buttons (see [HiringOfferDetails.allows]).
  /// Countering starts from the newest client terms.
  OfferActions? _actions(
    BuildContext context,
    HiringOfferDetails details,
    OfferDetailsCubit cubit,
    bool busy,
  ) {
    final base = details.terms
        .where((terms) => terms.party == OfferParty.client)
        .firstOrNull;
    final actions = OfferActions(
      busy: busy,
      onAccept: details.allows(OfferAction.accept)
          ? () => _accept(context, cubit)
          : null,
      onReject: details.allows(OfferAction.reject)
          ? () => _reject(context, cubit)
          : null,
      onNegotiate: details.allows(OfferAction.counter) && base != null
          ? () => _counter(context, cubit, base)
          : null,
    );
    return actions.isEmpty ? null : actions;
  }

  List<Widget> _content(
    BuildContext context,
    HiringOfferDetails details,
    OfferDetailsCubit cubit,
    bool busy,
  ) {
    final terms = details.terms;
    final actions = _actions(context, details, cubit, busy);
    final reason = switch (details.status) {
      ItemStatus.rejected => details.rejectionReason,
      ItemStatus.cancelled => details.cancellationReason,
      _ => null,
    };
    return [
      if (details.status == ItemStatus.onHold)
        OfferInfoBox(
          details.holdReason ??
              offerStatusText(context, details.status, details.statusLabel),
        ),
      OfferCompanyCard(company: details.company),
      OfferHiringProgress(
        step: details.progressStep,
        failed: details.failed,
        completed: details.completed,
        withInterview: details.interviewRequired,
      ),
      // As in Figma: a closed offer shows its banner under the progress,
      // then only the last offer.
      if (details.failed) ...[
        OfferAlertBanner(
          title: offerStatusText(context, details.status, details.statusLabel),
          message: reason ?? '',
        ),
        if (terms.firstOrNull case final last?)
          OfferTermsCard(
            terms: last,
            heading: OfferCardTitle(ot(context, 'last_offer')),
            chip: last.original
                ? ot(context, 'original')
                : last.party == OfferParty.client
                ? ot(context, 'client_counter')
                : last.party.title(context),
          ),
      ],
      if (details.expired)
        OfferAlertBanner(
          icon: Icons.schedule,
          title: ot(context, 'expired_title'),
          message: ot(context, 'expired_message'),
        ),
      if (details.awaitingCompany)
        OfferInfoBox(
          ot(
            context,
            'awaiting_company',
            args: {'company': details.company.name},
          ),
        ),
      // As in Figma: once accepted, the scheduling section replaces the
      // terms until the interview exists; then the interview leads.
      if (details.failed)
        ...const []
      else if (details.awaitingInterviewTimes)
        OfferAwaitingInterview(
          company: details.company.name,
          statusLabel: details.interviewStatusLabel,
        )
      else if (details.interview case final interview?)
        LiveInterviewCard(
          interview: interview,
          busy: busy,
          // Buttons follow `interview.available_actions` only.
          onAccept: interview.actions.contains(InterviewAction.acceptSchedule)
              ? () => _acceptTime(context, cubit)
              : null,
          onRequestChange:
              interview.actions.contains(InterviewAction.requestChange)
              ? () => _interviewReason(context, cubit, interview, change: true)
              : null,
          onApologize: interview.actions.contains(InterviewAction.apologize)
              ? () => _interviewReason(context, cubit, interview, change: false)
              : null,
        )
      else if (terms.length == 1)
        OfferTermsCard(
          terms: terms.single,
          heading: OfferCardTitle(ot(context, 'offer_details')),
          chip: terms.single.statusLabel.isEmpty
              ? null
              : terms.single.statusLabel,
          actions: actions,
        )
      else
        for (var i = 0; i < terms.length; i++)
          OfferTermsCard(
            terms: terms[i],
            heading: OfferVersionHeading(
              number: terms.length - i,
              party: terms[i].party,
            ),
            chip: terms[i].original
                ? ot(context, 'original')
                : terms[i].statusLabel.isEmpty
                ? null
                : terms[i].statusLabel,
            // Actions answer the newest version.
            actions: i == 0 ? actions : null,
          ),
    ];
  }
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.onRetry});
  final VoidCallback onRetry;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 8),
    child: Column(
      children: [
        const Icon(
          Icons.cloud_off_outlined,
          size: 40,
          color: AppColors.neutral500,
        ),
        const SizedBox(height: 12),
        Text(
          ot(context, 'details_failed'),
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 20 / 14),
        ),
        const SizedBox(height: 16),
        DefaultButton.compact(
          text: ot(context, 'try_again'),
          onPressed: onRetry,
        ),
      ],
    ),
  );
}
