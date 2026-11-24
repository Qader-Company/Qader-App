import 'package:flutter/material.dart';
import '../../../../core/network/failure.dart';
import '../../domain/entities/hiring_interview.dart';
import '../../domain/entities/talent_offer.dart';
import '../cubit/offer_details_cubit.dart';
import '../offers_copy.dart';
import 'apologize_dialog.dart';
import 'counter_offer_dialog.dart';

/// The talent's answers on the offer details screen: each asks what it
/// needs (a confirmation, terms, a reason), calls [OfferDetailsCubit],
/// which reloads the offer, and reports the result in a toast.

Future<void> acceptOfferFlow(
  BuildContext context,
  OfferDetailsCubit cubit,
) async {
  final go = await confirmOfferAction(
    context,
    title: ot(context, 'accept_confirm_title'),
    message: ot(context, 'accept_confirm_message'),
    action: ot(context, 'accept_offer'),
  );
  if (!go || !context.mounted) return;
  final failure = await cubit.accept();
  if (context.mounted) _report(context, failure, 'accepted_done');
}

Future<void> rejectOfferFlow(
  BuildContext context,
  OfferDetailsCubit cubit,
) async {
  final go = await confirmOfferAction(
    context,
    title: ot(context, 'reject_confirm_title'),
    message: ot(context, 'reject_confirm_message'),
    action: ot(context, 'reject'),
    destructive: true,
  );
  if (!go || !context.mounted) return;
  final failure = await cubit.reject();
  if (context.mounted) _report(context, failure, 'rejected_done');
}

/// Counters starting from [base], the newest client terms.
Future<void> counterOfferFlow(
  BuildContext context,
  OfferDetailsCubit cubit,
  OfferTerms base,
) async {
  final offer = await showCounterOfferDialog(context, base);
  if (offer == null || !context.mounted) return;
  final failure = await cubit.counter(offer);
  if (context.mounted) _report(context, failure, 'counter_done');
}

Future<void> acceptInterviewTimeFlow(
  BuildContext context,
  OfferDetailsCubit cubit,
) async {
  final failure = await cubit.acceptInterviewTime();
  if (context.mounted) _report(context, failure, 'time_accepted');
}

/// Request a new time ([change]) or apologize: both need a reason.
Future<void> interviewReasonFlow(
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
  _report(context, failure, change ? 'change_requested' : 'apology_sent');
}

void _report(BuildContext context, Failure? failure, String successKey) {
  showOfferActionResult(
    context,
    failure: failure?.message,
    success: ot(context, successKey),
  );
}
